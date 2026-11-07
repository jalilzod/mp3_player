import '../../domain/entities/import_result.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/favorites_local_datasource.dart';
import '../datasources/hidden_songs_local_datasource.dart';
import '../datasources/music_local_datasource.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicLocalDataSource music;
  final FavoritesLocalDataSource favorites;
  final HiddenSongsLocalDataSource hidden;

  MusicRepositoryImpl({
    required this.music,
    required this.favorites,
    required this.hidden,
  });

  @override
  Future<bool> requestPermission() => music.requestPermission();

  @override
  Future<void> openAppSettings() => music.openSettings();

  @override
  Future<List<Song>> getSongs() async {
    final results = await Future.wait([
      music.queryDeviceSongs(),
      music.scanAppFolder(),
    ]);
    final hiddenIds = hidden.getHiddenIds();
    // De-duplicate by id and drop songs the user removed.
    final map = <String, Song>{};
    for (final s in results.expand((e) => e)) {
      if (!hiddenIds.contains(s.id)) map[s.id] = s;
    }
    return map.values.toList();
  }

  @override
  Future<ImportResult> importSongs() async {
    final existing = await getSongs();
    return music.importFiles(existing);
  }

  @override
  Future<void> deleteSong(Song song) async {
    if (song.isImportedFile) {
      await music.deleteFile(song.uri);
    } else {
      final ids = hidden.getHiddenIds()..add(song.id);
      await hidden.saveHiddenIds(ids);
    }
    final favs = favorites.getFavoriteIds();
    if (favs.remove(song.id)) await favorites.saveFavoriteIds(favs);
  }

  @override
  Future<int> getHiddenCount() async => hidden.getHiddenIds().length;

  @override
  Future<void> restoreHiddenSongs() => hidden.saveHiddenIds({});

  @override
  Future<Set<String>> getFavoriteIds() async => favorites.getFavoriteIds();

  @override
  Future<Set<String>> toggleFavorite(String songId) async {
    final ids = favorites.getFavoriteIds();
    if (!ids.remove(songId)) ids.add(songId);
    await favorites.saveFavoriteIds(ids);
    return ids;
  }
}
