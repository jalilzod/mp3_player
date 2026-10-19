import '../../domain/entities/song.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/favorites_local_datasource.dart';
import '../datasources/music_local_datasource.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicLocalDataSource music;
  final FavoritesLocalDataSource favorites;

  MusicRepositoryImpl({required this.music, required this.favorites});

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
    // De-duplicate by id.
    final map = <String, Song>{};
    for (final s in results.expand((e) => e)) {
      map[s.id] = s;
    }
    return map.values.toList();
  }

  @override
  Future<int> importSongs() => music.importFiles();

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
