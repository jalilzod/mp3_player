import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/song.dart';
import '../models/song_model.dart';
import 'media_store_channel.dart';

abstract class MusicLocalDataSource {
  Future<bool> requestPermission();
  Future<void> openSettings();
  Future<List<SongModel>> queryDeviceSongs();
  Future<List<SongModel>> scanAppFolder();

  /// Picks files and copies the new ones. [existing] = current library,
  /// used to skip songs that are already there.
  Future<ImportResult> importFiles(List<Song> existing);

  /// Deletes an imported file (only files inside the app folder).
  Future<void> deleteFile(String path);
}

class MusicLocalDataSourceImpl implements MusicLocalDataSource {
  final MediaStoreChannel _mediaStore;
  MusicLocalDataSourceImpl(this._mediaStore);

  bool _libraryGranted = false;

  static const _pickerExtensions = ['mp3', 'm4a', 'aac', 'wav', 'flac', 'aiff'];

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      try {
        _libraryGranted = await _mediaStore.requestPermission();
      } catch (_) {
        _libraryGranted = false;
      }
    } else {
      // iOS: songs come from the app's own Documents folder — no permission needed.
      _libraryGranted = true;
    }
    return _libraryGranted;
  }

  @override
  Future<void> openSettings() async {
    if (Platform.isAndroid) await _mediaStore.openSettings();
  }

  /// Android: every song in the MediaStore. iOS: handled by [scanAppFolder].
  @override
  Future<List<SongModel>> queryDeviceSongs() async {
    if (!Platform.isAndroid || !_libraryGranted) return [];
    try {
      final rows = await _mediaStore.querySongs();
      final minMs = AppConstants.minSongDuration.inMilliseconds;
      return rows
          .map(SongModel.fromMediaStore)
          .where((s) => s.duration.inMilliseconds >= minMs)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// On iOS, files dropped into the app via the Files app / Finder land in
  /// Documents. Imported files on both platforms go to Documents/Music.
  @override
  Future<List<SongModel>> scanAppFolder() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      return _audioFilesIn(docs)
          .map((f) => SongModel.fromFile(f, root: docs.path))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ImportResult> importFiles(List<Song> existing) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _pickerExtensions,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) {
      return const ImportResult.cancelled();
    }

    final docs = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(docs.path, AppConstants.importFolder));
    if (!await target.exists()) await target.create(recursive: true);

    // ── Fingerprints of what is already in the library ──
    final knownNames = <String>{};
    final knownSizes = <String>{};
    for (final s in existing) {
      if (s.artist.isNotEmpty) knownNames.add(_normalize('${s.artist} - ${s.title}'));
      // Device songs often have the file name as title.
      if (s.artist.isEmpty || !s.isImportedFile) knownNames.add(_normalize(s.title));
    }
    for (final f in _audioFilesIn(docs)) {
      knownNames.add(_normalize(p.basenameWithoutExtension(f.path)));
      try {
        knownSizes.add(_sizeKey(f.lengthSync(), f.path));
      } catch (_) {}
    }

    var added = 0;
    var skipped = 0;
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;

      final name = _normalize(p.basenameWithoutExtension(path));
      final sizeKey = _sizeKey(file.size, path);
      final dest = p.join(target.path, p.basename(path));

      final isDuplicate = knownNames.contains(name) ||
          knownSizes.contains(sizeKey) ||
          await File(dest).exists();
      if (isDuplicate) {
        skipped++;
        continue;
      }

      await File(path).copy(dest);
      knownNames.add(name);
      knownSizes.add(sizeKey);
      added++;
    }

    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {}

    return ImportResult(added: added, skipped: skipped);
  }

  @override
  Future<void> deleteFile(String path) async {
    final docs = await getApplicationDocumentsDirectory();
    // Safety: never delete anything outside the app's own folder.
    if (!p.isWithin(docs.path, path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  // ───────────────────────── helpers ─────────────────────────

  Iterable<File> _audioFilesIn(Directory dir) {
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) => AppConstants.audioExtensions
            .contains(p.extension(f.path).toLowerCase()));
  }

  /// "Artist - Song (1)" → "artist - song"
  static String _normalize(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\s*\(\d+\)$'), '')
      .replaceAll(RegExp(r'[_\s]+'), ' ')
      .trim();

  static String _sizeKey(int bytes, String path) =>
      '$bytes|${p.extension(path).toLowerCase()}';
}
