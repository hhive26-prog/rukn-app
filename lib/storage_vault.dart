import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تصنيفات الملاحظات الخليجية السريعة في الشاشة الرئيسية
class RuknCategory {
  final String id;
  final String title;
  final String emoji;

  const RuknCategory({
    required this.id,
    required this.title,
    required this.emoji,
  });

  static const List<RuknCategory> allCategories = [
    RuknCategory(id: 'all', title: 'الكل', emoji: '🗂️'),
    RuknCategory(id: 'pinned', title: 'المثبتة', emoji: '📌'),
    RuknCategory(id: 'work', title: 'عمل والتزامات', emoji: '💼'),
    RuknCategory(id: 'poetry', title: 'شعر وخواطر', emoji: '✒️'),
    RuknCategory(id: 'tasks', title: 'مقاضي ومهام', emoji: '🛒'),
    RuknCategory(id: 'private', title: 'خاص', emoji: '🔒'),
  ];
}

/// نموذج ملف الملاحظة النصية (.txt)
class RuknNoteFile {
  final String filePath;
  final String title; // اسم الملف بدون .txt
  final String content;
  final DateTime lastModified;
  final bool isPinned;
  final String categoryId;
  final bool isLocked;

  const RuknNoteFile({
    required this.filePath,
    required this.title,
    required this.content,
    required this.lastModified,
    required this.isPinned,
    required this.categoryId,
    required this.isLocked,
  });

  String get fileNameWithExt => '$title.txt';
}

/// نموذج النسخة الآمنة داخل مجلد (خزنة_النسخ_الآمنة)
class SafeBackupEntry {
  final String filePath;
  final String fileName;
  final String noteTitle;
  final String formattedTimestamp;
  final DateTime modifiedTime;
  final int sizeBytes;

  const SafeBackupEntry({
    required this.filePath,
    required this.fileName,
    required this.noteTitle,
    required this.formattedTimestamp,
    required this.modifiedTime,
    required this.sizeBytes,
  });
}

