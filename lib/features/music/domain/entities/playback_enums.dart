enum RepeatMode { off, all, one }

enum SongSort { title, artist, dateAdded, duration }

extension SongSortLabel on SongSort {
  String get label => switch (this) {
        SongSort.title => 'Title',
        SongSort.artist => 'Artist',
        SongSort.dateAdded => 'Recently added',
        SongSort.duration => 'Duration',
      };
}
