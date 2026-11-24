import 'package:flutter/material.dart';

/// نطاق التطابق في النص الأصلي
class SmartMatchRange {
  final int start;
  final int end;

  const SmartMatchRange(this.start, this.end);
}

/// إحصائيات المستند (الكلمات، الحروف، الأسطر)
class DocumentStats {
  final int words;
  final int chars;
  final int lines;

  const DocumentStats({
    required this.words,
    required this.chars,
    required this.lines,
  });
}

/// المحرك العربي الذكي لتطبيق "رُكْن"
class SmartArabicEngine {
  /// التحقق مما إذا كان الحرف تشكيلاً أو تطويلاً (كشيدة) يجب تجاهله عند البحث
  static bool isIgnoredDiacriticOrTatweel(int codeUnit) {
    // التطويل (ـ) \u0640 + الحركات والتنوين والشدة (\u064B - \u065F) + الألف الخنجرية (\u0670)
    if (codeUnit == 0x0640) return true;
    if (codeUnit >= 0x064B && codeUnit <= 0x065F) return true;
    if (codeUnit == 0x0670) return true;
    if (codeUnit >= 0x06D6 && codeUnit <= 0x06ED) return true;
    return false;
  }

  /// تطبيع الحرف العربي لتوحيد الهمزات والتاء المربوطة والألف المقصورة والأرقام
  static String normalizeArabicChar(String ch) {
    switch (ch) {
      case 'أ':
      case 'إ':
      case 'آ':
      case 'ٱ':
        return 'ا';
      case 'ة':
        return 'ه';
      case 'ى':
      case 'ئ':
        return 'ي';
      case 'ؤ':
        return 'و';
      case '٠':
        return '0';
      case '١':
        return '1';
      case '٢':
        return '2';
      case '٣':
        return '3';
      case '٤':
        return '4';
      case '٥':
        return '5';
      case '٦':
        return '6';
      case '٧':
        return '7';
      case '٨':
        return '8';
      case '٩':
        return '9';
      default:
        return ch.toLowerCase();
    }
  }

