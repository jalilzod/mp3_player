import 'package:shared_preferences/shared_preferences.dart';

abstract class FavoritesLocalDataSource {
  Set<String> getFavoriteIds();
  Future<void> saveFavoriteIds(Set<String> ids);
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  static const _key = 'favorite_song_ids';
  final SharedPreferences _prefs;

  FavoritesLocalDataSourceImpl(this._prefs);

  @override
  Set<String> getFavoriteIds() => (_prefs.getStringList(_key) ?? []).toSet();

  @override
  Future<void> saveFavoriteIds(Set<String> ids) =>
      _prefs.setStringList(_key, ids.toList());
}
