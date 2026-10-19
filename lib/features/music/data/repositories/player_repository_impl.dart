import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/playback_enums.dart';
import '../../domain/entities/position_data.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final AudioPlayer _player;
  PlayerRepositoryImpl(this._player);

  final Map<String, Song> _songsById = {};
  List<Song> _queue = const [];

  // ---------------- Streams ----------------

  @override
  Stream<Song?> get currentSongStream => _player.sequenceStateStream
      .map((state) => _songFromTag(state?.currentSource?.tag))
      .distinct();

  @override
  Stream<List<Song>> get queueStream => _player.sequenceStateStream.map(
        (state) => (state?.effectiveSequence ?? const <IndexedAudioSource>[])
            .map((src) => _songFromTag(src.tag))
            .whereType<Song>()
            .toList(),
      );

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Stream<bool> get bufferingStream => _player.processingStateStream
      .map((s) => s == ProcessingState.loading || s == ProcessingState.buffering)
      .distinct();

  @override
  Stream<bool> get completedStream => _player.processingStateStream
      .map((s) => s == ProcessingState.completed)
      .distinct();

  @override
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (pos, buf, dur) => PositionData(pos, buf, dur ?? Duration.zero),
      );

  @override
  Stream<bool> get shuffleStream => _player.shuffleModeEnabledStream;

  @override
  Stream<RepeatMode> get repeatModeStream => _player.loopModeStream.map(
        (m) => switch (m) {
          LoopMode.off => RepeatMode.off,
          LoopMode.all => RepeatMode.all,
          LoopMode.one => RepeatMode.one,
        },
      );

  @override
  Stream<double> get speedStream => _player.speedStream;

  // ---------------- Commands ----------------

  @override
  Future<void> playQueue(List<Song> songs,
      {int index = 0, bool shuffle = false}) async {
    if (songs.isEmpty) return;
    final sameQueue = _sameIds(songs, _queue) && _player.audioSource != null;

    if (!sameQueue) {
      _queue = List.unmodifiable(songs);
      _songsById
        ..clear()
        ..addEntries(songs.map((s) => MapEntry(s.id, s)));

      final source = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: songs.map(_toAudioSource).toList(),
      );
      await _player.setAudioSource(source,
          initialIndex: index, initialPosition: Duration.zero);
    }

    if (shuffle) {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
      await _player.seek(Duration.zero, index: _firstEffectiveIndex());
    } else if (sameQueue) {
      await _player.seek(Duration.zero, index: index);
    }
    _player.play(); // not awaited: completes only when playback pauses
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() => _player.pause();

  /// "Stop" = pause and rewind to the start (keeps the queue loaded).
  @override
  Future<void> stop() async {
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> seekBy(Duration offset) async {
    final duration = _player.duration ?? Duration.zero;
    var target = _player.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target >= duration) {
      if (_player.hasNext) {
        await _player.seekToNext();
        return;
      }
      target = duration - const Duration(milliseconds: 500);
    }
    await _player.seek(target);
  }

  @override
  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_queue.isNotEmpty) {
      // Wrap around to the first song.
      await _player.seek(Duration.zero, index: _firstEffectiveIndex());
    }
  }

  @override
  Future<void> previous() async {
    if (_player.position > AppConstants.restartThreshold || !_player.hasPrevious) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToSong(Song song) async {
    final i = _queue.indexWhere((s) => s.id == song.id);
    if (i >= 0) {
      await _player.seek(Duration.zero, index: i);
      _player.play();
    }
  }

  @override
  Future<void> setShuffle(bool enabled) async {
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(RepeatMode mode) => _player.setLoopMode(
        switch (mode) {
          RepeatMode.off => LoopMode.off,
          RepeatMode.all => LoopMode.all,
          RepeatMode.one => LoopMode.one,
        },
      );

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() => _player.dispose();

  // ---------------- Helpers ----------------

  /// First song in the current (possibly shuffled) play order.
  int _firstEffectiveIndex() {
    final List<int>? indices = _player.effectiveIndices;
    if (indices == null || indices.isEmpty) return 0;
    return indices.first;
  }

  Song? _songFromTag(Object? tag) =>
      tag is MediaItem ? _songsById[tag.id] : null;

  bool _sameIds(List<Song> a, List<Song> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  AudioSource _toAudioSource(Song song) {
    final uri = song.uri.startsWith(RegExp(r'[a-z\-]+://'))
        ? Uri.parse(song.uri)
        : Uri.file(song.uri);

    Uri? artUri;
    if (Platform.isAndroid && song.albumId != null) {
      artUri = Uri.parse('content://media/external/audio/albumart/${song.albumId}');
    }

    return AudioSource.uri(
      uri,
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration == Duration.zero ? null : song.duration,
        artUri: artUri,
      ),
    );
  }
}