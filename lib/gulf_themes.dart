import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GulfThemeData {
  final int id;
  final String name;
  final String subtitle;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color bgLight;
  final Color cardLight;
  final Color paperLight;
  final Color textMainLight;
  final Color textSubLight;
  final Color borderLight;

  const GulfThemeData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.bgLight,
    required this.cardLight,
    required this.paperLight,
    required this.textMainLight,
    required this.textSubLight,
    required this.borderLight,
  });

  Color bg(bool isDark) => isDark ? const Color(0xFF0B111E) : bgLight;
  Color card(bool isDark) => isDark ? const Color(0xFF151F32) : cardLight;
  Color paper(bool isDark) => isDark ? const Color(0xFF111927) : paperLight;
  Color textMain(bool isDark) => isDark ? const Color(0xFFF3F4F6) : textMainLight;
  Color textSub(bool isDark) => isDark ? const Color(0xFF9CA3AF) : textSubLight;
  Color border(bool isDark) =>
      isDark ? accent.withOpacity(0.28) : borderLight;
}

class RuknFontOption {
  final String id;
  final String name;
  final String family;
  final String category;

  const RuknFontOption({
    required this.id,
    required this.name,
    required this.family,
    required this.category,
  });
}

class EditorToolDefinition {
  final String id;
  final String label;
  final IconData icon;
  final bool defaultVisible;

  const EditorToolDefinition({
    required this.id,
    required this.label,
    required this.icon,
    this.defaultVisible = true,
  });
}

