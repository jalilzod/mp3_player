import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/library/library_state.dart';
import '../widgets/aurora_background.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass.dart';
import '../widgets/library_sheets.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_list_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showNotice(BuildContext context, LibraryNotice notice) {
    final s = context.s;
    final cubit = context.read<LibraryCubit>();
    final (IconData icon, String text) = switch (notice.type) {
      LibraryNoticeType.imported => (
          Icons.check_circle_rounded,
          notice.skipped > 0
              ? s.importedWithSkipped(notice.count, notice.skipped)
              : s.importedSongs(notice.count),
        ),
      LibraryNoticeType.allDuplicates => (Icons.info_rounded, s.allAlreadyInLibrary),
      LibraryNoticeType.importFailed => (Icons.error_rounded, s.importFailed),
      LibraryNoticeType.deleted => (Icons.delete_rounded, s.songRemoved),
      LibraryNoticeType.restored => (Icons.restore_rounded, s.restoredSongs(notice.count)),
    };
    final song = notice.song;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
        duration: Duration(seconds: notice.type == LibraryNoticeType.deleted ? 4 : 3),
        content: Row(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
        action: notice.type == LibraryNoticeType.deleted && song != null
            ? SnackBarAction(
                label: s.undo,
                textColor: AppColors.primaryLight,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  cubit.undoDelete(song);
                },
              )
            : null,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            bottom: false,
            child: BlocConsumer<LibraryCubit, LibraryState>(
              listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
              listener: (context, state) => _showNotice(context, state.notice!),
              builder: (context, state) => Column(
                children: [
                  _Entrance(delay: 0, child: _Header(state: state)),
                  _Entrance(
                    delay: 80,
                    child: _SearchField(controller: _searchController),
                  ),
                  _Entrance(
                    delay: 160,
                    child: _Tabs(
                      controller: _tabs,
                      favoritesCount: state.favoritesCount,
                    ),
                  ),
                  Expanded(child: _buildBody(context, state)),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(top: false, child: MiniPlayer()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state) {
    final s = context.s;
    switch (state.status) {
      case LibraryStatus.initial:
      case LibraryStatus.loading:
        return const Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
        );
      case LibraryStatus.permissionDenied:
        return const _PermissionView();
      case LibraryStatus.error:
        return Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: s.somethingWentWrong,
            subtitle: state.message ?? '',
            actionLabel: s.tryAgain,
            actionIcon: Icons.refresh_rounded,
            onAction: context.read<LibraryCubit>().load,
          ),
        );
      case LibraryStatus.loaded:
        return TabBarView(
          controller: _tabs,
          children: [
            SongListView(
              songs: state.visibleSongs,
              library: state,
              emptyIcon: state.query.isEmpty
                  ? Icons.library_music_rounded
                  : Icons.search_off_rounded,
              emptyTitle: state.query.isEmpty ? s.noMusicFound : s.noResults,
              emptySubtitle:
                  state.query.isEmpty ? s.noMusicHint : s.tryDifferentSearch,
              showImportOnEmpty: state.query.isEmpty,
            ),
            SongListView(
              songs: state.favoriteSongs,
              library: state,
              emptyIcon: Icons.favorite_rounded,
              emptyTitle: s.noFavoritesYet,
              emptySubtitle: s.noFavoritesHint,
            ),
          ],
        );
    }
  }
}

/// Fades + slides a header element in once, with a small delay.
class _Entrance extends StatelessWidget {
  final int delay;
  final Widget child;
  const _Entrance({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 550 + delay),
      curve: Interval(delay / (550 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, -14 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final LibraryState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.greeting(DateTime.now().hour),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (r) => AppColors.titleGradient.createShader(r),
                  child: Text(
                    s.myMusic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.tune_rounded,
            tooltip: s.settings,
            onTap: () => LibrarySheets.showSettings(context),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.swap_vert_rounded,
            tooltip: s.sort,
            onTap: () => LibrarySheets.showSort(context),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.add_rounded,
            tooltip: s.importSongs,
            filled: true,
            onTap: state.isImporting ? null : cubit.importMusic,
            child: state.isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _focused ? AppColors.glassStrong : AppColors.glass,
        border: Border.all(
          color: _focused
              ? AppColors.primaryLight.withValues(alpha: 0.6)
              : AppColors.glassBorder,
        ),
        boxShadow: _focused ? AppColors.glow(AppColors.primary, strength: 0.35) : null,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, _) => TextField(
          controller: widget.controller,
          focusNode: _focus,
          onChanged: cubit.search,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: context.s.searchHint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _focused ? AppColors.primaryLight : AppColors.textTertiary,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      widget.controller.clear();
                      cubit.search('');
                      _focus.unfocus();
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final TabController controller;
  final int favoritesCount;
  const _Tabs({required this.controller, required this.favoritesCount});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.glow(AppColors.primary, strength: 0.45),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.library_music_rounded, size: 18),
                const SizedBox(width: 6),
                Flexible(child: Text(s.allSongs, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, size: 18),
                const SizedBox(width: 6),
                Flexible(child: Text(s.favorites, overflow: TextOverflow.ellipsis)),
                if (favoritesCount > 0) ...[
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Container(
                      key: ValueKey(favoritesCount),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$favoritesCount',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<LibraryCubit>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: EmptyState(
          icon: Icons.music_note_rounded,
          title: s.allowAccessTitle,
          subtitle: s.allowAccessBody,
          actionLabel: s.grantAccess,
          actionIcon: Icons.lock_open_rounded,
          onAction: cubit.load,
          secondary: TextButton(
            onPressed: cubit.openSettings,
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
            child: Text(s.openSettings),
          ),
        ),
      ),
    );
  }
}
