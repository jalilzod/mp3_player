import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/playback_enums.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/library/library_state.dart';
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
                listenWhen: (a, b) => b.message != null && a.message != b.message,
                listener: (context, state) {
                  if (state.status != LibraryStatus.error && state.message != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.message!)));
                  }
                },
                builder: (context, state) => Column(
                  children: [
                    _Header(state: state),
                    _SearchField(controller: _searchController),
                    _Tabs(controller: _tabs, favoritesCount: state.favoriteIds.length),
                    Expanded(child: _buildBody(state)),
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

  Widget _buildBody(LibraryState state) {
    switch (state.status) {
      case LibraryStatus.initial:
      case LibraryStatus.loading:
        return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary));
      case LibraryStatus.permissionDenied:
        return const _PermissionView();
      case LibraryStatus.error:
        return Center(child: Text(state.message ?? 'Something went wrong'));
      case LibraryStatus.loaded:
        return TabBarView(
          controller: _tabs,
          children: [
            SongListView(
              songs: state.visibleSongs,
              library: state,
              emptyIcon: Icons.library_music_outlined,
              emptyTitle: state.query.isEmpty ? 'No music found' : 'No results',
              emptySubtitle: state.query.isEmpty
                  ? 'Add music to your device or tap + to import songs.'
                  : 'Try a different search.',
            ),
            SongListView(
              songs: state.favoriteSongs,
              library: state,
              emptyIcon: Icons.favorite_border_rounded,
              emptyTitle: 'No favorites yet',
              emptySubtitle: 'Tap the heart on any song to add it here.',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (r) => AppColors.accentGradient.createShader(r),
            child: const Text(
              'Mariam music',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<SongSort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: state.sort,
            onSelected: cubit.changeSort,
            itemBuilder: (_) => SongSort.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(
                            s == state.sort
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: s == state.sort
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(s.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            tooltip: 'Import songs',
            onPressed: cubit.importMusic,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
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
            hintText: 'Search songs, artists, albums',
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
          const Tab(text: 'All songs'),
          Tab(text: favoritesCount > 0 ? 'Favorites ($favoritesCount)' : 'Favorites'),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView();

  @override
  Widget build(BuildContext context) {
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
          const Text('Allow access to your music',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'We need permission to find the songs stored on your device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<LibraryCubit>().load(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('Grant access'),
          ),
          TextButton(
            onPressed: () => context.read<LibraryCubit>().openSettings(),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}