class GulfThemes {
  static const List<GulfThemeData> allThemes = [
    // 0: السعودي الملكي (معتمد وممتاز)
    GulfThemeData(
      id: 0,
      name: 'السعودي الملكي',
      subtitle: 'أخضر سلمان الفاخر مع الذهب الملكي',
      primary: Color(0xFF0F5132),
      primaryDark: Color(0xFF072B1A),
      accent: Color(0xFFD4AF37),
      bgLight: Color(0xFFF7F5F0),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFFFFDF9),
      textMainLight: Color(0xFF14241B),
      textSubLight: Color(0xFF52665A),
      borderLight: Color(0xFFE2DCCB),
    ),
    // 1: العنابي القطري (معتمد وممتاز)
    GulfThemeData(
      id: 1,
      name: 'العنابي القطري',
      subtitle: 'عنابي الأدعم الفخم مع اللمسة الذهبية',
      primary: Color(0xFF7A122E),
      primaryDark: Color(0xFF4A081A),
      accent: Color(0xFFD4AF37),
      bgLight: Color(0xFFF9F5F6),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFFFFCFD),
      textMainLight: Color(0xFF281117),
      textSubLight: Color(0xFF6E4F57),
      borderLight: Color(0xFFE6D5D9),
    ),
    // 2: الإماراتي الفاخر (أسود كربوني وتيتانيوم وذهب إماراتي وأبيض لؤلؤي)
    GulfThemeData(
      id: 2,
      name: 'الإماراتي الفاخر',
      subtitle: 'كربون وتيتانيوم ملكي مع الذهب والأبيض اللؤلؤي',
      primary: Color(0xFF23272F),
      primaryDark: Color(0xFF111318),
      accent: Color(0xFFD4AF37),
      bgLight: Color(0xFFF4F5F7),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFFAFAFC),
      textMainLight: Color(0xFF141619),
      textSubLight: Color(0xFF5A606B),
      borderLight: Color(0xFFDCE0E6),
    ),
    // 3: الأزرق الكويتي (أزرق خليجي حيوي ومشرق)
    GulfThemeData(
      id: 3,
      name: 'الأزرق الكويتي',
      subtitle: 'أزرق الخليج الحيوي المشرق مع لمسة ذهبية',
      primary: Color(0xFF0066CC),
      primaryDark: Color(0xFF004494),
      accent: Color(0xFFF59E0B),
      bgLight: Color(0xFFF0F7FF),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFF9FCFF),
      textMainLight: Color(0xFF0A2540),
      textSubLight: Color(0xFF426384),
      borderLight: Color(0xFFCFE4FF),
    ),
    // 4: العُماني السلطاني (معتمد وممتاز)
    GulfThemeData(
      id: 4,
      name: 'العُماني السلطاني',
      subtitle: 'نحاسي سلطاني أصيل مع اللبان العُماني',
      primary: Color(0xFF7C2D12),
      primaryDark: Color(0xFF4A1807),
      accent: Color(0xFFD97706),
      bgLight: Color(0xFFF8F5F2),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFFFFDFB),
      textMainLight: Color(0xFF291711),
      textSubLight: Color(0xFF6B534B),
      borderLight: Color(0xFFE5D8D0),
    ),
    // 5: البحريني اللؤلؤي (أحمرياقوتي مشرق مع بياض اللؤلؤ البحريني)
    GulfThemeData(
      id: 5,
      name: 'البحريني اللؤلؤي',
      subtitle: 'أحمر ياقوتي حيوي مع إشراقة اللؤلؤ والذهب',
      primary: Color(0xFFC8102E),
      primaryDark: Color(0xFF8F081E),
      accent: Color(0xFFEAB308),
      bgLight: Color(0xFFFFF6F7),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFFFFBFC),
      textMainLight: Color(0xFF2D0C12),
      textSubLight: Color(0xFF784750),
      borderLight: Color(0xFFF5D0D6),
    ),
    // 6: الصحراوي النجدي (رملي ذهبي مشرق وعسل السدر - مستقل تماماً عن العُماني)
    GulfThemeData(
      id: 6,
      name: 'الصحراوي النجدي',
      subtitle: 'رمال النفود الذهبية الدافئة وأصالة طويق',
      primary: Color(0xFF9A6B32),
      primaryDark: Color(0xFF66441B),
      accent: Color(0xFFD97706),
      bgLight: Color(0xFFFCF9F2),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFFFFEFA),
      textMainLight: Color(0xFF2B2113),
      textSubLight: Color(0xFF705D43),
      borderLight: Color(0xFFEAE0C8),
    ),
    // 7: الليلي الماسي
    GulfThemeData(
      id: 7,
      name: 'الليلي الماسي',
      subtitle: 'كحلي ملكي عميق مع بريق الألماس والذهب',
      primary: Color(0xFF1E293B),
      primaryDark: Color(0xFF0B132B),
      accent: Color(0xFFE2B857),
      bgLight: Color(0xFFF3F5F8),
      cardLight: Color(0xFFFFFFFF),
      paperLight: Color(0xFFFAFBFD),
      textMainLight: Color(0xFF0F172A),
      textSubLight: Color(0xFF475569),
      borderLight: Color(0xFFD8E0EA),
    ),
  ];

  static const List<RuknFontOption> allFonts = [
    RuknFontOption(
      id: 'Tajawal',
      name: 'خط تجوال (الافتراضي الأنيق)',
      family: 'Tajawal',
      category: 'عصري يومي',
    ),
    RuknFontOption(
      id: 'Cairo',
      name: 'خط القاهرة (واضح ورسمي)',
      family: 'Cairo',
      category: 'عصري يومي',
    ),
    RuknFontOption(
      id: 'Almarai',
      name: 'خط المراعي (سلس ومريح للعين)',
      family: 'Almarai',
      category: 'عصري يومي',
    ),
    RuknFontOption(
      id: 'ReadexPro',
      name: 'خط ريدكس برو (حداثة ودقة)',
      family: 'ReadexPro',
      category: 'عصري يومي',
    ),
    RuknFontOption(
      id: 'IBMPlexSansArabic',
      name: 'خط آي بي إم العربي (تقني فاخر)',
      family: 'IBMPlexSansArabic',
      category: 'عصري يومي',
    ),
    RuknFontOption(
      id: 'NotoSansArabic',
      name: 'خط نوتو سانس (متوازن وشامل)',
      family: 'NotoSansArabic',
      category: 'عصري يومي',
    ),
    RuknFontOption(
      id: 'Amiri',
      name: 'الخط الأميري (نسخ تراثي للشعر والأدب)',
      family: 'Amiri',
      category: 'أدبي وتراثي',
    ),
    RuknFontOption(
      id: 'ScheherazadeNew',
      name: 'خط شهرزاد (نسخ كلاسيكي أصيل)',
      family: 'ScheherazadeNew',
      category: 'أدبي وتراثي',
    ),
    RuknFontOption(
      id: 'NotoNaskhArabic',
      name: 'خط نوتو نسخ (قراءة مطولة مريحة)',
      family: 'NotoNaskhArabic',
      category: 'أدبي وتراثي',
    ),
    RuknFontOption(
      id: 'Lateef',
      name: 'خط لطيف (ديواني ناعم للخواطر)',
      family: 'Lateef',
      category: 'أدبي وتراثي',
    ),
    RuknFontOption(
      id: 'ArefRuqaa',
      name: 'خط عارف رقعة (ديواني فخم للعناوين)',
      family: 'ArefRuqaa',
      category: 'ديواني وفني',
    ),
    RuknFontOption(
      id: 'ReemKufi',
      name: 'خط ريم كوفي (كوفي هندسي عريق)',
      family: 'ReemKufi',
      category: 'ديواني وفني',
    ),
  ];

  static const List<EditorToolDefinition> allEditorTools = [
    EditorToolDefinition(id: 'undo', label: 'تراجع', icon: Icons.undo_rounded),
    EditorToolDefinition(id: 'redo', label: 'إعادة', icon: Icons.redo_rounded),
    EditorToolDefinition(id: 'copy', label: 'نسخ', icon: Icons.copy_rounded),
    EditorToolDefinition(id: 'paste', label: 'لصق', icon: Icons.content_paste_rounded),
    EditorToolDefinition(id: 'select_all', label: 'تحديد الكل', icon: Icons.select_all_rounded),
    EditorToolDefinition(id: 'auto_format', label: 'تنسيق النص', icon: Icons.auto_fix_high_rounded),
    EditorToolDefinition(id: 'smart_calc', label: 'جمع الأرقام', icon: Icons.functions_rounded),
    EditorToolDefinition(id: 'num_convert', label: 'تحويل الأرقام', icon: Icons.pin_rounded),
    EditorToolDefinition(id: 'checklist', label: 'مربع مهمة', icon: Icons.check_box_outlined),
    EditorToolDefinition(id: 'signature', label: 'التوقيع', icon: Icons.draw_rounded),
    EditorToolDefinition(id: 'cut', label: 'قص', icon: Icons.content_cut_rounded),
    EditorToolDefinition(id: 'select_up', label: 'تحديد للأعلى', icon: Icons.vertical_align_top_rounded),
    EditorToolDefinition(id: 'select_down', label: 'تحديد للأسفل', icon: Icons.vertical_align_bottom_rounded),
    EditorToolDefinition(id: 'datetime', label: 'التاريخ والوقت', icon: Icons.calendar_month_rounded),
    EditorToolDefinition(id: 'find_replace', label: 'بحث واستبدال', icon: Icons.find_replace_rounded),
  ];

  static const List<String> defaultUserCategories = [
    'عمل والتزامات',
    'شعر وخواطر',
    'مقاضي ومهام',
    'خاص',
  ];
}

