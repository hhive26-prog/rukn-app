import 'package:flutter/material.dart';
import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'storage_vault.dart';
import 'smart_arabic_engine.dart';
import 'share_card_studio.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class RuknHomeScreen extends StatefulWidget {
  final AppSettingsController settings;
  final StorageVaultController vault;

  const RuknHomeScreen({
    super.key,
    required this.settings,
    required this.vault,
  });

  @override
  State<RuknHomeScreen> createState() => _RuknHomeScreenState();
}

class _RuknHomeScreenState extends State<RuknHomeScreen> {
  final ScrollController _homeScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  double _savedHomeScrollY = 0.0;
  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  bool _isCreatingZip = false;

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(() {
      if (_homeScrollController.hasClients) {
        _savedHomeScrollY = _homeScrollController.offset;
      }
    });
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// استعادة موضع التمرير في القائمة الرئيسية بعد الرجوع من المستند أو الإعدادات
  void _restoreHomeScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_homeScrollController.hasClients) {
        final maxScroll = _homeScrollController.position.maxScrollExtent;
        final target = _savedHomeScrollY.clamp(0.0, maxScroll);
        _homeScrollController.jumpTo(target);
      }
    });
  }

  /// تصفية الملاحظات حسب التصنيف المختار والبحث العربي الذكي
  List<RuknNoteFile> _getFilteredNotes() {
    final all = widget.vault.notes;
    final q = _searchQuery.trim();

    return all.where((note) {
      // تصفية حسب التصنيف
      if (_selectedCategoryId == 'pinned') {
        if (!note.isPinned) return false;
      } else if (_selectedCategoryId != 'all') {
        if (note.categoryId != _selectedCategoryId) return false;
      }

      // تصفية حسب محرك البحث العربي الذكي (في العنوان أو المحتوى)
      if (q.isEmpty) return true;
      final matchInTitle = SmartArabicEngine.smartContains(note.title, q);
      final matchInContent = SmartArabicEngine.smartContains(note.content, q);
      return matchInTitle || matchInContent;
    }).toList();
  }

  /// فتح نافذة إنشاء ملف جديد
  Future<void> _showCreateNewNoteDialog() async {
    final titleCtrl = TextEditingController();
    String chosenCategory =
        (_selectedCategoryId == 'all' || _selectedCategoryId == 'pinned')
            ? 'all'
            : _selectedCategoryId;

    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'إنشاء ملف جديد في رُكْن',
      subtitle: 'اختر عنواناً للملاحظة والتصنيف المناسب لها',
      headerIcon: Icons.note_add_rounded,
      content: StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = widget.settings.activeTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: widget.settings.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب اسم الملف هنا (مثال: أفكار ومشاريع)...',
                  hintStyle: TextStyle(
                    color: widget.settings.secondaryTextColor,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: widget.settings.scaffoldBgColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: widget.settings.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'تصنيف الملاحظة:',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: widget.settings.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RuknCategory.allCategories
                    .where((c) => c.id != 'pinned')
                    .map((cat) {
                  final selected = chosenCategory == cat.id;
                  return GestureDetector(
                    onTap: () {
                      RuknHaptics.selectionClick();
                      setModalState(() => chosenCategory = cat.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.primary
                            : widget.settings.scaffoldBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? theme.accentGold
                              : widget.settings.borderColor,
                        ),
                      ),
                      child: Text(
                        '${cat.emoji} ${cat.title}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : widget.settings.primaryTextColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 46,
            gradient: LinearGradient(
              colors: [
                widget.settings.activeTheme.primaryDark,
                widget.settings.activeTheme.primary,
              ],
            ),
            borderColor: widget.settings.activeTheme.accentGold,
            onTap: () async {
              final rawName = titleCtrl.text.trim().isEmpty
                  ? 'ملاحظة جديدة'
                  : titleCtrl.text.trim();
              Navigator.of(context).pop();
              final created = await widget.vault.createNewNote(
                title: rawName,
                categoryId: chosenCategory,
              );
              if (mounted) {
                _openNoteDocument(created, startInEditMode: true);
              }
            },
            child: const Text(
              'إنشاء وفتح المحرر',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
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
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// فتح المستند (مع التحقق من رمز الحماية إذا كانت الملاحظة مقفلة/خاصة)
  Future<void> _openNoteDocument(
    RuknNoteFile note, {
    bool startInEditMode = false,
  }) async {
    if (note.isLocked && widget.settings.pinCode.isNotEmpty) {
      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (ctx) => RuknPinLockScreen(
            settings: widget.settings,
            title: 'ملاحظة خاصة مقفلة 🔒',
            subtitle: 'أدخل رمز الحماية لفتح "${note.title}"',
            onUnlocked: () => Navigator.of(ctx).pop(true),
            onCancel: () => Navigator.of(ctx).pop(false),
          ),
        ),
      );
      if (unlocked != true) return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RuknEditorScreen(
          settings: widget.settings,
          vault: widget.vault,
          initialNote: note,
          initialSearchQuery: _searchQuery,
          startInEditMode: startInEditMode,
        ),
      ),
    );
    await widget.vault.reloadNotes();
    _restoreHomeScrollPosition();
  }

  /// فتح شاشة الإعدادات مع استعادة موضع التمرير عند العودة
  Future<void> _openSettingsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RuknSettingsScreen(
          settings: widget.settings,
          vault: widget.vault,
        ),
      ),
    );
    _restoreHomeScrollPosition();
  }

  /// نافذة تعديل الهوية الشخصية السريعة عند لمس عنوان البطاقة الملكية
  Future<void> _showQuickPersonalizeDialog() async {
    String selectedPrefix = widget.settings.personalPrefix;
    final nameCtrl = TextEditingController(text: widget.settings.userName);
    final subCtrl = TextEditingController(text: widget.settings.customSubtitle);
    const prefixes = ['رُكْن', 'مِساحة', 'دِيوان', 'خَلوة', 'مفكرة'];

    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'تخصيص هويتك الشخصية',
      subtitle: 'اجعل البطاقة الملكية العلوية تحمل اسمك أو كنيتك',
      headerIcon: Icons.workspace_premium_rounded,
      content: StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = widget.settings.activeTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر اللقب الافتتاحي:',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: widget.settings.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: prefixes.map((p) {
                  final active = selectedPrefix == p;
                  return GestureDetector(
                    onTap: () {
                      RuknHaptics.selectionClick();
                      setModalState(() => selectedPrefix = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? theme.primary
                            : widget.settings.scaffoldBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? theme.accentGold
                              : widget.settings.borderColor,
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: active
                              ? Colors.white
                              : widget.settings.primaryTextColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: widget.settings.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'اسمك أو كنيتك (مثال: أبو فهد / عبد العزيز / نورة)',
                  filled: true,
                  fillColor: widget.settings.scaffoldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subCtrl,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: widget.settings.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'العبارة الفرعية تحت الاسم',
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
            height: 46,
            gradient: LinearGradient(
              colors: [
                widget.settings.activeTheme.primaryDark,
                widget.settings.activeTheme.primary,
              ],
            ),
            borderColor: widget.settings.activeTheme.accentGold,
            onTap: () async {
              await widget.settings.updatePersonalIdentity(
                prefix: selectedPrefix,
                userName: nameCtrl.text,
                subtitle: subCtrl.text,
              );
              if (mounted) {
                Navigator.of(context).pop();
                showRuknToast(context, 'تم تحديث هويتك الشخصية بنجاح');
              }
            },
            child: const Text(
              'حفظ الهوية',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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

  /// قائمة الثلاث نقاط (⋮) الفاخرة بالخيارات الـ 7 المعتمدة + المشاركة المصورة
  Future<void> _showFileOptionsMenu(RuknNoteFile note) async {
    // إذا كانت الملاحظة مقفلة برمز سري نتحقق منه قبل عرض خيارات التعديل/الحذف
    if (note.isLocked && widget.settings.pinCode.isNotEmpty) {
      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (ctx) => RuknPinLockScreen(
            settings: widget.settings,
            title: 'خيارات ملف خاص 🔒',
            subtitle: 'أدخل رمز الحماية لإدارة "${note.title}"',
            onUnlocked: () => Navigator.of(ctx).pop(true),
            onCancel: () => Navigator.of(ctx).pop(false),
          ),
        ),
      );
      if (unlocked != true || !mounted) return;
    }

    final theme = widget.settings.activeTheme;

    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: note.title,
      subtitle: 'إدارة الملف والخزنة الآمنة والمشاركة',
      headerIcon: Icons.description_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. تثبيت الملف / إلغاء تثبيت الملف
          _buildOptionTile(
            icon: note.isPinned
                ? Icons.push_pin_outlined
                : Icons.push_pin_rounded,
            title: note.isPinned ? 'إلغاء تثبيت الملف' : 'تثبيت الملف',
            color: theme.primary,
            onTap: () async {
              Navigator.of(context).pop();
              final pinned = await widget.vault.togglePin(note.title);
              if (mounted) {
                showRuknToast(
                  context,
                  pinned ? 'تم تثبيت الملف في الأعلى 📌' : 'تم إلغاء تثبيت الملف',
                );
              }
            },
          ),
          // 2. إعادة تسمية الملف
          _buildOptionTile(
            icon: Icons.drive_file_rename_outline_rounded,
            title: 'إعادة تسمية الملف',
            color: theme.primary,
            onTap: () {
              Navigator.of(context).pop();
              _showRenameNoteDialog(note);
            },
          ),
          // 3. إنشاء نسخة مكررة من الملف
          _buildOptionTile(
            icon: Icons.copy_all_rounded,
            title: 'إنشاء نسخة مكررة من الملف',
            color: theme.primary,
            onTap: () async {
              Navigator.of(context).pop();
              final copy = await widget.vault.duplicateNote(note);
              if (mounted) {
                showRuknToast(
                  context,
                  'تم إنشاء نسخة مكررة: ${copy.title}',
                );
              }
            },
          ),
          // 4. إنشاء نسخة آمنة
          _buildOptionTile(
            icon: Icons.shield_rounded,
            title: 'إنشاء نسخة آمنة',
            color: theme.primary,
            onTap: () async {
              Navigator.of(context).pop();
              await widget.vault.createSafeBackup(note.title);
              if (mounted) {
                showRuknToast(
                  context,
                  'تم حفظ نسخة آمنة في (خزنة_النسخ_الآمنة) 🛡️',
                  icon: Icons.verified_user_rounded,
                );
              }
            },
          ),
          // 5. تصفح النسخ الآمنة
          _buildOptionTile(
            icon: Icons.history_edu_rounded,
            title: 'تصفح النسخ الآمنة',
            color: theme.primary,
            onTap: () {
              Navigator.of(context).pop();
              _showSafeBackupsBrowserDialog(note);
            },
          ),
          // 6. مشاركة الملف (+ خيار البطاقة المصورة الفاخرة)
          _buildOptionTile(
            icon: Icons.share_rounded,
            title: 'مشاركة الملف',
            color: theme.primary,
            onTap: () {
              Navigator.of(context).pop();
              _showShareChoiceDialog(note);
            },
          ),
          // خيار إضافي سريع لتغيير التصنيف أو القفل الخاص
          _buildOptionTile(
            icon: note.isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            title: note.isLocked
                ? 'إلغاء القفل الخاص عن الملف'
                : 'قفل الملف كملاحظة خاصة 🔒',
            color: theme.primary,
            onTap: () async {
              Navigator.of(context).pop();
              final locked = await widget.vault.toggleNoteLock(note.title);
              if (mounted) {
                showRuknToast(
                  context,
                  locked
                      ? 'تم وضع الملف تحت الحماية الخاصة 🔒'
                      : 'تم فتح حماية الملف',
                );
              }
            },
          ),
          // 7. حذف الملف (باللون الأحمر الصريح #DC2626 دائماً)
          _buildOptionTile(
            icon: Icons.delete_forever_rounded,
            title: 'حذف الملف',
            color: const Color(0xFFDC2626),
            isDanger: true,
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmDialog(note);
            },
          ),
        ],
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 44,
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.borderColor,
            elevation: 0,
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'إغلاق',
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

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final textColor =
        isDanger ? const Color(0xFFDC2626) : widget.settings.primaryTextColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RuknSpringButton(
        height: 48,
        elevation: 0,
        margin: EdgeInsets.zero,
        backgroundColor: isDanger
            ? const Color(0xFFDC2626).withOpacity(0.08)
            : widget.settings.scaffoldBgColor,
        borderColor: isDanger
            ? const Color(0xFFDC2626).withOpacity(0.35)
            : widget.settings.borderColor,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDanger
                  ? const Color(0xFFDC2626)
                  : widget.settings.secondaryTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة إعادة تسمية الملف
  Future<void> _showRenameNoteDialog(RuknNoteFile note) async {
    final renameCtrl = TextEditingController(text: note.title);
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'إعادة تسمية الملف',
      subtitle: 'سيتم تلقائياً ربط جميع النسخ الآمنة بالاسم الجديد',
      headerIcon: Icons.drive_file_rename_outline_rounded,
      content: TextField(
        controller: renameCtrl,
        autofocus: true,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: widget.settings.primaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: 'الاسم الجديد للملف',
          filled: true,
          fillColor: widget.settings.scaffoldBgColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 46,
            gradient: LinearGradient(
              colors: [
                widget.settings.activeTheme.primaryDark,
                widget.settings.activeTheme.primary,
              ],
            ),
            borderColor: widget.settings.activeTheme.accentGold,
            onTap: () async {
              try {
                final updated = await widget.vault.renameNote(
                  oldTitle: note.title,
                  newRawTitle: renameCtrl.text,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  if (updated != null) {
                    showRuknToast(context, 'تم تغيير الاسم إلى: ${updated.title}');
                  }
                }
              } catch (e) {
                if (mounted) {
                  showRuknToast(
                    context,
                    'يوجد ملف آخر يحمل نفس الاسم!',
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: const Color(0xFFDC2626),
                  );
                }
              }
            },
            child: const Text(
              'حفظ الاسم',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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

  /// نافذة تصفح النسخ الآمنة واستعادتها الذكية الصامتة
  Future<void> _showSafeBackupsBrowserDialog(RuknNoteFile note) async {
    final backups = await widget.vault.listSafeBackupsForNote(note.title);
    if (!mounted) return;

    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'خزنة النسخ الآمنة 🛡️',
      subtitle: 'النسخ المحفوظة لملف: ${note.title}',
      headerIcon: Icons.history_edu_rounded,
      content: backups.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 46,
                    color: widget.settings.secondaryTextColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'لا توجد نسخ آمنة محفوظة لهذا الملف حتى الآن.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.settings.secondaryTextColor,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: backups.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.settings.scaffoldBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.settings.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: widget.settings.activeTheme.primary,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.formattedTimestamp,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: widget.settings.primaryTextColor,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.sizeBytes} بايت',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: widget.settings.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RuknSpringButton(
                              height: 38,
                              margin: EdgeInsets.zero,
                              backgroundColor:
                                  widget.settings.activeTheme.primary,
                              onTap: () async {
                                Navigator.of(context).pop();
                                await widget.vault.restoreSafeBackupSmartly(
                                  noteTitle: note.title,
                                  targetBackup: entry,
                                );
                                if (mounted) {
                                  showRuknToast(
                                    context,
                                    'تمت استعادة النسخة الآمنة بنجاح (مع تأمين النص السابق تلقائياً)',
                                  );
                                }
                              },
                              child: const Text(
                                'استعادة هذه النسخة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RuknSpringButton(
                              height: 38,
                              margin: EdgeInsets.zero,
                              backgroundColor: widget.settings.cardBgColor,
                              borderColor: widget.settings.borderColor,
                              elevation: 0,
                              onTap: () async {
                                final previewText = await widget.vault
                                    .readSafeBackupContent(entry);
                                if (mounted) {
                                  _showBackupPreviewDialog(
                                    note: note,
                                    entry: entry,
                                    previewText: previewText,
                                  );
                                }
                              },
                              child: Text(
                                'معاينة النص',
                                style: TextStyle(
                                  color: widget.settings.primaryTextColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 44,
            backgroundColor: widget.settings.scaffoldBgColor,
            borderColor: widget.settings.borderColor,
            elevation: 0,
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'إغلاق',
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

  /// نافذة معاينة محتوى النسخة الآمنة قبل استعادتها
  Future<void> _showBackupPreviewDialog({
    required RuknNoteFile note,
    required SafeBackupEntry entry,
    required String previewText,
  }) async {
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'معاينة النسخة الآمنة',
      subtitle: entry.formattedTimestamp,
      headerIcon: Icons.visibility_rounded,
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.settings.paperBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.settings.borderColor),
        ),
        child: SelectableText(
          previewText.isEmpty ? '(نسخة فارغة)' : previewText,
          style: TextStyle(
            color: widget.settings.primaryTextColor,
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: widget.settings.activeTheme.primary,
            onTap: () async {
              Navigator.of(context).pop(); // إغلاق المعاينة
              Navigator.of(context).pop(); // إغلاق المتصفح
              await widget.vault.restoreSafeBackupSmartly(
                noteTitle: note.title,
                targetBackup: entry,
              );
              if (mounted) {
                showRuknToast(context, 'تمت استعادة النسخة الآمنة بنجاح');
              }
            },
            child: const Text(
              'استعادة هذه النسخة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
              'رجوع',
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

  /// نافذة اختيار طريقة المشاركة (كبطاقة مصورة فاخرة أو كملف/نص)
  Future<void> _showShareChoiceDialog(RuknNoteFile note) async {
    final theme = widget.settings.activeTheme;
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'مشاركة "${note.title}"',
      subtitle: 'اختر الطريقة الأنسب للمشاركة',
      headerIcon: Icons.ios_share_rounded,
      content: Column(
        children: [
          _buildOptionTile(
            icon: Icons.auto_awesome_rounded,
            title: 'مشاركة كبطاقة مصورة فاخرة (واتساب / سناب)',
            color: theme.accentGold,
            onTap: () {
              Navigator.of(context).pop();
              showRuknShareCardStudio(
                context: context,
                settings: widget.settings,
                noteTitle: note.title,
                noteContent: note.content,
              );
            },
          ),
          _buildOptionTile(
            icon: Icons.description_outlined,
            title: 'مشاركة كملف نصي (.txt) أو نص مباشر',
            color: theme.primary,
            onTap: () {
              Navigator.of(context).pop();
              widget.vault.shareNoteFile(note);
            },
          ),
        ],
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 44,
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

  /// نافذة تأكيد الحذف باللون الأحمر الصريح (#DC2626) مع حفظ نسخة آمنة تلقائية قبل الحذف
  Future<void> _showDeleteConfirmDialog(RuknNoteFile note) async {
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'تأكيد حذف الملف',
      subtitle: 'هل أنت متأكد من حذف "${note.title}"؟',
      headerIcon: Icons.warning_amber_rounded,
      content: Text(
        'لحمايتك من فقدان البيانات، سيقوم تطبيق «رُكْن» تلقائياً بحفظ نسخة آمنة من هذا الملف داخل (خزنة_النسخ_الآمنة) قبل حذفه.',
        style: TextStyle(
          color: widget.settings.primaryTextColor,
          fontSize: 14.5,
          height: 1.6,
        ),
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 46,
            backgroundColor: const Color(0xFFDC2626),
            shadowColor: const Color(0xFFDC2626).withOpacity(0.35),
            onTap: () async {
              Navigator.of(context).pop();
              await widget.vault.deleteNoteWithSafetyBackup(note);
              if (mounted) {
                showRuknToast(
                  context,
                  'تم حذف الملف (وتم تأمين نسخة في خزنة النسخ الآمنة)',
                  icon: Icons.delete_sweep_rounded,
                );
              }
            },
            child: const Text(
              'حذف الملف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
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
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNoteDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    int hour = dt.hour;
    final amPm = hour >= 12 ? 'م' : 'ص';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${dt.year}/${two(dt.month)}/${two(dt.day)}  •  $hour:${two(dt.minute)} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.activeTheme;
    final filteredNotes = _getFilteredNotes();

    return Scaffold(
      backgroundColor: widget.settings.scaffoldBgColor,
      body: Column(
        children: [
          // 1. البطاقة الملكية العلوية الثابتة (Hero Header Card)
          _buildHeroHeaderCard(theme),

          // 2. المنطقة الوسطى القابلة للتمرير (التصنيفات + البحث الموحد + قائمة البطاقات)
          Expanded(
            child: SingleChildScrollView(
              controller: _homeScrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // سطر العنوان (ملفاتي النصية يميناً وشارة TXT يساراً)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_special_rounded,
                            color: theme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ملفاتي النصية (${filteredNotes.length})',
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: widget.settings.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.accentGold.withOpacity(0.55),
                          ),
                        ),
                        child: Text(
                          'TXT • UTF-8',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // شريط التصنيفات الخليجية السريعة
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: RuknCategory.allCategories.map((cat) {
                        final selected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: () {
                              RuknHaptics.selectionClick();
                              setState(() => _selectedCategoryId = cat.id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? theme.primary
                                    : widget.settings.cardBgColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? theme.accentGold
                                      : widget.settings.borderColor,
                                  width: selected ? 1.3 : 1.0,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color:
                                              theme.primary.withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                '${cat.emoji}  ${cat.title}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : widget.settings.primaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // شريط البحث العربي الذكي الموحد (يتحرك مع القائمة لتوفير أكبر مساحة)
                  Container(
                    decoration: BoxDecoration(
                      color: widget.settings.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty
                            ? theme.primary
                            : widget.settings.borderColor,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(
                        color: widget.settings.primaryTextColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'ابحث بذكاء في عناوين ومحتوى ملاحظاتك (يتجاهل التشكيل)...',
                        hintStyle: TextStyle(
                          color: widget.settings.secondaryTextColor,
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.primary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: widget.settings.secondaryTextColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // قائمة بطاقات الملفات
                  if (filteredNotes.isEmpty)
                    _buildEmptyNotesState(theme)
                  else
                    ...filteredNotes.map(
                      (note) => _buildNoteCard(note, theme),
                    ),
                ],
              ),
            ),
          ),

          // 3. الشريط السفلي الثابت (Bottom Bar) مع عدم اقتصاص الأزرار أو الظلال
          _buildBottomFixedBar(theme),
        ],
      ),
    );
  }

  /// بناء البطاقة الملكية العلوية الثابتة (Hero Header Card)
  Widget _buildHeroHeaderCard(GulfThemeData theme) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding + 14, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryDark,
            theme.primary,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.accentGold.withOpacity(0.55),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryDark.withOpacity(0.32),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // العنوان الرئيسي في المنتصف (مع إمكانية التخصيص السريع باللمس)
          GestureDetector(
            onTap: _showQuickPersonalizeDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.settings.fullPersonalHeaderTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: theme.accentGold,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // العنوان الفرعي في المنتصف
          Text(
            widget.settings.customSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 14,
            ),
          ),
          if (widget.settings.showHijriInHeader) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.accentGold.withOpacity(0.35),
                  width: 0.8,
                ),
              ),
              child: Text(
                SmartArabicEngine.getHijriAndGregorianHeaderDate(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.accentGold,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // زر عريض "＋  ملف جديد" بارتفاع 46dp
          RuknSpringButton(
            height: 46,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 2),
            backgroundColor: Colors.white,
            borderColor: theme.accentGold,
            borderRadius: 15,
            elevation: 4,
            onTap: _showCreateNewNoteDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_rounded,
                  color: theme.primaryDark,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Text(
                  '＋  ملف جديد',
                  style: TextStyle(
                    color: theme.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة ملف واحد في القائمة الرئيسية
  Widget _buildNoteCard(RuknNoteFile note, GulfThemeData theme) {
    final snippet = note.isLocked && widget.settings.pinCode.isNotEmpty
        ? '🔒 محتوى خاص محمي برمز القفل...'
        : SmartArabicEngine.extractSmartSnippet(note.content, _searchQuery);

    final catObj = RuknCategory.allCategories.firstWhere(
      (c) => c.id == note.categoryId,
      orElse: () => RuknCategory.allCategories.first,
    );

    final baseTitleStyle = TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.bold,
      color: widget.settings.primaryTextColor,
      fontFamily: widget.settings.activeFontFamily,
    );

    final baseSnippetStyle = TextStyle(
      fontSize: 13.5,
      height: 1.55,
      color: widget.settings.secondaryTextColor,
      fontFamily: widget.settings.activeFontFamily,
    );

    return RuknSpringButton(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      backgroundColor: widget.settings.cardBgColor,
      borderRadius: 18,
      elevation: 2.5,
      borderColor: note.isPinned
          ? theme.accentGold.withOpacity(0.85)
          : widget.settings.borderColor,
      onTap: () => _openNoteDocument(note),
      onLongPress: () => _showFileOptionsMenu(note),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (note.isPinned) ...[
                const Text('📌', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              if (note.isLocked) ...[
                Icon(Icons.lock_rounded, color: theme.accentGold, size: 17),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  text: SmartArabicEngine.buildHighlightedTextSpan(
                    text: note.title,
                    query: _searchQuery,
                    baseStyle: baseTitleStyle,
                  ),
                ),
              ),
              if (note.categoryId != 'all') ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${catObj.emoji} ${catObj.title}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                    ),
                  ),
                ),
              ],
              // زر الثلاث نقاط (⋮)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  RuknHaptics.lightTap();
                  _showFileOptionsMenu(note);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.settings.scaffoldBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.settings.borderColor),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: widget.settings.primaryTextColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (snippet.isNotEmpty) ...[
            const SizedBox(height: 7),
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              text: SmartArabicEngine.buildHighlightedTextSpan(
                text: snippet,
                query: note.isLocked ? '' : _searchQuery,
                baseStyle: baseSnippetStyle,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatNoteDateTime(note.lastModified),
                style: TextStyle(
                  fontSize: 11.5,
                  color: widget.settings.secondaryTextColor.withOpacity(0.85),
                ),
              ),
              Text(
                '${SmartArabicEngine.computeStats(note.content).words} كلمة',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotesState(GulfThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: widget.settings.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.settings.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.auto_stories_outlined,
            size: 52,
            color: theme.primary.withOpacity(0.65),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج مطابقة لبحثك "$_searchQuery"'
                : 'لا توجد ملفات في هذا التصنيف حالياً',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.settings.primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط على زر «＋ ملف جديد» في الأعلى لبدء التدوين في ركنك الخاص',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: widget.settings.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// الشريط السفلي الثابت (⚙ الإعدادات + نسخ احتياطي ZIP) بارتفاع 46dp مع عدم الاقتصاص
  Widget _buildBottomFixedBar(GulfThemeData theme) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 12),
      decoration: BoxDecoration(
        color: widget.settings.cardBgColor,
        border: Border(
          top: BorderSide(color: widget.settings.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الإعدادات
          Expanded(
            child: RuknSpringButton(
              height: 46,
              margin: const EdgeInsets.only(bottom: 4),
              backgroundColor: widget.settings.scaffoldBgColor,
              borderColor: theme.primary.withOpacity(0.45),
              borderRadius: 14,
              elevation: 2,
              onTap: _openSettingsScreen,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_rounded, color: theme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '⚙  الإعدادات',
                    style: TextStyle(
                      color: widget.settings.primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // زر نسخ احتياطي (ZIP)
          Expanded(
            child: RuknSpringButton(
              height: 46,
              margin: const EdgeInsets.only(bottom: 4),
              gradient: LinearGradient(
                colors: [theme.primaryDark, theme.primary],
              ),
              borderColor: theme.accentGold,
              borderRadius: 14,
              elevation: 3,
              onTap: () async {
                if (_isCreatingZip) return;
                setState(() => _isCreatingZip = true);
                try {
                  final savedPath = await widget.vault.exportFullZipBackup();
                  if (mounted) {
                    showRuknToast(
                      context,
                      'تم حفظ ومشاركة النسخة الاحتياطية ZIP: $savedPath',
                      icon: Icons.folder_zip_rounded,
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isCreatingZip = false);
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_zip_rounded,
                    color: theme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCreatingZip ? 'جارٍ الضغط...' : 'نسخ احتياطي (ZIP)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
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
