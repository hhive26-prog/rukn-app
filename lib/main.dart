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

  @override
  void initState() {
    super.initState();
    if (!widget.settings.hasPinCode || !widget.settings.lockFullAppOnStart) {
      _appUnlocked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.settings, widget.vault]),
      builder: (context, _) {
        final GulfThemeData theme = widget.settings.currentTheme;
        final RuknFontOption font = widget.settings.currentFont;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: theme.scaffoldBg,
            systemNavigationBarIconBrightness:
                widget.settings.isDarkMode ? Brightness.light : Brightness.dark,
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
            brightness:
                widget.settings.isDarkMode ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: theme.scaffoldBg,
            primaryColor: theme.primary,
            fontFamily: font.familyName,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primary,
              brightness:
                  widget.settings.isDarkMode ? Brightness.dark : Brightness.light,
              primary: theme.primary,
              secondary: theme.goldAccent,
              surface: theme.cardBg,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: theme.primary,
              selectionColor: theme.goldAccent.withOpacity(0.32),
              selectionHandleColor: theme.primary,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: theme.primaryDark,
              contentTextStyle: TextStyle(
                fontFamily: font.familyName,
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.goldAccent, width: 1),
              ),
              behavior: SnackBarBehavior.floating,
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
          home: _buildHomeGate(theme, font),
        );
      },
    );
  }

  Widget _buildHomeGate(GulfThemeData theme, RuknFontOption font) {
    if (!_appUnlocked &&
        widget.settings.hasPinCode &&
        widget.settings.lockFullAppOnStart) {
      return RuknPinLockScreen(
        theme: theme,
        fontFamily: font.familyName,
        title: 'رُكْن محمي برمز سري',
        subtitle: 'أدخل رمز الحماية المكون من 4 أرقام للدخول',
        correctPin: widget.settings.appPinCode,
        isEmbeddedFullScreen: true,
        onSuccess: () {
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
