import 'package:flutter/material.dart';
import 'gulf_themes.dart';
import 'luxury_ui.dart';

class RuknSettingsScreen extends StatefulWidget {
  final AppSettingsController settings;
  final VoidCallback onOpenToolbarCustomizer;

  const RuknSettingsScreen({
    super.key,
    required this.settings,
    required this.onOpenToolbarCustomizer,
  });

  @override
  State<RuknSettingsScreen> createState() => _RuknSettingsScreenState();
}

class _RuknSettingsScreenState extends State<RuknSettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _signatureCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.settings.userName);
    _subtitleCtrl = TextEditingController(text: widget.settings.headerSubtitle);
    _signatureCtrl = TextEditingController(text: widget.settings.signatureText);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _signatureCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveIdentity() async {
    await widget.settings.updatePersonalIdentity(
      userName: _nameCtrl.text,
      subtitle: _subtitleCtrl.text,
      signature: _signatureCtrl.text,
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    showRuknToast(context, widget.settings, 'تم حفظ بيانات رُكْنك الشخصي بنجاح');
  }

  Future<void> _showThemeDropdownDialog() async {
    final s = widget.settings;
    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, color: s.accentColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اختر الثيم الملكي',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: s.textMainColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: s.textSubColor),
                  ),
                ],
              ),
              const Divider(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: GulfThemes.allThemes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) {
                    final item = GulfThemes.allThemes[idx];
                    final isSelected = s.themeIndex == idx;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        RuknHaptics.selection();
                        await s.setThemeIndex(idx);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? item.primary.withOpacity(0.12)
                              : s.bgColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? item.primary : s.borderColor,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [item.primaryDark, item.primary],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                border: Border.all(
                                  color: item.accent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontFamily: s.fontFamily,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: s.textMainColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      fontFamily: s.fontFamily,
                                      fontSize: 12,
                                      color: s.textSubColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: item.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFontDropdownDialog() async {
    final s = widget.settings;
    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 520),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.font_download_outlined, color: s.accentColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اختر الخط العربي',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: s.textMainColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: s.textSubColor),
                  ),
                ],
              ),
              const Divider(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: GulfThemes.allFonts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) {
                    final f = GulfThemes.allFonts[idx];
                    final isSelected = s.fontFamily == f.family;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        RuknHaptics.selection();
                        await s.setFontFamily(f.family);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? s.primaryColor.withOpacity(0.11)
                              : s.bgColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? s.primaryColor : s.borderColor,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    style: TextStyle(
                                      fontFamily: f.family,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: s.textMainColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ • ${f.category}',
                                    style: TextStyle(
                                      fontFamily: f.family,
                                      fontSize: 12.5,
                                      color: s.textSubColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: s.primaryColor,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPinSetupDialog() async {
    final s = widget.settings;
    final ctrl = TextEditingController(text: s.pinCode);
    String? errorText;

    await showRuknModalDialog(
      context: context,
      settings: s,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: s.accentColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.hasPin ? 'تعديل الرمز السري (4 أرقام)' : 'إعداد رمز سري (4 أرقام)',
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 22,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w800,
                      color: s.textMainColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      errorText: errorText,
                      filled: true,
                      fillColor: s.bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: s.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
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
                            final pin = ctrl.text.trim();
                            if (pin.length != 4 || int.tryParse(pin) == null) {
                              setModalState(() {
                                errorText = 'يرجى إدخال 4 أرقام صحيحة';
                              });
                              return;
                            }
                            await s.setPinCode(pin);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              showRuknToast(context, s, 'تم تفعيل الرمز السري بنجاح');
                            }
                          },
                          child: Text(
                            'حفظ الرمز',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (s.hasPin) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await s.setPinCode('');
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              showRuknToast(context, s, 'تم إلغاء الرمز السري');
                            }
                          },
                          child: Text(
                            'إلغاء القفل',
                            style: TextStyle(
                              fontFamily: s.fontFamily,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'إغلاق',
                          style: TextStyle(
                            fontFamily: s.fontFamily,
                            color: s.textSubColor,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        final s = widget.settings;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: s.bgColor,
            body: Column(
              children: [
                _buildTopBar(s),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // 1. المظهر والثيم والخطوط (قوائم منسدلة مرتبة)
                      _buildSectionCard(
                        s: s,
                        title: 'المظهر والخطوط',
                        icon: Icons.palette_outlined,
                        children: [
                          _buildDropdownRow(
                            s: s,
                            label: 'الثيم الملكي',
                            valueText: s.theme.name,
                            leadingColor: s.primaryColor,
                            accentColor: s.accentColor,
                            onTap: _showThemeDropdownDialog,
                          ),
                          const SizedBox(height: 12),
                          _buildDropdownRow(
                            s: s,
                            label: 'الخط العربي',
                            valueText: s.font.name,
                            onTap: _showFontDropdownDialog,
                          ),
                          const SizedBox(height: 8),
                          RuknSlidingSwitchRow(
                            title: 'الوضع الليلي الداكن',
                            subtitle: 'خلفية داكنة مريحة للعين في الإضاءة المنخفضة',
                            value: s.isDarkMode,
                            onChanged: (v) => s.setDarkMode(v),
                            settings: s,
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              Text(
                                'حجم الخط الأساسي',
                                style: TextStyle(
                                  fontFamily: s.fontFamily,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: s.textMainColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: s.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${s.baseFontSize.toInt()}',
                                  style: TextStyle(
                                    fontFamily: s.fontFamily,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: s.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: s.baseFontSize,
                            min: 14.0,
                            max: 30.0,
                            divisions: 16,
                            activeColor: s.primaryColor,
                            inactiveColor: s.borderColor,
                            onChanged: (val) => s.setBaseFontSize(val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 2. أدوات التحرير والقراءة
                      _buildSectionCard(
                        s: s,
                        title: 'أدوات التحرير والقراءة',
                        icon: Icons.tune_rounded,
                        children: [
                          // "عرض أدوات التحرير" مع زر [ نصوص | رموز ] متناسق ومحتوى داخل المستطيل 100%
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'عرض أدوات التحرير',
                                  style: TextStyle(
                                    fontFamily: s.fontFamily,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: s.textMainColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: s.bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: s.borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildCompactModeChip(
                                      s: s,
                                      label: 'نصوص',
                                      selected: !s.toolbarShowIconsOnly,
                                      onTap: () => s.setToolbarShowIconsOnly(false),
                                    ),
                                    _buildCompactModeChip(
                                      s: s,
                                      label: 'رموز',
                                      selected: s.toolbarShowIconsOnly,
                                      onTap: () => s.setToolbarShowIconsOnly(true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RuknSpringButton(
                            onTap: widget.onOpenToolbarCustomizer,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: s.primaryColor.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: s.primaryColor.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.reorder_rounded,
                                    color: s.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'تخصيص وترتيب أدوات التحرير',
                                        style: TextStyle(
                                          fontFamily: s.fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: s.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          RuknSlidingSwitchRow(
                            title: 'إبقاء الشاشة مضاءة أثناء القراءة',
                            subtitle: 'منع انطفاء الشاشة تلقائياً داخل شاشة المستند',
                            value: s.keepScreenOn,
                            onChanged: (v) => s.setKeepScreenOn(v),
                            settings: s,
                          ),
                          RuknSlidingSwitchRow(
                            title: 'إظهار التاريخ الهجري والميلادي',
                            subtitle: 'عرض شريط التاريخ في ترويسة الشاشة الرئيسية',
                            value: s.showHijriDateInHeader,
                            onChanged: (v) => s.setShowHijriDateInHeader(v),
                            settings: s,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 3. تخصيص ترويسة "رُكْن" والتوقيع
                      _buildSectionCard(
                        s: s,
                        title: 'تخصيص ترويسة رُكْن والتوقيع',
                        icon: Icons.badge_outlined,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: s.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  size: 18,
                                  color: s.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'المعاينة الحالية: ${s.fullHeaderTitle}',
                                    style: TextStyle(
                                      fontFamily: s.fontFamily,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: s.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            s: s,
                            controller: _nameCtrl,
                            label: 'الاسم بعد كلمة رُكْن (مثلاً: أبو فهد، أو اتركه فارغاً ليكون "رُكْن خاص")',
                            hint: 'خاص',
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            s: s,
                            controller: _subtitleCtrl,
                            label: 'العبارة الترحيبية أسفل العنوان',
                            hint: 'مفكرتي اليومية وملاذي الآمن للنصوص والأفكار',
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            s: s,
                            controller: _signatureCtrl,
                            label: 'نص التوقيع الشخصي (يُدرج بضغطة زر في المحرر)',
                            hint: 'كتبه: ...',
                          ),
                          const SizedBox(height: 12),
                          RuknSpringButton(
                            onTap: _saveIdentity,
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: s.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'حفظ بيانات الترويسة والتوقيع',
                                style: TextStyle(
                                  fontFamily: s.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 4. الحماية والخصوصية (PIN)
                      _buildSectionCard(
                        s: s,
                        title: 'الحماية والرمز السري',
                        icon: Icons.shield_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.hasPin
                                          ? 'الرمز السري مفعل حالياً (4 أرقام)'
                                          : 'لم يتم تعيين رمز سري بعد',
                                      style: TextStyle(
                                        fontFamily: s.fontFamily,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: s.textMainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'يُستخدم لحماية الملفات المقفلة أو قفل التطبيق عند فتحه',
                                      style: TextStyle(
                                        fontFamily: s.fontFamily,
                                        fontSize: 12,
                                        color: s.textSubColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              RuknSpringButton(
                                onTap: _showPinSetupDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    s.hasPin ? 'تعديل الرمز' : 'تعيين رمز',
                                    style: TextStyle(
                                      fontFamily: s.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RuknSlidingSwitchRow(
                            title: 'طلب الرمز السري عند فتح التطبيق',
                            subtitle: s.hasPin
                                ? 'قفل التطبيق بالكامل عند التشغيل أو العودة إليه'
                                : 'عيّن رمزاً سرياً أولاً لتفعيل هذا الخيار',
                            value: s.shouldLockAppOnStart,
                            onChanged: (val) async {
                              if (!s.hasPin) {
                                await _showPinSetupDialog();
                                if (s.hasPin) {
                                  await s.setLockWholeApp(true);
                                }
                              } else {
                                await s.setLockWholeApp(val);
                              }
                            },
                            settings: s,
                          ),
                        ],
                      ),
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

  // ترويسة واحدة أنيقة على اليمين فقط بدون تكرار على اليسار
  Widget _buildTopBar(AppSettingsController s) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 14,
        right: 16,
        left: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [s.primaryDarkColor, s.primaryColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border(
          bottom: BorderSide(color: s.accentColor, width: 1.4),
        ),
      ),
      child: Row(
        children: [
          RuknSpringButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: s.accentColor.withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'رجوع',
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'إعدادات رُكْن',
            style: TextStyle(
              fontFamily: s.fontFamily,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required AppSettingsController s,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: s.borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(s.isDarkMode ? 0.22 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: s.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: s.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: s.primaryColor,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required AppSettingsController s,
    required String label,
    required String valueText,
    required VoidCallback onTap,
    Color? leadingColor,
    Color? accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: s.textSubColor,
          ),
        ),
        const SizedBox(height: 6),
        RuknSpringButton(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: s.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                if (leadingColor != null) ...[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: leadingColor,
                      border: Border.all(
                        color: accentColor ?? s.accentColor,
                        width: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: s.textMainColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: s.primaryColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactModeChip({
    required AppSettingsController s,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        RuknHaptics.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? s.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : s.textSubColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required AppSettingsController s,
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: s.textSubColor,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: 14,
            color: s.textMainColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            filled: true,
            fillColor: s.bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: s.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: s.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: s.primaryColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
