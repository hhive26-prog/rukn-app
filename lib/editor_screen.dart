import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'storage_vault.dart';
import 'smart_arabic_engine.dart';
import 'share_card_studio.dart';

class RuknEditorScreen extends StatefulWidget {
  final AppSettingsController settings;
  final StorageVaultController vault;
  final RuknNoteFile initialNote;
  final String initialSearchQuery;
  final bool startInEditMode;

  const RuknEditorScreen({
    super.key,
    required this.settings,
    required this.vault,
    required this.initialNote,
    this.initialSearchQuery = '',
    this.startInEditMode = false,
  });

  @override
  State<RuknEditorScreen> createState() => _RuknEditorScreenState();
}

class _RuknEditorScreenState extends State<RuknEditorScreen>
    with WidgetsBindingObserver {
  late String _noteTitle;
  late bool _isEditMode;

  late final TextEditingController _textController;
  final FocusNode _editorFocusNode = FocusNode();

  final ScrollController _readScrollController = ScrollController();
  final ScrollController _editScrollController = ScrollController();

  // سجل التراجع والإعادة (Undo / Redo)
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isInternalTextChange = false;

  // متغيرات الحفظ التلقائي الفوري فائق الأمان
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  String _lastSavedContent = '';

  // متغيرات التمرير السريع الجانبي والقفز وثبات الموضع
  double _scrollFraction = 0.0;
  bool _isDraggingFastThumb = false;
  bool _showJumpMenuPopup = false;

  // البحث داخل المستند
  String _activeHighlightQuery = '';

  ScrollController get _activeScrollController =>
      _isEditMode ? _editScrollController : _readScrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _noteTitle = widget.initialNote.title;
    _isEditMode = widget.startInEditMode;
    _lastSavedContent = widget.initialNote.content;
    _activeHighlightQuery = widget.initialSearchQuery.trim();

    _textController = TextEditingController(text: widget.initialNote.content);
    _undoStack.add(widget.initialNote.content);

    _textController.addListener(_onEditorTextChanged);
    _readScrollController.addListener(_onScrollUpdated);
    _editScrollController.addListener(_onScrollUpdated);

    // تفعيل وضع "القهوة والقراءة" لإبقاء الشاشة مضاءة
    widget.settings.applyWakeLock(true);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (_isDirty) {
      widget.vault.saveNoteContent(_noteTitle, _textController.text);
    }
    widget.settings.applyWakeLock(false);
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_onEditorTextChanged);
    _readScrollController.removeListener(_onScrollUpdated);
    _editScrollController.removeListener(_onScrollUpdated);
    _textController.dispose();
    _editorFocusNode.dispose();
    _readScrollController.dispose();
    _editScrollController.dispose();
    super.dispose();
  }

  /// الحفظ التلقائي الفوري عند سحب ستارة الإشعارات أو وصول رسالة أو الخروج للخلفية
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _flushImmediateAutoSave();
    }
  }

  void _onScrollUpdated() {
    if (_isDraggingFastThumb) return;
    final ctrl = _activeScrollController;
    if (!ctrl.hasClients) return;
    final maxExtent = ctrl.position.maxScrollExtent;
    final frac = maxExtent <= 0 ? 0.0 : (ctrl.offset / maxExtent).clamp(0.0, 1.0);
    if ((frac - _scrollFraction).abs() > 0.005 && mounted) {
      setState(() {
        _scrollFraction = frac;
      });
    }
  }

  void _onEditorTextChanged() {
    if (_isInternalTextChange) return;
    final currentText = _textController.text;

    if (_undoStack.isEmpty || _undoStack.last != currentText) {
      _undoStack.add(currentText);
      if (_undoStack.length > 80) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    }

    if (currentText != _lastSavedContent) {
      _isDirty = true;
      _autoSaveTimer?.cancel();
      // حفظ تلقائي بعد 600ms من التوقف عن الكتابة
      _autoSaveTimer = Timer(const Duration(milliseconds: 600), () {
        _flushImmediateAutoSave();
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _flushImmediateAutoSave() async {
    _autoSaveTimer?.cancel();
    if (!_isDirty) return;
    final textToSave = _textController.text;
    _isDirty = false;
    _lastSavedContent = textToSave;
    await widget.vault.saveNoteContent(_noteTitle, textToSave);
  }

  /// التبديل بين وضعي القراءة والتحرير مع الحفاظ على نفس الموضع النسبي للسطور (prevScrollFraction)
  Future<void> _toggleEditReadMode(bool targetEditMode) async {
    if (_isEditMode == targetEditMode) return;

    double prevScrollFraction = _scrollFraction;
    if (_activeScrollController.hasClients) {
      final maxExt = _activeScrollController.position.maxScrollExtent;
      prevScrollFraction = maxExt <= 0
          ? 0.0
          : (_activeScrollController.offset / maxExt).clamp(0.0, 1.0);
    }

    if (!targetEditMode) {
      await _flushImmediateAutoSave();
      FocusScope.of(context).unfocus();
    }

    setState(() {
      _isEditMode = targetEditMode;
      _showJumpMenuPopup = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newCtrl = _activeScrollController;
      if (newCtrl.hasClients) {
        final newMax = newCtrl.position.maxScrollExtent;
        newCtrl.jumpTo((prevScrollFraction * newMax).clamp(0.0, newMax));
      }
      if (targetEditMode) {
        _editorFocusNode.requestFocus();
      }
    });
  }

  /// إيقاف اندفاع التمرير السريع (stopOngoingScrollFling) فور لمس مقبض التمرير الجانبي
  void _stopOngoingScrollFling() {
    final ctrl = _activeScrollController;
    if (ctrl.hasClients) {
      ctrl.jumpTo(ctrl.offset);
    }
  }

  void _scrollToFraction(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    setState(() {
      _scrollFraction = clamped;
    });
    final ctrl = _activeScrollController;
    if (ctrl.hasClients) {
      final maxExt = ctrl.position.maxScrollExtent;
      ctrl.jumpTo(clamped * maxExt);
    }
  }

  void _jumpToDocumentEdge({required bool toTop}) {
    setState(() => _showJumpMenuPopup = false);
    final ctrl = _activeScrollController;
    if (!ctrl.hasClients) return;
    final target = toTop ? 0.0 : ctrl.position.maxScrollExtent;
    ctrl.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// نافذة إعادة تسمية الملف عند الضغط على العنوان في الشريط العلوي
  Future<void> _showRenameFromHeaderDialog() async {
    final ctrl = TextEditingController(text: _noteTitle);
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'إعادة تسمية الملف',
      subtitle: 'سيتم تحديث اسم الملف وجميع نسخه الآمنة تلقائياً',
      headerIcon: Icons.drive_file_rename_outline_rounded,
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: widget.settings.primaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.settings.scaffoldBgColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 46,
            backgroundColor: widget.settings.activeTheme.primary,
            onTap: () async {
              await _flushImmediateAutoSave();
              try {
                final updated = await widget.vault.renameNote(
                  oldTitle: _noteTitle,
                  newRawTitle: ctrl.text,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  if (updated != null) {
                    setState(() => _noteTitle = updated.title);
                    showRuknToast(context, 'تم تغيير الاسم إلى: $_noteTitle');
                  }
                }
              } catch (_) {
                if (mounted) {
                  showRuknToast(
                    context,
                    'يوجد ملف آخر بنفس هذا الاسم!',
                    backgroundColor: const Color(0xFFDC2626),
                  );
                }
              }
            },
            child: const Text(
              'حفظ الاسم',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RuknSpringButton(
            height: 46,
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.borderColor,
            elevation: 0,
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: widget.settings.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// نافذة إعادة حجم الخط إلى 100% عند الضغط على النسبة المئوية في كبسولة التكبير
  Future<void> _showResetZoomDialog() async {
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'حجم عرض النص (${widget.settings.zoomPercent}%)',
      subtitle: 'هل ترغب في إعادة حجم النص إلى الوضع القياسي 100%؟',
      headerIcon: Icons.zoom_in_rounded,
      content: Text(
        'يمكنك دائماً التكبير والتصغير من 50% حتى 250% بخطوات 10% عبر كبسولة التكبير العلوية.',
        style: TextStyle(
          color: widget.settings.primaryTextColor,
          fontSize: 14.5,
          height: 1.5,
        ),
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: widget.settings.activeTheme.primary,
            onTap: () {
              widget.settings.setZoomPercent(100);
              Navigator.of(context).pop();
            },
            child: const Text(
              'إعادة إلى 100%',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.borderColor,
            elevation: 0,
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: widget.settings.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== تنفيذ أدوات التحرير الـ 15 ====================
  Future<void> _executeEditorTool(String toolId) async {
    final fullText = _textController.text;
    final sel = _textController.selection;
    final start = sel.isValid ? sel.start.clamp(0, fullText.length) : fullText.length;
    final end = sel.isValid ? sel.end.clamp(0, fullText.length) : fullText.length;

    switch (toolId) {
      case 'undo':
        if (_undoStack.length > 1) {
          _isInternalTextChange = true;
          final current = _undoStack.removeLast();
          _redoStack.add(current);
          final prev = _undoStack.last;
          _textController.value = TextEditingValue(
            text: prev,
            selection: TextSelection.collapsed(offset: prev.length),
          );
          _isInternalTextChange = false;
          _isDirty = true;
          _flushImmediateAutoSave();
          setState(() {});
        } else {
          showRuknToast(context, 'لا توجد خطوات سابقة للتراجع');
        }
        break;

      case 'redo':
        if (_redoStack.isNotEmpty) {
          _isInternalTextChange = true;
          final next = _redoStack.removeLast();
          _undoStack.add(next);
          _textController.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
          _isInternalTextChange = false;
          _isDirty = true;
          _flushImmediateAutoSave();
          setState(() {});
        } else {
          showRuknToast(context, 'لا توجد خطوات للإعادة');
        }
        break;

      case 'copy':
        final toCopy = start != end ? fullText.substring(start, end) : fullText;
        await Clipboard.setData(ClipboardData(text: toCopy));
        if (mounted) {
          showRuknToast(
            context,
            start != end ? 'تم نسخ النص المحدد' : 'تم نسخ كامل النص',
          );
        }
        break;

      case 'cut':
        if (start != end) {
          final cutPart = fullText.substring(start, end);
          await Clipboard.setData(ClipboardData(text: cutPart));
          final updated = fullText.replaceRange(start, end, '');
          _textController.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: start),
          );
          if (mounted) showRuknToast(context, 'تم قص النص المحدد');
        } else {
          showRuknToast(context, 'حدد نصاً أولاً لقصه');
        }
        break;

      case 'paste':
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final clip = data?.text ?? '';
        if (clip.isNotEmpty) {
          final updated = fullText.replaceRange(start, end, clip);
          _textController.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: start + clip.length),
          );
        }
        break;

      case 'select_all':
        _editorFocusNode.requestFocus();
        _textController.selection =
            TextSelection(baseOffset: 0, extentOffset: fullText.length);
        break;

      case 'select_up':
        _editorFocusNode.requestFocus();
        _textController.selection =
            TextSelection(baseOffset: end, extentOffset: 0);
        break;

      case 'select_down':
        _editorFocusNode.requestFocus();
        _textController.selection =
            TextSelection(baseOffset: start, extentOffset: fullText.length);
        break;

      case 'auto_format':
        final formatted = SmartArabicEngine.autoFormatArabicText(fullText);
        _textController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        showRuknToast(
          context,
          'تم التنسيق الآلي وضبط الفواصل والفقرات ✨',
          icon: Icons.auto_fix_high_rounded,
        );
        break;

      case 'smart_calc':
        final res = SmartArabicEngine.calculateAndAppendSum(fullText);
        final count = res['count'] as int;
        if (count == 0) {
          showRuknToast(
            context,
            'لم يتم العثور على أرقام في النص لجمعها',
            icon: Icons.info_outline_rounded,
          );
        } else {
          final updated = res['updatedText'] as String;
          final sumStr = res['formattedSum'] as String;
          _textController.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: updated.length),
          );
          showRuknToast(
            context,
            'تم جمع $count رقم • الإجمالي: $sumStr 💰',
            icon: Icons.functions_rounded,
          );
        }
        break;

      case 'num_convert':
        if (start != end) {
          final convertedSel = SmartArabicEngine.toggleArabicWesternNumbers(
            fullText.substring(start, end),
          );
          final updated = fullText.replaceRange(start, end, convertedSel);
          _textController.value = TextEditingValue(
            text: updated,
            selection: TextSelection(
              baseOffset: start,
              extentOffset: start + convertedSel.length,
            ),
          );
        } else {
          final convertedAll =
              SmartArabicEngine.toggleArabicWesternNumbers(fullText);
          _textController.value = TextEditingValue(
            text: convertedAll,
            selection: TextSelection.collapsed(
              offset: start.clamp(0, convertedAll.length),
            ),
          );
        }
        showRuknToast(context, 'تم تحويل صيغة الأرقام (١٢٣ ↔ 123)');
        break;

      case 'checklist':
        final updated =
            SmartArabicEngine.toggleChecklistAtCursor(fullText, start);
        _textController.value = TextEditingValue(
          text: updated,
          selection: TextSelection.collapsed(
            offset: (start + 2).clamp(0, updated.length),
          ),
        );
        break;

      case 'datetime':
        final stamp = SmartArabicEngine.getInsertableDateTimeString();
        final insertStr =
            (start > 0 && !fullText.substring(0, start).endsWith('\n'))
                ? '\n$stamp\n'
                : '$stamp\n';
        final updated = fullText.replaceRange(start, end, insertStr);
        _textController.value = TextEditingValue(
          text: updated,
          selection:
              TextSelection.collapsed(offset: start + insertStr.length),
        );
        break;

      case 'signature':
        if (widget.settings.signatureText.trim().isEmpty) {
          _showQuickSignatureSetupDialog();
        } else {
          final sig = '\n\n✒️ ${widget.settings.signatureText.trim()}\n';
          final updated = fullText.replaceRange(start, end, sig);
          _textController.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: start + sig.length),
          );
          showRuknToast(context, 'تم إدراج التوقيع');
        }
        break;

      case 'find_replace':
        _showSmartFindReplaceDialog();
        break;
    }
  }

  /// نافذة إعداد التوقيع السريعة إذا ضغط المستخدم على أداة التوقيع وهو فارغ
  Future<void> _showQuickSignatureSetupDialog() async {
    final sigCtrl =
        TextEditingController(text: widget.settings.signatureText);
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'إعداد التوقيع الشخصي ✒️',
      subtitle: 'اكتب توقيعك ليتم حفظه وإدراجه بلمسة زر دائماً',
      headerIcon: Icons.draw_rounded,
      content: TextField(
        controller: sigCtrl,
        autofocus: true,
        maxLines: 2,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: widget.settings.primaryTextColor),
        decoration: InputDecoration(
          hintText: 'مثال: كتبه أخوكم أبو فهد — الرياض',
          filled: true,
          fillColor: widget.settings.scaffoldBgColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: widget.settings.activeTheme.primary,
            onTap: () async {
              final text = sigCtrl.text.trim();
              await widget.settings.setSignatureText(text);
              if (mounted) {
                Navigator.of(context).pop();
                if (text.isNotEmpty) {
                  _executeEditorTool('signature');
                }
              }
            },
            child: const Text(
              'حفظ وإدراج التوقيع',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.borderColor,
            elevation: 0,
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: widget.settings.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// نافذة "بحث واستبدال" المعتمدة على محرك البحث العربي الذكي
  Future<void> _showSmartFindReplaceDialog() async {
    final findCtrl = TextEditingController(text: _activeHighlightQuery);
    final replaceCtrl = TextEditingController();

    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'بحث واستبدال ذكي',
      subtitle: 'يتجاهل التشكيل ويوحّد الهمزات والتاء المربوطة تلقائياً',
      headerIcon: Icons.find_replace_rounded,
      content: StatefulBuilder(
        builder: (ctx, setModalState) {
          final matchesCount = SmartArabicEngine.findSmartMatchRanges(
            _textController.text,
            findCtrl.text,
          ).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: findCtrl,
                autofocus: true,
                onChanged: (_) => setModalState(() {}),
                style: TextStyle(color: widget.settings.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'ابحث عن الكلمة أو العبارة...',
                  suffixText: findCtrl.text.trim().isEmpty
                      ? ''
                      : '$matchesCount تطابق',
                  filled: true,
                  fillColor: widget.settings.scaffoldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replaceCtrl,
                style: TextStyle(color: widget.settings.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'استبدال بـ...',
                  filled: true,
                  fillColor: widget.settings.scaffoldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: widget.settings.activeTheme.primary,
            onTap: () {
              final q = findCtrl.text.trim();
              if (q.isEmpty) return;
              final matches = SmartArabicEngine.findSmartMatchRanges(
                _textController.text,
                q,
              );
              if (matches.isEmpty) {
                showRuknToast(context, 'لا توجد نتائج مطابقة');
                return;
              }
              final replaced = SmartArabicEngine.smartReplaceAll(
                _textController.text,
                q,
                replaceCtrl.text,
              );
              _textController.value = TextEditingValue(
                text: replaced,
                selection: TextSelection.collapsed(offset: replaced.length),
              );
              setState(() => _activeHighlightQuery = '');
              Navigator.of(context).pop();
              showRuknToast(
                context,
                'تم استبدال ${matches.length} تطابق بنجاح',
              );
            },
            child: const Text(
              'استبدال الكل',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.activeTheme.primary,
            elevation: 0,
            onTap: () {
              setState(() {
                _activeHighlightQuery = findCtrl.text.trim();
              });
              Navigator.of(context).pop();
              if (_isEditMode && _activeHighlightQuery.isNotEmpty) {
                _toggleEditReadMode(false);
              }
            },
            child: Text(
              'تظليل النتائج',
              style: TextStyle(
                color: widget.settings.activeTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.activeTheme;
    final stats = SmartArabicEngine.computeStats(_textController.text);
    final zoomScale = widget.settings.zoomPercent / 100.0;
    final scaledFontSize = (18.0 * zoomScale).clamp(11.0, 44.0);

    final docTextStyle = TextStyle(
      fontSize: scaledFontSize,
      height: 1.75,
      color: widget.settings.primaryTextColor,
      fontFamily: widget.settings.activeFontFamily,
    );

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        await _flushImmediateAutoSave();
      },
      child: Scaffold(
        backgroundColor: widget.settings.scaffoldBgColor,
        body: Column(
          children: [
            // 1. الشريط العلوي للمستند (يميناً: رجوع | وسطاً: العنوان | يساراً: كبسولة التكبير)
            _buildDocumentTopBar(theme),

            // 2. شريط أدوات التحرير القابل للتخصيص (يظهر في وضع التحرير)
            if (_isEditMode) _buildCustomizableEditorToolbar(theme),

            // 3. ورقة المستند + شريط التمرير السريع الجانبي (يسار الورقة) + زر الانتقال العائم
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: widget.settings.paperBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.settings.borderColor,
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // محتوى الورقة (وضع القراءة أو وضع التحرير)
                      Positioned.fill(
                        child: _isEditMode
                            ? SingleChildScrollView(
                                controller: _editScrollController,
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(34, 18, 18, 80),
                                child: TextField(
                                  controller: _textController,
                                  focusNode: _editorFocusNode,
                                  maxLines: null,
                                  textDirection: TextDirection.rtl,
                                  style: docTextStyle,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        'ابدأ بتدوين أفكارك، قصائدك، أو التزاماتك هنا...',
                                    hintStyle: docTextStyle.copyWith(
                                      color: widget.settings.secondaryTextColor
                                          .withOpacity(0.55),
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onDoubleTap: () => _toggleEditReadMode(true),
                                child: SingleChildScrollView(
                                  controller: _readScrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      34, 18, 18, 80),
                                  child: _textController.text.isEmpty
                                      ? Text(
                                          '(المستند فارغ — اضغط على «تحرير الملف» بالأسفل أو انقر مرتين للكتابة)',
                                          style: docTextStyle.copyWith(
                                            color: widget
                                                .settings.secondaryTextColor,
                                          ),
                                        )
                                      : SelectableText.rich(
                                          SmartArabicEngine
                                              .buildHighlightedTextSpan(
                                            text: _textController.text,
                                            query: _activeHighlightQuery,
                                            baseStyle: docTextStyle,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                ),
                              ),
                      ),

                      // شريط التمرير السريع الجانبي في أقصى يسار الورقة (LAYOUT_DIRECTION_LTR)
                      Positioned(
                        left: 2,
                        top: 14,
                        bottom: 72,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: _buildLeftFastScrollbar(theme),
                        ),
                      ),

                      // القائمة المنبثقة لزر القفز السريع (↑ أول المستند | ↓ آخر المستند)
                      if (_showJumpMenuPopup)
                        Positioned(
                          left: 14,
                          bottom: 68,
                          child: _buildQuickJumpPopupCard(theme),
                        ),

                      // زر الانتقال السريع العائم (أسفل يسار الورقة — بأسلوب TextPad)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: RuknSpringButton(
                          width: 44,
                          height: 44,
                          borderRadius: 22,
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          backgroundColor: theme.primary,
                          borderColor: theme.accentGold,
                          elevation: 4,
                          onTap: () {
                            setState(() {
                              _showJumpMenuPopup = !_showJumpMenuPopup;
                            });
                          },
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. شريط الإحصائيات السفلي (الكلمات • الحروف • الأسطر)
            _buildStatisticsBar(stats, theme),

            // 5. شريط أزرار وضع القراءة / التحرير السفلي
            _buildBottomDocumentActions(theme),
          ],
        ),
      ),
    );
  }

  /// الشريط العلوي للمستند (يميناً: رجوع | وسطاً: العنوان | يساراً: كبسولة التكبير)
  Widget _buildDocumentTopBar(GulfThemeData theme) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(12, topInset + 10, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryDark, theme.primary],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.accentGold.withOpacity(0.55),
            width: 1.1,
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // يميناً: زر "→ رجوع"
          RuknSpringButton(
            height: 38,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: Colors.white.withOpacity(0.14),
            borderColor: theme.accentGold.withOpacity(0.45),
            borderRadius: 12,
            elevation: 0,
            onTap: () async {
              await _flushImmediateAutoSave();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '→ رجوع',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // وسطاً: عنوان الملف (الضغط عليه يفتح نافذة إعادة تسمية الملف)
          Expanded(
            child: GestureDetector(
              onTap: _showRenameFromHeaderDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _noteTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.edit_note_rounded,
                      color: theme.accentGold,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // يساراً: كبسولة التكبير والتصغير الموحدة [ ＋ | 100% | － ]
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.accentGold.withOpacity(0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                // زر تكبير ＋
                InkWell(
                  onTap: () {
                    RuknHaptics.selectionClick();
                    widget.settings
                        .setZoomPercent(widget.settings.zoomPercent + 10);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    child: Text(
                      '＋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withOpacity(0.25),
                ),
                // النسبة المئوية (الضغط عليها يفتح نافذة إعادة الحجم إلى 100%)
                InkWell(
                  onTap: () {
                    RuknHaptics.lightTap();
                    _showResetZoomDialog();
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      '${widget.settings.zoomPercent}%',
                      style: TextStyle(
                        color: theme.accentGold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withOpacity(0.25),
                ),
                // زر تصغير －
                InkWell(
                  onTap: () {
                    RuknHaptics.selectionClick();
                    widget.settings
                        .setZoomPercent(widget.settings.zoomPercent - 10);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    child: Text(
                      '－',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// شريط أدوات التحرير القابل للتخصيص
  Widget _buildCustomizableEditorToolbar(GulfThemeData theme) {
    final activeTools = widget.settings.activeOrderedTools;
    final iconsOnly = widget.settings.toolbarIconsOnly;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: widget.settings.cardBgColor,
        border: Border(
          bottom: BorderSide(color: widget.settings.borderColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: activeTools.map((tool) {
            return Padding(
              padding: const EdgeInsets.only(left: 7),
              child: RuknSpringButton(
                height: 38,
                margin: const EdgeInsets.only(bottom: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: iconsOnly ? 11 : 12,
                  vertical: 6,
                ),
                backgroundColor: widget.settings.scaffoldBgColor,
                borderColor: theme.primary.withOpacity(0.35),
                borderRadius: 11,
                elevation: 1,
                onTap: () => _executeEditorTool(tool.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tool.icon, color: theme.primary, size: 18),
                    if (!iconsOnly) ...[
                      const SizedBox(width: 6),
                      Text(
                        tool.label,
                        style: TextStyle(
                          color: widget.settings.primaryTextColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// شريط التمرير السريع الجانبي (يسار الورقة) مع فقاعة النسبة المئوية والإمساك الفوري
  Widget _buildLeftFastScrollbar(GulfThemeData theme) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final trackHeight = constraints.maxHeight;
        const thumbHeight = 46.0;
        final maxTop = (trackHeight - thumbHeight).clamp(0.0, double.infinity);
        final thumbTop = (_scrollFraction * maxTop).clamp(0.0, maxTop);
        final percentInt = (_scrollFraction * 100).round().clamp(0, 100);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragDown: (_) {
            // إيقاف اندفاع الصفحة فوراً (stopOngoingScrollFling) من أول لمسة
            _stopOngoingScrollFling();
            setState(() => _isDraggingFastThumb = true);
          },
          onVerticalDragStart: (details) {
            _stopOngoingScrollFling();
            setState(() => _isDraggingFastThumb = true);
            if (trackHeight > 0) {
              _scrollToFraction(details.localPosition.dy / trackHeight);
            }
          },
          onVerticalDragUpdate: (details) {
            if (trackHeight > 0) {
              _scrollToFraction(details.localPosition.dy / trackHeight);
            }
          },
          onVerticalDragEnd: (_) {
            setState(() => _isDraggingFastThumb = false);
          },
          onVerticalDragCancel: () {
            setState(() => _isDraggingFastThumb = false);
          },
          child: SizedBox(
            width: _isDraggingFastThumb ? 96 : 26,
            height: trackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // مسار التمرير الجانبي
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // مقبض السحب
                Positioned(
                  left: 2,
                  top: thumbTop,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: thumbHeight,
                        decoration: BoxDecoration(
                          color: _isDraggingFastThumb
                              ? theme.accentGold
                              : theme.primary.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (_isDraggingFastThumb) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.accentGold),
                          ),
                          child: Text(
                            '$percentInt%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// بطاقة الانتقال السريع المنبثقة فوق الزر العائم (↑ أول المستند | ↓ آخر المستند)
  Widget _buildQuickJumpPopupCard(GulfThemeData theme) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.settings.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accentGold, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RuknSpringButton(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.borderColor,
            elevation: 0,
            onTap: () => _jumpToDocumentEdge(toTop: true),
            child: Text(
              '↑  أول المستند',
              style: TextStyle(
                color: widget.settings.primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          RuknSpringButton(
            height: 38,
            margin: EdgeInsets.zero,
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.borderColor,
            elevation: 0,
            onTap: () => _jumpToDocumentEdge(toTop: false),
            child: Text(
              '↓  آخر المستند',
              style: TextStyle(
                color: widget.settings.primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// شريط الإحصائيات السفلي: الكلمات: X • الحروف: Y • الأسطر: Z
  Widget _buildStatisticsBar(DocumentStats stats, GulfThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.settings.cardBgColor,
        border: Border(
          top: BorderSide(color: widget.settings.borderColor),
        ),
      ),
      child: Text(
        'الكلمات: ${stats.words}   •   الحروف: ${stats.chars}   •   الأسطر: ${stats.lines}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: widget.settings.secondaryTextColor,
        ),
      ),
    );
  }

  /// شريط أزرار وضع القراءة / التحرير السفلي
  Widget _buildBottomDocumentActions(GulfThemeData theme) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottomInset + 10),
      decoration: BoxDecoration(
        color: widget.settings.cardBgColor,
        border: Border(
          top: BorderSide(color: widget.settings.borderColor),
        ),
      ),
      child: _isEditMode
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: RuknSpringButton(
                    height: 45,
                    margin: const EdgeInsets.only(bottom: 3),
                    gradient: LinearGradient(
                      colors: [theme.primaryDark, theme.primary],
                    ),
                    borderColor: theme.accentGold,
                    onTap: () => _toggleEditReadMode(false),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'حفظ والانتقال لوضع القراءة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: RuknSpringButton(
                    height: 45,
                    margin: const EdgeInsets.only(bottom: 3),
                    backgroundColor: widget.settings.scaffoldBgColor,
                    borderColor: theme.accentGold,
                    elevation: 1,
                    onTap: () async {
                      await _flushImmediateAutoSave();
                      if (mounted) {
                        showRuknShareCardStudio(
                          context: context,
                          settings: widget.settings,
                          noteTitle: _noteTitle,
                          noteContent: _textController.text,
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: theme.primary, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          'بطاقة مصورة',
                          style: TextStyle(
                            color: widget.settings.primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // زر تحرير الملف
                Expanded(
                  flex: 2,
                  child: RuknSpringButton(
                    height: 45,
                    margin: const EdgeInsets.only(bottom: 3),
                    gradient: LinearGradient(
                      colors: [theme.primaryDark, theme.primary],
                    ),
                    borderColor: theme.accentGold,
                    onTap: () => _toggleEditReadMode(true),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.white, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'تحرير الملف',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // زر بطاقة مصورة فاخرة
                Expanded(
                  flex: 2,
                  child: RuknSpringButton(
                    height: 45,
                    margin: const EdgeInsets.only(bottom: 3),
                    backgroundColor: widget.settings.scaffoldBgColor,
                    borderColor: theme.accentGold,
                    elevation: 2,
                    onTap: () {
                      showRuknShareCardStudio(
                        context: context,
                        settings: widget.settings,
                        noteTitle: _noteTitle,
                        noteContent: _textController.text,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: theme.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'بطاقة مصورة',
                          style: TextStyle(
                            color: widget.settings.primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // زر مشاركة الملف
                Expanded(
                  flex: 2,
                  child: RuknSpringButton(
                    height: 45,
                    margin: const EdgeInsets.only(bottom: 3),
                    backgroundColor: widget.settings.scaffoldBgColor,
                    borderColor: theme.primary.withOpacity(0.45),
                    elevation: 2,
                    onTap: () {
                      final note = RuknNoteFile(
                        filePath:
                            '${widget.vault.notesDirectoryPath}/$_noteTitle.txt',
                        title: _noteTitle,
                        content: _textController.text,
                        lastModified: DateTime.now(),
                        isPinned: false,
                        categoryId: 'all',
                        isLocked: false,
                      );
                      widget.vault.shareNoteFile(note);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded,
                            color: theme.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'مشاركة الملف',
                          style: TextStyle(
                            color: widget.settings.primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
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
}
