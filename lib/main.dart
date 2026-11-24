import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'storage_vault.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final settings = AppSettingsController();
  await settings.loadSettings();

  final vault = StorageVaultController();
  await vault.initializeVault();

  runApp(
    RuknLuxuryApp(
      settings: settings,
      vault: vault,
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

class _RuknLuxuryAppState extends State<RuknLuxuryApp> {
  bool _appUnlocked = false;

  bool _shouldLockOnStart() {
    try {
      final dynamic dynSettings = widget.settings;
      final bool hasPin = (dynSettings.pinCode as String?)?.length == 4;
      final bool lockApp = (dynSettings.lockWholeApp as bool?) ?? false;
      return hasPin && lockApp;
    } catch (_) {
      return false;
    }
  }

  String _resolveFontFamily() {
    try {
      final dynamic dynSettings = widget.settings;
      return (dynSettings.fontFamily as String?) ?? 'Tajawal';
    } catch (_) {
      return 'Tajawal';
    }
  }

  Color _resolvePrimaryColor() {
    try {
      final dynamic dynSettings = widget.settings;
      return (dynSettings.primaryColor as Color?) ?? const Color(0xFF0F5132);
    } catch (_) {
      return const Color(0xFF0F5132);
    }
  }

  Color _resolveScaffoldBg() {
    try {
      final dynamic dynSettings = widget.settings;
      return (dynSettings.bgColor as Color?) ??
          (widget.settings.isDarkMode
              ? const Color(0xFF0B132B)
              : const Color(0xFFF8F5F0));
    } catch (_) {
      return widget.settings.isDarkMode
          ? const Color(0xFF0B132B)
          : const Color(0xFFF8F5F0);
    }
  }

  @override
  void initState() {
    super.initState();
    if (!_shouldLockOnStart()) {
      _appUnlocked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.settings, widget.vault]),
      builder: (context, _) {
        final bool isDark = widget.settings.isDarkMode;
        final Color primary = _resolvePrimaryColor();
        final Color scaffoldBg = _resolveScaffoldBg();
        final String fontFamily = _resolveFontFamily();

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: scaffoldBg,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'رُكْن',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar', 'SA'),
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('ar'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: scaffoldBg,
            primaryColor: primary,
            fontFamily: fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primary,
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: primary,
            ),
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: _buildHomeGate(),
        );
      },
    );
  }

  Widget _buildHomeGate() {
    if (!_appUnlocked && _shouldLockOnStart()) {
      return RuknPinLockScreen(
        settings: widget.settings,
        title: 'رُكْن محمي برمز سري',
        subtitle: 'أدخل رمز الحماية المكون من 4 أرقام للدخول',
        onUnlocked: () {
          setState(() {
            _appUnlocked = true;
          });
        },
      );
    }

    return RuknHomeScreen(
      settings: widget.settings,
      vault: widget.vault,
    );
  }
}