class AppSettingsController extends ChangeNotifier {
  int _themeIndex = 0;
  bool _isDarkMode = false;
  String _fontFamily = 'Tajawal';
  double _baseFontSize = 18.0;

  String _userName = '';
  String _headerSubtitle = 'مفكرتي اليومية وملاذي الآمن للنصوص والأفكار';
  String _signatureText = '';

  bool _showHijriDateInHeader = true;
  bool _keepScreenOn = true;
  bool _toolbarShowIconsOnly = false;

  String _pinCode = '';
  bool _lockWholeApp = false;

  List<String> _toolbarOrder =
      GulfThemes.allEditorTools.map((e) => e.id).toList();
  Set<String> _hiddenTools = {};
  List<String> _customCategories = List<String>.from(GulfThemes.defaultUserCategories);

  int get themeIndex => _themeIndex;
  bool get isDarkMode => _isDarkMode;
  String get fontFamily => _fontFamily;
  double get baseFontSize => _baseFontSize;

  // Fixed prefix "رُكْن" only as requested
  String get titlePrefix => 'رُكْن';
  String get userName => _userName;
  String get headerSubtitle => _headerSubtitle;
  String get signatureText => _signatureText;

  bool get showHijriDateInHeader => _showHijriDateInHeader;
  bool get keepScreenOn => _keepScreenOn;
  bool get toolbarShowIconsOnly => _toolbarShowIconsOnly;

