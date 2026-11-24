import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بيانات كل ثيم خليجي فاخر
class GulfThemeData {
  final int id;
  final String name;
  final String badge;
  final String description;
  final Color primary;
  final Color primaryDark;
  final Color accentGold;
  final Color softTint;
  final Color lightBackground;
  final Color lightPaper;

  const GulfThemeData({
    required this.id,
    required this.name,
    required this.badge,
    required this.description,
    required this.primary,
    required this.primaryDark,
    required this.accentGold,
    required this.softTint,
    required this.lightBackground,
    required this.lightPaper,
  });
}

/// بيانات الخطوط الـ 12 المدمجة في رُكْن
class RuknFontOption {
  final int id;
  final String title;
  final String? fontFamily;

  const RuknFontOption({
    required this.id,
    required this.title,
    required this.fontFamily,
  });
}

/// تعريف أداة من أدوات شريط التحرير القابل للتخصيص
class EditorToolDefinition {
  final String id;
  final String label;
  final IconData icon;

  const EditorToolDefinition({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class GulfThemes {
  /// الثيمات الخليجية الـ 8 المعتمدة
  static const List<GulfThemeData> themes = [
    GulfThemeData(
      id: 0,
      name: 'السعودي الملكي',
      badge: '🇸🇦',
      description: 'أخضر زمردي ملكي مع لمسات ذهبية فاخرة',
      primary: Color(0xFF065F46),
      primaryDark: Color(0xFF033829),
      accentGold: Color(0xFFD4AF37),
      softTint: Color(0xFFD1FAE5),
      lightBackground: Color(0xFFF4F7F5),
      lightPaper: Color(0xFFFFFFFF),
    ),
    GulfThemeData(
      id: 1,
      name: 'العنابي القطري',
      badge: '🇶🇦',
      description: 'عنابي مخملي رسمي مع إطار ذهبي دافئ',
      primary: Color(0xFF8A1538),
      primaryDark: Color(0xFF4C0519),
      accentGold: Color(0xFFE5C158),
      softTint: Color(0xFFFFE4E6),
      lightBackground: Color(0xGGG9F5F6 == 0 ? 0xFFF9F5F6 : 0xFFF9F5F6),
      lightPaper: Color(0xFFFFFFFF),
    ),
    GulfThemeData(
      id: 2,
      name: 'الإماراتي الفاخر',
      badge: '🇦🇪',
      description: 'أسود كربوني ملكي مطعّم بالذهب المصقول',
      primary: Color(0xFF1F2937),
      primaryDark: Color(0xFF090D16),
      accentGold: Color(0xFFC5A059),
      softTint: Color(0xFFFEF3C7),
      lightBackground: Color(0xFFF5F5F4),
      lightPaper: Color(0xFFFFFFFF),
    ),
    GulfThemeData(
      id: 3,
      name: 'الأزرق الكويتي',
      badge: '🇰🇼',
      description: 'أزرق بحري ياقوتي مستوحى من الخليج العربي',
      primary: Color(0xFF0C4A6E),
      primaryDark: Color(0xFF072A40),
      accentGold: Color(0xFF38BDF8),
      softTint: Color(0xFFE0F2FE),
      lightBackground: Color(0xFFF3F7FA),
      lightPaper: Color(0xFFFFFFFF),
    ),
    GulfThemeData(
      id: 4,
      name: 'العُماني السلطاني',
      badge: '🇴🇲',
      description: 'نحاسي سلطاني أصيل مستوحى من التراث العُماني',
      primary: Color(0xFF8C2D19),
      primaryDark: Color(0xFF431407),
      accentGold: Color(0xFFD97706),
      softTint: Color(0xFFFFEDD5),
      lightBackground: Color(0xGGG8F5F2 == 0 ? 0xFFF8F5F2 : 0xFFF8F5F2),
      lightPaper: Color(0xFFFFFFFF),
    ),
    GulfThemeData(
      id: 5,
      name: 'البحريني اللؤلؤي',
      badge: '🇧🇭',
      description: 'أحمر ياقوتي فخم مع صفاء اللؤلؤ البحريني',
      primary: Color(0xFF991B1B),
      primaryDark: Color(0xFF450A0A),
      accentGold: Color(0xFFF59E0B),
      softTint: Color(0xFFFEE2E2),
      lightBackground: Color(0xGGG9F6F6 == 0 ? 0xFFF9F6F6 : 0xFFF9F6F6),
      lightPaper: Color(0xFFFFFFFF),
    ),
    GulfThemeData(
      id: 6,
      name: 'الصحراوي النجدي',
      badge: '🐪',
      description: 'درجات القهوة الشقراء والرمال العربية الدافئة',
      primary: Color(0xFF78350F),
      primaryDark: Color(0xFF451A03),
      accentGold: Color(0xFFD97706),
      softTint: Color(0xFFFEF3C7),
      lightBackground: Color(0xFFFAF6F0),
      lightPaper: Color(0xFFFFFDF9),
    ),
    GulfThemeData(
      id: 7,
      name: 'الليلي الماسي',
      badge: '🌑',
      description: 'كحلي ماسي عميق بلمسات فضية وذهبية هادئة',
      primary: Color(0xFF1E293B),
      primaryDark: Color(0xFF0B1120),
      accentGold: Color(0xFFD4AF37),
      softTint: Color(0xFFE2E8F0),
      lightBackground: Color(0xFFF1F5F9),
      lightPaper: Color(0xFFFFFFFF),
    ),
  ];

  /// الخطوط الـ 12 المعتمدة
  static const List<RuknFontOption> fonts = [
    RuknFontOption(id: 0, title: 'Sans — خط واضح وعصري (افتراضي)', fontFamily: null),
    RuknFontOption(id: 1, title: 'تجوال — خط خليجي حديث وأنيق', fontFamily: 'Tajawal'),
    RuknFontOption(id: 2, title: 'المراعي — خط عربي كلاسيكي مريح ومتوازن', fontFamily: 'Almarai'),
    RuknFontOption(id: 3, title: 'شهرزاد عريض — خط نسخي تراثي أصيل', fontFamily: 'ScheherazadeNew'),
    RuknFontOption(id: 4, title: 'ريدكس برو — خط عصري فائق الوضوح', fontFamily: 'ReadexPro'),
    RuknFontOption(id: 5, title: 'نوتو سانس — خط قياسي متوازن', fontFamily: 'NotoSansArabic'),
    RuknFontOption(id: 6, title: 'نوتو نسخ — خط نسخي مطبعي للأبحاث', fontFamily: 'NotoNaskhArabic'),
    RuknFontOption(id: 7, title: 'آي بي إم بليكس — خط تقني حديث وأنيق', fontFamily: 'IBMPlexSansArabic'),
    RuknFontOption(id: 8, title: 'عارف رقعة — خط الرقعة العربي الفاخر', fontFamily: 'ArefRuqaa'),
    RuknFontOption(id: 9, title: 'ريم كوفي — خط كوفي هندسي مميز', fontFamily: 'ReemKufi'),
    RuknFontOption(id: 10, title: 'Serif — خط رسمي مريح للقراءة', fontFamily: 'serif'),
    RuknFontOption(id: 11, title: 'Monospace — خط هندسي متساوي الأبعاد', fontFamily: 'monospace'),
  ];

  /// جميع أدوات التحرير الاحترافية (الأدوات الـ 12 الكلاسيكية + 3 أدوات خليجية ذكية)
  static const List<EditorToolDefinition> allEditorTools = [
    EditorToolDefinition(id: 'undo', label: 'تراجع', icon: Icons.undo_rounded),
    EditorToolDefinition(id: 'redo', label: 'إعادة', icon: Icons.redo_rounded),
    EditorToolDefinition(id: 'copy', label: 'نسخ', icon: Icons.content_copy_rounded),
    EditorToolDefinition(id: 'paste', label: 'لصق', icon: Icons.content_paste_rounded),
    EditorToolDefinition(id: 'select_all', label: 'تحديد الكل', icon: Icons.select_all_rounded),
    EditorToolDefinition(id: 'auto_format', label: 'تنسيق آلي', icon: Icons.auto_fix_high_rounded),
    EditorToolDefinition(id: 'smart_calc', label: 'جمع الأرقام ∑', icon: Icons.functions_rounded),
    EditorToolDefinition(id: 'num_convert', label: '١٢٣ ↔ 123', icon: Icons.pin_rounded),
    EditorToolDefinition(id: 'checklist', label: 'قائمة مهام', icon: Icons.check_box_outlined),
    EditorToolDefinition(id: 'signature', label: 'التوقيع', icon: Icons.draw_rounded),
    EditorToolDefinition(id: 'cut', label: 'قص', icon: Icons.content_cut_rounded),
    EditorToolDefinition(id: 'select_up', label: 'تحديد للأعلى', icon: Icons.vertical_align_top_rounded),
    EditorToolDefinition(id: 'select_down', label: 'تحديد للأسفل', icon: Icons.vertical_align_bottom_rounded),
    EditorToolDefinition(id: 'datetime', label: 'التاريخ والوقت', icon: Icons.calendar_month_rounded),
    EditorToolDefinition(id: 'find_replace', label: 'بحث واستبدال', icon: Icons.find_replace_rounded),
  ];

  static ThemeData buildMaterialTheme({
    required GulfThemeData gulfTheme,
    required bool isDarkMode,
    required String? fontFamily,
  }) {
    final bg = isDarkMode ? const Color(0xFF0F172A) : gulfTheme.lightBackground;
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : gulfTheme.lightPaper;
    final textPrimary = isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: gulfTheme.primary,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gulfTheme.primary,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: gulfTheme.primary,
        secondary: gulfTheme.accentGold,
        surface: cardBg,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontFamily: fontFamily),
        bodyMedium: TextStyle(color: textPrimary, fontFamily: fontFamily),
        titleLarge: TextStyle(
          color: textPrimary,
          fontFamily: fontFamily,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// متحكم الإعدادات الشامل لتطبيق "رُكْن"
class AppSettingsController extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.rukn.app/native');

  // التخصيص الشخصي لصاحب الركن
  String _personalPrefix = 'رُكْن'; // رُكْن، مِساحة، دِيوان، خَلوة، مفكرة
  String _userName = '';
  String _customSubtitle = 'مساحتك الخاصة لتدوين الفكر وتنظيم اليوم';
  String _signatureText = '';

  // المظهر والخطوط
  int _themeIndex = 0; // افتراضي: السعودي الملكي
  bool _isDarkMode = false;
  int _fontIndex = 1; // افتراضي: خط تجوال الخليجي الأنيق
  int _zoomPercent = 100; // من 50% إلى 250%

  // إعدادات شريط أدوات التحرير
  bool _toolbarIconsOnly = false; // نصوص + رموز افتراضياً
  List<String> _orderedToolIds = [];
  Set<String> _enabledToolIds = {};

  // الخصوصية والراحة
  String _pinCode = '';
  bool _lockWholeAppOnStart = false;
  bool _keepScreenOnInReader = true;
  bool _showHijriInHeader = true;

  // Getters
  String get personalPrefix => _personalPrefix;
  String get userName => _userName;
  String get customSubtitle => _customSubtitle;
  String get signatureText => _signatureText;
  int get themeIndex => _themeIndex;
  bool get isDarkMode => _isDarkMode;
  int get fontIndex => _fontIndex;
  int get zoomPercent => _zoomPercent;
  bool get toolbarIconsOnly => _toolbarIconsOnly;
  List<String> get orderedToolIds => List.unmodifiable(_orderedToolIds);
  Set<String> get enabledToolIds => Set.unmodifiable(_enabledToolIds);
  String get pinCode => _pinCode;
  bool get lockWholeAppOnStart => _lockWholeAppOnStart;
  bool get keepScreenOnInReader => _keepScreenOnInReader;
  bool get showHijriInHeader => _showHijriInHeader;

  GulfThemeData get activeTheme =>
      GulfThemes.themes[_themeIndex.clamp(0, GulfThemes.themes.length - 1)];

  RuknFontOption get activeFontOption =>
      GulfThemes.fonts[_fontIndex.clamp(0, GulfThemes.fonts.length - 1)];

  String? get activeFontFamily => activeFontOption.fontFamily;

  /// العنوان الكامل الذي يظهر في البطاقة الملكية العلوية
  String get fullPersonalHeaderTitle {
    final cleanName = _userName.trim();
    if (cleanName.isEmpty) {
      return '$_personalPrefix خاص';
    }
    return '$_personalPrefix $cleanName';
  }

  // ألوان ديناميكية حسب الوضع الليلي أو النهاري
  Color get scaffoldBgColor =>
      _isDarkMode ? const Color(0xFF0F172A) : activeTheme.lightBackground;

  Color get cardBgColor =>
      _isDarkMode ? const Color(0xFF1E293B) : activeTheme.lightPaper;

  Color get paperBgColor =>
      _isDarkMode ? const Color(0xFF131C2E) : activeTheme.lightPaper;

  Color get primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  Color get secondaryTextColor =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  Color get borderColor => _isDarkMode
      ? const Color(0xFF334155)
      : activeTheme.primary.withOpacity(0.14);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _personalPrefix = prefs.getString('rukn_prefix') ?? 'رُكْن';
    _userName = prefs.getString('rukn_user_name') ?? '';
    _customSubtitle = prefs.getString('rukn_subtitle') ??
        'مساحتك الخاصة لتدوين الفكر وتنظيم اليوم';
    _signatureText = prefs.getString('rukn_signature') ?? '';

    _themeIndex = (prefs.getInt('rukn_theme_index') ?? 0)
        .clamp(0, GulfThemes.themes.length - 1);
    _isDarkMode = prefs.getBool('rukn_dark_mode') ?? false;
    _fontIndex = (prefs.getInt('rukn_font_index') ?? 1)
        .clamp(0, GulfThemes.fonts.length - 1);
    _zoomPercent = (prefs.getInt('rukn_zoom_percent') ?? 100).clamp(50, 250);

    _toolbarIconsOnly = prefs.getBool('rukn_toolbar_icons_only') ?? false;
    _pinCode = prefs.getString('rukn_pin_code') ?? '';
    _lockWholeAppOnStart = prefs.getBool('rukn_lock_app_start') ?? false;
    _keepScreenOnInReader = prefs.getBool('rukn_keep_screen_on') ?? true;
    _showHijriInHeader = prefs.getBool('rukn_show_hijri') ?? true;

    final savedOrder = prefs.getStringList('rukn_tool_order');
    final savedEnabled = prefs.getStringList('rukn_tool_enabled');

    final defaultIds = GulfThemes.allEditorTools.map((e) => e.id).toList();
    if (savedOrder != null && savedOrder.isNotEmpty) {
      _orderedToolIds = List<String>.from(savedOrder);
      for (final id in defaultIds) {
        if (!_orderedToolIds.contains(id)) {
          _orderedToolIds.add(id);
        }
      }
    } else {
      _orderedToolIds = List<String>.from(defaultIds);
    }

    if (savedEnabled != null) {
      _enabledToolIds = Set<String>.from(savedEnabled);
    } else {
      _enabledToolIds = Set<String>.from(defaultIds);
    }

    notifyListeners();
  }

  Future<void> updatePersonalIdentity({
    required String prefix,
    required String userName,
    required String subtitle,
  }) async {
    _personalPrefix = prefix.trim().isEmpty ? 'رُكْن' : prefix.trim();
    _userName = userName.trim();
    _customSubtitle = subtitle.trim().isEmpty
        ? 'مساحتك الخاصة لتدوين الفكر وتنظيم اليوم'
        : subtitle.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rukn_prefix', _personalPrefix);
    await prefs.setString('rukn_user_name', _userName);
    await prefs.setString('rukn_subtitle', _customSubtitle);
    notifyListeners();
  }

  Future<void> setSignatureText(String text) async {
    _signatureText = text;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rukn_signature', text);
    notifyListeners();
  }

  Future<void> setThemeIndex(int index) async {
    _themeIndex = index.clamp(0, GulfThemes.themes.length - 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rukn_theme_index', _themeIndex);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_dark_mode', value);
    notifyListeners();
  }

  Future<void> setFontIndex(int index) async {
    _fontIndex = index.clamp(0, GulfThemes.fonts.length - 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rukn_font_index', _fontIndex);
    notifyListeners();
  }

  Future<void> setZoomPercent(int percent) async {
    _zoomPercent = percent.clamp(50, 250);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rukn_zoom_percent', _zoomPercent);
    notifyListeners();
  }

  Future<void> setToolbarIconsOnly(bool iconsOnly) async {
    _toolbarIconsOnly = iconsOnly;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_toolbar_icons_only', iconsOnly);
    notifyListeners();
  }

  Future<void> saveToolbarCustomization({
    required List<String> orderedIds,
    required Set<String> enabledIds,
  }) async {
    _orderedToolIds = List<String>.from(orderedIds);
    _enabledToolIds = Set<String>.from(enabledIds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rukn_tool_order', _orderedToolIds);
    await prefs.setStringList('rukn_tool_enabled', _enabledToolIds.toList());
    notifyListeners();
  }

  Future<void> resetToolbarToDefault() async {
    final defaultIds = GulfThemes.allEditorTools.map((e) => e.id).toList();
    await saveToolbarCustomization(
      orderedIds: defaultIds,
      enabledIds: Set<String>.from(defaultIds),
    );
  }

  List<EditorToolDefinition> get activeOrderedTools {
    final List<EditorToolDefinition> result = [];
    for (final id in _orderedToolIds) {
      if (_enabledToolIds.contains(id)) {
        final match = GulfThemes.allEditorTools.where((t) => t.id == id);
        if (match.isNotEmpty) {
          result.add(match.first);
        }
      }
    }
    return result;
  }

  Future<void> setPinCode(String newPin) async {
    _pinCode = newPin.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rukn_pin_code', _pinCode);
    if (_pinCode.isEmpty) {
      _lockWholeAppOnStart = false;
      await prefs.setBool('rukn_lock_app_start', false);
    }
    notifyListeners();
  }

  Future<void> setLockWholeAppOnStart(bool value) async {
    _lockWholeAppOnStart = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_lock_app_start', value);
    notifyListeners();
  }

  Future<void> setKeepScreenOnInReader(bool value) async {
    _keepScreenOnInReader = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_keep_screen_on', value);
    notifyListeners();
  }

  Future<void> setShowHijriInHeader(bool value) async {
    _showHijriInHeader = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rukn_show_hijri', value);
    notifyListeners();
  }

  /// تفعيل أو إيقاف بقاء الشاشة مضاءة أثناء القراءة (وضع القهوة والقراءة)
  Future<void> applyWakeLock(bool enable) async {
    try {
      await _nativeChannel.invokeMethod('setKeepScreenOn', {
        'enable': enable && _keepScreenOnInReader,
      });
    } catch (_) {}
  }
}
