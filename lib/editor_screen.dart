import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'smart_arabic_engine.dart';
import 'storage_vault.dart';
import 'share_card_studio.dart';

class EditorScreen extends StatefulWidget {
  final AppSettingsController settings;
  final StorageVaultController vault;
  final RuknNoteFile note;
  final bool initialEditMode;
  final String? initialSearchQuery;

  const EditorScreen({
    super.key,
    required this.settings,
    required this.vault,
    required this.note,
    this.initialEditMode = false,
    this.initialSearchQuery,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  late TextEditingController _textController;
  final ScrollController _readScrollController = ScrollController();
  final ScrollController _editScrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();

  late bool _isEditMode;
  bool _isToolbarExpanded = true;
  double _zoomFactor = 1.0;

  // البحث الذكي داخل المذكرة
  bool _showInNoteSearch = false;
  final TextEditingController _inNoteSearchCtrl = TextEditingController();
  String _inNoteQuery = '';
  List<SmartMatchRange> _matches = [];
  int _currentMatchIndex = 0;

  // التراجع والإعادة (Undo / Redo)
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isApplyingUndoRedo = false;

  // الحفظ التلقائي
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  // زر القفز السريع (أول / آخر المستند)
  bool _showJumpButton = false;
  bool _jumpToTop = false;

  AppSettingsController get s => widget.settings;
  StorageVaultController get v => widget.vault;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _isEditMode = widget.initialEditMode;
    _textController = TextEditingController(text: widget.note.content);
    _undoStack.add(widget.note.content);

    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.trim().isNotEmpty) {
      _showInNoteSearch = true;
      _inNoteSearchCtrl.text = widget.initialSearchQuery!.trim();
      _inNoteQuery = _inNoteSearchCtrl.text;
      _recomputeMatches();
    }

    _textController.addListener(_onTextChanged);
    _inNoteSearchCtrl.addListener(_onSearchQueryChanged);

    _readScrollController.addListener(_onScrollUpdated);
    _editScrollController.addListener(_onScrollUpdated);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    if (_hasUnsavedChanges) {
      v.saveNoteContent(widget.note, _textController.text);
    }
    _textController.dispose();
    _readScrollController.dispose();
    _editScrollController.dispose();
    _editorFocusNode.dispose();
    _inNoteSearchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flushSaveNow();
    }
  }

  void _onScrollUpdated() {
    final activeCtrl =
        _isEditMode ? _editScrollController : _readScrollController;
    if (!activeCtrl.hasClients) return;

    final maxScroll = activeCtrl.position.maxScrollExtent;
    final offset = activeCtrl.offset;

    final shouldShow = maxScroll > 260;
    final shouldJumpTop = offset > (maxScroll * 0.45);

    if (shouldShow != _showJumpButton || shouldJumpTop != _jumpToTop) {
      setState(() {
        _showJumpButton = shouldShow;
        _jumpToTop = shouldJumpTop;
      });
    }
  }

  void _onTextChanged() {
    if (_isApplyingUndoRedo) return;

    final current = _textController.text;
    if (_undoStack.isEmpty || _undoStack.last != current) {
      _undoStack.add(current);
      if (_undoStack.length > 60) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    }

    _hasUnsavedChanges = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 600), _flushSaveNow);

    if (_showInNoteSearch && _inNoteQuery.isNotEmpty) {
      _recomputeMatches();
    }
    setState(() {});
  }

  Future<void> _flushSaveNow() async {
    if (!_hasUnsavedChanges) return;
    _autoSaveTimer?.cancel();
    if (mounted) setState(() => _isSaving = true);
    await v.saveNoteContent(widget.note, _textController.text);
    _hasUnsavedChanges = false;
    if (mounted) setState(() => _isSaving = false);
  }

  void _onSearchQueryChanged() {
    final q = _inNoteSearchCtrl.text.trim();
    if (q == _inNoteQuery) return;
    setState(() {
      _inNoteQuery = q;
      _recomputeMatches();
    });
  }

  void _recomputeMatches() {
    if (_inNoteQuery.isEmpty) {
      _matches = [];
      _currentMatchIndex = 0;
      return;
    }
    _matches = SmartArabicEngine.findSmartMatchRanges(
      _textController.text,
      _inNoteQuery,
    );
    if (_matches.isEmpty) {
      _currentMatchIndex = 0;
    } else if (_currentMatchIndex >= _matches.length) {
      _currentMatchIndex = 0;
    }
  }

  void _jumpToMatch(int delta) {
    if (_matches.isEmpty) return;
    RuknHaptics.selection();
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex + delta + _matches.length) % _matches.length;
    });

    final match = _matches[_currentMatchIndex];
    final textLen = _textController.text.length;
    if (textLen == 0) return;

    final fraction = (match.start / textLen).clamp(0.0, 1.0);
    final activeCtrl =
        _isEditMode ? _editScrollController : _readScrollController;
    if (activeCtrl.hasClients) {
      final target = activeCtrl.position.maxScrollExtent * fraction;
      activeCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    if (_isEditMode) {
      _textController.selection = TextSelection(
        baseOffset: match.start,
        extentOffset: match.end,
      );
    }
  }

  // التبديل السلس بين وضع القراءة ووضع التحرير مع حفظ نسبة التمرير
  void _toggleReadEditMode() {
    RuknHaptics.light();
    double scrollFraction = 0.0;
    final oldCtrl =
        _isEditMode ? _editScrollController : _readScrollController;
    if (oldCtrl.hasClients && oldCtrl.position.maxScrollExtent > 0) {
      scrollFraction =
          (oldCtrl.offset / oldCtrl.position.maxScrollExtent).clamp(0.0, 1.0);
    }

    if (_isEditMode) {
      _flushSaveNow();
      _editorFocusNode.unfocus();
    }

    setState(() {
      _isEditMode = !_isEditMode;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newCtrl =
          _isEditMode ? _editScrollController : _readScrollController;
      if (newCtrl.hasClients && newCtrl.position.maxScrollExtent > 0) {
        newCtrl.jumpTo(newCtrl.position.maxScrollExtent * scrollFraction);
      }
      _onScrollUpdated();
    });
  }

  // إيقاف الاندفاع اللحظي وتنفيذ القفز لأول/آخر المستند
  void _performQuickJump() {
    RuknHaptics.light();
    final activeCtrl =
        _isEditMode ? _editScrollController : _readScrollController;
    if (!activeCtrl.hasClients) return;

    final target = _jumpToTop ? 0.0 : activeCtrl.position.maxScrollExtent;
    activeCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // ===========================================================================
  // تنفيذ أدوات شريط التحرير الذكي
  // ===========================================================================
  Future<void> _executeEditorTool(String toolId) async {
    RuknHaptics.light();
    switch (toolId) {
      case 'undo':
        if (_undoStack.length > 1) {
          _isApplyingUndoRedo = true;
          final current = _undoStack.removeLast();
          _redoStack.add(current);
          final prev = _undoStack.last;
          _textController.value = TextEditingValue(
            text: prev,
            selection: TextSelection.collapsed(offset: prev.length),
          );
          _isApplyingUndoRedo = false;
          _hasUnsavedChanges = true;
          _flushSaveNow();
          setState(() {});
        } else {
          showRuknToast(context, s, 'لا توجد خطوات سابقة للتراجع');
        }
        break;

      case 'redo':
        if (_redoStack.isNotEmpty) {
          _isApplyingUndoRedo = true;
          final next = _redoStack.removeLast();
          _undoStack.add(next);
          _textController.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
          _isApplyingUndoRedo = false;
          _hasUnsavedChanges = true;
          _flushSaveNow();
          setState(() {});
        } else {
          showRuknToast(context, s, 'لا توجد خطوات للإعادة');
        }
        break;

      case 'copy_all':
        await Clipboard.setData(ClipboardData(text: _textController.text));
        if (mounted) showRuknToast(context, s, 'تم نسخ كامل النص للحافظة');
        break;

      case 'paste':
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final clip = data?.text ?? '';
        if (clip.isNotEmpty) {
          _insertAtCursor(clip);
        }
        break;

      case 'search':
        setState(() {
          _showInNoteSearch = !_showInNoteSearch;
          if (!_showInNoteSearch) {
            _inNoteSearchCtrl.clear();
          }
        });
        break;

      case 'auto_format':
        final formatted =
            SmartArabicEngine.autoFormatArabicText(_textController.text);
        _replaceFullText(formatted);
        showRuknToast(context, s, 'تم تنسيق النص وترتيب المسافات وعلامات الترقيم');
        break;

      case 'calc_sum':
        final sel = _textController.selection;
        final targetText = (sel.isValid && !sel.isCollapsed)
            ? _textController.text.substring(sel.start, sel.end)
            : _textController.text;
        final res = SmartArabicEngine.calculateNumbersInText(targetText);
        if (res == null) {
          showRuknToast(
            context,
            s,
            'لم يتم العثور على أرقام في النص لحسابها',
            isError: true,
          );
        } else {
          await _showSumReportModal(res.count, res.sum, res.formattedReport);
        }
        break;

      case 'convert_numbers':
        final converted = SmartArabicEngine.toggleArabicIndicAndWesternDigits(
          _textController.text,
        );
        _replaceFullText(converted);
        showRuknToast(context, s, 'تم تبديل صيغة الأرقام (١٢٣ ⇄ 123)');
        break;

      case 'date_stamp':
        final stamp = SmartArabicEngine.getFormattedHijriAndGregorianNow();
        _insertAtCursor('\n$stamp\n');
        break;

      case 'bullet_list':
        _insertAtCursor('\n• ');
        break;

      case 'divider':
        _insertAtCursor('\n────────────────────\n');
        break;

      case 'share_card':
        await _flushSaveNow();
        if (mounted) {
          await showRuknShareCardStudio(
            context: context,
            settings: s,
            noteTitle: widget.note.title,
            noteContent: _textController.text,
          );
        }
        break;

      case 'clear_all':
        if (_textController.text.trim().isEmpty) return;
        await _confirmClearAllText();
        break;
    }
  }

  void _insertAtCursor(String insertion) {
    final text = _textController.text;
    final sel = _textController.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    final newText = text.replaceRange(start, end, insertion);
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );
  }

  void _replaceFullText(String newText) {
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  Future<void> _showSumReportModal(
    int count,
    double sum,
    String report,
  ) async {
    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: s.accentColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'الحاسبة الذكية للأرقام',
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: s.textMainColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: s.bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: s.borderColor),
              ),
              child: Text(
                report,
                style: TextStyle(
                  fontFamily: s.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                  color: s.textMainColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        color: s.textSubColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: Text(
                      'إدراج المجموع في المذكرة',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _insertAtCursor('\n$report\n');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAllText() async {
    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مسح كامل النص؟',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم تفريغ محتوى المذكرة بالكامل (يمكنك التراجع عبر زر التراجع فوراً).',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 13.5,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        color: s.textSubColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _replaceFullText('');
                    },
                    child: Text(
                      'مسح النص',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // نافذة تخصيص وترتيب أدوات التحرير (مقابض سحب على اليمين وسريعة الاستجابة)
  // ===========================================================================
  Future<void> _showCustomizeToolbarDialog() async {
    List<EditorToolItem> workingOrder = List.from(s.orderedAllTools);
    Set<String> hiddenSet = workingOrder
        .where((t) => !s.isToolVisible(t.id))
        .map((t) => t.id)
        .toSet();

    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // الرأس + زر استعادة الافتراضي في الأعلى
                  Row(
                    children: [
                      Icon(
                        Icons.Handyman_outlined,
                        color: s.accentColor,
                        size: 21,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تخصيص أدوات التحرير',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: s.textMainColor,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final confirm = await _confirmResetToolbar();
                          if (confirm) {
                            await s.resetToolbarToDefault();
                            setModalState(() {
                              workingOrder = List.from(s.orderedAllTools);
                              hiddenSet.clear();
                            });
                          }
                        },
                        child: Text(
                          'استعادة الافتراضي',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: s.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'اسحب من مقبض الترتيب على اليمين لتحريك الأداة للأعلى أو الأسفل بسهولة:',
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 12,
                      color: s.textSubColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // القائمة القابلة للسحب مع مقبض فوري الاستجابة على اليمين
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 330),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        buildDefaultDragHandles: false,
                        itemCount: workingOrder.length,
                        onReorder: (oldIndex, newIndex) {
                          RuknHaptics.selection();
                          setModalState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = workingOrder.removeAt(oldIndex);
                            workingOrder.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final tool = workingOrder[index];
                          final isVisible = !hiddenSet.contains(tool.id);

                          return Container(
                            key: ValueKey(tool.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: s.bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isVisible
                                    ? s.accentColor.withOpacity(0.45)
                                    : s.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                // مقبض السحب الفوري على اليمين (أول عنصر في صف RTL)
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    color: Colors.transparent,
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      color: s.accentColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                Icon(
                                  tool.icon,
                                  size: 19,
                                  color: isVisible
                                      ? s.textMainColor
                                      : s.textSubColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ReorderableDragStartListener(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        tool.label,
                                        style: TextStyle(
                                          fontFamily: s.fontFamily,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isVisible
                                              ? s.textMainColor
                                              : s.textSubColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: isVisible,
                                  activeColor: s.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (val) {
                                    RuknHaptics.selection();
                                    setModalState(() {
                                      if (val == true) {
                                        hiddenSet.remove(tool.id);
                                      } else {
                                        hiddenSet.add(tool.id);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  // أزرار الحفظ والإلغاء فقط في الأسفل
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              color: s.textSubColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: s.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await s.saveToolbarCustomization(
                              orderedIds:
                                  workingOrder.map((e) => e.id).toList(),
                              hiddenIds: hiddenSet,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) setState(() {});
                          },
                          child: Text(
                            'حفظ',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmResetToolbar() async {
    bool confirmed = false;
    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'استعادة الترتيب الافتراضي؟',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إظهار جميع أدوات التحرير وإعادتها إلى ترتيبها الأصلي.',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 13,
                color: s.textSubColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'تراجع',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        color: s.textSubColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      confirmed = true;
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      'تأكيد',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = (s.baseFontSize * _zoomFactor).clamp(12.0, 36.0);
    final stats = SmartArabicEngine.computeStats(_textController.text);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: s.paperColor,
        body: Column(
          children: [
            // 1. الشريط العلوي المدمج (مع تصغير كبسولة التكبير لإعطاء مساحة للعنوان)
            _buildTopAppBar(),

            // 2. شريط البحث داخل المذكرة (إن كان مفعلاً)
            if (_showInNoteSearch) _buildInNoteSearchBar(),

            // 3. شريط أدوات التحرير الذكي (في وضع التحرير)
            if (_isEditMode) _buildCollapsibleSmartToolbar(),

            // 4. مساحة القراءة / التحرير مع شريط التمرير الأيسر السريع
            Expanded(
              child: Stack(
                children: [
                  // وضع شريط التمرير على اليسار عبر Directionality.ltr حول RawScrollbar
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: RawScrollbar(
                      controller: _isEditMode
                          ? _editScrollController
                          : _readScrollController,
                      thumbVisibility: true,
                      interactive: true,
                      thickness: 6,
                      radius: const Radius.circular(8),
                      thumbColor: s.accentColor.withOpacity(0.55),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: _isEditMode
                            ? _buildEditorView(effectiveFontSize)
                            : _buildReaderView(effectiveFontSize),
                      ),
                    ),
                  ),

                  // الزر العائم الذكي في أسفل اليسار (أول المستند / آخر المستند)
                  if (_showJumpButton)
                    Positioned(
                      left: 16,
                      bottom: 14,
                      child: RuknSpringButton(
                        onTap: _performQuickJump,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: s.primaryColor.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: s.accentColor.withOpacity(0.65),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _jumpToTop
                                    ? Icons.vertical_align_top_rounded
                                    : Icons.vertical_align_bottom_rounded,
                                color: s.accentColor,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _jumpToTop ? 'أول المستند' : 'آخر المستند',
                                style: TextStyle(
                                  fontFamily: s.fontFamily,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 5. الشريط السفلي للإحصائيات وحالة الحفظ
            _buildBottomStatsBar(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    final zoomPct = (_zoomFactor * 100).round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [s.primaryColor, s.primaryDarkColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: s.primaryDarkColor.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // زر رجوع مدمج
              RuknSpringButton(
                onTap: () async {
                  await _flushSaveNow();
                  if (mounted) Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // عنوان المذكرة (بمساحة واسعة وواضحة)
              Expanded(
                child: Text(
                  widget.note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // كبسولة التكبير والتصغير المدمجة والصغيرة [ + | 100% | - ]
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: s.accentColor.withOpacity(0.40),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                      onTap: () {
                        RuknHaptics.selection();
                        setState(() {
                          _zoomFactor = (_zoomFactor + 0.1).clamp(0.7, 2.0);
                        });
                      },
                      child: const SizedBox(
                        width: 24,
                        height: 30,
                        child: Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        RuknHaptics.light();
                        setState(() => _zoomFactor = 1.0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        child: Text(
                          '$zoomPct%',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: s.accentColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      onTap: () {
                        RuknHaptics.selection();
                        setState(() {
                          _zoomFactor = (_zoomFactor - 0.1).clamp(0.7, 2.0);
                        });
                      },
                      child: const SizedBox(
                        width: 24,
                        height: 30,
                        child: Icon(
                          Icons.remove_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // زر التبديل بين وضع القراءة والتحرير
              RuknSpringButton(
                onTap: _toggleReadEditMode,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _isEditMode
                        ? s.accentColor
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: s.accentColor.withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEditMode
                            ? Icons.visibility_outlined
                            : Icons.edit_note_rounded,
                        size: 15,
                        color:
                            _isEditMode ? const Color(0xFF111827) : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isEditMode ? 'قراءة' : 'تحرير',
                        style: TextStyle(
                          fontFamily: s.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _isEditMode
                              ? const Color(0xFF111827)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInNoteSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: s.cardColor,
        border: Border(bottom: BorderSide(color: s.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: s.bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: s.borderColor),
              ),
              child: TextField(
                controller: _inNoteSearchCtrl,
                autofocus: true,
                style: TextStyle(
                  fontFamily: s.fontFamily,
                  fontSize: 13.5,
                  color: s.textMainColor,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث داخل هذه المذكرة...',
                  hintStyle: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 12.5,
                    color: s.textSubColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: s.accentColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _matches.isEmpty
                ? '0/0'
                : '${_currentMatchIndex + 1}/${_matches.length}',
            style: TextStyle(
              fontFamily: s.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: s.accentColor,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: s.textMainColor,
            ),
            onPressed: () => _jumpToMatch(-1),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: s.textMainColor,
            ),
            onPressed: () => _jumpToMatch(1),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: s.textSubColor,
            ),
            onPressed: () {
              setState(() {
                _showInNoteSearch = false;
                _inNoteSearchCtrl.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSmartToolbar() {
    final visibleTools = s.visibleEditorTools;
    final iconsOnly = s.toolbarShowIconsOnly;

    return Container(
      decoration: BoxDecoration(
        color: s.cardColor,
        border: Border(bottom: BorderSide(color: s.borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isToolbarExpanded)
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                itemCount: visibleTools.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, idx) {
                  if (idx == visibleTools.length) {
                    return GestureDetector(
                      onTap: _showCustomizeToolbarDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: s.bgColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: s.accentColor.withOpacity(0.55),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: s.accentColor,
                            ),
                            if (!iconsOnly) ...[
                              const SizedBox(width: 5),
                              Text(
                                'تخصيص',
                                style: TextStyle(
                                  fontFamily: s.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: s.accentColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  final tool = visibleTools[idx];
                  return Tooltip(
                    message: tool.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => _executeEditorTool(tool.id),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: iconsOnly ? 10 : 11,
                        ),
                        decoration: BoxDecoration(
                          color: s.bgColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: s.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tool.icon,
                              size: 17,
                              color: s.accentColor,
                            ),
                            if (!iconsOnly) ...[
                              const SizedBox(width: 5),
                              Text(
                                tool.label,
                                style: TextStyle(
                                  fontFamily: s.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: s.textMainColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // شريط طي / إظهار الأدوات المدمج
          GestureDetector(
            onTap: () {
              RuknHaptics.selection();
              setState(() => _isToolbarExpanded = !_isToolbarExpanded);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              color: s.bgColor.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isToolbarExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: s.textSubColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isToolbarExpanded ? 'إخفاء الأدوات' : 'إظهار الأدوات',
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: s.textSubColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderView(double fontSize) {
    final content = _textController.text;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: _toggleReadEditMode,
      child: SingleChildScrollView(
        controller: _readScrollController,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 64),
        child: SizedBox(
          width: double.infinity,
          child: content.trim().isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'المذكرة فارغة — اضغط على زر "تحرير" في الأعلى أو انقر مرتين للكتابة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 14,
                        color: s.textSubColor,
                      ),
                    ),
                  ),
                )
              : (_showInNoteSearch && _inNoteQuery.isNotEmpty)
                  ? SelectableText.rich(
                      SmartArabicEngine.buildHighlightedTextSpan(
                        text: content,
                        query: _inNoteQuery,
                        baseStyle: TextStyle(
                          fontFamily: s.fontFamily,
                          fontSize: fontSize,
                          height: 1.75,
                          color: s.textMainColor,
                        ),
                      ),
                    )
                  : SelectableText(
                      content,
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: fontSize,
                        height: 1.75,
                        color: s.textMainColor,
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEditorView(double fontSize) {
    return SingleChildScrollView(
      controller: _editScrollController,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 80),
      child: TextField(
        controller: _textController,
        focusNode: _editorFocusNode,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: TextStyle(
          fontFamily: s.fontFamily,
          fontSize: fontSize,
          height: 1.75,
          color: s.textMainColor,
        ),
        decoration: InputDecoration(
          hintText: 'ابدأ الكتابة في رُكْنك الخاص...',
          hintStyle: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: fontSize,
            color: s.textSubColor.withOpacity(0.55),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBottomStatsBar(DocumentStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: s.cardColor,
        border: Border(top: BorderSide(color: s.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '${stats.words} كلمة  •  ${stats.characters} حرف  •  ${stats.lines} سطر',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: s.textSubColor,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isSaving
                      ? Icons.sync_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: _isSaving ? s.accentColor : const Color(0xFF16A34A),
                ),
                const SizedBox(width: 4),
                Text(
                  _isSaving ? 'جارٍ الحفظ...' : 'محفوظ تلقائياً',
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.textSubColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
