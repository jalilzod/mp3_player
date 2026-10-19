import 'package:flutter/services.dart';

/// Talks to the native code in android/.../MainActivity.kt.
class MediaStoreChannel {
  static const _channel = MethodChannel('music_player/media_store');

  /// Asks for the "read music" permission. Returns true when granted.
  Future<bool> requestPermission() async {
    final granted = await _channel.invokeMethod<bool>('requestPermission');
    return granted ?? false;
  }

  /// Opens this app's page in Android settings.
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  Future<List<Map<dynamic, dynamic>>> querySongs() async {
    final result = await _channel.invokeMethod<List<dynamic>>('querySongs');
    return (result ?? const []).cast<Map<dynamic, dynamic>>();
  }

  Future<Uint8List?> getArtwork({
    required int id,
    int? albumId,
    int size = 300,
  }) {
    return _channel.invokeMethod<Uint8List>('getArtwork', {
      'id': id,
      'albumId': albumId,
      'size': size,
    });
  }
}