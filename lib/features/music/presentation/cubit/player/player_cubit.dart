import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/playback_enums.dart';
import '../../../domain/entities/position_data.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/player_repository.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerViewState> {
  final PlayerRepository _player;
  final List<StreamSubscription> _subs = [];
  Timer? _sleepTimer;

  PlayerCubit(this._player) : super(const PlayerViewState()) {
    _subs.addAll([
      _player.currentSongStream.listen((s) {
        if (s != null) emit(state.copyWith(currentSong: s));
      }),
      _player.queueStream.listen((q) => emit(state.copyWith(queue: q))),
      _player.playingStream.listen((p) => emit(state.copyWith(isPlaying: p))),
      _player.bufferingStream.listen((b) => emit(state.copyWith(isBuffering: b))),
      _player.shuffleStream.listen((s) => emit(state.copyWith(shuffle: s))),
      _player.repeatModeStream.listen((r) => emit(state.copyWith(repeatMode: r))),
      _player.speedStream.listen((s) => emit(state.copyWith(speed: s))),
      _player.completedStream.listen((done) {
        if (done) _player.stop();
      }),
    ]);
  }

  /// High-frequency stream; consumed directly by the seek bar widget
  /// so the whole UI does not rebuild every 200ms.
  Stream<PositionData> get positionStream => _player.positionDataStream;

  Future<void> playSongs(List<Song> songs, {int index = 0}) =>
      _player.playQueue(songs, index: index);

  Future<void> shuffleAll(List<Song> songs) =>
      _player.playQueue(songs, shuffle: true);

  void togglePlay() => state.isPlaying ? _player.pause() : _player.play();
  void stop() => _player.stop();
  void next() => _player.next();
  void previous() => _player.previous();
  void forward10() => _player.seekBy(AppConstants.seekStep);
  void rewind10() => _player.seekBy(-AppConstants.seekStep);
  void seek(Duration position) => _player.seek(position);
  void skipTo(Song song) => _player.skipToSong(song);

  void toggleShuffle() => _player.setShuffle(!state.shuffle);

  void cycleRepeat() {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    _player.setRepeatMode(next);
  }

  void setSpeed(double speed) => _player.setSpeed(speed);

  /// Pass null to cancel.
  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      emit(state.copyWith(clearSleep: true));
      return;
    }
    _sleepTimer = Timer(duration, () {
      _player.pause();
      emit(state.copyWith(clearSleep: true));
    });
    emit(state.copyWith(sleepAt: DateTime.now().add(duration)));
  }

  @override
  Future<void> close() async {
    _sleepTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await _player.dispose();
    return super.close();
  }
}
