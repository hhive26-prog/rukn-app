import 'package:flutter/material.dart';
import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'storage_vault.dart';

class RuknSettingsScreen extends StatefulWidget {
  final AppSettingsController settings;
  final StorageVaultController vault;

  const RuknSettingsScreen({
    super.key,
    required this.settings,
    required this.vault,
  });

  @override
  State<RuknSettingsScreen> createState() => _RuknSettingsScreenState();
}

class _RuknSettingsScreenState extends State<RuknSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _subtitleController;
  late TextEditingController _signatureController;
  late String _selectedPrefix;

  @override
  void initState() {
    super.initState();
    _selectedPrefix = widget.settings.personalPrefix;
    _nameController = TextEditingController(text: widget.settings.userName);
    _subtitleController =
        TextEditingController(text: widget.settings.customSubtitle);
    _signatureController =
        TextEditingController(text: widget.settings.signatureText);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  /// نافذة «تخصيص أدوات التحرير» (الاسم المعتمد حرفياً بدون كلمة وترتيب، وبدون خيار نصوص|رموز داخلها)
  /// يقع زر "استعادة الافتراضي" في أعلى النافذة، وفي الأسفل زرا "حفظ" و"إلغاء" فقط.
  Future<void> _showCustomizeEditorToolsDialog() async {
    List<String> tempOrder = List<String>.from(widget.settings.orderedToolIds);
    Set<String> tempEnabled = Set<String>.from(widget.settings.enabledToolIds);

    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'تخصيص أدوات التحرير',
      subtitle: 'اختر الأدوات الظاهرة واسحب المقبض (≡) لترتيبها بمرونة',
      headerIcon: Icons.tune_rounded,
      content: StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = widget.settings.activeTheme;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // زر "استعادة الافتراضي" في أعلى النافذة تحت العنوان والوصف مباشرة وقبل قائمة الأدوات
              RuknSpringButton(
                height: 42,
                margin: const EdgeInsets.only(bottom: 12),
                backgroundColor: theme.primary.withOpacity(0.10),
                borderColor: theme.primary.withOpacity(0.45),
                elevation: 0,
                onTap: () async {
                  final confirmed =
                      await _showConfirmRestoreDefaultToolsDialog();
                  if (confirmed == true) {
                    final defaultIds =
                        GulfThemes.allEditorTools.map((e) => e.id).toList();
                    setModalState(() {
                      tempOrder = List<String>.from(defaultIds);
                      tempEnabled = Set<String>.from(defaultIds);
                    });
                    if (mounted) {
                      showRuknToast(
                          context, 'تمت استعادة ترتيب وتفعيل الأدوات الافتراضية');
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restore_rounded, color: theme.primary, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      'استعادة الافتراضي',
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // قائمة الأدوات مع السحب والإفلات المتصل السلس (ReorderableListView)
              SizedBox(
                height: 360,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: tempOrder.length,
                  onReorder: (oldIndex, newIndex) {
                    RuknHaptics.selectionClick();
                    setModalState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = tempOrder.removeAt(oldIndex);
                      tempOrder.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (ctx, index) {
                    final toolId = tempOrder[index];
                    final tool = GulfThemes.allEditorTools.firstWhere(
                      (t) => t.id == toolId,
                      orElse: () => GulfThemes.allEditorTools.first,
                    );
                    final isEnabled = tempEnabled.contains(toolId);

                    return Container(
                      key: ValueKey(toolId),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.settings.scaffoldBgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isEnabled
                              ? theme.primary.withOpacity(0.45)
                              : widget.settings.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          // مربع الاختيار (تفعيل/إخفاء الأداة)
                          GestureDetector(
                            onTap: () {
                              RuknHaptics.lightTap();
                              setModalState(() {
                                if (isEnabled && tempEnabled.length > 1) {
                                  tempEnabled.remove(toolId);
                                } else {
                                  tempEnabled.add(toolId);
                                }
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? theme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: isEnabled
                                      ? theme.primary
                                      : widget.settings.secondaryTextColor,
                                  width: 1.5,
                                ),
                              ),
                              child: isEnabled
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 17)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(tool.icon, color: theme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tool.label,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: widget.settings.primaryTextColor,
                              ),
                            ),
                          ),
                          // مقبض السحب المتصل السلس (≡)
                          ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: widget.settings.secondaryTextColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // أسفل النافذة يحتوي على زري "حفظ" و"إلغاء" فقط
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
              await widget.settings.saveToolbarCustomization(
                orderedIds: tempOrder,
                enabledIds: tempEnabled,
              );
              if (mounted) {
                Navigator.of(context).pop();
                showRuknToast(context, 'تم حفظ تخصيص أدوات التحرير');
              }
            },
            child: const Text(
              'حفظ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// نافذة التأكيد عند الضغط على "استعادة الافتراضي":
  /// "هل أنت متأكد أنك تريد استعادة الإعدادات الافتراضية؟" مع زر (نعم) بلون الثيم النشط وزر (لا)
  Future<bool?> _showConfirmRestoreDefaultToolsDialog() {
    final theme = widget.settings.activeTheme;
    return showRuknModalDialog<bool>(
      context: context,
      settings: widget.settings,
      title: 'تأكيد الاستعادة',
      headerIcon: Icons.help_outline_rounded,
      content: Text(
        'هل أنت متأكد أنك تريد استعادة الإعدادات الافتراضية؟',
        style: TextStyle(
          color: widget.settings.primaryTextColor,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
      actions: [
        Expanded(
          child: RuknSpringButton(
            height: 45,
            backgroundColor: theme.primary,
            borderColor: theme.accentGold,
            onTap: () => Navigator.of(context).pop(true),
            child: const Text(
              'نعم',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
            onTap: () => Navigator.of(context).pop(false),
            child: Text(
              'لا',
              style: TextStyle(
                color: widget.settings.primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// نافذة إعداد أو تغيير رمز الحماية السري (PIN)
  Future<void> _showConfigurePinDialog() async {
    final pinCtrl = TextEditingController(text: widget.settings.pinCode);
    await showRuknModalDialog(
      context: context,
      settings: widget.settings,
      title: 'رمز الحماية والخصوصية 🔒',
      subtitle: 'أدخل رمزاً من 4 أرقام لقفل الملاحظات الخاصة أو التطبيق',
      headerIcon: Icons.lock_person_rounded,
      content: TextField(
        controller: pinCtrl,
        autofocus: true,
        maxLength: 4,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.settings.primaryTextColor,
          fontSize: 22,
          letterSpacing: 10,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: '••••',
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
              final raw = pinCtrl.text.trim();
              if (raw.isNotEmpty && raw.length != 4) {
                showRuknToast(
                  context,
                  'يرجى إدخال 4 أرقام بالضبط أو تركه فارغاً لإلغاء الرمز',
                  backgroundColor: const Color(0xFFDC2626),
                );
                return;
              }
              await widget.settings.setPinCode(raw);
              if (mounted) {
                Navigator.of(context).pop();
                showRuknToast(
                  context,
                  raw.isEmpty
                      ? 'تم إلغاء رمز الحماية'
                      : 'تم تفعيل رمز الحماية (4 أرقام) بنجاح 🔒',
                );
              }
            },
            child: const Text(
              'حفظ الرمز',
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.activeTheme;
    final topInset = MediaQuery.of(context).padding.top;
    const prefixes = ['رُكْن', 'مِساحة', 'دِيوان', 'خَلوة', 'مفكرة'];

    return Scaffold(
      backgroundColor: widget.settings.scaffoldBgColor,
      body: Column(
        children: [
          // شريط عنوان الإعدادات الملكي
          Container(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryDark, theme.primary],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.accentGold.withOpacity(0.55),
                  width: 1.2,
                ),
              ),
            ),
            child: Row(
              children: [
                RuknSpringButton(
                  height: 38,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: Colors.white.withOpacity(0.14),
                  borderColor: theme.accentGold.withOpacity(0.45),
                  elevation: 0,
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    '→ رجوع',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'إعدادات وتخصيص «رُكْن»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 64),
              ],
            ),
          ),

          // محتوى الإعدادات القابل للتمرير
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // أولاً: الهوية الشخصية لصاحب الركن
                  _buildSectionHeader(
                      '١. الهوية الشخصية والتوقيع', Icons.badge_rounded, theme),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.settings.cardBgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: widget.settings.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'مسمى مساحتك الخاصة في الترويسة:',
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
                            final active = _selectedPrefix == p;
                            return GestureDetector(
                              onTap: () {
                                RuknHaptics.selectionClick();
                                setState(() => _selectedPrefix = p);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active
                                      ? theme.primary
                                      : widget.settings.scaffoldBgColor,
                                  borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          style:
                              TextStyle(color: widget.settings.primaryTextColor),
                          decoration: InputDecoration(
                            labelText: 'اسمك أو كنيتك (مثال: أبو فهد / نورة)',
                            filled: true,
                            fillColor: widget.settings.scaffoldBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _subtitleController,
                          style:
                              TextStyle(color: widget.settings.primaryTextColor),
                          decoration: InputDecoration(
                            labelText: 'العنوان الفرعي تحت اسمك',
                            filled: true,
                            fillColor: widget.settings.scaffoldBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _signatureController,
                          style:
                              TextStyle(color: widget.settings.primaryTextColor),
                          decoration: InputDecoration(
                            labelText: 'التوقيع الشخصي المحفوظ (لأداة التوقيع)',
                            filled: true,
                            fillColor: widget.settings.scaffoldBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        RuknSpringButton(
                          height: 44,
                          gradient: LinearGradient(
                            colors: [theme.primaryDark, theme.primary],
                          ),
                          borderColor: theme.accentGold,
                          onTap: () async {
                            await widget.settings.updatePersonalIdentity(
                              prefix: _selectedPrefix,
                              userName: _nameController.text,
                              subtitle: _subtitleController.text,
                            );
                            await widget.settings
                                .setSignatureText(_signatureController.text);
                            if (mounted) {
                              FocusScope.of(context).unfocus();
                              showRuknToast(
                                  context, 'تم حفظ الهوية الشخصية والتوقيع ✨');
                            }
                          },
                          child: const Text(
                            'حفظ الهوية والتوقيع',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ثانياً: الثيمات الخليجية الـ 8 والوضع الليلي
                  _buildSectionHeader(
                      '٢. الثيمات الخليجية الفاخرة (8 ثيمات)',
                      Icons.palette_rounded,
                      theme),
                  RuknSlidingSwitchRow(
                    title: 'الوضع الليلي المريح للعين (Dark Mode)',
                    subtitle: 'خلفيات كحلية داكنة مع الحفاظ على روح الثيم المختار',
                    value: widget.settings.isDarkMode,
                    onChanged: (v) => widget.settings.setDarkMode(v),
                    settings: widget.settings,
                    icon: Icons.dark_mode_rounded,
                  ),
                  RuknSlidingSwitchRow(
                    title: 'إظهار التاريخ الهجري والميلادي في الترويسة',
                    subtitle: 'عرض اليوم والتاريخ الهجري والميلادي أعلى الشاشة',
                    value: widget.settings.showHijriInHeader,
                    onChanged: (v) => widget.settings.setShowHijriInHeader(v),
                    settings: widget.settings,
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.35,
                    ),
                    itemCount: GulfThemes.themes.length,
                    itemBuilder: (ctx, idx) {
                      final t = GulfThemes.themes[idx];
                      final isSelected = widget.settings.themeIndex == idx;

                      return RuknSpringButton(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        gradient: LinearGradient(
                          colors: [t.primaryDark, t.primary],
                        ),
                        borderColor: isSelected
                            ? t.accentGold
                            : Colors.white.withOpacity(0.18),
                        borderRadius: 16,
                        elevation: isSelected ? 4 : 1,
                        onTap: () => widget.settings.setThemeIndex(idx),
                        child: Row(
                          children: [
                            Text(t.badge, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: t.accentGold, size: 19),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // ثالثاً: الخطوط الـ 12 المدمجة
                  _buildSectionHeader(
                      '٣. الخطوط العربية الفاخرة (12 خطاً)',
                      Icons.font_download_rounded,
                      theme),
                  ...GulfThemes.fonts.map((fontOpt) {
                    final selected = widget.settings.fontIndex == fontOpt.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RuknSpringButton(
                        height: 50,
                        margin: EdgeInsets.zero,
                        backgroundColor: selected
                            ? theme.primary.withOpacity(0.12)
                            : widget.settings.cardBgColor,
                        borderColor: selected
                            ? theme.primary
                            : widget.settings.borderColor,
                        elevation: 0,
                        onTap: () => widget.settings.setFontIndex(fontOpt.id),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected
                                  ? theme.primary
                                  : widget.settings.secondaryTextColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                fontOpt.title,
                                style: TextStyle(
                                  fontFamily: fontOpt.fontFamily,
                                  fontSize: 14.5,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: widget.settings.primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // رابعاً: أدوات التحرير ووضع القهوة والقراءة
                  _buildSectionHeader(
                      '٤. شريط التحرير وتجربة القراءة',
                      Icons.construction_rounded,
                      theme),
                  // خيار [ نصوص | رموز ] في شاشة الإعدادات فقط
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: widget.settings.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.settings.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'نمط عرض شريط أدوات التحرير:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: widget.settings.primaryTextColor,
                          ),
                        ),
                        Row(
                          children: [
                            _buildModeChip(
                              label: 'نصوص ورموز',
                              selected: !widget.settings.toolbarIconsOnly,
                              onTap: () =>
                                  widget.settings.setToolbarIconsOnly(false),
                              theme: theme,
                            ),
                            const SizedBox(width: 6),
                            _buildModeChip(
                              label: 'رموز فقط',
                              selected: widget.settings.toolbarIconsOnly,
                              onTap: () =>
                                  widget.settings.setToolbarIconsOnly(true),
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // زر «تخصيص أدوات التحرير»
                  RuknSpringButton(
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 8),
                    gradient: LinearGradient(
                      colors: [theme.primaryDark, theme.primary],
                    ),
                    borderColor: theme.accentGold,
                    onTap: _showCustomizeEditorToolsDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune_rounded,
                            color: theme.accentGold, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'تخصيص أدوات التحرير',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  RuknSlidingSwitchRow(
                    title: 'وضع «القهوة والقراءة» ☕ (منع انطفاء الشاشة)',
                    subtitle: 'إبقاء الشاشة مضاءة دائماً أثناء قراءة أو تحرير المستند',
                    value: widget.settings.keepScreenOnInReader,
                    onChanged: (v) =>
                        widget.settings.setKeepScreenOnInReader(v),
                    settings: widget.settings,
                    icon: Icons.coffee_rounded,
                  ),
                  const SizedBox(height: 20),

                  // خامساً: الخصوصية وقفل الحماية
                  _buildSectionHeader(
                      '٥. قفل الخصوصية والأمان 🔒',
                      Icons.security_rounded,
                      theme),
                  RuknSpringButton(
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 8),
                    backgroundColor: widget.settings.cardBgColor,
                    borderColor: theme.primary.withOpacity(0.45),
                    onTap: _showConfigurePinDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pin_rounded,
                                color: theme.primary, size: 21),
                            const SizedBox(width: 10),
                            Text(
                              widget.settings.pinCode.isEmpty
                                  ? 'إعداد رمز الحماية السري (4 أرقام)'
                                  : 'تغيير أو إلغاء رمز الحماية السري (مفعّل ✓)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.settings.primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: widget.settings.secondaryTextColor),
                      ],
                    ),
                  ),
                  if (widget.settings.pinCode.isNotEmpty)
                    RuknSlidingSwitchRow(
                      title: 'قفل تطبيق «رُكْن» بالكامل عند التشغيل',
                      subtitle:
                          'طلب رمز الحماية فور فتح التطبيق (إضافة لقفل الملاحظات الخاصة)',
                      value: widget.settings.lockWholeAppOnStart,
                      onChanged: (v) =>
                          widget.settings.setLockWholeAppOnStart(v),
                      settings: widget.settings,
                      icon: Icons.phonelink_lock_rounded,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, GulfThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Row(
        children: [
          Icon(icon, color: theme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.settings.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required GulfThemeData theme,
  }) {
    return GestureDetector(
      onTap: () {
        RuknHaptics.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.primary : widget.settings.scaffoldBgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.accentGold : widget.settings.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : widget.settings.primaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
