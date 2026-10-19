class PositionData {
  final Duration position;
  final Duration buffered;
  final Duration duration;

  const PositionData(this.position, this.buffered, this.duration);

  static const zero = PositionData(Duration.zero, Duration.zero, Duration.zero);

  double get progress => duration.inMilliseconds == 0
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}
