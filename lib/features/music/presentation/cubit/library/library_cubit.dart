import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/playback_enums.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/usecases/delete_song.dart';
import '../../../domain/usecases/get_favorite_ids.dart';
import '../../../domain/usecases/get_hidden_count.dart';
import '../../../domain/usecases/get_songs.dart';
import '../../../domain/usecases/import_songs.dart';
import '../../../domain/usecases/open_app_settings.dart';
import '../../../domain/usecases/request_permission.dart';
import '../../../domain/usecases/restore_hidden_songs.dart';
import '../../../domain/usecases/toggle_favorite.dart';
import 'library_state.dart';

class _PendingDelete {
  final Song song;
  final Timer timer;
  _PendingDelete(this.song, this.timer);
}

class LibraryCubit extends Cubit<LibraryState> {
  final RequestPermission _requestPermission;
  final GetSongs _getSongs;
  final ImportSongs _importSongs;
  final GetFavoriteIds _getFavoriteIds;
  final ToggleFavorite _toggleFavorite;
  final OpenAppSettings _openAppSettings;
  final DeleteSong _deleteSong;
  final GetHiddenCount _getHiddenCount;
  final RestoreHiddenSongs _restoreHiddenSongs;

  /// How long the user can press "Undo" before the delete is final.
  static const undoWindow = Duration(seconds: 5);
  final Map<String, _PendingDelete> _pending = {};

  LibraryCubit({
    required RequestPermission requestPermission,
    required GetSongs getSongs,
    required ImportSongs importSongs,
    required GetFavoriteIds getFavoriteIds,
    required ToggleFavorite toggleFavorite,
    required OpenAppSettings openAppSettings,
    required DeleteSong deleteSong,
    required GetHiddenCount getHiddenCount,
    required RestoreHiddenSongs restoreHiddenSongs,
  })  : _requestPermission = requestPermission,
        _getSongs = getSongs,
        _importSongs = importSongs,
        _getFavoriteIds = getFavoriteIds,
        _toggleFavorite = toggleFavorite,
        _openAppSettings = openAppSettings,
        _deleteSong = deleteSong,
        _getHiddenCount = getHiddenCount,
        _restoreHiddenSongs = restoreHiddenSongs,
        super(const LibraryState());

  /// Songs waiting for "Undo" must not reappear after a refresh.
  List<Song> _withoutPending(List<Song> songs) =>
      songs.where((s) => !_pending.containsKey(s.id)).toList();

  Future<void> load() async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final granted = await _requestPermission();
      final songs = await _getSongs();
      final favorites = await _getFavoriteIds();
      final hidden = await _getHiddenCount();

      // On Android without permission and nothing imported → show permission screen.
      if (!granted && songs.isEmpty && Platform.isAndroid) {
        emit(state.copyWith(status: LibraryStatus.permissionDenied));
        return;
      }
      emit(state.copyWith(
        status: LibraryStatus.loaded,
        songs: _withoutPending(songs),
        favoriteIds: favorites,
        hiddenCount: hidden,
      ));
    } catch (e) {
      emit(state.copyWith(status: LibraryStatus.error, message: e.toString()));
    }
  }

  /// Pull-to-refresh: re-scan without showing the full loader.
  Future<void> refresh() async {
    try {
      final songs = await _getSongs();
      emit(state.copyWith(
        status: LibraryStatus.loaded,
        songs: _withoutPending(songs),
        hiddenCount: await _getHiddenCount(),
      ));
    } catch (_) {}
  }

  Future<void> importMusic() async {
    if (state.isImporting) return;
    emit(state.copyWith(isImporting: true));
    try {
      final result = await _importSongs();
      if (result.cancelled) {
        emit(state.copyWith(isImporting: false));
        return;
      }
      final songs = await _getSongs();
      emit(state.copyWith(
        status: LibraryStatus.loaded,
        songs: _withoutPending(songs),
        isImporting: false,
        notice: result.added == 0 && result.skipped > 0
            ? LibraryNotice(LibraryNoticeType.allDuplicates, skipped: result.skipped)
            : LibraryNotice(
                LibraryNoticeType.imported,
                count: result.added,
                skipped: result.skipped,
              ),
      ));
    } catch (_) {
      emit(state.copyWith(
        isImporting: false,
        notice: LibraryNotice(LibraryNoticeType.importFailed),
      ));
    }
  }

  /// Removes the song from the list right away; the real delete happens
  /// after [undoWindow] unless [undoDelete] is called.
  void deleteSong(Song song) {
    if (_pending.containsKey(song.id)) return;
    _pending[song.id] = _PendingDelete(
      song,
      Timer(undoWindow, () => _commitDelete(song.id)),
    );
    emit(state.copyWith(
      songs: state.songs.where((s) => s.id != song.id).toList(),
      notice: LibraryNotice(LibraryNoticeType.deleted, song: song),
    ));
  }

  void undoDelete(Song song) {
    final pending = _pending.remove(song.id);
    if (pending == null) return;
    pending.timer.cancel();
    if (state.songs.any((s) => s.id == song.id)) return;
    emit(state.copyWith(songs: [...state.songs, song]));
  }

  Future<void> _commitDelete(String id) async {
    final pending = _pending.remove(id);
    if (pending == null) return;
    try {
      await _deleteSong(pending.song);
    } catch (_) {}
    if (isClosed) return;
    final hidden = await _getHiddenCount();
    final favorites = {...state.favoriteIds}..remove(id);
    emit(state.copyWith(favoriteIds: favorites, hiddenCount: hidden));
  }

  Future<void> restoreHiddenSongs() async {
    final count = state.hiddenCount;
    await _restoreHiddenSongs();
    final songs = await _getSongs();
    emit(state.copyWith(
      songs: _withoutPending(songs),
      hiddenCount: 0,
      notice: LibraryNotice(LibraryNoticeType.restored, count: count),
    ));
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

  @override
  Future<void> close() async {
    // Finish any deletes still waiting for "Undo".
    for (final p in _pending.values) {
      p.timer.cancel();
      unawaited(_deleteSong(p.song).catchError((_) {}));
    }
    _pending.clear();
    return super.close();
  }
}
