import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/song.dart';
import 'song_artwork.dart';

/// Artwork shown as a spinning vinyl record with a pink halo.
/// Spins while playing, glows brighter while playing, settles when paused.
class VinylArtwork extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  final double size;

  const VinylArtwork({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.size,
  });

  @override
  State<VinylArtwork> createState() => _VinylArtworkState();
}

class _VinylArtworkState extends State<VinylArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant VinylArtwork old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.isPlaying && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final label = size * 0.58;
    final playing = widget.isPlaying;

    return AnimatedScale(
      scale: playing ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: playing ? 0.5 : 0.18),
              blurRadius: playing ? 80 : 36,
              spreadRadius: playing ? 6 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 40,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _spin,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Disc
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFF2B1626), Color(0xFF0C050A), Color(0xFF221420)],
                        stops: [0.0, 0.74, 1.0],
                      ),
                    ),
                  ),
                  // Grooves
                  CustomPaint(
                    size: Size.square(size),
                    painter: _GroovesPainter(labelFraction: label / size),
                  ),
                  // Pink ring around the label
                  Container(
                    width: label + 8,
                    height: label + 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                    ),
                  ),
                  // Album art label (flies in from the mini player)
                  Hero(
                    tag: 'now-playing-artwork',
                    child: ClipOval(
                      child: SongArtwork(
                        song: widget.song,
                        size: label,
                        radius: label / 2,
                        quality: 100,
                      ),
                    ),
                  ),
                  // Spindle hole
                  Container(
                    width: size * 0.07,
                    height: size * 0.07,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                ],
              ),
            ),
            // Static light reflection (does not rotate → looks like real vinyl).
            IgnorePointer(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.13),
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                    stops: const [0, 0.35, 0.7, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroovesPainter extends CustomPainter {
  final double labelFraction;
  _GroovesPainter({required this.labelFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2 - 4;
    final inner = size.width * labelFraction / 2 + 8;
    const rings = 16;
    for (var i = 0; i <= rings; i++) {
      final r = inner + (outer - inner) * i / rings;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: i.isEven ? 0.06 : 0.025),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroovesPainter old) =>
      old.labelFraction != labelFraction;
}
