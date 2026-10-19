import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/playback_enums.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/usecases/get_favorite_ids.dart';
import '../../../domain/usecases/get_songs.dart';
import '../../../domain/usecases/import_songs.dart';
import '../../../domain/usecases/open_app_settings.dart';
import '../../../domain/usecases/request_permission.dart';
import '../../../domain/usecases/toggle_favorite.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final RequestPermission _requestPermission;
  final GetSongs _getSongs;
  final ImportSongs _importSongs;
  final GetFavoriteIds _getFavoriteIds;
  final ToggleFavorite _toggleFavorite;
  final OpenAppSettings _openAppSettings;

  LibraryCubit({
    required RequestPermission requestPermission,
    required GetSongs getSongs,
    required ImportSongs importSongs,
    required GetFavoriteIds getFavoriteIds,
    required ToggleFavorite toggleFavorite,
    required OpenAppSettings openAppSettings,
  })  : _requestPermission = requestPermission,
        _getSongs = getSongs,
        _importSongs = importSongs,
        _getFavoriteIds = getFavoriteIds,
        _toggleFavorite = toggleFavorite,
        _openAppSettings = openAppSettings,
        super(const LibraryState());

  Future<void> load() async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final granted = await _requestPermission();
      final songs = await _getSongs();
      final favorites = await _getFavoriteIds();

      // On Android without permission and nothing imported → show permission screen.
      if (!granted && songs.isEmpty && Platform.isAndroid) {
        emit(state.copyWith(status: LibraryStatus.permissionDenied));
        return;
      }
      emit(state.copyWith(
        status: LibraryStatus.loaded,
        songs: songs,
        favoriteIds: favorites,
      ));
    } catch (e) {
      emit(state.copyWith(status: LibraryStatus.error, message: e.toString()));
    }
  }

  /// Pull-to-refresh: re-scan without showing the full loader.
  Future<void> refresh() async {
    try {
      final songs = await _getSongs();
      emit(state.copyWith(status: LibraryStatus.loaded, songs: songs));
    } catch (_) {}
  }

  Future<void> importMusic() async {
    try {
      final count = await _importSongs();
      if (count == 0) return;
      final songs = await _getSongs();
      emit(state.copyWith(
        status: LibraryStatus.loaded,
        songs: songs,
        message: 'Imported $count song${count == 1 ? '' : 's'}',
      ));
    } catch (e) {
      emit(state.copyWith(message: 'Import failed'));
    }
  }

  Future<void> openSettings() => _openAppSettings();

  void search(String query) => emit(state.copyWith(query: query));

  void changeSort(SongSort sort) => emit(state.copyWith(sort: sort));

  Future<void> toggleFavorite(Song song) async {
    // Optimistic update for instant UI feedback.
    final optimistic = {...state.favoriteIds};
    if (!optimistic.remove(song.id)) optimistic.add(song.id);
    emit(state.copyWith(favoriteIds: optimistic));
    final saved = await _toggleFavorite(song.id);
    emit(state.copyWith(favoriteIds: saved));
  }
}