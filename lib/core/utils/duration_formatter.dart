extension DurationFormatter on Duration {
  /// 3:07 or 1:02:45
  String toClock() {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }
}
