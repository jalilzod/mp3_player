import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/playback_enums.dart' as pe;
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';

class PlayerControls extends StatelessWidget {
  final PlayerViewState state;
  final PlayerCubit cubit;

  const PlayerControls({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main row: -10s | prev | play | next | +10s
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SeekStepButton(forward: false, onTap: cubit.rewind10),
            _PressableIcon(
              icon: Icons.skip_previous_rounded,
              size: 40,
              onTap: cubit.previous,
            ),
            _BigPlayButton(
              isPlaying: state.isPlaying,
              isBuffering: state.isBuffering,
              onTap: cubit.togglePlay,
            ),
            _PressableIcon(
              icon: Icons.skip_next_rounded,
              size: 40,
              onTap: cubit.next,
            ),
            _SeekStepButton(forward: true, onTap: cubit.forward10),
          ],
        ),
        const SizedBox(height: 22),
        // Secondary row: shuffle | stop | repeat
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToggleIcon(
              icon: Icons.shuffle_rounded,
              active: state.shuffle,
              onTap: cubit.toggleShuffle,
              tooltip: 'Shuffle',
            ),
            _ToggleIcon(
              icon: Icons.stop_rounded,
              active: false,
              onTap: cubit.stop,
              tooltip: 'Stop',
            ),
            _ToggleIcon(
              icon: state.repeatMode == pe.RepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              active: state.repeatMode != pe.RepeatMode.off,
              onTap: cubit.cycleRepeat,
              tooltip: 'Repeat',
            ),
          ],
        ),
      ],
    );
  }
}

class _BigPlayButton extends StatefulWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  const _BigPlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
  });

  @override
  State<_BigPlayButton> createState() => _BigPlayButtonState();
}

class _BigPlayButtonState extends State<_BigPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _icon = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.isPlaying ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _BigPlayButton old) {
    super.didUpdateWidget(old);
    widget.isPlaying ? _icon.forward() : _icon.reverse();
  }

  @override
  void dispose() {
    _icon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary
                  .withValues(alpha: widget.isPlaying ? 0.55 : 0.25),
              blurRadius: widget.isPlaying ? 32 : 16,
              spreadRadius: widget.isPlaying ? 2 : 0,
            ),
          ],
        ),
        child: widget.isBuffering
            ? const Padding(
                padding: EdgeInsets.all(26),
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Center(
                child: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: _icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _SeekStepButton extends StatelessWidget {
  final bool forward;
  final VoidCallback onTap;
  const _SeekStepButton({required this.forward, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressableIcon(
      icon: forward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
      size: 30,
      onTap: onTap,
      color: Colors.white70,
    );
  }
}

class _PressableIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color color;

  const _PressableIcon({
    required this.icon,
    required this.size,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  const _ToggleIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.secondary.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
          ),
          child: Icon(icon,
              size: 24,
              color: active ? AppColors.secondary : Colors.white70),
        ),
      ),
    );
  }
}

/// Shrinks slightly when pressed.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}