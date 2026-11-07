import 'package:shared_preferences/shared_preferences.dart';

/// Device-library songs the user removed from the list (Android).
/// The original files are not touched; they are just hidden.
abstract class HiddenSongsLocalDataSource {
  Set<String> getHiddenIds();
  Future<void> saveHiddenIds(Set<String> ids);
}

class HiddenSongsLocalDataSourceImpl implements HiddenSongsLocalDataSource {
  static const _key = 'hidden_song_ids';
  final SharedPreferences _prefs;

  HiddenSongsLocalDataSourceImpl(this._prefs);

  @override
  Set<String> getHiddenIds() => (_prefs.getStringList(_key) ?? []).toSet();

  @override
  Future<void> saveHiddenIds(Set<String> ids) =>
      _prefs.setStringList(_key, ids.toList());
}