  String get pinCode => _pinCode;
  bool get hasPin => _pinCode.trim().length == 4;
  bool get lockWholeApp => _lockWholeApp;
  bool get shouldLockAppOnStart => hasPin && _lockWholeApp;

  List<String> get customCategories => List.unmodifiable(_customCategories);

  GulfThemeData get theme =>
      GulfThemes.allThemes[_themeIndex.clamp(0, GulfThemes.allThemes.length - 1)];

  RuknFontOption get font => GulfThemes.allFonts.firstWhere(
        (f) => f.family == _fontFamily,
        orElse: () => GulfThemes.allFonts.first,
      );

  Color get bgColor => theme.bg(_isDarkMode);
  Color get cardColor => theme.card(_isDarkMode);
  Color get paperColor => theme.paper(_isDarkMode);
  Color get textMainColor => theme.textMain(_isDarkMode);
  Color get textSubColor => theme.textSub(_isDarkMode);
  Color get borderColor => theme.border(_isDarkMode);
  Color get primaryColor => theme.primary;
  Color get primaryDarkColor => theme.primaryDark;
  Color get accentColor => theme.accent;

  String get fullHeaderTitle {
    final cleanName = _userName.trim();
    if (cleanName.isEmpty) {
      return 'رُكْن خاص';
    }
    if (cleanName.startsWith('رُكْن') || cleanName.startsWith('ركن')) {
      return cleanName;
    }
    return 'رُكْن $cleanName';
  }

  List<EditorToolDefinition> get orderedAllTools {
    final map = {for (final t in GulfThemes.allEditorTools) t.id: t};
    final result = <EditorToolDefinition>[];
    for (final id in _toolbarOrder) {
      if (map.containsKey(id)) {
        result.add(map.remove(id)!);
      }
    }
    result.addAll(map.values);
    return result;
  }

  List<EditorToolDefinition> get visibleEditorTools {
    return orderedAllTools.where((t) => !_hiddenTools.contains(t.id)).toList();
  }

  bool isToolVisible(String id) => !_hiddenTools.contains(id);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeIndex = prefs.getInt('rukn_theme_index') ?? 0;
    _isDarkMode = prefs.getBool('rukn_dark_mode') ?? false;
    _fontFamily = prefs.getString('rukn_font_family') ?? 'Tajawal';
    _baseFontSize = prefs.getDouble('rukn_base_font_size') ?? 18.0;

    _userName = prefs.getString('rukn_user_name') ?? '';
    _headerSubtitle = prefs.getString('rukn_header_subtitle') ??
        'مفكرتي اليومية وملاذي الآمن للنصوص والأفكار';
    _signatureText = prefs.getString('rukn_signature_text') ?? '';

    _showHijriDateInHeader = prefs.getBool('rukn_show_hijri') ?? true;
    _keepScreenOn = prefs.getBool('rukn_keep_screen_on') ?? true;
    _toolbarShowIconsOnly = prefs.getBool('rukn_toolbar_icons_only') ?? false;

    _pinCode = prefs.getString('rukn_pin_code') ?? '';
    _lockWholeApp = prefs.getBool('rukn_lock_whole_app') ?? false;

    final savedOrder = prefs.getStringList('rukn_toolbar_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      _toolbarOrder = savedOrder;
    }

    final savedHidden = prefs.getStringList('rukn_hidden_tools');
    if (savedHidden != null) {
      _hiddenTools = savedHidden.toSet();
    }

