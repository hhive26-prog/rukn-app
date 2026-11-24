import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RuknNoteFile {
  final File file;
  final String title;
  final String content;
  final DateTime modifiedAt;
  final bool isPinned;
  final bool isLocked;
  final String category;

  const RuknNoteFile({
    required this.file,
    required this.title,
    required this.content,
    required this.modifiedAt,
    this.isPinned = false,
    this.isLocked = false,
    this.category = '',
  });

  String get fileName => p.basename(file.path);

  RuknNoteFile copyWith({
    File? file,
    String? title,
    String? content,
    DateTime? modifiedAt,
    bool? isPinned,
    bool? isLocked,
    String? category,
  }) {
    return RuknNoteFile(
      file: file ?? this.file,
      title: title ?? this.title,
      content: content ?? this.content,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      category: category ?? this.category,
    );
  }
}

class SafeBackupEntry {
  final File file;
  final String originalNoteTitle;
  final DateTime createdAt;
  final int sizeBytes;

  const SafeBackupEntry({
    required this.file,
    required this.originalNoteTitle,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get formattedDate =>
      DateFormat('yyyy-MM-dd • HH:mm:ss', 'en').format(createdAt);
}

class StorageVaultController extends ChangeNotifier {
  static const MethodChannel _nativeChannel =
      MethodChannel('com.rukn.app/native');

  static const String notesFolderName = 'Rukn_Notes';
  static const String safeVaultFolderName = 'خزنة_النسخ_الآمنة';

  late Directory _notesDir;
  late Directory _safeVaultDir;

  List<RuknNoteFile> _notes = [];
  Set<String> _pinnedTitles = {};
  Set<String> _lockedTitles = {};
  Map<String, String> _categoryMap = {};
  bool _isLoading = true;

  List<RuknNoteFile> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  Directory get notesDirectory => _notesDir;
  Directory get safeVaultDirectory => _safeVaultDir;

  Future<void> initializeVault() async {
    _isLoading = true;
    notifyListeners();

    final appDocDir = await getApplicationDocumentsDirectory();
    _notesDir = Directory(p.join(appDocDir.path, notesFolderName));
    if (!await _notesDir.exists()) {
      await _notesDir.create(recursive: true);
    }

    _safeVaultDir = Directory(p.join(_notesDir.path, safeVaultFolderName));
    if (!await _safeVaultDir.exists()) {
      await _safeVaultDir.create(recursive: true);
    }

    final noMediaFile = File(p.join(_safeVaultDir.path, '.nomedia'));
    if (!await noMediaFile.exists()) {
      await noMediaFile.writeAsString('', flush: true);
    }

    await _loadMetadata();
    await refreshNotes();

    if (_notes.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final welcomed = prefs.getBool('rukn_welcome_created') ?? false;
      if (!welcomed) {
        await createNewNote(
          title: 'مرحباً بك في رُكْن',
          initialContent:
              'بسم الله الرحمن الرحيم\n\nأهلاً بك في تطبيق "رُكْن" — مفكرتك العربية الفاخرة وملاذك الآمن لتدوين الأفكار، الالتزامات، والخواطر.\n\n• جميع ملاحظاتك تُحفظ مباشرة بصيغة نصية صافية (TXT).\n• يمكنك تثبيت الملفات المهمة أو قفلها برمز سري.\n• خزنة النسخ الآمنة تحفظ لك نسخك السابقة دون حدود.',
        );
        await prefs.setBool('rukn_welcome_created', true);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    _pinnedTitles = (prefs.getStringList('rukn_pinned_files') ?? []).toSet();
    _lockedTitles = (prefs.getStringList('rukn_locked_files') ?? []).toSet();

    final catJson = prefs.getString('rukn_file_categories') ?? '{}';
    try {
      final decoded = jsonDecode(catJson) as Map<String, dynamic>;
      _categoryMap = decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _categoryMap = {};
    }
  }

  Future<void> _saveMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rukn_pinned_files', _pinnedTitles.toList());
    await prefs.setStringList('rukn_locked_files', _lockedTitles.toList());
    await prefs.setString('rukn_file_categories', jsonEncode(_categoryMap));
  }

  String _sanitizeTitle(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll('\n', ' ')
        .trim();
    return cleaned.isEmpty ? 'ملف بدون عنوان' : cleaned;
  }

  Future<void> refreshNotes() async {
    if (!await _notesDir.exists()) return;

    final entities = await _notesDir.list(followLinks: false).toList();
    final loaded = <RuknNoteFile>[];

    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.txt')) {
        try {
          final fileName = p.basenameWithoutExtension(entity.path);
          final stat = await entity.stat();
          final content = await entity.readAsString(encoding: utf8);
          loaded.add(
            RuknNoteFile(
              file: entity,
              title: fileName,
              content: content,
              modifiedAt: stat.modified,
              isPinned: _pinnedTitles.contains(fileName),
              isLocked: _lockedTitles.contains(fileName),
              category: _categoryMap[fileName] ?? '',
            ),
          );
        } catch (_) {}
      }
    }

    loaded.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.modifiedAt.compareTo(a.modifiedAt);
    });

