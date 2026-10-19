import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.album,
    required super.uri,
    required super.duration,
    super.artworkId,
    super.albumId,
    super.dateAdded,
  });

  /// From the Android MediaStore (see MainActivity.kt).
  factory SongModel.fromMediaStore(Map<dynamic, dynamic> map) {
    final id = (map['id'] as num).toInt();
    final artist = map['artist'] as String?;
    final album = map['album'] as String?;
    final title = map['title'] as String?;
    final dateAdded = (map['dateAdded'] as num?)?.toInt();

    return SongModel(
      id: 'lib_$id',
      title: (title == null || title.isEmpty) ? 'Unknown title' : title,
      // Empty = unknown; the UI shows a translated "Unknown artist/album".
      artist: (artist == null || artist == '<unknown>') ? '' : artist,
      album: album ?? '',
      uri: map['uri'] as String,
      duration: Duration(milliseconds: (map['duration'] as num?)?.toInt() ?? 0),
      artworkId: id,
      albumId: (map['albumId'] as num?)?.toInt(),
      dateAdded: dateAdded != null && dateAdded > 0
          ? DateTime.fromMillisecondsSinceEpoch(dateAdded * 1000)
          : null,
    );
  }

  /// From a raw audio file in the app's documents folder.
  factory SongModel.fromFile(File file) {
    final name = p.basenameWithoutExtension(file.path);
    // "Artist - Title.mp3" convention
    final parts = name.split(' - ');
    final hasArtist = parts.length >= 2;
    DateTime? modified;
    try {
      modified = file.lastModifiedSync();
    } catch (_) {}
    return SongModel(
      id: 'file_${file.path.hashCode}',
      title: hasArtist ? parts.sublist(1).join(' - ').trim() : name,
      artist: hasArtist ? parts.first.trim() : '',
      album: '',
      uri: file.path,
      duration: Duration.zero, // resolved by the player once loaded
      dateAdded: modified,
    );
  }
}
