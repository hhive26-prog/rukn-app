import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'smart_arabic_engine.dart';
import 'storage_vault.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';
import 'share_card_studio.dart';

class HomeScreen extends StatefulWidget {
  final AppSettingsController settings;
  final StorageVaultController vault;

  const HomeScreen({
    super.key,
    required this.settings,
    required this.vault,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  bool _isExportingZip = false;

  AppSettingsController get s => widget.settings;
  StorageVaultController get v => widget.vault;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RuknNoteFile> _getFilteredNotes() {
    final all = v.notes;
    return all.where((note) {
      if (_selectedCategory == 'المثبتة') {
        if (!note.isPinned) return false;
      } else if (_selectedCategory != 'الكل') {
        if (note.category != _selectedCategory) return false;
      }

      if (_searchQuery.isEmpty) return true;

      if (note.isLocked) {
        return SmartArabicEngine.containsSmartMatch(note.title, _searchQuery);
      }

      final matchTitle =
          SmartArabicEngine.containsSmartMatch(note.title, _searchQuery);
      final matchContent =
          SmartArabicEngine.containsSmartMatch(note.content, _searchQuery);
      return matchTitle || matchContent;
    }).toList();
  }

  Future<bool> _verifyPinIfLocked(RuknNoteFile note) async {
    if (!note.isLocked) return true;

    if (!s.hasPin) {
      final created = await _showCreatePinModal();
      return created;
    }

    bool unlocked = false;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (ctx, anim, secAnim) => FadeTransition(
          opacity: anim,
          child: RuknPinLockScreen(
            settings: s,
            title: 'مذكرة مقفلة',
            subtitle: 'أدخل رمز الحماية لفتح "${note.title}"',
            onUnlocked: () {
              unlocked = true;
              Navigator.of(ctx).pop();
            },
            onCancel: () {
              unlocked = false;
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    );
    return unlocked;
  }

  Future<bool> _showCreatePinModal() async {
    final pinCtrl = TextEditingController();
    bool saved = false;
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
                Icon(Icons.lock_outline_rounded, color: s.accentColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إعداد رمز الحماية (PIN)',
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: s.textMainColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل رمزاً مكوناً من 4 أرقام لقفل المذكرات الخاصة بك:',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 13.5,
                color: s.textSubColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 12,
                color: s.textMainColor,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                filled: true,
                fillColor: s.bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: s.borderColor),
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
                      backgroundColor: s.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final pin = pinCtrl.text.trim();
                      if (pin.length == 4 && int.tryParse(pin) != null) {
                        await s.setPinCode(pin);
                        saved = true;
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } else {
                        showRuknToast(
                          context,
                          s,
                          'يرجى إدخال 4 أرقام صحيحة',
                          isError: true,
                        );
                      }
                    },
                    child: Text(
                      'حفظ الرمز',
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
    return saved;
  }

  Future<void> _openNote(
    RuknNoteFile note, {
    bool startInEditMode = false,
  }) async {
    final canOpen = await _verifyPinIfLocked(note);
    if (!canOpen || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          settings: s,
          vault: v,
          note: note,
          initialEditMode: startInEditMode,
          initialSearchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
      ),
    );
  }

  Future<void> _showCreateNoteDialog() async {
    final titleCtrl = TextEditingController();
    String chosenCategory =
        (_selectedCategory != 'الكل' && _selectedCategory != 'المثبتة')
            ? _selectedCategory
            : '';

    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: s.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.note_add_outlined,
                          color: s.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'مذكرة نصية جديدة',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: s.textMainColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 15,
                      color: s.textMainColor,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: 'عنوان المذكرة',
                      hintText: 'مثال: أفكار وملاحظات اليوم...',
                      labelStyle: TextStyle(
                        fontFamily: s.fontFamily,
                        color: s.textSubColor,
                      ),
                      filled: true,
                      fillColor: s.bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: s.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: s.accentColor, width: 1.5),
                      ),
                    ),
                  ),
                  if (s.customCategories.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'المجلد (اختياري):',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: s.textSubColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryChoiceChip(
                          label: 'بدون مجلد',
                          selected: chosenCategory.isEmpty,
                          onTap: () =>
                              setModalState(() => chosenCategory = ''),
                        ),
                        ...s.customCategories.map(
                          (cat) => _buildCategoryChoiceChip(
                            label: cat,
                            selected: chosenCategory == cat,
                            onTap: () =>
                                setModalState(() => chosenCategory = cat),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
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
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: s.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            'إنشاء وفتح',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          onPressed: () async {
                            final rawTitle = titleCtrl.text.trim().isEmpty
                                ? 'مذكرة ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'
                                : titleCtrl.text.trim();
                            Navigator.of(ctx).pop();
                            final created = await v.createNewNote(
                              title: rawTitle,
                              category: chosenCategory,
                            );
                            if (mounted) {
                              await _openNote(
                                created,
                                startInEditMode: true,
                              );
                            }
                          },
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

  Widget _buildCategoryChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        RuknHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? s.primaryColor : s.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? s.accentColor : s.borderColor,
            width: selected ? 1.3 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : s.textMainColor,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // نافذة إدارة وتعديل المجلدات (إضافة / إعادة تسمية / حذف)
  // ===========================================================================
  Future<void> _showManageFoldersModal() async {
    final newFolderCtrl = TextEditingController();

    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final folders = s.customCategories;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        color: s.accentColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'إدارة وتعديل المجلدات',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: s.textMainColor,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await s.resetCategoriesToDefault();
                          setModalState(() {});
                          if (mounted) setState(() {});
                        },
                        child: Text(
                          'استعادة الافتراضي',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: s.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // حقل إضافة مجلد جديد
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newFolderCtrl,
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 14,
                            color: s.textMainColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اسم مجلد جديد...',
                            hintStyle: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 13,
                              color: s.textSubColor,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            filled: true,
                            fillColor: s.bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: s.borderColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final name = newFolderCtrl.text.trim();
                          if (name.isEmpty) return;
                          await s.addCustomCategory(name);
                          newFolderCtrl.clear();
                          setModalState(() {});
                          if (mounted) setState(() {});
                        },
                        child: Text(
                          'إضافة',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: folders.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'لا توجد مجلدات مخصصة حالياً',
                                style: TextStyle(
                                  fontFamily: s.fontFamily,
                                  fontSize: 13,
                                  color: s.textSubColor,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: folders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, idx) {
                              final folderName = folders[idx];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: s.bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: s.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        folderName,
                                        style: TextStyle(
                                          fontFamily: s.fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: s.textMainColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'إعادة تسمية',
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 19,
                                        color: s.accentColor,
                                      ),
                                      onPressed: () async {
                                        await _showRenameFolderDialog(
                                          folderName,
                                        );
                                        setModalState(() {});
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'حذف المجلد',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 19,
                                        color: Color(0xFFDC2626),
                                      ),
                                      onPressed: () async {
                                        await s.deleteCustomCategory(
                                          folderName,
                                        );
                                        await v.renameCategoryAcrossNotes(
                                          folderName,
                                          '',
                                        );
                                        if (_selectedCategory == folderName) {
                                          _selectedCategory = 'الكل';
                                        }
                                        setModalState(() {});
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRenameFolderDialog(String oldName) async {
    final ctrl = TextEditingController(text: oldName);
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
              'إعادة تسمية المجلد',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 14.5,
                color: s.textMainColor,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: s.bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: s.borderColor),
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
                      backgroundColor: s.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final newName = ctrl.text.trim();
                      if (newName.isNotEmpty && newName != oldName) {
                        await s.renameCustomCategory(oldName, newName);
                        await v.renameCategoryAcrossNotes(oldName, newName);
                        if (_selectedCategory == oldName) {
                          _selectedCategory = newName;
                        }
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: Text(
                      'حفظ',
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
  // تعديل الترويسة الشخصية (رُكْن فقط + الاسم والترحيب)
  // ===========================================================================
  Future<void> _showPersonalHeaderModal() async {
    final nameCtrl = TextEditingController(text: s.userName);
    final subCtrl = TextEditingController(text: s.headerSubtitle);
    final sigCtrl = TextEditingController(text: s.signatureText);

    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: s.accentColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تخصيص ترويسة رُكْن',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: s.textMainColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    color: s.textMainColor,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'الاسم أو اللقب بجانب رُكْن (اتركه فارغاً لـ "رُكْن خاص")',
                    hintText: 'مثال: أبو فهد / سارة',
                    filled: true,
                    fillColor: s.bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subCtrl,
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    color: s.textMainColor,
                  ),
                  decoration: InputDecoration(
                    labelText: 'عبارة الترحيب أسفل العنوان',
                    filled: true,
                    fillColor: s.bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sigCtrl,
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    color: s.textMainColor,
                  ),
                  decoration: InputDecoration(
                    labelText: 'التوقيع الشخصي على بطاقات المشاركة',
                    hintText: 'مثال: من رُكْن أبو فهد',
                    filled: true,
                    fillColor: s.bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
                          await s.setUserName(nameCtrl.text);
                          await s.setHeaderSubtitle(
                            subCtrl.text.trim().isEmpty
                                ? 'مساحتك الخاصة للكتابة والتنظيم'
                                : subCtrl.text.trim(),
                          );
                          await s.setSignatureText(sigCtrl.text);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: Text(
                          'حفظ التخصيص',
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
      },
    );
  }

  // ===========================================================================
  // قائمة خيارات الملف (⋮) - بدون أي إيموجيات ملونة (أيقونات موحدة فاخرة فقط)
  // ===========================================================================
  Future<void> _showFileOptionsMenu(RuknNoteFile note) async {
    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        note.isLocked
                            ? Icons.lock_rounded
                            : Icons.description_outlined,
                        color: s.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: s.textMainColor,
                            ),
                          ),
                          Text(
                            note.category.isNotEmpty
                                ? 'المجلد: ${note.category}'
                                : 'ملف نصي قياسي',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 11.5,
                              color: s.textSubColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: s.borderColor, height: 1),
                const SizedBox(height: 6),

                // 1. تثبيت / إلغاء تثبيت
                _buildOptionTile(
                  icon: note.isPinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  title: note.isPinned
                      ? 'إلغاء تثبيت الملف من الأعلى'
                      : 'تثبيت الملف في الأعلى',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await v.togglePinNote(note);
                    if (mounted) {
                      showRuknToast(
                        context,
                        s,
                        note.isPinned
                            ? 'تم إلغاء التثبيت'
                            : 'تم تثبيت الملف في الأعلى',
                      );
                    }
                  },
                ),

                // 2. نقل إلى مجلد
                _buildOptionTile(
                  icon: Icons.folder_outlined,
                  title: 'نقل إلى مجلد',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _showCategoryAssignDialog(note);
                  },
                ),

                // 3. قفل / إلغاء قفل الخصوصية
                _buildOptionTile(
                  icon: note.isLocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  title: note.isLocked
                      ? 'إلغاء قفل الخصوصية عن الملف'
                      : 'قفل الملف برمز الحماية (PIN)',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await _verifyPinIfLocked(note);
                    if (!ok) return;
                    if (!note.isLocked && !s.hasPin) {
                      final created = await _showCreatePinModal();
                      if (!created) return;
                    }
                    await v.toggleLockNote(note);
                    if (mounted) {
                      showRuknToast(
                        context,
                        s,
                        note.isLocked
                            ? 'تم إلغاء القفل عن الملف'
                            : 'تم قفل الملف برمز الحماية',
                      );
                    }
                  },
                ),

                // 4. إعادة تسمية الملف
                _buildOptionTile(
                  icon: Icons.drive_file_rename_outline_rounded,
                  title: 'إعادة تسمية الملف',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await _verifyPinIfLocked(note);
                    if (!ok) return;
                    await _showRenameDialog(note);
                  },
                ),

                // 5. إنشاء نسخة مكررة
                _buildOptionTile(
                  icon: Icons.copy_all_rounded,
                  title: 'إنشاء نسخة مكررة',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await _verifyPinIfLocked(note);
                    if (!ok) return;
                    await v.duplicateNote(note);
                    if (mounted) {
                      showRuknToast(
                        context,
                        s,
                        'تم إنشاء نسخة مكررة من الملف',
                      );
                    }
                  },
                ),

                // 6. إنشاء نسخة آمنة فورية
                _buildOptionTile(
                  icon: Icons.shield_outlined,
                  title: 'إنشاء نسخة آمنة فورية',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await _verifyPinIfLocked(note);
                    if (!ok) return;
                    await v.createSafeBackup(note);
                    if (mounted) {
                      showRuknToast(
                        context,
                        s,
                        'تم حفظ نسخة آمنة في الخزنة الداخلية',
                      );
                    }
                  },
                ),

