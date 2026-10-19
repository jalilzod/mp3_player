import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import 'equalizer_bars.dart';
import 'song_artwork.dart';

class PlayerSheets {
  PlayerSheets._();

  /// "Up next" queue. Tap a song to jump to it.
  static void showQueue(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          builder: (context, controller) =>
              BlocBuilder<PlayerCubit, PlayerViewState>(
            builder: (context, state) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Up next',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: state.queue.length,
                    itemBuilder: (_, i) {
                      final song = state.queue[i];
                      final isCurrent = song.id == state.currentSong?.id;
                      return ListTile(
                        leading: SongArtwork(song: song, size: 44, radius: 10),
                        title: Text(song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? AppColors.secondary : Colors.white,
                              fontWeight: FontWeight.w600,
                            )),
                        subtitle: Text(song.artist,
                            maxLines: 1,
                            style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: isCurrent
                            ? EqualizerBars(animating: state.isPlaying)
                            : null,
                        onTap: () => cubit.skipTo(song),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showSpeed(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Playback speed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: AppConstants.playbackSpeeds.map((s) {
                  final selected = cubit.state.speed == s;
                  return ChoiceChip(
                    label: Text('${s}x'),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    onSelected: (_) {
                      cubit.setSpeed(s);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSleepTimer(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    final active = cubit.state.sleepAt;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sleep timer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (active != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Stops in ${active.difference(DateTime.now()).inMinutes + 1} min',
                  style: const TextStyle(color: AppColors.secondary),
                ),
              ),
            const SizedBox(height: 8),
            ...AppConstants.sleepTimerOptions.map((d) => ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: Text(d.inMinutes >= 60
                      ? '${d.inHours} hour'
                      : '${d.inMinutes} minutes'),
                  onTap: () {
                    cubit.setSleepTimer(d);
                    Navigator.pop(context);
                  },
                )),
            if (active != null)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined,
                    color: AppColors.secondary),
                title: const Text('Turn off timer',
                    style: TextStyle(color: AppColors.secondary)),
                onTap: () {
                  cubit.setSleepTimer(null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
