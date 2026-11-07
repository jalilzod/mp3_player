import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/playback_enums.dart' as pe;
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import 'pressable.dart';

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
            _IconAction(
              icon: Icons.replay_10_rounded,
              size: 30,
              color: Colors.white70,
              onTap: cubit.rewind10,
            ),
            _IconAction(
              icon: Icons.skip_previous_rounded,
              size: 42,
              onTap: cubit.previous,
            ),
            _BigPlayButton(
              isPlaying: state.isPlaying,
              isBuffering: state.isBuffering,
              onTap: cubit.togglePlay,
            ),
            _IconAction(
              icon: Icons.skip_next_rounded,
              size: 42,
              onTap: cubit.next,
            ),
            _IconAction(
              icon: Icons.forward_10_rounded,
              size: 30,
              color: Colors.white70,
              onTap: cubit.forward10,
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Secondary row: shuffle | stop | repeat
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToggleIcon(
              icon: Icons.shuffle_rounded,
              active: state.shuffle,
              onTap: cubit.toggleShuffle,
              tooltip: context.s.shuffle,
            ),
            _ToggleIcon(
              icon: Icons.stop_rounded,
              active: false,
              onTap: cubit.stop,
              tooltip: context.s.stop,
            ),
            _ToggleIcon(
              icon: state.repeatMode == pe.RepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              active: state.repeatMode != pe.RepeatMode.off,
              onTap: cubit.cycleRepeat,
              tooltip: context.s.repeat,
            ),
          ],
        ),
      ],
    );
  }
}

/// Big gradient play / pause button with "sound wave" rings while playing.
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
    with TickerProviderStateMixin {
  late final AnimationController _icon = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    value: widget.isPlaying ? 1 : 0,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _BigPlayButton old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _icon.forward();
        _pulse.repeat();
      } else {
        _icon.reverse();
        _pulse.stop();
        _pulse.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _icon.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const buttonSize = 76.0;
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Two expanding rings, half a cycle apart.
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                for (final offset in const [0.0, 0.5])
                  _ring(((_pulse.value + offset) % 1.0), buttonSize),
              ],
            ),
          ),
          Pressable(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withValues(alpha: widget.isPlaying ? 0.6 : 0.3),
                    blurRadius: widget.isPlaying ? 34 : 18,
                    spreadRadius: widget.isPlaying ? 2 : 0,
                  ),
                ],
              ),
              child: widget.isBuffering
                  ? const Padding(
                      padding: EdgeInsets.all(25),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
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
          ),
        ],
      ),
    );
  }

  Widget _ring(double t, double base) {
    if (!widget.isPlaying) return const SizedBox.shrink();
    final size = base * (1 + 0.36 * t);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.45 * (1 - t)),
          width: 2,
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color color;

  const _IconAction({
    required this.icon,
    required this.size,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.82,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
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
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.glass,
            border: Border.all(
              color: active
                  ? AppColors.primaryLight.withValues(alpha: 0.55)
                  : AppColors.glassBorder,
            ),
            boxShadow: active ? AppColors.glow(AppColors.primary, strength: 0.4) : null,
          ),
          child: Icon(icon,
              size: 22, color: active ? AppColors.primaryLight : Colors.white70),
        ),
      ),
    );
  }
}
