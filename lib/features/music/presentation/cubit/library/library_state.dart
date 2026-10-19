import 'package:equatable/equatable.dart';

import '../../../domain/entities/playback_enums.dart';
import '../../../domain/entities/song.dart';

enum LibraryStatus { initial, loading, loaded, permissionDenied, error }

class LibraryState extends Equatable {
  final LibraryStatus status;
  final List<Song> songs;
  final Set<String> favoriteIds;
  final String query;
  final SongSort sort;
  final String? message;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.songs = const [],
    this.favoriteIds = const {},
    this.query = '',
    this.sort = SongSort.title,
    this.message,
  });

  bool isFavorite(String id) => favoriteIds.contains(id);

  /// Songs after search + sort.
  List<Song> get visibleSongs => _sorted(_filtered(songs));

  List<Song> get favoriteSongs =>
      _sorted(_filtered(songs.where((s) => favoriteIds.contains(s.id))));

  Iterable<Song> _filtered(Iterable<Song> input) {
    if (query.trim().isEmpty) return input;
    final q = query.toLowerCase().trim();
    return input.where((s) =>
        s.title.toLowerCase().contains(q) ||
        s.artist.toLowerCase().contains(q) ||
        s.album.toLowerCase().contains(q));
  }

  List<Song> _sorted(Iterable<Song> input) {
    final list = input.toList();
    switch (sort) {
      case SongSort.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SongSort.artist:
        list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      case SongSort.dateAdded:
        list.sort((a, b) => (b.dateAdded ?? DateTime(1970))
            .compareTo(a.dateAdded ?? DateTime(1970)));
      case SongSort.duration:
        list.sort((a, b) => b.duration.compareTo(a.duration));
    }
    return list;
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<Song>? songs,
    Set<String>? favoriteIds,
    String? query,
    SongSort? sort,
    String? message,
  }) =>
      LibraryState(
        status: status ?? this.status,
        songs: songs ?? this.songs,
        favoriteIds: favoriteIds ?? this.favoriteIds,
        query: query ?? this.query,
        sort: sort ?? this.sort,
        message: message,
      );

  @override
  List<Object?> get props => [status, songs, favoriteIds, query, sort, message];
}
