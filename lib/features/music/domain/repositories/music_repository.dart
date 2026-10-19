import '../entities/song.dart';

/// Access to the user's music library and favorites.
abstract class MusicRepository {
  /// Returns true when the device music library can be read.
  Future<bool> requestPermission();

  /// Opens the system settings page for this app.
  Future<void> openAppSettings();

  /// All songs: device library + imported files.
  Future<List<Song>> getSongs();

  /// Opens a file picker and copies chosen audio into the app. Returns count imported.
  Future<int> importSongs();

  Future<Set<String>> getFavoriteIds();

  /// Toggles and returns the updated favorite set.
  Future<Set<String>> toggleFavorite(String songId);
}
