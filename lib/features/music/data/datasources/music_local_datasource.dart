import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/song_model.dart';
import 'media_store_channel.dart';

abstract class MusicLocalDataSource {
  Future<bool> requestPermission();
  Future<void> openSettings();
  Future<List<SongModel>> queryDeviceSongs();
  Future<List<SongModel>> scanAppFolder();
  Future<int> importFiles();
}

class MusicLocalDataSourceImpl implements MusicLocalDataSource {
  final MediaStoreChannel _mediaStore;
  MusicLocalDataSourceImpl(this._mediaStore);

  bool _libraryGranted = false;

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
      if (!await docs.exists()) return [];
      final files = docs
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => AppConstants.audioExtensions
              .contains(p.extension(f.path).toLowerCase()));
      return files.map(SongModel.fromFile).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<int> importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'aiff'],
      allowMultiple: true,
    );
    if (result == null) return 0;

    final docs = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(docs.path, AppConstants.importFolder));
    if (!await target.exists()) await target.create(recursive: true);

    var count = 0;
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      final dest = p.join(target.path, p.basename(path));
      if (await File(dest).exists()) continue;
      await File(path).copy(dest);
      count++;
    }
    return count;
  }
}