                // 7. تصفح واسترجاع النسخ الآمنة
                _buildOptionTile(
                  icon: Icons.history_rounded,
                  title: 'تصفح واسترجاع النسخ الآمنة',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await _verifyPinIfLocked(note);
                    if (!ok) return;
                    await _showSafeBackupsBrowser(note);
                  },
                ),

                // 8. مشاركة الملف أو تصدير بطاقة
                _buildOptionTile(
                  icon: Icons.ios_share_rounded,
                  title: 'مشاركة الملف أو تصدير بطاقة فاخرة',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await _verifyPinIfLocked(note);
                    if (!ok) return;
                    await _showShareOptionsDialog(note);
                  },
                ),

                const SizedBox(height: 4),
                Divider(color: s.borderColor, height: 1),
                const SizedBox(height: 4),

                // 9. حذف الملف نهائياً (بالأحمر)
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'حذف الملف نهائياً',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await _verifyPinIfLocked(note);
                    if (!ok) return;
                    await _showDeleteConfirmationDialog(note);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFDC2626) : s.textMainColor;
    final iconColor = isDestructive ? const Color(0xFFDC2626) : s.accentColor;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        RuknHaptics.light();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: s.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: isDestructive
                  ? const Color(0xFFDC2626).withOpacity(0.6)
                  : s.textSubColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryAssignDialog(RuknNoteFile note) async {
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
              'اختر مجلداً لـ "${note.title}"',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryChoiceChip(
                  label: 'بدون مجلد',
                  selected: note.category.isEmpty,
                  onTap: () async {
                    await v.setNoteCategory(note, '');
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
                ...s.customCategories.map(
                  (cat) => _buildCategoryChoiceChip(
                    label: cat,
                    selected: note.category == cat,
                    onTap: () async {
                      await v.setNoteCategory(note, cat);
                      if (ctx.mounted) Navigator.of(ctx).pop();
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

  Future<void> _showRenameDialog(RuknNoteFile note) async {
    final ctrl = TextEditingController(text: note.title);
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
              'إعادة تسمية الملف',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(
                fontFamily: s.fontFamily,
                color: s.textMainColor,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: s.bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      backgroundColor: s.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final newTitle = ctrl.text.trim();
                      if (newTitle.isNotEmpty) {
                        await v.renameNote(note, newTitle);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          showRuknToast(context, s, 'تم تغيير اسم الملف');
                        }
                      }
                    },
                    child: Text(
                      'حفظ الاسم',
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

  Future<void> _showSafeBackupsBrowser(RuknNoteFile note) async {
    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return FutureBuilder<List<SafeBackupEntry>>(
              future: v.listSafeBackupsForNote(note),
              builder: (context, snapshot) {
                final backups = snapshot.data ?? [];
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history_edu_rounded,
                            color: s.accentColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'النسخ الآمنة لـ "${note.title}"',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: s.fontFamily,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: s.textMainColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'عند الاسترجاع، يتم حفظ نصك الحالي تلقائياً في نسخة آمنة أولاً قبل الاستبدال:',
                        style: TextStyle(
                          fontFamily: s.fontFamily,
                          fontSize: 12,
                          color: s.textSubColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (backups.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: s.bgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'لا توجد نسخ آمنة محفوظة لهذا الملف حتى الآن',
                              style: TextStyle(
                                fontFamily: s.fontFamily,
                                fontSize: 13,
                                color: s.textSubColor,
                              ),
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: backups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, idx) {
                              final b = backups[idx];
                              final dtStr = DateFormat('yyyy/MM/dd - hh:mm a')
                                  .format(b.timestamp);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: s.bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: s.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dtStr,
                                            style: TextStyle(
                                              fontFamily: s.fontFamily,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: s.textMainColor,
                                            ),
                                          ),
                                          Text(
                                            'الحجم: ${b.sizeBytes} بايت',
                                            style: TextStyle(
                                              fontFamily: s.fontFamily,
                                              fontSize: 11.5,
                                              color: s.textSubColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await v.restoreSafeBackupSmartly(
                                          note,
                                          b,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        if (mounted) {
                                          showRuknToast(
                                            context,
                                            s,
                                            'تم استرجاع النسخة وحفظ نصك السابق بأمان',
                                          );
                                        }
                                      },
                                      child: Text(
                                        'استرجاع',
                                        style: TextStyle(
                                          fontFamily: s.fontFamily,
                                          fontWeight: FontWeight.w800,
                                          color: s.accentColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 19,
                                      ),
                                      onPressed: () async {
                                        await v.deleteSafeBackup(b);
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'إغلاق',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontWeight: FontWeight.w700,
                            color: s.textSubColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showShareOptionsDialog(RuknNoteFile note) async {
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
              'مشاركة "${note.title}"',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 14),
            _buildOptionTile(
              icon: Icons.photo_Size_select_actual_outlined,
              title: 'تصميم بطاقة مشاركة فاخرة (انستغرام / واتساب)',
              onTap: () async {
                Navigator.of(ctx).pop();
                await showRuknShareCardStudio(
                  context: context,
                  settings: s,
                  noteTitle: note.title,
                  noteContent: note.content,
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.subject_rounded,
              title: 'مشاركة كنص مباشر',
              onTap: () async {
                Navigator.of(ctx).pop();
                await Share.share(
                  '${note.title}\n\n${note.content}',
                  subject: note.title,
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.insert_drive_file_outlined,
              title: 'مشاركة كملف نصي (.txt)',
              onTap: () async {
                Navigator.of(ctx).pop();
                final file = File(note.filePath);
                if (await file.exists()) {
                  await Share.shareXFiles(
                    [XFile(file.path, mimeType: 'text/plain')],
                    subject: note.title,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(RuknNoteFile note) async {
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
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تأكيد حذف الملف',
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'هل أنت متأكد من حذف "${note.title}"؟\nسيقوم رُكْن بحفظ نسخة احتياطية صامتة في الخزنة الآمنة قبل الحذف.',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 13.5,
                height: 1.5,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 18),
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
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await v.deleteNoteWithSafetyBackup(note);
                      if (mounted) {
                        showRuknToast(context, s, 'تم حذف الملف');
                      }
                    },
                    child: Text(
                      'حذف الملف',
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

  Future<void> _showVaultZipBackupModal() async {
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
                Icon(
                  Icons.archive_outlined,
                  color: s.accentColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'النسخ الاحتياطي الشامل (ZIP)',
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: s.textMainColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'يجمع كافة مذكراتك النصية ونسخك الآمنة في ملف مضغوط واحد (.zip) لحفظه في الهاتف أو إرساله سحابياً:',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 13,
                height: 1.5,
                color: s.textSubColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.download_done_rounded,
              title: 'حفظ في تنزيلات الهاتف فقط (Downloads)',
              onTap: () async {
                Navigator.of(ctx).pop();
                await _runZipBackup(saveToDevice: true, shareExternally: false);
              },
            ),
            _buildOptionTile(
              icon: Icons.share_outlined,
              title: 'مشاركة خارجية فقط (واتساب / تيليجرام / درايف)',
              onTap: () async {
                Navigator.of(ctx).pop();
                await _runZipBackup(saveToDevice: false, shareExternally: true);
              },
            ),
            _buildOptionTile(
              icon: Icons.cloud_done_outlined,
              title: 'حفظ في الهاتف + مشاركة خارجية معاً',
              onTap: () async {
                Navigator.of(ctx).pop();
                await _runZipBackup(saveToDevice: true, shareExternally: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runZipBackup({
    required bool saveToDevice,
    required bool shareExternally,
  }) async {
    setState(() => _isExportingZip = true);
    try {
      final msg = await v.exportFullVaultZip(
        saveToDevice: saveToDevice,
        shareExternally: shareExternally,
      );
      if (mounted) {
        showRuknToast(context, s, msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingZip = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _getFilteredNotes();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: s.bgColor,
        body: Column(
          children: [
            // 1. الهيدر الملكي الفاخر (يقتصر على مسمى رُكْن)
            _buildLuxuryHeader(),

            // 2. شريط البحث + زر الإنشاء السريع
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: s.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: s.borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontFamily: s.fontFamily,
                          fontSize: 14,
                          color: s.textMainColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث في عناوين ومحتوى مذكراتك...',
                          hintStyle: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 13,
                            color: s.textSubColor,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: s.accentColor,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: s.textSubColor,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RuknSpringButton(
                    onTap: _showCreateNoteDialog,
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [s.primaryColor, s.primaryDarkColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: s.accentColor.withOpacity(0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: s.primaryColor.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: s.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'جديد',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. شريط المجلدات الأفقي (نصوص صافية بدون إيموجي + قابل للتعديل والإضافة والحذف)
            _buildCategoriesBar(),

            const SizedBox(height: 6),

            // 4. قائمة المذكرات
            Expanded(
              child: v.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: s.accentColor),
                    )
                  : filteredNotes.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: filteredNotes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, idx) =>
                              _buildNoteCard(filteredNotes[idx]),
                        ),
            ),

            // 5. الشريط السفلي الثابت (الأزرار متوسطة تماماً وغير مقصوصة)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [s.primaryColor, s.primaryDarkColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: s.primaryDarkColor.withOpacity(0.26),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showPersonalHeaderModal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              s.fullHeaderTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: s.fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: s.accentColor,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // تبديل الوضع الليلي/النهاري السريع
                  RuknSpringButton(
                    onTap: () => s.setDarkMode(!s.isDarkMode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: s.accentColor.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            s.isDarkMode
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: s.accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.isDarkMode ? 'نهاري' : 'ليلي',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.headerSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: s.fontFamily,
                  fontSize: 12.5,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
              if (s.showHijriDateInHeader) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    SmartArabicEngine.getHeaderDateString(),
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: s.accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesBar() {
    final List<String> allTabs = [
      'الكل',
      'المثبتة',
      ...s.customCategories,
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: allTabs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, idx) {
          // الزر الأخير: إدارة وتعديل المجلدات
          if (idx == allTabs.length) {
            return GestureDetector(
              onTap: () {
                RuknHaptics.light();
                _showManageFoldersModal();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.cardColor,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: s.accentColor.withOpacity(0.55),
                  ),
                ),
                child: Text(
                  '+ تعديل المجلدات',
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: s.accentColor,
                  ),
                ),
              ),
            );
          }

          final tab = allTabs[idx];
          final selected = _selectedCategory == tab;
          final isCustom = tab != 'الكل' && tab != 'المثبتة';

          return GestureDetector(
            onTap: () {
              RuknHaptics.selection();
              setState(() => _selectedCategory = tab);
            },
            onLongPress: isCustom
                ? () {
                    RuknHaptics.medium();
                    _showManageFoldersModal();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? s.primaryColor : s.cardColor,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selected ? s.accentColor : s.borderColor,
                  width: selected ? 1.3 : 1.0,
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontFamily: s.fontFamily,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : s.textMainColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(RuknNoteFile note) {
    final dateStr = DateFormat('yyyy/MM/dd').format(note.lastModified);
    final snippet = note.isLocked
        ? 'محتوى محمي برمز القفل السري (PIN)'
        : (_searchQuery.isNotEmpty
            ? SmartArabicEngine.extractSearchSnippet(note.content, _searchQuery)
            : (note.content.trim().isEmpty
                ? 'مذكرة فارغة — اضغط للكتابة...'
                : note.content.trim().replaceAll('\n', ' ')));

    return RuknSpringButton(
      onTap: () => _openNote(note),
      onLongPress: () => _showFileOptionsMenu(note),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: s.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: note.isPinned
                ? s.accentColor.withOpacity(0.65)
                : s.borderColor,
            width: note.isPinned ? 1.3 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(s.isDarkMode ? 0.16 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.isPinned) ...[
                  Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: s.accentColor,
                  ),
                  const SizedBox(width: 6),
                ],
                if (note.isLocked) ...[
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: s.accentColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: SmartArabicEngine.buildHighlightedTextSpan(
                            text: note.title,
                            query: _searchQuery,
                            baseStyle: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: s.textMainColor,
                            ),
                          ),
                        )
                      : Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: s.textMainColor,
                          ),
                        ),
                ),
                if (note.category.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: s.primaryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: s.accentColor.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: s.accentColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showFileOptionsMenu(note),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: s.textSubColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _searchQuery.isNotEmpty && !note.isLocked
                ? RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: SmartArabicEngine.buildHighlightedTextSpan(
                      text: snippet,
                      query: _searchQuery,
                      baseStyle: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 13,
                        height: 1.45,
                        color: s.textSubColor,
                      ),
                    ),
                  )
                : Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 13,
                      height: 1.45,
                      color: s.textSubColor,
                    ),
                  ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 11,
                    color: s.textSubColor.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                if (!note.isLocked)
                  Text(
                    '${SmartArabicEngine.computeStats(note.content).words} كلمة',
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: s.textSubColor.withOpacity(0.85),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: s.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: s.borderColor),
              ),
              child: Icon(
                Icons.notes_rounded,
                size: 36,
                color: s.accentColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty
                  ? 'لا توجد نتائج مطابقة لبحثك'
                  : 'لا توجد مذكرات في هذا القسم',
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: s.textMainColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'جرّب البحث بكلمات أخرى'
                  : 'اضغط على زر "+ جديد" في الأعلى لبدء تدوين مذكرتك الأولى',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: s.fontFamily,
                fontSize: 13,
                color: s.textSubColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: s.cardColor,
        border: Border(top: BorderSide(color: s.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(s.isDarkMode ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              // زر الإعدادات (متوسط تماماً)
              Expanded(
                child: RuknSpringButton(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(settings: s),
                      ),
                    );
                  },
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.bgColor,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: s.borderColor, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: s.accentColor,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الإعدادات',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: s.textMainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // زر النسخ الاحتياطي (ZIP) - متوسط تماماً داخل الإطار
              Expanded(
                child: RuknSpringButton(
                  onTap: _isExportingZip ? null : _showVaultZipBackupModal,
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [s.primaryColor, s.primaryDarkColor],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: s.accentColor.withOpacity(0.55),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isExportingZip)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            Icons.archive_outlined,
                            color: s.accentColor,
                            size: 19,
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'نسخ احتياطي (ZIP)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
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
      ),
    );
  }
}
