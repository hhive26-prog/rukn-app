import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gulf_themes.dart';

class RuknHaptics {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }
}

class RuknSpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final bool enableHaptic;

  const RuknSpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
    this.enableHaptic = true,
  });

  @override
  State<RuknSpringButton> createState() => _RuknSpringButtonState();
}

class _RuknSpringButtonState extends State<RuknSpringButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
      onTapUp: widget.onTap != null ? (_) => _setPressed(false) : null,
      onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
      onTap: widget.onTap != null
          ? () {
              if (widget.enableHaptic) RuknHaptics.light();
              widget.onTap!();
            }
          : null,
      onLongPress: widget.onLongPress != null
          ? () {
              _setPressed(false);
              if (widget.enableHaptic) RuknHaptics.medium();
              widget.onLongPress!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 115),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class RuknSlidingSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppSettingsController settings;
  final IconData? leadingIcon;

  const RuknSlidingSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.settings,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = settings.primaryColor;
    final goldColor = settings.accentColor;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        RuknHaptics.selection();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
        child: Row(
          children: [
            _buildSlidingSwitch(activeColor, goldColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: settings.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: settings.textMainColor,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: 12.5,
                        color: settings.textSubColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (leadingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                leadingIcon,
                size: 20,
                color: settings.accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlidingSwitch(Color activeColor, Color goldColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      width: 50,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: value
            ? activeColor
            : (settings.isDarkMode
                ? Colors.white.withOpacity(0.14)
                : Colors.black.withOpacity(0.12)),
        border: Border.all(
          color: value ? goldColor : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? goldColor : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showRuknModalDialog<T>({
  required BuildContext context,
  required AppSettingsController settings,
  required Widget Function(BuildContext ctx) builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'RuknDialog',
    barrierColor: Colors.black.withOpacity(0.58),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  decoration: BoxDecoration(
                    color: settings.cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: settings.accentColor.withOpacity(0.55),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: builder(ctx),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
  );
}

void showRuknToast(
  BuildContext context,
  AppSettingsController settings,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor:
          isError ? const Color(0xFFB91C1C) : settings.primaryDarkColor,
      duration: const Duration(milliseconds: 2200),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isError ? Colors.redAccent : settings.accentColor,
          width: 1.1,
        ),
      ),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? Colors.white : settings.accentColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: settings.fontFamily,
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class RuknPinLockScreen extends StatefulWidget {
  final AppSettingsController settings;
  final String title;
  final String subtitle;
  final VoidCallback onUnlocked;
  final VoidCallback? onCancel;

  const RuknPinLockScreen({
    super.key,
    required this.settings,
    this.title = 'الركن الخاص محمي',
    this.subtitle = 'أدخل رمز الحماية المكون من 4 أرقام للمتابعة',
    required this.onUnlocked,
    this.onCancel,
  });

  @override
  State<RuknPinLockScreen> createState() => _RuknPinLockScreenState();
}

class _RuknPinLockScreenState extends State<RuknPinLockScreen> {
  String _entered = '';
  bool _hasError = false;

  void _onDigitPress(String digit) {
    if (_entered.length >= 4) return;
    RuknHaptics.selection();
    setState(() {
      _hasError = false;
      _entered += digit;
    });

    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (_entered == widget.settings.pinCode) {
          RuknHaptics.medium();
          widget.onUnlocked();
        } else {
          RuknHaptics.medium();
          setState(() {
            _hasError = true;
            _entered = '';
          });
        }
      });
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    RuknHaptics.light();
    setState(() {
      _hasError = false;
      _entered = _entered.substring(0, _entered.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: s.primaryDarkColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.primaryColor,
                      border: Border.all(color: s.accentColor, width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: s.accentColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _hasError
                        ? 'رمز الحماية غير صحيح، حاول مرة أخرى'
                        : widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 13.5,
                      color: _hasError
                          ? const Color(0xFFFCA5A5)
                          : Colors.white.withOpacity(0.78),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < _entered.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 9),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? s.accentColor
                                : Colors.white.withOpacity(0.18),
                            border: Border.all(
                              color: _hasError
                                  ? Colors.redAccent
                                  : s.accentColor.withOpacity(0.8),
                              width: 1.4,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(
                        children: [
                          _buildKeypadRow(['1', '2', '3'], s),
                          const SizedBox(height: 14),
                          _buildKeypadRow(['4', '5', '6'], s),
                          const SizedBox(height: 14),
                          _buildKeypadRow(['7', '8', '9'], s),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (widget.onCancel != null)
                                _buildActionKey(
                                  icon: Icons.close_rounded,
                                  onTap: widget.onCancel!,
                                  s: s,
                                )
                              else
                                const SizedBox(width: 68, height: 68),
                              _buildDigitKey('0', s),
                              _buildActionKey(
                                icon: Icons.backspace_outlined,
                                onTap: _onBackspace,
                                s: s,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, AppSettingsController s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitKey(d, s)).toList(),
    );
  }

  Widget _buildDigitKey(String digit, AppSettingsController s) {
    return RuknSpringButton(
      onTap: () => _onDigitPress(digit),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.09),
          border: Border.all(
            color: s.accentColor.withOpacity(0.38),
            width: 1.1,
          ),
        ),
        child: Text(
          digit,
          style: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required VoidCallback onTap,
    required AppSettingsController s,
  }) {
    return RuknSpringButton(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.0,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