    _notes = loaded;
    notifyListeners();
  }

  Future<RuknNoteFile?> createNewNote({
    required String title,
    String initialContent = '',
    String category = '',
  }) async {
    String baseTitle = _sanitizeTitle(title);
    String finalTitle = baseTitle;
    int counter = 1;

    while (await File(p.join(_notesDir.path, '$finalTitle.txt')).exists()) {
      counter++;
      finalTitle = '$baseTitle ($counter)';
    }

    final file = File(p.join(_notesDir.path, '$finalTitle.txt'));
    await file.writeAsString(initialContent, encoding: utf8, flush: true);

    if (category.isNotEmpty && category != 'الكل' && category != 'المثبتة') {
      _categoryMap[finalTitle] = category;
      await _saveMetadata();
    }

    await refreshNotes();
    try {
      return _notes.firstWhere((n) => n.title == finalTitle);
    } catch (_) {
      return _notes.isNotEmpty ? _notes.first : null;
    }
  }

  Future<void> saveNoteContent(RuknNoteFile note, String newContent) async {
    await note.file.writeAsString(newContent, encoding: utf8, flush: true);
    final idx = _notes.indexWhere((n) => n.title == note.title);
    if (idx != -1) {
      _notes[idx] = _notes[idx].copyWith(
        content: newContent,
        modifiedAt: DateTime.now(),
      );
      _notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.modifiedAt.compareTo(a.modifiedAt);
      });
      notifyListeners();
    } else {
      await refreshNotes();
    }
  }

  Future<void> togglePinNote(RuknNoteFile note) async {
    if (_pinnedTitles.contains(note.title)) {
      _pinnedTitles.remove(note.title);
    } else {
      _pinnedTitles.add(note.title);
    }
    await _saveMetadata();
    await refreshNotes();
  }

  Future<void> toggleLockNote(RuknNoteFile note) async {
    if (_lockedTitles.contains(note.title)) {
      _lockedTitles.remove(note.title);
    } else {
      _lockedTitles.add(note.title);
    }
    await _saveMetadata();
    await refreshNotes();
  }

  Future<void> setNoteCategory(RuknNoteFile note, String category) async {
    if (category.isEmpty || category == 'الكل') {
      _categoryMap.remove(note.title);
    } else {
      _categoryMap[note.title] = category;
    }
    await _saveMetadata();
    await refreshNotes();
  }

  Future<void> renameCategoryAcrossNotes(
    String oldCategory,
    String newCategory,
  ) async {
    bool changed = false;
    final keys = _categoryMap.keys.toList();
    for (final k in keys) {
      if (_categoryMap[k] == oldCategory) {
        if (newCategory.isEmpty) {
          _categoryMap.remove(k);
        } else {
          _categoryMap[k] = newCategory;
        }
        changed = true;
      }
    }
    if (changed) {
      await _saveMetadata();
      await refreshNotes();
    }
  }

  Future<RuknNoteFile?> renameNote(
    RuknNoteFile note,
    String newRawTitle,
  ) async {
    final cleanNew = _sanitizeTitle(newRawTitle);
    if (cleanNew == note.title) return note;

    final targetPath = p.join(_notesDir.path, '$cleanNew.txt');
    if (await File(targetPath).exists()) {
      throw Exception('يوجد ملف آخر بنفس الاسم');
    }

    final renamedFile = await note.file.rename(targetPath);

    if (_pinnedTitles.remove(note.title)) {
      _pinnedTitles.add(cleanNew);
    }
    if (_lockedTitles.remove(note.title)) {
      _lockedTitles.add(cleanNew);
    }
    if (_categoryMap.containsKey(note.title)) {
      _categoryMap[cleanNew] = _categoryMap.remove(note.title)!;
    }
    await _saveMetadata();

    // Update associated safe backups prefix so they stay linked to the renamed file
    if (await _safeVaultDir.exists()) {
      final oldPrefix = '${note.title}__نسخة_آمنة_';
      final newPrefix = '${cleanNew}__نسخة_آمنة_';
      final entities = await _safeVaultDir.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          final base = p.basename(entity.path);
          if (base.startsWith(oldPrefix)) {
            final suffix = base.substring(oldPrefix.length);
            final newBackupPath = p.join(_safeVaultDir.path, '$newPrefix$suffix');
            try {
              await entity.rename(newBackupPath);
            } catch (_) {}
          }
        }
      }
    }

    await refreshNotes();
    try {
      return _notes.firstWhere((n) => n.title == cleanNew);
    } catch (_) {
      return RenamedFallback.from(renamedFile, cleanNew, note);
    }
  }

  Future<RuknNoteFile?> duplicateNote(RuknNoteFile note) async {
    return createNewNote(
      title: '${note.title} - نسخة',
      initialContent: note.content,
      category: note.category,
    );
  }

  Future<SafeBackupEntry?> createSafeBackup(
    RuknNoteFile note, {
    String? overrideContent,
  }) async {
    if (!await _safeVaultDir.exists()) {
      await _safeVaultDir.create(recursive: true);
    }
    final stamp =
        DateFormat('yyyy-MM-dd_HH-mm-ss', 'en').format(DateTime.now());
    final fileName = '${note.title}__نسخة_آمنة_$stamp.txt';
    final backupFile = File(p.join(_safeVaultDir.path, fileName));
    final textToSave = overrideContent ?? note.content;
    await backupFile.writeAsString(textToSave, encoding: utf8, flush: true);
    final stat = await backupFile.stat();

    return SafeBackupEntry(
      file: backupFile,
      originalNoteTitle: note.title,
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<List<SafeBackupEntry>> listSafeBackupsForNote(
    RuknNoteFile note,
  ) async {
    if (!await _safeVaultDir.exists()) return [];
    final prefix = '${note.title}__نسخة_آمنة_';
    final entities = await _safeVaultDir.list().toList();
    final result = <SafeBackupEntry>[];

    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.txt')) {
        final base = p.basename(entity.path);
        if (base.startsWith(prefix)) {
          final stat = await entity.stat();
          result.add(
            SafeBackupEntry(
              file: entity,
              originalNoteTitle: note.title,
              createdAt: stat.modified,
              sizeBytes: stat.size,
            ),
          );
        }
      }
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<String> restoreSafeBackupSmartly(
    RuknNoteFile note,
    SafeBackupEntry backup,
  ) async {
    final backupContent = await backup.file.readAsString(encoding: utf8);
    if (note.content.trim().isNotEmpty && note.content != backupContent) {
      await createSafeBackup(note, overrideContent: note.content);
    }
    await saveNoteContent(note, backupContent);
    return backupContent;
  }

  Future<void> deleteSafeBackup(SafeBackupEntry backup) async {
    if (await backup.file.exists()) {
      await backup.file.delete();
    }
  }

  Future<void> deleteNoteWithSafetyBackup(RuknNoteFile note) async {
    try {
      await createSafeBackup(note);
    } catch (_) {}

    if (await note.file.exists()) {
      await note.file.delete();
    }
    _pinnedTitles.remove(note.title);
    _lockedTitles.remove(note.title);
    _categoryMap.remove(note.title);
    await _saveMetadata();
    await refreshNotes();
  }

  Future<String?> exportFullVaultZip({
    required bool saveToDevice,
    required bool shareExternally,
  }) async {
    final archive = Archive();

    for (final note in _notes) {
      final bytes = utf8.encode(note.content);
      archive.addFile(
        ArchiveFile('ملفاتي/${note.title}.txt', bytes.length, bytes),
      );
    }

    if (await _safeVaultDir.exists()) {
      final entities = await _safeVaultDir.list().toList();
      for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.txt')) {
          final bytes = await entity.readAsBytes();
          final name = p.basename(entity.path);
          archive.addFile(
            ArchiveFile('$safeVaultFolderName/$name', bytes.length, bytes),
          );
        }
      }
    }

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) return null;

    final stamp = DateFormat('yyyy-MM-dd_HH-mm', 'en').format(DateTime.now());
    final zipFileName = 'Rukn_Backup_$stamp.zip';

    String? savedLocation;
    if (saveToDevice) {
      try {
        savedLocation = await _nativeChannel.invokeMethod<String>(
          'saveToDownloads',
          {
            'fileName': zipFileName,
            'bytes': Uint8List.fromList(zipBytes),
            'mimeType': 'application/zip',
          },
        );
      } catch (_) {}
    }

    if (shareExternally) {
      final tempDir = await getTemporaryDirectory();
      final tempZip = File(p.join(tempDir.path, zipFileName));
      await tempZip.writeAsBytes(zipBytes, flush: true);
      await Share.shareXFiles(
        [
          XFile(
            tempZip.path,
            name: zipFileName,
            mimeType: 'application/zip',
          ),
        ],
        text: 'نسخة احتياطية شاملة من تطبيق رُكْن',
      );
    }

    return savedLocation ?? zipFileName;
  }
}

class RenamedFallback {
  static RuknNoteFile from(File file, String title, RuknNoteFile old) {
    return old.copyWith(file: file, title: title);
  }
}
