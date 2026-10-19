import 'package:equatable/equatable.dart';

import '../../../domain/entities/playback_enums.dart';
import '../../../domain/entities/song.dart';

/// Named PlayerViewState to avoid clashing with just_audio's PlayerState.
class PlayerViewState extends Equatable {
  final Song? currentSong;
  final List<Song> queue;
  final bool isPlaying;
  final bool isBuffering;
  final bool shuffle;
  final RepeatMode repeatMode;
  final double speed;
  final DateTime? sleepAt;

  const PlayerViewState({
    this.currentSong,
    this.queue = const [],
    this.isPlaying = false,
    this.isBuffering = false,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
    this.speed = 1.0,
    this.sleepAt,
  });

  bool get hasSong => currentSong != null;

  PlayerViewState copyWith({
    Song? currentSong,
    List<Song>? queue,
    bool? isPlaying,
    bool? isBuffering,
    bool? shuffle,
    RepeatMode? repeatMode,
    double? speed,
    DateTime? sleepAt,
    bool clearSleep = false,
  }) =>
      PlayerViewState(
        currentSong: currentSong ?? this.currentSong,
        queue: queue ?? this.queue,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        shuffle: shuffle ?? this.shuffle,
        repeatMode: repeatMode ?? this.repeatMode,
        speed: speed ?? this.speed,
        sleepAt: clearSleep ? null : (sleepAt ?? this.sleepAt),
      );

  @override
  List<Object?> get props =>
      [currentSong, queue, isPlaying, isBuffering, shuffle, repeatMode, speed, sleepAt];
}
