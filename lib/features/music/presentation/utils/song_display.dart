import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/playback_enums.dart';
import '../../domain/entities/song.dart';

/// Localized display text for song fields that may be empty.
extension SongDisplay on Song {
  String artistText(AppStrings s) => artist.isEmpty ? s.unknownArtist : artist;
  String albumText(AppStrings s) => album.isEmpty ? s.unknownAlbum : album;
}

/// Localized name of a sort option.
extension SongSortText on SongSort {
  String label(AppStrings s) => switch (this) {
        SongSort.title => s.sortTitle,
        SongSort.artist => s.sortArtist,
        SongSort.dateAdded => s.sortRecentlyAdded,
        SongSort.duration => s.sortDuration,
      };
}
