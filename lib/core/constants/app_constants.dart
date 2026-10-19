class AppConstants {
  AppConstants._();

  /// How far the ±10s buttons jump.
  static const seekStep = Duration(seconds: 10);

  /// Pressing "previous" after this point restarts the song instead.
  static const restartThreshold = Duration(seconds: 3);

  /// Ignore ringtones / voice notes shorter than this.
  static const minSongDuration = Duration(seconds: 30);

  /// Folder inside app documents where imported music is copied.
  static const importFolder = 'Music';

  static const audioExtensions = {
    '.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.opus', '.alac', '.aiff',
  };

  static const playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  static const sleepTimerOptions = [
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
  ];
}
