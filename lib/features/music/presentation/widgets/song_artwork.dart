import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/artwork_loader.dart';
import '../../domain/entities/song.dart';

/// Embedded album art, or a colorful gradient placeholder.
class SongArtwork extends StatefulWidget {
  final Song song;
  final double size;
  final double radius;

  /// Kept for compatibility with existing callers (higher = sharper image).
  final int quality;

  const SongArtwork({
    super.key,
    required this.song,
    this.size = 52,
    this.radius = 14,
    this.quality = 50,
  });

  @override
  State<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends State<SongArtwork> {
  final ArtworkLoader _loader = sl<ArtworkLoader>();
  late Future<Uint8List?> _future;

  /// Small sizes share one cache entry; large ones (player screen) get a sharper one.
  int get _requestSize => widget.size > 120 ? 800 : 200;

  @override
  void initState() {
    super.initState();
    _future = _loader.load(widget.song, size: _requestSize);
  }

  @override
  void didUpdateWidget(covariant SongArtwork old) {
    super.didUpdateWidget(old);
    if (old.song.id != widget.song.id || old.size != widget.size) {
      _future = _loader.load(widget.song, size: _requestSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(
        song: widget.song, size: widget.size, radius: widget.radius);
    if (widget.song.artworkId == null) return placeholder;

    return FutureBuilder<Uint8List?>(
      future: _future,
      initialData: _loader.peek(widget.song, _requestSize),
      builder: (context, snap) {
        final bytes = snap.data;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: bytes == null
              ? placeholder
              : ClipRRect(
                  key: ValueKey(widget.song.id),
                  borderRadius: BorderRadius.circular(widget.radius),
                  child: Image.memory(
                    bytes,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => placeholder,
                  ),
                ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Song song;
  final double size;
  final double radius;
  const _Placeholder({required this.song, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.gradientFor(song.album + song.artist);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.9), size: size * 0.45),
    );
  }
}