    final savedCatsJson = prefs.getString('rukn_custom_categories_v2');
    if (savedCatsJson != null && savedCatsJson.isNotEmpty) {
      try {
        final decoded = (jsonDecode(savedCatsJson) as List).cast<String>();
        if (decoded.isNotEmpty) {
          _customCategories = decoded;
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> setThemeIndex(int index) async {
    _themeIndex = index.clamp(0, GulfThemes.allThemes.length - 1);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rukn_theme_index', _themeIndex);
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_dark_mode', _isDarkMode);
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rukn_font_family', _fontFamily);
  }

  Future<void> setBaseFontSize(double size) async {
    _baseFontSize = size.clamp(12.0, 34.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rukn_base_font_size', _baseFontSize);
  }

  Future<void> updatePersonalIdentity({
    String? prefix,
    required String userName,
    required String subtitle,
    required String signature,
  }) async {
    _userName = userName.trim();
    _headerSubtitle = subtitle.trim().isEmpty
        ? 'مفكرتي اليومية وملاذي الآمن للنصوص والأفكار'
        : subtitle.trim();
    _signatureText = signature.trim();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rukn_user_name', _userName);
    await prefs.setString('rukn_header_subtitle', _headerSubtitle);
    await prefs.setString('rukn_signature_text', _signatureText);
  }

  Future<void> setShowHijriDateInHeader(bool value) async {
    _showHijriDateInHeader = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_show_hijri', _showHijriDateInHeader);
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_keep_screen_on', _keepScreenOn);
  }

  Future<void> setToolbarShowIconsOnly(bool value) async {
    _toolbarShowIconsOnly = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_toolbar_icons_only', _toolbarShowIconsOnly);
  }

  Future<void> setPinCode(String newPin) async {
    _pinCode = newPin.trim();
    if (_pinCode.length != 4) {
      _lockWholeApp = false;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rukn_pin_code', _pinCode);
    await prefs.setBool('rukn_lock_whole_app', _lockWholeApp);
  }

  Future<void> setLockWholeApp(bool value) async {
    _lockWholeApp = hasPin ? value : false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_lock_whole_app', _lockWholeApp);
  }

  Future<void> saveToolbarCustomization({
    required List<String> orderedIds,
    required Set<String> hiddenIds,
  }) async {
    _toolbarOrder = List<String>.from(orderedIds);
    _hiddenTools = Set<String>.from(hiddenIds);
    if (_hiddenTools.length >= GulfThemes.allEditorTools.length) {
      _hiddenTools.remove(_toolbarOrder.first);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rukn_toolbar_order', _toolbarOrder);
    await prefs.setStringList('rukn_hidden_tools', _hiddenTools.toList());
  }

  Future<void> resetToolbarToDefault() async {
    _toolbarOrder = GulfThemes.allEditorTools.map((e) => e.id).toList();
    _hiddenTools = {};
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rukn_toolbar_order');
    await prefs.remove('rukn_hidden_tools');
  }

  Future<void> addCustomCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty ||
        clean == 'الكل' ||
        clean == 'المثبتة' ||
        _customCategories.contains(clean)) {
      return;
    }
    _customCategories.add(clean);
    notifyListeners();
    await _persistCategories();
  }

  Future<void> renameCustomCategory(String oldName, String newName) async {
    final cleanNew = newName.trim();
    if (cleanNew.isEmpty || cleanNew == 'الكل' || cleanNew == 'المثبتة') return;
    final idx = _customCategories.indexOf(oldName);
    if (idx != -1 && !_customCategories.contains(cleanNew)) {
      _customCategories[idx] = cleanNew;
      notifyListeners();
      await _persistCategories();
    }
  }

  Future<void> deleteCustomCategory(String name) async {
    _customCategories.remove(name);
    notifyListeners();
    await _persistCategories();
  }

  Future<void> resetCategoriesToDefault() async {
    _customCategories = List<String>.from(GulfThemes.defaultUserCategories);
    notifyListeners();
    await _persistCategories();
  }

  Future<void> _persistCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'rukn_custom_categories_v2',
      jsonEncode(_customCategories),
    );
  }
}
