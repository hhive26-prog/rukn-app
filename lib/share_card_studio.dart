import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'gulf_themes.dart';
import 'luxury_ui.dart';
import 'smart_arabic_engine.dart';

/// استوديو مشاركة الملاحظة أو القصيدة كبطاقة مصورة فاخرة للواتساب وسناب شات
Future<void> showRuknShareCardStudio({
  required BuildContext context,
  required AppSettingsController settings,
  required String noteTitle,
  required String noteContent,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _RuknShareCardStudioSheet(
        settings: settings,
        noteTitle: noteTitle,
        noteContent: noteContent,
      );
    },
  );
}

class _RuknShareCardStudioSheet extends StatefulWidget {
  final AppSettingsController settings;
  final String noteTitle;
  final String noteContent;

  const _RuknShareCardStudioSheet({
    required this.settings,
    required this.noteTitle,
    required this.noteContent,
  });

  @override
  State<_RuknShareCardStudioSheet> createState() =>
      _RuknShareCardStudioSheetState();
}

class _RuknShareCardStudioSheetState extends State<_RuknShareCardStudioSheet> {
  static const MethodChannel _nativeChannel = MethodChannel('com.rukn.app/native');
  final GlobalKey _repaintKey = GlobalKey();

  int _selectedCardStyle = 0; // 0: الثيم الخليجي، 1: الكحلي الملكي، 2: الرقعة الكريمي، 3: الأسود الماسي
  bool _showTitleOnCard = true;
  bool _showDateOnCard = true;
  bool _centerAlignText = true;
  bool _isExporting = false;

