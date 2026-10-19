import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/song.dart';
import 'media_store_channel.dart';

/// Loads embedded album art once and keeps it in a small memory cache.
class ArtworkLoader {
  final MediaStoreChannel _channel;
  ArtworkLoader(this._channel);

  static const _maxEntries = 300;
  final Map<String, Uint8List?> _cache = {};
  final Map<String, Future<Uint8List?>> _pending = {};

  String _key(Song song, int size) => '${song.artworkId}_$size';

  /// Already-loaded artwork (or null) — used to avoid a flicker on rebuild.
  Uint8List? peek(Song song, int size) => _cache[_key(song, size)];

  bool isLoaded(Song song, int size) => _cache.containsKey(_key(song, size));

  Future<Uint8List?> load(Song song, {int size = 300}) {
    if (song.artworkId == null || !Platform.isAndroid) {
      return Future.value(null);
    }
    final key = _key(song, size);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);

    return _pending[key] ??= _channel
        .getArtwork(id: song.artworkId!, albumId: song.albumId, size: size)
        .then<Uint8List?>((bytes) => bytes)
        .catchError((_) => null)
        .then((bytes) {
      _pending.remove(key);
      if (_cache.length >= _maxEntries) _cache.remove(_cache.keys.first);
      _cache[key] = bytes;
      return bytes;
    });
  }
}