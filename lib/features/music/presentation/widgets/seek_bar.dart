import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/entities/position_data.dart';

/// Pink gradient seek bar. The track grows and the thumb glows while dragging;
/// position is tracked locally during the drag so the thumb never jumps.
class SeekBar extends StatefulWidget {
  final Stream<PositionData> stream;
  final ValueChanged<Duration> onSeek;

  const SeekBar({super.key, required this.stream, required this.onSeek});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  static const _sidePadding = 24.0;
  double? _drag; // 0..1 while dragging

  void _updateDrag(double dx, double width) {
    final v = ((dx - _sidePadding) / width).clamp(0.0, 1.0);
    setState(() => _drag = v);
  }

  void _commit(Duration total) {
    final v = _drag;
    if (v != null && total > Duration.zero) {
      widget.onSeek(Duration(milliseconds: (total.inMilliseconds * v).round()));
      HapticFeedback.selectionClick();
    }
    setState(() => _drag = null);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: widget.stream,
      builder: (context, snap) {
        final data = snap.data ?? PositionData.zero;
        final total = data.duration;
        final progress = _drag ?? data.progress;
        final buffered = total.inMilliseconds == 0
            ? 0.0
            : (data.buffered.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
        final shownPosition = _drag != null
            ? Duration(milliseconds: (total.inMilliseconds * _drag!).round())
            : data.position;

        return Column(
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth - _sidePadding * 2;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) => _updateDrag(d.localPosition.dx, width),
                  onHorizontalDragUpdate: (d) => _updateDrag(d.localPosition.dx, width),
                  onHorizontalDragEnd: (_) => _commit(total),
                  onTapDown: (d) => _updateDrag(d.localPosition.dx, width),
                  onTapUp: (_) => _commit(total),
                  onTapCancel: () => setState(() => _drag = null),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _drag != null ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (_, active, __) => SizedBox(
                      height: 36,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SeekPainter(
                          progress: progress,
                          buffered: buffered,
                          active: active,
                          sidePadding: _sidePadding,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(shownPosition.toClock(),
                      style: TextStyle(
                        color: _drag != null
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  Text(
                    total.toClock(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
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

class _SeekPainter extends CustomPainter {
  final double progress;
  final double buffered;
  final double active; // 0..1 (dragging animation)
  final double sidePadding;

  _SeekPainter({
    required this.progress,
    required this.buffered,
    required this.active,
    required this.sidePadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = sidePadding;
    final width = size.width - sidePadding * 2;
    final cy = size.height / 2;
    final trackH = 4 + 3 * active;
    final r = Radius.circular(trackH / 2);

    RRect bar(double fraction) => RRect.fromLTRBR(
        left, cy - trackH / 2, left + width * fraction, cy + trackH / 2, r);

    // Inactive + buffered
    canvas.drawRRect(bar(1), Paint()..color = Colors.white.withValues(alpha: 0.12));
    canvas.drawRRect(bar(buffered), Paint()..color = Colors.white.withValues(alpha: 0.12));

    // Active gradient
    final fullRect = Rect.fromLTWH(left, cy - trackH / 2, width, trackH);
    if (progress > 0) {
      canvas.drawRRect(
        bar(progress),
        Paint()..shader = AppColors.accentGradient.createShader(fullRect),
      );
    }

    // Thumb with glow
    final thumb = Offset(left + width * progress, cy);
    final thumbR = 6.5 + 3 * active;
    canvas.drawCircle(
      thumb,
      thumbR + 4,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.35 + 0.25 * active)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(thumb, thumbR, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SeekPainter old) =>
      old.progress != progress || old.buffered != buffered || old.active != active;
}
