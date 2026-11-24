import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'gulf_themes.dart';
import 'luxury_ui.dart';

enum RuknCardFormat {
  instagramSquare, // 1:1 لمنشورات انستغرام
  whatsappStory,   // 9:16 لحالات واتساب وستوري
}

Future<void> showRuknShareCardStudio({
  required BuildContext context,
  required AppSettingsController settings,
  required String noteTitle,
  required String noteContent,
}) async {
  await showRuknModalDialog(
    context: context,
    settings: settings,
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
  final GlobalKey _repaintKey = GlobalKey();
  static const MethodChannel _nativeChannel =
      MethodChannel('com.rukn.app/native');

  RuknCardFormat _selectedFormat = RuknCardFormat.instagramSquare;
  int _cardStyleIndex = 0;
  bool _showTitleOnCard = true;
  bool _showSignatureOnCard = true;
  bool _isExporting = false;

  int get _maxRecommendedChars =>
      _selectedFormat == RuknCardFormat.instagramSquare ? 280 : 520;

  int get _maxRecommendedLines =>
      _selectedFormat == RuknCardFormat.instagramSquare ? 7 : 13;

  String get _cleanedSourceText {
    final trimmed = widget.noteContent.trim();
    return trimmed.isEmpty ? widget.noteTitle : trimmed;
  }

  bool get _isTextTooLong {
    final text = _cleanedSourceText;
    final lineCount = text.split('\n').length;
    return text.length > _maxRecommendedChars ||
        lineCount > _maxRecommendedLines;
  }

  String get _fittedCardText {
    final text = _cleanedSourceText;
    final lines = text.split('\n');
    String result = text;
    if (lines.length > _maxRecommendedLines) {
      result = '${lines.take(_maxRecommendedLines).join('\n')} ...';
    }
    if (result.length > _maxRecommendedChars) {
      result = '${result.substring(0, _maxRecommendedChars).trim()} ...';
    }
    return result;
  }

  Future<Uint8List?> _captureCardPngBytes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 40));
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

  Future<void> _shareAsPngImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final pngBytes = await _captureCardPngBytes();
      if (pngBytes == null) {
        if (mounted) {
          showRuknToast(context, widget.settings, 'تعذر تجهيز الصورة', isError: true);
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Rukn_Card_$timestamp.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            name: fileName,
            mimeType: 'image/png',
          ),
        ],
        text: widget.noteTitle,
      );
    } catch (e) {
      if (mounted) {
        showRuknToast(context, widget.settings, 'حدث خطأ أثناء المشاركة', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _savePngToDevice() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final pngBytes = await _captureCardPngBytes();
      if (pngBytes == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Rukn_Card_$timestamp.png';

      final savedPath = await _nativeChannel.invokeMethod<String>(
        'saveToDownloads',
        {
          'fileName': fileName,
          'bytes': pngBytes,
          'mimeType': 'image/png',
        },
      );

      if (mounted) {
        showRuknToast(
          context,
          widget.settings,
          'تم حفظ البطاقة كصورة PNG في: ${savedPath ?? "التنزيلات"}',
        );
      }
    } catch (_) {
      if (mounted) {
        showRuknToast(context, widget.settings, 'تعذر حفظ الصورة', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final aspectRatio =
        _selectedFormat == RuknCardFormat.instagramSquare ? 1.0 : (9.0 / 16.0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: s.accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'استوديو بطاقات المشاركة',
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: s.textMainColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: s.textSubColor),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 1. اختيار المقاس: منشور انستغرام (1:1) أو حالة واتساب (9:16)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: s.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFormatTab(
                    s: s,
                    title: 'منشور انستغرام (1:1)',
                    icon: Icons.crop_square_rounded,
                    selected: _selectedFormat == RuknCardFormat.instagramSquare,
                    onTap: () => setState(
                      () => _selectedFormat = RuknCardFormat.instagramSquare,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildFormatTab(
                    s: s,
                    title: 'حالة واتساب (9:16)',
                    icon: Icons.stay_current_portrait_rounded,
                    selected: _selectedFormat == RuknCardFormat.whatsappStory,
                    onTap: () => setState(
                      () => _selectedFormat = RuknCardFormat.whatsappStory,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // تنبيه ذكي إذا كان النص طويلاً على القالب المختار
          if (_isTextTooLong) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB45309),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'النص طويل على هذا القالب؛ تم ضبط المعاينة تلقائياً ليبقى مقاس الصورة متناسقاً دون استطالة.',
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // 2. منطقة المعاينة بأبعاد ثابتة (1:1 أو 9:16)
          Flexible(
            child: Center(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _selectedFormat == RuknCardFormat.instagramSquare
                          ? 310
                          : 235,
                    ),
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: _buildLuxuryCardCanvas(s),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 3. خيارات نمط البطاقة وإظهار العنوان/التوقيع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildStyleChoiceChip(s, 0, 'ملكي داكن'),
                  const SizedBox(width: 6),
                  _buildStyleChoiceChip(s, 1, 'ورق فاخر'),
                  const SizedBox(width: 6),
                  _buildStyleChoiceChip(s, 2, 'ذهبي كحلي'),
                ],
              ),
              Row(
                children: [
                  FilterChip(
                    label: Text(
                      'العنوان',
                      style: TextStyle(fontFamily: s.fontFamily, fontSize: 11.5),
                    ),
                    selected: _showTitleOnCard,
                    onSelected: (v) => setState(() => _showTitleOnCard = v),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: Text(
                      'التوقيع',
                      style: TextStyle(fontFamily: s.fontFamily, fontSize: 11.5),
                    ),
                    selected: _showSignatureOnCard,
                    onSelected: (v) => setState(() => _showSignatureOnCard = v),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. أزرار التصدير والمشاركة كصورة PNG صافية
          Row(
            children: [
              Expanded(
                flex: 2,
                child: RuknSpringButton(
                  onTap: _isExporting ? null : _shareAsPngImage,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isExporting ? 'جاري التجهيز...' : 'مشاركة كصورة (PNG)',
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
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: RuknSpringButton(
                  onTap: _isExporting ? null : _savePngToDevice,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: s.primaryColor, width: 1.2),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: s.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'حفظ PNG',
                              style: TextStyle(
                                fontFamily: s.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: s.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTab({
    required AppSettingsController s,
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        RuknHaptics.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? s.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : s.textSubColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: s.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : s.textSubColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleChoiceChip(
      AppSettingsController s, int idx, String label) {
    final selected = _cardStyleIndex == idx;
    return GestureDetector(
      onTap: () {
        RuknHaptics.selection();
        setState(() => _cardStyleIndex = idx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? s.primaryColor : s.bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? s.accentColor : s.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: s.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : s.textMainColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryCardCanvas(AppSettingsController s) {
    final bool isPaperStyle = _cardStyleIndex == 1;
    final bool isNavyGold = _cardStyleIndex == 2;

    final List<Color> bgGradient = isPaperStyle
        ? [const Color(0xFFFFFDF9), const Color(0xFFF5EFE2)]
        : isNavyGold
            ? [const Color(0xFF0B132B), const Color(0xFF1C2541)]
            : [s.primaryDarkColor, s.primaryColor];

    final Color textColor =
        isPaperStyle ? const Color(0xFF1F2937) : Colors.white;
    final Color goldColor =
        isPaperStyle ? s.primaryColor : s.accentColor;

    final String signature = s.signatureText.trim().isNotEmpty
        ? s.signatureText.trim()
        : s.fullHeaderTitle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: goldColor.withOpacity(0.65),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showTitleOnCard && widget.noteTitle.trim().isNotEmpty)
              Column(
                children: [
                  Text(
                    widget.noteTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: goldColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 48,
                    height: 1.5,
                    color: goldColor.withOpacity(0.5),
                  ),
                ],
              )
            else
              const SizedBox(height: 4),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _fittedCardText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: s.fontFamily,
                      fontSize: _fittedCardText.length > 220 ? 13.5 : 15.5,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),

            if (_showSignatureOnCard)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: goldColor.withOpacity(0.45),
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      signature,
                      style: TextStyle(
                        fontFamily: s.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: goldColor,
                      ),
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
