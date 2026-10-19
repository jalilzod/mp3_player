import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/entities/position_data.dart';

/// Seek bar that tracks drag locally so the thumb doesn't jump while dragging.
class SeekBar extends StatefulWidget {
  final Stream<PositionData> stream;
  final ValueChanged<Duration> onSeek;

  const SeekBar({super.key, required this.stream, required this.onSeek});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: widget.stream,
      builder: (context, snap) {
        final data = snap.data ?? PositionData.zero;
        final maxMs = data.duration.inMilliseconds.toDouble();
        final max = maxMs <= 0 ? 1.0 : maxMs;
        final value =
            (_dragValue ?? data.position.inMilliseconds.toDouble()).clamp(0.0, max);
        final buffered = data.buffered.inMilliseconds.toDouble().clamp(0.0, max);

        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Buffered track
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: buffered / max,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(
                          Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    inactiveTrackColor: Colors.transparent,
                    activeTrackColor: AppColors.secondary,
                    thumbColor: Colors.white,
                    thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: _dragValue != null ? 9 : 6),
                  ),
                  child: Slider(
                    min: 0,
                    max: max,
                    value: value,
                    onChanged: (v) => setState(() => _dragValue = v),
                    onChangeEnd: (v) {
                      widget.onSeek(Duration(milliseconds: v.round()));
                      setState(() => _dragValue = null);
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(Duration(milliseconds: value.round()).toClock(),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5)),
                  Text(
                    data.duration.toClock(),
                    style:
                        const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
