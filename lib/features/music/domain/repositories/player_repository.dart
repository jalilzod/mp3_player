import '../entities/playback_enums.dart';
import '../entities/position_data.dart';
import '../entities/song.dart';

/// Playback engine contract (implemented with just_audio in the data layer).
abstract class PlayerRepository {
  Stream<Song?> get currentSongStream;
  Stream<List<Song>> get queueStream;
  Stream<bool> get playingStream;
  Stream<bool> get bufferingStream;
  Stream<bool> get completedStream;
  Stream<PositionData> get positionDataStream;
  Stream<bool> get shuffleStream;
  Stream<RepeatMode> get repeatModeStream;
  Stream<double> get speedStream;

  Future<void> playQueue(List<Song> songs, {int index = 0, bool shuffle = false});
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> seekBy(Duration offset);
  Future<void> next();
  Future<void> previous();
  Future<void> skipToSong(Song song);
  Future<void> setShuffle(bool enabled);
  Future<void> setRepeatMode(RepeatMode mode);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}
