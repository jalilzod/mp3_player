import '../entities/import_result.dart';
import '../entities/song.dart';

/// Access to the user's music library and favorites.
abstract class MusicRepository {
  /// Returns true when the device music library can be read.
  Future<bool> requestPermission();

  /// Opens the system settings page for this app.
  Future<void> openAppSettings();

  /// All songs: device library + imported files (minus removed ones).
  Future<List<Song>> getSongs();

  /// Opens a file picker and copies chosen audio into the app.
  /// Songs that already exist in the library are skipped.
  Future<ImportResult> importSongs();

  /// Imported files are deleted from the device; device-library songs
  /// are removed from the list (the original file is not touched).
  Future<void> deleteSong(Song song);

  /// How many device-library songs were removed from the list.
  Future<int> getHiddenCount();

  /// Brings back every device-library song removed from the list.
  Future<void> restoreHiddenSongs();

  Future<Set<String>> getFavoriteIds();

  /// Toggles and returns the updated favorite set.
  Future<Set<String>> toggleFavorite(String songId);
}