/// المحرك الرئيسي للتخزين المباشر (.txt) وخزنة النسخ الآمنة والـ ZIP
class StorageVaultController extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.rukn.app/native');
  static const String safeVaultFolderName = 'خزنة_النسخ_الآمنة';

  late Directory _notesRootDir;
  late Directory _safeVaultDir;

  List<RuknNoteFile> _notes = [];
  Set<String> _pinnedTitles = {};
  Map<String, String> _noteCategories = {};
  Set<String> _lockedTitles = {};

  bool _isInitialized = false;

  List<RuknNoteFile> get notes => List.unmodifiable(_notes);
  bool get isInitialized => _isInitialized;
  String get notesDirectoryPath => _isInitialized ? _notesRootDir.path : '';

  Future<void> initializeVault() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _notesRootDir = Directory('${appDocDir.path}/Rukn_Notes');
    if (!await _notesRootDir.exists()) {
      await _notesRootDir.create(recursive: true);
    }

    _safeVaultDir = Directory('${_notesRootDir.path}/$safeVaultFolderName');
    if (!await _safeVaultDir.exists()) {
      await _safeVaultDir.create(recursive: true);
    }

    // إنشاء ملف .nomedia تلقائياً داخل خزنة_النسخ_الآمنة لمنع ظهورها في المستندات الأخيرة بالهاتف
    final noMediaFile = File('${_safeVaultDir.path}/.nomedia');
    if (!await noMediaFile.exists()) {
      await noMediaFile.writeAsString('', flush: true);
    }

    await _loadMetadata();
    await _ensureStarterWelcomeNote();
    await reloadNotes();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    _pinnedTitles = (prefs.getStringList('rukn_pinned_titles') ?? []).toSet();
    _lockedTitles = (prefs.getStringList('rukn_locked_titles') ?? []).toSet();

    final catJson = prefs.getString('rukn_note_categories');
    if (catJson != null && catJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(catJson) as Map<String, dynamic>;
        _noteCategories = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _noteCategories = {};
      }
    }
  }

  Future<void> _saveMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rukn_pinned_titles', _pinnedTitles.toList());
    await prefs.setStringList('rukn_locked_titles', _lockedTitles.toList());
    await prefs.setString('rukn_note_categories', jsonEncode(_noteCategories));
  }

  /// إنشاء ملاحظة ترحيبية فاخرة عند تشغيل "رُكْن" لأول مرة فقط
  Future<void> _ensureStarterWelcomeNote() async {
    final prefs = await SharedPreferences.getInstance();
    final createdWelcome = prefs.getBool('rukn_welcome_note_created') ?? false;
    if (createdWelcome) return;

    final welcomeTitle = 'مرحباً بك في رُكْن — مساحتك الخاصة';
    final welcomeFile = File('${_notesRootDir.path}/$welcomeTitle.txt');
    if (!await welcomeFile.exists()) {
      const welcomeContent = '''بسم الله الرحمن الرحيم

أهلاً بك في تطبيق «رُكْن» — مساحتك الشخصية الفاخرة لتدوين الفكر، حفظ القصائد والخواطر، وتنظيم التزاماتك اليومية بهوية خليجية أصيلة.

✨ أبرز المزايا التي صُممت لأجلك:
1. تخصيص الهوية: من الإعدادات يمكنك كتابة اسمك أو كنيتك ليظهر في البطاقة الملكية العلوية مع اختيار الثيم الخليجي المفضل لديك.
2. خزنة النسخ الآمنة: كل ملف تحفظه يمكنك أخذ نسخ آمنة غير محدودة منه واستعادتها في أي لحظة دون خوف من ضياع أي حرف.
3. جمع الأرقام التلقائي (∑): اكتب أي مصاريف أو التزامات مالية في سطور متتالية، ثم اضغط أداة (جمع الأرقام ∑) في شريط التحرير ليحسب الإجمالي فوراً!
4. المشاركة كبطاقة مصورة: حوّل أي قصيدة أو خاطرة أو فائدة إلى بطاقة مصورة فاخرة جاهزة للمشاركة في الواتساب وسناب شات.
5. البحث العربي الذكي: ابحث عن أي كلمة حتى لو كانت مشكّلة أو تختلف فيها الهمزات والتاء المربوطة.

نتمنى لك تجربة تدوين راقية ومثمرة.''';

      await welcomeFile.writeAsString(welcomeContent, encoding: utf8, flush: true);
      _pinnedTitles.add(welcomeTitle);
      _noteCategories[welcomeTitle] = 'work';
      await _saveMetadata();
    }
    await prefs.setBool('rukn_welcome_note_created', true);
  }

  /// تنظيف اسم الملف من الرموز غير المسموحة في نظام الملفات
  String sanitizeTitle(String rawTitle) {
    var clean = rawTitle
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.toLowerCase().endsWith('.txt')) {
      clean = clean.substring(0, clean.length - 4).trim();
    }
    return clean;
  }

  /// إعادة تحميل جميع ملفات .txt وترتيبها (المثبتة أولاً ثم من الأحدث للأقدم)
  Future<void> reloadNotes() async {
    if (!await _notesRootDir.exists()) return;

    final entities = await _notesRootDir.list(followLinks: false).toList();
    final List<RuknNoteFile> loaded = [];

    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.txt')) {
        final fileName = entity.uri.pathSegments.last;
        if (fileName.startsWith('.')) continue;

        final title = fileName.substring(0, fileName.length - 4);
        String content = '';
        DateTime modified = DateTime.now();
        try {
          content = await entity.readAsString(encoding: utf8);
          modified = await entity.lastModified();
        } catch (_) {}

        final isPinned = _pinnedTitles.contains(title);
        final categoryId = _noteCategories[title] ?? 'all';
        final isLocked = _lockedTitles.contains(title) || categoryId == 'private';

        loaded.add(
          RuknNoteFile(
            filePath: entity.path,
            title: title,
            content: content,
            lastModified: modified,
            isPinned: isPinned,
            categoryId: categoryId,
            isLocked: isLocked,
          ),
        );
      }
    }

    loaded.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.lastModified.compareTo(a.lastModified);
    });

    _notes = loaded;
    notifyListeners();
  }

  /// التحقق من وجود ملف بنفس الاسم
  bool noteExists(String title) {
    final clean = sanitizeTitle(title);
    return _notes.any((n) => n.title == clean);
  }

  /// إنشاء ملف نصي جديد (.txt)
  Future<RuknNoteFile> createNewNote({
    required String title,
    String initialContent = '',
    String categoryId = 'all',
  }) async {
    String clean = sanitizeTitle(title);
    if (clean.isEmpty) {
      clean = 'ملاحظة جديدة';
    }

    String finalTitle = clean;
    int counter = 2;
    while (await File('${_notesRootDir.path}/$finalTitle.txt').exists()) {
      finalTitle = '$clean ($counter)';
      counter++;
    }

    final file = File('${_notesRootDir.path}/$finalTitle.txt');
    await file.writeAsString(initialContent, encoding: utf8, flush: true);

    if (categoryId != 'all' && categoryId != 'pinned') {
      _noteCategories[finalTitle] = categoryId;
      if (categoryId == 'private') {
        _lockedTitles.add(finalTitle);
      }
      await _saveMetadata();
    } else if (categoryId == 'pinned') {
      _pinnedTitles.add(finalTitle);
      await _saveMetadata();
    }

    await reloadNotes();
    return _notes.firstWhere((n) => n.title == finalTitle);
  }

  /// حفظ محتوى الملاحظة مباشرة بصيغة UTF-8
  Future<void> saveNoteContent(String title, String newContent) async {
    final clean = sanitizeTitle(title);
    if (clean.isEmpty) return;

    final file = File('${_notesRootDir.path}/$clean.txt');
    await file.writeAsString(newContent, encoding: utf8, flush: true);
    await reloadNotes();
  }

  /// 1. تثبيت أو إلغاء تثبيت الملف
  Future<bool> togglePin(String title) async {
    final isNowPinned = !_pinnedTitles.contains(title);
    if (isNowPinned) {
      _pinnedTitles.add(title);
    } else {
      _pinnedTitles.remove(title);
    }
    await _saveMetadata();
    await reloadNotes();
    return isNowPinned;
  }

  /// تغيير تصنيف الملف أو قفله
  Future<void> setNoteCategory(String title, String categoryId) async {
    _noteCategories[title] = categoryId;
    if (categoryId == 'private') {
      _lockedTitles.add(title);
    }
    await _saveMetadata();
    await reloadNotes();
  }

  Future<bool> toggleNoteLock(String title) async {
    final isNowLocked = !_lockedTitles.contains(title);
    if (isNowLocked) {
      _lockedTitles.add(title);
    } else {
      _lockedTitles.remove(title);
      if (_noteCategories[title] == 'private') {
        _noteCategories[title] = 'all';
      }
    }
    await _saveMetadata();
    await reloadNotes();
    return isNowLocked;
  }

  /// 2. إعادة تسمية الملف مع الحفاظ على حالة التثبيت وإعادة تسمية جميع نسخه الآمنة تلقائياً
  Future<RuknNoteFile?> renameNote({
    required String oldTitle,
    required String newRawTitle,
  }) async {
    final newTitle = sanitizeTitle(newRawTitle);
    if (newTitle.isEmpty || newTitle == oldTitle) return null;

    final oldFile = File('${_notesRootDir.path}/$oldTitle.txt');
    final newFile = File('${_notesRootDir.path}/$newTitle.txt');

    if (!await oldFile.exists()) return null;
    if (await newFile.exists()) {
      throw Exception('يوجد ملف آخر بنفس هذا الاسم');
    }

    await oldFile.rename(newFile.path);

    // نقل حالة التثبيت والتصنيف والقفل للاسم الجديد
    if (_pinnedTitles.remove(oldTitle)) {
      _pinnedTitles.add(newTitle);
    }
    if (_lockedTitles.remove(oldTitle)) {
      _lockedTitles.add(newTitle);
    }
    if (_noteCategories.containsKey(oldTitle)) {
      _noteCategories[newTitle] = _noteCategories.remove(oldTitle)!;
    }
    await _saveMetadata();

    // إعادة تسمية جميع النسخ الآمنة المرتبطة بهذا الملف داخل خزنة_النسخ_الآمنة
    if (await _safeVaultDir.exists()) {
      final prefix = '${oldTitle}__نسخة_آمنة_';
      final entities = await _safeVaultDir.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          final fName = entity.uri.pathSegments.last;
          if (fName.startsWith(prefix)) {
            final suffix = fName.substring(oldTitle.length);
            final renamedBackupPath = '${_safeVaultDir.path}/$newTitle$suffix';
            try {
              await entity.rename(renamedBackupPath);
            } catch (_) {}
          }
        }
      }
    }

    await reloadNotes();
    try {
      return _notes.firstWhere((n) => n.title == newTitle);
    } catch (_) {
      return null;
    }
  }

  /// 3. إنشاء نسخة مكررة من الملف
  Future<RuknNoteFile> duplicateNote(RuknNoteFile sourceNote) async {
    final baseCopyTitle = '${sourceNote.title} - نسخة';
    return createNewNote(
      title: baseCopyTitle,
      initialContent: sourceNote.content,
      categoryId: sourceNote.categoryId,
    );
  }

  /// صياغة طابع التاريخ والوقت للنسخ الآمنة: yyyy-MM-dd_HH-mm-ss
  String _formatSafeTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}_${two(dt.hour)}-${two(dt.minute)}-${two(dt.second)}';
  }

  /// 4. إنشاء نسخة آمنة في (خزنة_النسخ_الآمنة) بدون أي حد أقصى (No Cap)
  Future<SafeBackupEntry> createSafeBackup(String noteTitle, {String? customContent}) async {
    if (!await _safeVaultDir.exists()) {
      await _safeVaultDir.create(recursive: true);
    }
    final noMediaFile = File('${_safeVaultDir.path}/.nomedia');
    if (!await noMediaFile.exists()) {
      await noMediaFile.writeAsString('', flush: true);
    }

    String textToSave = customContent ?? '';
    if (customContent == null) {
      final originalFile = File('${_notesRootDir.path}/$noteTitle.txt');
      if (await originalFile.exists()) {
        textToSave = await originalFile.readAsString(encoding: utf8);
      }
    }

    final now = DateTime.now();
    var stamp = _formatSafeTimestamp(now);
    var backupFileName = '${noteTitle}__نسخة_آمنة_$stamp.txt';
    var backupFile = File('${_safeVaultDir.path}/$backupFileName');

    int extra = 1;
    while (await backupFile.exists()) {
      backupFileName = '${noteTitle}__نسخة_آمنة_${stamp}_$extra.txt';
      backupFile = File('${_safeVaultDir.path}/$backupFileName');
      extra++;
    }

    await backupFile.writeAsString(textToSave, encoding: utf8, flush: true);
    final stat = await backupFile.stat();

    return SafeBackupEntry(
      filePath: backupFile.path,
      fileName: backupFileName,
      noteTitle: noteTitle,
      formattedTimestamp: stamp.replaceAll('_', '  '),
      modifiedTime: stat.modified,
      sizeBytes: stat.size,
    );
  }

  /// 5. تصفح النسخ الآمنة الخاصة بملف معين مرتبة من الأحدث للأقدم
  Future<List<SafeBackupEntry>> listSafeBackupsForNote(String noteTitle) async {
    if (!await _safeVaultDir.exists()) return [];

    final prefix = '${noteTitle}__نسخة_آمنة_';
    final entities = await _safeVaultDir.list().toList();
    final List<SafeBackupEntry> list = [];

    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.txt')) {
        final fName = entity.uri.pathSegments.last;
        if (fName.startsWith(prefix)) {
          final stat = await entity.stat();
          final rawStamp = fName
              .substring(prefix.length, fName.length - 4)
              .replaceAll('_', '  •  ');
          list.add(
            SafeBackupEntry(
              filePath: entity.path,
              fileName: fName,
              noteTitle: noteTitle,
              formattedTimestamp: rawStamp,
              modifiedTime: stat.modified,
              sizeBytes: stat.size,
            ),
          );
        }
      }
    }

    list.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    return list;
  }

  /// قراءة محتوى نسخة آمنة للمعاينة
  Future<String> readSafeBackupContent(SafeBackupEntry entry) async {
    final file = File(entry.filePath);
    if (!await file.exists()) return '';
    return file.readAsString(encoding: utf8);
  }

  /// الاستعادة الذكية الصامتة (Silent Smart Restore):
  /// تفحص بصمت إذا كان النص الحالي يختلف عن أحدث نسخة آمنة؛ فإذا اختلف تنشئ نسخة آمنة صامتة أولاً ثم تستعيد فوراً
  Future<String> restoreSafeBackupSmartly({
    required String noteTitle,
    required SafeBackupEntry targetBackup,
  }) async {
    final currentFile = File('${_notesRootDir.path}/$noteTitle.txt');
    String currentText = '';
    if (await currentFile.exists()) {
      currentText = await currentFile.readAsString(encoding: utf8);
    }

    final existingBackups = await listSafeBackupsForNote(noteTitle);
    String latestBackupText = '';
    if (existingBackups.isNotEmpty) {
      latestBackupText = await readSafeBackupContent(existingBackups.first);
    }

    final selectedBackupText = await readSafeBackupContent(targetBackup);

    // إذا كان النص الحالي يحتوي على تعديلات غير محفوظة في أحدث نسخة آمنة ويختلف عن النسخة المراد استعادتها
    if (currentText.trim().isNotEmpty &&
        currentText != latestBackupText &&
        currentText != selectedBackupText) {
      await createSafeBackup(noteTitle, customContent: currentText);
    }

    await currentFile.writeAsString(selectedBackupText, encoding: utf8, flush: true);
    await reloadNotes();
    return selectedBackupText;
  }

  /// 6. مشاركة الملف النصي أو محتواه
  Future<void> shareNoteFile(RuknNoteFile note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain')],
        subject: note.title,
        text: note.content,
      );
    } else {
      await Share.share(note.content, subject: note.title);
    }
  }

  /// 7. حذف الملف (ينشئ بصمت نسخة آمنة تلقائية في خزنة_النسخ_الآمنة قبل الحذف الفعلي)
  Future<void> deleteNoteWithSafetyBackup(RuknNoteFile note) async {
    await createSafeBackup(note.title, customContent: note.content);

    final file = File(note.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    _pinnedTitles.remove(note.title);
    _lockedTitles.remove(note.title);
    _noteCategories.remove(note.title);
    await _saveMetadata();
    await reloadNotes();
  }

  /// النسخ الاحتياطي الشامل (ZIP) لجميع ملفات .txt وخزنة النسخ الآمنة
  Future<String> exportFullZipBackup({bool shareImmediately = true}) async {
    final archive = Archive();

    // إضافة جميع ملفات الملاحظات .txt
    if (await _notesRootDir.exists()) {
      final rootEntities = await _notesRootDir.list().toList();
      for (final entity in rootEntities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.txt')) {
          final bytes = await entity.readAsBytes();
          final name = entity.uri.pathSegments.last;
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }
    }

    // إضافة ملفات خزنة_النسخ_الآمنة داخل مجلدها في الـ ZIP
    if (await _safeVaultDir.exists()) {
      final vaultEntities = await _safeVaultDir.list().toList();
      for (final entity in vaultEntities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.txt')) {
          final bytes = await entity.readAsBytes();
          final name = '$safeVaultFolderName/${entity.uri.pathSegments.last}';
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }
    }

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive) ?? [];

    final now = DateTime.now();
    final stamp = _formatSafeTimestamp(now);
    final zipFileName = 'Rukn_Backup_$stamp.zip';

    final tempDir = await getTemporaryDirectory();
    final tempZipFile = File('${tempDir.path}/$zipFileName');
    await tempZipFile.writeAsBytes(zipBytes, flush: true);

    String savedLocation = tempZipFile.path;
    try {
      final res = await _nativeChannel.invokeMethod<String>('saveToDownloads', {
        'fileName': zipFileName,
        'bytes': Uint8List.fromList(zipBytes),
        'mimeType': 'application/zip',
      });
      if (res != null && res.isNotEmpty) {
        savedLocation = res;
      }
    } catch (_) {}

    if (shareImmediately) {
      await Share.shareXFiles(
        [XFile(tempZipFile.path, mimeType: 'application/zip')],
        subject: 'نسخة احتياطية شاملة — تطبيق رُكْن',
      );
    }

    return savedLocation;
  }
}
