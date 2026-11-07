import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../domain/entities/playback_enums.dart';
import '../cubit/library/library_cubit.dart';
import '../utils/song_display.dart';
import 'glass.dart';

class LibrarySheets {
  LibrarySheets._();

  static void showSort(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    final current = cubit.state.sort;
    final s = context.s;

    IconData iconFor(SongSort sort) => switch (sort) {
          SongSort.title => Icons.sort_by_alpha_rounded,
          SongSort.artist => Icons.person_rounded,
          SongSort.dateAdded => Icons.schedule_rounded,
          SongSort.duration => Icons.timer_outlined,
        };

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(s.sort),
              for (final sort in SongSort.values)
                SheetOption(
                  icon: iconFor(sort),
                  label: sort.label(s),
                  selected: sort == current,
                  onTap: () {
                    cubit.changeSort(sort);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Language + restoring songs removed from the list.
  static void showSettings(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final library = context.read<LibraryCubit>();
    final current = localeCubit.state.languageCode;
    final hidden = library.state.hiddenCount;
    final s = context.s;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(s.settings),
              _SectionLabel(s.language),
              for (final lang in AppStrings.supported)
                SheetOption(
                  icon: Icons.translate_rounded,
                  label: lang.languageName,
                  selected: lang.code == current,
                  onTap: () {
                    localeCubit.setLanguage(lang.code);
                    Navigator.pop(sheetContext);
                  },
                ),
              if (hidden > 0) ...[
                const SizedBox(height: 8),
                SheetOption(
                  icon: Icons.restore_rounded,
                  label: s.restoreRemovedSongs,
                  subtitle: s.restoreRemovedHint(hidden),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    library.restoreHiddenSongs();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8C6C82),
          ),
        ),
      ),
    );
  }
}
