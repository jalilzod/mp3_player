import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/playback_enums.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/library/library_state.dart';
import '../utils/song_display.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: BlocConsumer<LibraryCubit, LibraryState>(
                listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
                listener: (context, state) {
                  final s = context.s;
                  final notice = state.notice!;
                  final text = switch (notice.type) {
                    LibraryNoticeType.imported => s.importedSongs(notice.count),
                    LibraryNoticeType.importFailed => s.importFailed,
                  };
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(text)));
                },
                builder: (context, state) => Column(
                  children: [
                    _Header(state: state),
                    _SearchField(controller: _searchController),
                    _Tabs(controller: _tabs, favoritesCount: state.favoriteIds.length),
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
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state) {
    final s = context.s;
    switch (state.status) {
      case LibraryStatus.initial:
      case LibraryStatus.loading:
        return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary));
      case LibraryStatus.permissionDenied:
        return const _PermissionView();
      case LibraryStatus.error:
        return Center(child: Text(s.somethingWentWrong));
      case LibraryStatus.loaded:
        return TabBarView(
          controller: _tabs,
          children: [
            SongListView(
              songs: state.visibleSongs,
              library: state,
              emptyIcon: Icons.library_music_outlined,
              emptyTitle: state.query.isEmpty ? s.noMusicFound : s.noResults,
              emptySubtitle:
                  state.query.isEmpty ? s.noMusicHint : s.tryDifferentSearch,
            ),
            SongListView(
              songs: state.favoriteSongs,
              library: state,
              emptyIcon: Icons.favorite_border_rounded,
              emptyTitle: s.noFavoritesYet,
              emptySubtitle: s.noFavoritesHint,
            ),
          ],
        );
    }
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
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: ShaderMask(
              shaderCallback: (r) => AppColors.accentGradient.createShader(r),
              child: Text(
                s.myMusic,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: s.language,
            onPressed: () => _showLanguagePicker(context),
            icon: const Icon(Icons.language_rounded),
          ),
          PopupMenuButton<SongSort>(
            tooltip: s.sort,
            icon: const Icon(Icons.sort_rounded),
            initialValue: state.sort,
            onSelected: cubit.changeSort,
            itemBuilder: (_) => SongSort.values
                .map((sort) => PopupMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(
                            sort == state.sort
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: sort == state.sort
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(sort.label(s)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            tooltip: s.importSongs,
            onPressed: cubit.importMusic,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final current = localeCubit.state.languageCode;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.s.language,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final lang in AppStrings.supported)
              ListTile(
                leading: Icon(
                  lang.code == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: lang.code == current
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
                title: Text(lang.languageName),
                onTap: () {
                  localeCubit.setLanguage(lang.code);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: cubit.search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.s.searchHint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      cubit.search('');
                      FocusScope.of(context).unfocus();
                    },
                  ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
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
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(11),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        tabs: [
          Tab(text: s.allSongs),
          Tab(
            text: favoritesCount > 0
                ? s.favoritesWithCount(favoritesCount)
                : s.favorites,
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(s.allowAccessTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            s.allowAccessBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<LibraryCubit>().load(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text(s.grantAccess),
          ),
          TextButton(
            onPressed: () => context.read<LibraryCubit>().openSettings(),
            child: Text(s.openSettings),
          ),
        ],
      ),
    );
  }
}
