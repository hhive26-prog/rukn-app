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

class _RuknLuxuryAppState extends State<RuknLuxuryApp>
    with WidgetsBindingObserver {
  bool _appUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appUnlocked = !widget.settings.shouldLockAppOnStart;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when app goes to background if startup lock is enabled
    if (state == AppLifecycleState.paused &&
        widget.settings.shouldLockAppOnStart) {
      setState(() {
        _appUnlocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.settings, widget.vault]),
      builder: (context, _) {
        final bool isDark = widget.settings.isDarkMode;
        final Color primary = widget.settings.primaryColor;
        final Color scaffoldBg = widget.settings.bgColor;
        final String fontFamily = widget.settings.fontFamily;

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
              secondary: widget.settings.accentColor,
              surface: widget.settings.cardColor,
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
    if (!_appUnlocked && widget.settings.shouldLockAppOnStart) {
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
