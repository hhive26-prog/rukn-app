import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'storage_vault.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ضبط شريط الحالة العلوي والسفلي ليكون شفافاً ومتناغماً مع الثيم الملكي
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // تحميل إعدادات المستخدم والثيم الخليجي والخط المفضل
  final settingsController = AppSettingsController();
  await settingsController.loadSettings();

  // تهيئة محرك التخزين وخزنة النسخ الآمنة
  final vaultController = StorageVaultController();
  await vaultController.initializeVault();

  runApp(
    RuknLuxuryApp(
      settings: settingsController,
      vault: vaultController,
    ),
  );
}

class RuknLuxuryApp extends StatefulWidget {
  final AppSettingsController settings;
  final StorageVaultController vault;

  const RuknLuxuryApp({
    super.key,
    required this.settings,
    required this.vault,
  });

  @override
  State<RuknLuxuryApp> createState() => _RuknLuxuryAppState();
}

class _RuknLuxuryAppState extends State<RuknLuxuryApp>
    with WidgetsBindingObserver {
  bool _isAppLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_onSettingsChanged);
    widget.vault.addListener(_onSettingsChanged);

    // إذا كان قفل التطبيق العام مفعلاً عند التشغيل
    if (widget.settings.lockWholeAppOnStart &&
        widget.settings.pinCode.isNotEmpty) {
      _isAppLocked = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_onSettingsChanged);
    widget.vault.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // قفل التطبيق تلقائياً عند الخروج للخلفية إذا اختار المستخدم قفل التطبيق الكامل
    if (state == AppLifecycleState.paused) {
      if (widget.settings.lockWholeAppOnStart &&
          widget.settings.pinCode.isNotEmpty) {
        setState(() {
          _isAppLocked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = widget.settings.activeTheme;
    final fontFamily = widget.settings.activeFontFamily;

    return MaterialApp(
      title: 'رُكْن',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: GulfThemes.buildMaterialTheme(
        gulfTheme: activeTheme,
        isDarkMode: widget.settings.isDarkMode,
        fontFamily: fontFamily,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            // الحفاظ على تناسق الواجهة مع السماح بالتكبير الداخلي للمستند
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: _isAppLocked
          ? RuknPinLockScreen(
              settings: widget.settings,
              title: 'مرحباً بك في ${widget.settings.fullPersonalHeaderTitle}',
              subtitle: 'أدخل رمز الحماية لفتح ركنك الخاص',
              onUnlocked: () {
                setState(() {
                  _isAppLocked = false;
                });
              },
            )
          : RuknHomeScreen(
              settings: widget.settings,
              vault: widget.vault,
            ),
    );
  }
}
