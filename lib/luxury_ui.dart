import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gulf_themes.dart';

/// أداة الاهتزاز اللمسي الفاخر (Subtle Haptic Feedback)
class RuknHaptics {
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyWarning() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}

/// زر نابض بفيزياء الزنبرك (Spring Bounce Button) مع عدم اقتصاص الحواف أو الظلال
class RuknSpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final Color? shadowColor;
  final double? height;
  final double? width;

  const RuknSpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.borderRadius = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.margin = const EdgeInsets.only(bottom: 4),
    this.elevation = 3.0,
    this.shadowColor,
    this.height,
    this.width,
  });

  @override
  State<RuknSpringButton> createState() => _RuknSpringButtonState();
}

class _RuknSpringButtonState extends State<RuknSpringButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 95),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.955).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = widget.shadowColor ??
        (widget.backgroundColor ?? Colors.black).withOpacity(0.22);

    return Container(
      margin: widget.margin,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap == null
            ? null
            : () {
                RuknHaptics.lightTap();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                RuknHaptics.mediumImpact();
                widget.onLongPress!();
              },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: widget.height,
            width: widget.width,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.gradient == null ? widget.backgroundColor : null,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!, width: 1.1)
                  : null,
              boxShadow: widget.elevation > 0
                  ? [
                      BoxShadow(
                        color: effectiveShadow,
                        blurRadius: widget.elevation * 3.2,
                        offset: Offset(0, widget.elevation * 1.1),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// مفتاح التبديل المنزلق الفاخر (Sliding Switch) — يوضع على يمين النص في بداية السطر العربي
class RuknSlidingSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppSettingsController settings;
  final IconData? icon;

  const RuknSlidingSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.settings,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = settings.activeTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        RuknHaptics.selectionClick();
        onChanged(!value);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: settings.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? theme.primary.withOpacity(0.45)
                : settings.borderColor,
            width: 1.1,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // المفتاح المنزلق يقع على يمين النص (بداية السطر العربي)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value
                    ? theme.primary
                    : (settings.isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: theme.primary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? theme.accentGold : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            if (icon != null) ...[
              Icon(
                icon,
                color: value ? theme.primary : settings.secondaryTextColor,
                size: 21,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: settings.primaryTextColor,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: settings.secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة منبثقة فاخرة مضمونة عدم اقتصاص الأزرار السفلية بنسبة 100%
Future<T?> showRuknModalDialog<T>({
  required BuildContext context,
  required AppSettingsController settings,
  required String title,
  String? subtitle,
  IconData? headerIcon,
  required Widget content,
  List<Widget>? actions,
}) {
  final theme = settings.activeTheme;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'RuknDialog',
    barrierColor: Colors.black.withOpacity(0.58),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.90,
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: MediaQuery.of(ctx).size.height * 0.86,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                color: settings.cardBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.accentGold.withOpacity(0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رأس النافذة
                  Row(
                    children: [
                      if (headerIcon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            headerIcon,
                            color: theme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: settings.primaryTextColor,
                              ),
                            ),
                            if (subtitle != null && subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: settings.secondaryTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: settings.borderColor,
                  ),
                  const SizedBox(height: 14),
                  // المحتوى القابل للتمرير
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: content,
                    ),
                  ),
                  if (actions != null && actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    // حاوية الأزرار مع هامش سفلي إضافي لمنع أي اقتصاص للظلال أو الحواف
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 2),
                      child: Row(
                        children: actions,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(
        parent: anim1,
        curve: Curves.easeOutBack,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}

/// رسالة تنبيه سريعة وأنيقة (Luxury Toast / SnackBar)
void showRuknToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_outline_rounded,
  Color? backgroundColor,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      backgroundColor: backgroundColor ?? const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
      ),
      duration: const Duration(seconds: 2),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// شاشة قفل الخصوصية الملكية (Rukn PIN Lock Screen)
class RuknPinLockScreen extends StatefulWidget {
  final AppSettingsController settings;
  final String title;
  final String subtitle;
  final VoidCallback onUnlocked;
  final VoidCallback? onCancel;

  const RuknPinLockScreen({
    super.key,
    required this.settings,
    required this.title,
    required this.subtitle,
    required this.onUnlocked,
    this.onCancel,
  });

  @override
  State<RuknPinLockScreen> createState() => _RuknPinLockScreenState();
}

class _RuknPinLockScreenState extends State<RuknPinLockScreen> {
  String _enteredPin = '';
  String _errorMessage = '';

  void _onDigitPress(String digit) {
    RuknHaptics.lightTap();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    RuknHaptics.selectionClick();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == widget.settings.pinCode) {
      RuknHaptics.mediumImpact();
      widget.onUnlocked();
    } else {
      RuknHaptics.heavyWarning();
      setState(() {
        _enteredPin = '';
        _errorMessage = 'رمز الحماية غير صحيح، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.activeTheme;

    return Scaffold(
      backgroundColor: theme.primaryDark,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              theme.primaryDark,
              theme.primary,
              const Color(0xFF090D16),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.onCancel != null)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: RuknSpringButton(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      borderColor: theme.accentGold.withOpacity(0.4),
                      onTap: widget.onCancel,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('رجوع',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accentGold.withOpacity(0.15),
                  border: Border.all(color: theme.accentGold, width: 1.5),
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  color: theme.accentGold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // دوائر الرمز السري الـ 4
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: filled ? 20 : 18,
                    height: filled ? 20 : 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? theme.accentGold : Colors.transparent,
                      border: Border.all(
                        color: theme.accentGold,
                        width: 2,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: theme.accentGold.withOpacity(0.5),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 24,
                child: _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              // لوحة الأرقام الملكية
              SizedBox(
                width: 290,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    children: [
                      _buildKeypadRow(['1', '2', '3'], theme),
                      const SizedBox(height: 12),
                      _buildKeypadRow(['4', '5', '6'], theme),
                      const SizedBox(height: 12),
                      _buildKeypadRow(['7', '8', '9'], theme),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(width: 74, height: 64),
                          _buildDigitButton('0', theme),
                          RuknSpringButton(
                            width: 74,
                            height: 64,
                            borderRadius: 36,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            borderColor: Colors.white.withOpacity(0.18),
                            elevation: 0,
                            onTap: _onBackspace,
                            child: const Icon(
                              Icons.backspace_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, GulfThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d, theme)).toList(),
    );
  }

  Widget _buildDigitButton(String digit, GulfThemeData theme) {
    return RuknSpringButton(
      width: 74,
      height: 64,
      borderRadius: 36,
      backgroundColor: Colors.white.withOpacity(0.10),
      borderColor: theme.accentGold.withOpacity(0.35),
      elevation: 0,
      onTap: () => _onDigitPress(digit),
      child: Text(
        digit,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
