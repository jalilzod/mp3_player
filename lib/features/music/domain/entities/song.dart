import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;

  /// content://, file:// or plain file path.
  final String uri;
  final Duration duration;

  /// Id used to load embedded artwork from the device library (null for imported files).
  final int? artworkId;
  final int? albumId;
  final DateTime? dateAdded;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    required this.duration,
    this.artworkId,
    this.albumId,
    this.dateAdded,
  });

  @override
  List<Object?> get props => [id];
}