  Future<Uint8List?> _captureCardPng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareCardImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final bytes = await _captureCardPng();
    if (bytes != null && mounted) {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/Rukn_Card_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: widget.noteTitle,
      );
    }

    if (mounted) {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _saveCardToGallery() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final bytes = await _captureCardPng();
    if (bytes != null && mounted) {
      final fileName =
          'Rukn_Card_${DateTime.now().millisecondsSinceEpoch}.png';
      try {
        final path = await _nativeChannel.invokeMethod<String>(
          'saveToDownloads',
          {
            'fileName': fileName,
            'bytes': bytes,
            'mimeType': 'image/png',
          },
        );
        if (mounted) {
          showRuknToast(
            context,
            'تم حفظ البطاقة المصورة في: ${path ?? "التنزيلات"}',
            icon: Icons.photo_library_rounded,
          );
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = widget.settings.activeTheme;
    final displayBody = widget.noteContent.trim().isEmpty
        ? 'اكتب خاطرتك أو قصيدتك لتظهر في هذه البطاقة الفاخرة...'
        : (widget.noteContent.trim().length > 650
            ? '${widget.noteContent.trim().substring(0, 650)}...'
            : widget.noteContent.trim());

    final footerSignature = widget.settings.signatureText.trim().isNotEmpty
        ? widget.settings.signatureText.trim()
        : widget.settings.fullPersonalHeaderTitle;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: BoxDecoration(
          color: widget.settings.scaffoldBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: activeTheme.accentGold.withOpacity(0.5),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // مقبض السحب العلوي
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.settings.secondaryTextColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: activeTheme.accentGold, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'استوديو البطاقة المصورة الفاخرة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.settings.primaryTextColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: widget.settings.secondaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // اختيار نمط البطاقة
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStyleChip(0, '${activeTheme.badge} ${activeTheme.name}'),
                  const SizedBox(width: 8),
                  _buildStyleChip(1, '👑 الكحلي الملكي'),
                  const SizedBox(width: 8),
                  _buildStyleChip(2, '📜 الرقعة الكريمي'),
                  const SizedBox(width: 8),
                  _buildStyleChip(3, '🌑 الأسود الماسي'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // أزرار التحكم السريعة في شكل البطاقة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTogglePill(
                  label: 'إظهار العنوان',
                  active: _showTitleOnCard,
                  onTap: () =>
                      setState(() => _showTitleOnCard = !_showTitleOnCard),
                ),
                const SizedBox(width: 8),
                _buildTogglePill(
                  label: 'التاريخ الهجري',
                  active: _showDateOnCard,
                  onTap: () =>
                      setState(() => _showDateOnCard = !_showDateOnCard),
                ),
                const SizedBox(width: 8),
                _buildTogglePill(
                  label: _centerAlignText ? 'توسيط النص' : 'محاذاة يمين',
                  active: _centerAlignText,
                  onTap: () =>
                      setState(() => _centerAlignText = !_centerAlignText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // معاينة البطاقة الفاخرة القابلة للالتقاط كصورة عالية الدقة
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: _buildRenderedLuxuryCard(
                      activeTheme: activeTheme,
                      bodyText: displayBody,
                      footerSignature: footerSignature,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // أزرار المشاركة والحفظ مع هامش سفلي لمنع الاقتصاص
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: RuknSpringButton(
                      height: 48,
                      gradient: LinearGradient(
                        colors: [activeTheme.primaryDark, activeTheme.primary],
                      ),
                      borderColor: activeTheme.accentGold,
                      onTap: _shareCardImage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.ios_share_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isExporting
                                ? 'جارٍ التجهيز...'
                                : 'مشاركة البطاقة المصورة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: RuknSpringButton(
                      height: 48,
                      backgroundColor: widget.settings.cardBgColor,
                      borderColor: activeTheme.primary.withOpacity(0.5),
                      onTap: _saveCardToGallery,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded,
                              color: activeTheme.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'حفظ',
                            style: TextStyle(
                              color: widget.settings.primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleChip(int index, String title) {
    final selected = _selectedCardStyle == index;
    final theme = widget.settings.activeTheme;
    return GestureDetector(
      onTap: () {
        RuknHaptics.selectionClick();
        setState(() => _selectedCardStyle = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.primary : widget.settings.cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.accentGold : widget.settings.borderColor,
            width: 1.2,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : widget.settings.primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = widget.settings.activeTheme;
    return GestureDetector(
      onTap: () {
        RuknHaptics.lightTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? theme.primary.withOpacity(0.14)
              : widget.settings.cardBgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? theme.primary : widget.settings.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? theme.primary : widget.settings.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRenderedLuxuryCard({
    required GulfThemeData activeTheme,
    required String bodyText,
    required String footerSignature,
  }) {
    late List<Color> bgGradient;
    late Color borderGold;
    late Color textColor;
    late Color subColor;

    if (_selectedCardStyle == 0) {
      bgGradient = [activeTheme.primaryDark, activeTheme.primary];
      borderGold = activeTheme.accentGold;
      textColor = Colors.white;
      subColor = Colors.white.withOpacity(0.80);
    } else if (_selectedCardStyle == 1) {
      bgGradient = [const Color(0xFF0B132B), const Color(0xFF1C2541)];
      borderGold = const Color(0xFFD4AF37);
      textColor = Colors.white;
      subColor = const Color(0xFFE2E8F0);
    } else if (_selectedCardStyle == 2) {
      bgGradient = [const Color(0xFFFFFDF9), const Color(0xFFF5EFE6)];
      borderGold = const Color(0xFF9A6B26);
      textColor = const Color(0xFF1E1B18);
      subColor = const Color(0xFF57534E);
    } else {
      bgGradient = [const Color(0xFF09090B), const Color(0xFF18181B)];
      borderGold = const Color(0xFFD4AF37);
      textColor = const Color(0xFFF8FAFC);
      subColor = const Color(0xFF94A3B8);
    }

    return Container(
      width: 360,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: bgGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderGold.withOpacity(0.65), width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _centerAlignText
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            // زخرفة علوية ذهبية
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 1.2,
                  color: borderGold.withOpacity(0.6),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.auto_awesome, color: borderGold, size: 16),
                ),
                Container(
                  width: 32,
                  height: 1.2,
                  color: borderGold.withOpacity(0.6),
                ),
              ],
            ),
            if (_showTitleOnCard && widget.noteTitle.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                widget.noteTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: borderGold,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  fontFamily: widget.settings.activeFontFamily,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              bodyText,
              textAlign:
                  _centerAlignText ? TextAlign.center : TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 16.5,
                height: 1.75,
                fontFamily: widget.settings.activeFontFamily,
              ),
            ),
            const SizedBox(height: 22),
            Divider(color: borderGold.withOpacity(0.35), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    footerSignature,
                    style: TextStyle(
                      color: borderGold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: widget.settings.activeFontFamily,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: borderGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: borderGold.withOpacity(0.45), width: 0.8),
                  ),
                  child: Text(
                    'رُكْن',
                    style: TextStyle(
                      color: borderGold,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_showDateOnCard) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  SmartArabicEngine.getHijriAndGregorianHeaderDate(),
                  style: TextStyle(
                    color: subColor,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