  /// تطبيع نص كامل للاستعلام السريع
  static String normalizeText(String input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (isIgnoredDiacriticOrTatweel(code)) continue;
      buffer.write(normalizeArabicChar(input[i]));
    }
    return buffer.toString();
  }

  /// محرك البحث العربي الذكي (findSmartMatchRanges):
  /// يربط مواقع الأحرف المطبّعة بمواقعها الحقيقية في النص الأصلي بدقة 100%
  static List<SmartMatchRange> findSmartMatchRanges(String sourceText, String query) {
    final normalizedQuery = normalizeText(query.trim());
    if (normalizedQuery.isEmpty || sourceText.isEmpty) {
      return const [];
    }

    final normChars = StringBuffer();
    final List<int> normToOrigIndex = [];

    for (int i = 0; i < sourceText.length; i++) {
      final code = sourceText.codeUnitAt(i);
      if (isIgnoredDiacriticOrTatweel(code)) continue;
      normChars.write(normalizeArabicChar(sourceText[i]));
      normToOrigIndex.add(i);
    }

    final normalizedSource = normChars.toString();
    final List<SmartMatchRange> ranges = [];
    int searchFrom = 0;

    while (true) {
      final matchIdx = normalizedSource.indexOf(normalizedQuery, searchFrom);
      if (matchIdx == -1) break;

      final origStart = normToOrigIndex[matchIdx];
      final lastNormIdx = matchIdx + normalizedQuery.length - 1;
      int origEnd = normToOrigIndex[lastNormIdx] + 1;

      // ضم أي حركات تشكيل تابعة لآخر حرف في الكلمة المطابقة
      while (origEnd < sourceText.length &&
          isIgnoredDiacriticOrTatweel(sourceText.codeUnitAt(origEnd))) {
        origEnd++;
      }

      ranges.add(SmartMatchRange(origStart, origEnd));
      searchFrom = matchIdx + normalizedQuery.length;
    }

    return ranges;
  }

  static bool smartContains(String sourceText, String query) {
    return findSmartMatchRanges(sourceText, query).isNotEmpty;
  }

  /// استخراج مقتطف ذكي من النص حول أول كلمة مطابقة للبحث في الشاشة الرئيسية
  static String extractSmartSnippet(String content, String query, {int radius = 48}) {
    final cleanContent = content.replaceAll('\n', ' ').trim();
    if (query.trim().isEmpty) {
      return cleanContent.length <= 95
          ? cleanContent
          : '${cleanContent.substring(0, 95)}...';
    }

    final matches = findSmartMatchRanges(cleanContent, query);
    if (matches.isEmpty) {
      return cleanContent.length <= 95
          ? cleanContent
          : '${cleanContent.substring(0, 95)}...';
    }

    final first = matches.first;
    final start = (first.start - radius).clamp(0, cleanContent.length);
    final end = (first.end + radius).clamp(0, cleanContent.length);
    final prefix = start > 0 ? '...' : '';
    final suffix = end < cleanContent.length ? '...' : '';
    return '$prefix${cleanContent.substring(start, end)}$suffix';
  }

  /// بناء TextSpan مع تظليل الكلمات المطابقة باللون الأصفر (0xFFFDE047)
  static TextSpan buildHighlightedTextSpan({
    required String text,
    required String query,
    required TextStyle baseStyle,
    int? activeMatchIndex,
  }) {
    final ranges = findSmartMatchRanges(text, query);
    if (ranges.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final List<InlineSpan> children = [];
    int currentPos = 0;

    for (int i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      if (range.start > currentPos) {
        children.add(
          TextSpan(
            text: text.substring(currentPos, range.start),
            style: baseStyle,
          ),
        );
      }

      final isFocused = activeMatchIndex != null && activeMatchIndex == i;
      children.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: baseStyle.copyWith(
            backgroundColor: isFocused
                ? const Color(0xFFF59E0B)
                : const Color(0xFFFDE047),
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      currentPos = range.end;
    }

    if (currentPos < text.length) {
      children.add(
        TextSpan(
          text: text.substring(currentPos),
          style: baseStyle,
        ),
      );
    }

    return TextSpan(children: children, style: baseStyle);
  }

  /// استبدال ذكي لجميع التطابقات في النص الأصلي
  static String smartReplaceAll(String sourceText, String findQuery, String replacement) {
    final ranges = findSmartMatchRanges(sourceText, findQuery);
    if (ranges.isEmpty) return sourceText;

    final buffer = StringBuffer();
    int lastEnd = 0;
    for (final range in ranges) {
      if (range.start > lastEnd) {
        buffer.write(sourceText.substring(lastEnd, range.start));
      }
      buffer.write(replacement);
      lastEnd = range.end;
    }
    if (lastEnd < sourceText.length) {
      buffer.write(sourceText.substring(lastEnd));
    }
    return buffer.toString();
  }

  /// التنسيق الآلي السحري للنصوص العربية والقصائد (auto_format)
  static String autoFormatArabicText(String input) {
    if (input.trim().isEmpty) return input;

    final rawLines = input.split('\n');
    final List<String> formattedLines = [];
    int consecutiveBlankLines = 0;

    for (var line in rawLines) {
      // توحيد المسافات المتعددة داخل السطر الواحد
      var cleaned = line.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

      // ضبط المسافات قبل وبعد علامات الترقيم العربية والإنجليزية
      cleaned = cleaned.replaceAll(RegExp(r'\s+([،؛؟.!,:])'), r'$1');
      cleaned = cleaned.replaceAll(RegExp(r'([،؛؟.!,:])([^\s\d\n\)\]\}»"])'), r'$1 $2');

      if (cleaned.isEmpty) {
        consecutiveBlankLines++;
        if (consecutiveBlankLines <= 1 && formattedLines.isNotEmpty) {
          formattedLines.add('');
        }
      } else {
        consecutiveBlankLines = 0;
        formattedLines.add(cleaned);
      }
    }

    while (formattedLines.isNotEmpty && formattedLines.last.isEmpty) {
      formattedLines.removeLast();
    }

    return formattedLines.join('\n');
  }

  /// أداة محول الأرقام الفوري (١٢٣ ↔ 123)
  static String toggleArabicWesternNumbers(String text) {
    if (text.isEmpty) return text;
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const westernDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    bool hasArabic = false;
    for (final d in arabicDigits) {
      if (text.contains(d)) {
        hasArabic = true;
        break;
      }
    }

    var result = text;
    if (hasArabic) {
      for (int i = 0; i < 10; i++) {
        result = result.replaceAll(arabicDigits[i], westernDigits[i]);
      }
    } else {
      for (int i = 0; i < 10; i++) {
        result = result.replaceAll(westernDigits[i], arabicDigits[i]);
      }
    }
    return result;
  }

  /// تحويل الأرقام الهندية/العربية إلى غربية لأغراض الحساب
  static String _toWesternDigitsOnly(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var out = input;
    for (int i = 0; i < 10; i++) {
      out = out.replaceAll(arabicDigits[i], i.toString());
    }
    return out;
  }

  /// حاسبة الملاحظات الذكية التلقائية (جمع الأرقام ∑)
  /// تقرأ الأرقام المالية والكميات في سطور الملاحظة وتضيف سطر الإجمالي في الأسفل
  static Map<String, dynamic> calculateAndAppendSum(String text) {
    final lines = text.split('\n');
    final List<String> cleanedLines = [];

    // إزالة سطر الإجمالي السابق إن وجد لتحديثه بدقة
    for (final line in lines) {
      if (line.trim() == '────────────────────' ||
          line.trim().startsWith('💰 الإجمالي:')) {
        continue;
      }
      cleanedLines.add(line);
    }

    double sum = 0.0;
    int count = 0;

    final numRegex = RegExp(r'[-+]?\d+(?:[.,]\d+)?');

    for (final rawLine in cleanedLines) {
      final westernLine = _toWesternDigitsOnly(rawLine).trim();
      if (westernLine.isEmpty) continue;

      // تجاهل الأرقام الترتيبية في بداية السطر مثل "1-" أو "1." أو "١)"
      final withoutListIndex = westernLine.replaceFirst(RegExp(r'^\d+\s*[-.)]\s*'), '');

      final matches = numRegex.allMatches(withoutListIndex);
      for (final m in matches) {
        final token = m.group(0)!.replaceAll(',', '');
        final value = double.tryParse(token);
        if (value != null) {
          sum += value;
          count++;
        }
      }
    }

    if (count == 0) {
      return {
        'updatedText': text,
        'count': 0,
        'formattedSum': '0',
      };
    }

    final formattedSum = _formatNumberWithCommas(sum);
    while (cleanedLines.isNotEmpty && cleanedLines.last.trim().isEmpty) {
      cleanedLines.removeLast();
    }

    cleanedLines.add('');
    cleanedLines.add('────────────────────');
    cleanedLines.add('💰 الإجمالي: $formattedSum   ($count عنصر)');

    return {
      'updatedText': cleanedLines.join('\n'),
      'count': count,
      'formattedSum': formattedSum,
    };
  }

  static String _formatNumberWithCommas(double value) {
    final isInt = value == value.roundToDouble();
    final str = isInt ? value.toInt().toString() : value.toStringAsFixed(2);
    final parts = str.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  /// تحويل السطر الحالي إلى عنصر قائمة مهام تفاعلي (☐ / ☑)
  static String toggleChecklistAtCursor(String fullText, int cursorOffset) {
    if (fullText.isEmpty) {
      return '☐ ';
    }
    final safeCursor = cursorOffset.clamp(0, fullText.length);
    int lineStart = fullText.lastIndexOf('\n', safeCursor > 0 ? safeCursor - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    int lineEnd = fullText.indexOf('\n', safeCursor);
    if (lineEnd == -1) lineEnd = fullText.length;

    final currentLine = fullText.substring(lineStart, lineEnd);
    String updatedLine;
    if (currentLine.startsWith('☐ ')) {
      updatedLine = '☑ ${currentLine.substring(2)}';
    } else if (currentLine.startsWith('☑ ')) {
      updatedLine = currentLine.substring(2);
    } else {
      updatedLine = '☐ $currentLine';
    }

    return fullText.substring(0, lineStart) +
        updatedLine +
        fullText.substring(lineEnd);
  }

  /// حساب إحصائيات النص (الكلمات، الحروف، الأسطر)
  static DocumentStats computeStats(String text) {
    final chars = text.length;
    final trimmed = text.trim();
    final words = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final lines = text.isEmpty ? 1 : text.split('\n').length;
    return DocumentStats(words: words, chars: chars, lines: lines);
  }

  /// التقويم الهجري والميلادي المدمج (بدون الحاجة لاتصال بالإنترنت)
  static String getHijriAndGregorianHeaderDate([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    const arabicWeekdays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayName = arabicWeekdays[(now.weekday - 1).clamp(0, 6)];
    final hijri = _gregorianToHijri(now.year, now.month, now.day);

    const hijriMonths = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];

    final hDay = hijri['day']!;
    final hMonth = hijriMonths[(hijri['month']! - 1).clamp(0, 11)];
    final hYear = hijri['year']!;

    String two(int n) => n.toString().padLeft(2, '0');
    final gregStr = '${now.year}/${two(now.month)}/${two(now.day)}م';

    return '$dayName  •  $hDay $hMonth ${hYear}هـ  •  $gregStr';
  }

  /// صيغة التاريخ والوقت الجاهزة للإدراج داخل المحرر
  static String getInsertableDateTimeString() {
    final now = DateTime.now();
    final header = getHijriAndGregorianHeaderDate(now);
    int hour = now.hour;
    final period = hour >= 12 ? 'م' : 'ص';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final min = now.minute.toString().padLeft(2, '0');
    return '📅 $header — $hour:$min $period';
  }

  /// خوارزمية تحويل التاريخ الميلادي إلى هجري بدقة عالية
  static Map<String, int> _gregorianToHijri(int year, int month, int day) {
    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    if (y < 1583) b = 0;
    if (y == 1582) {
      if (m > 10) b = -10;
      if (m == 10) {
        b = 0;
        if (day > 4) b = -10;
      }
    }

    int jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524;

    double iyear = 10631.0 / 30.0;
    int epochAstro = 1948084;
    double shift1 = 8.01 / 60.0;

    int z = jd - epochAstro;
    int cyc = (z / 10631.0).floor();
    z = z - 10631 * cyc;
    int j = ((z - shift1) / iyear).floor();
    int iy = 30 * cyc + j;
    z = z - (j * iyear + shift1).floor();
    int im = ((z + 28.5001) / 29.5).floor();
    if (im == 13) im = 12;
    int id = z - (29.5001 * im - 29).floor();

    return {
      'day': id.clamp(1, 30),
      'month': im.clamp(1, 12),
      'year': iy,
    };
  }
}
