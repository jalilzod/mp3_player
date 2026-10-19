import 'package:flutter/material.dart';

import '../../domain/entities/song.dart';
import 'song_artwork.dart';

/// Artwork shown as a spinning vinyl record. Spins while playing,
/// slows to a stop when paused, and scales slightly with play state.
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
    duration: const Duration(seconds: 18),
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
    final inner = size * 0.62;

    return AnimatedScale(
      scale: widget.isPlaying ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: RotationTransition(
          turns: _spin,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vinyl disc with grooves
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF2A2A2A), Color(0xFF0A0A0A), Color(0xFF1C1C1C)],
                    stops: [0.0, 0.7, 1.0],
                  ),
                ),
              ),
              ...List.generate(5, (i) {
                final d = inner + (size - inner) * (i + 1) / 6;
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05), width: 1),
                  ),
                );
              }),
              // Album art label
              Hero(
                tag: 'now-playing-artwork',
                child: ClipOval(
                  child: SongArtwork(
                    song: widget.song,
                    size: inner,
                    radius: inner / 2,
                    quality: 100,
                  ),
                ),
              ),
              // Spindle hole
              Container(
                width: size * 0.06,
                height: size * 0.06,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B0B12),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
