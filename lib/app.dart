import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/music/presentation/cubit/library/library_cubit.dart';
import 'features/music/presentation/cubit/player/player_cubit.dart';
import 'features/music/presentation/pages/home_page.dart';

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LibraryCubit>(create: (_) => sl<LibraryCubit>()..load()),
        BlocProvider<PlayerCubit>(create: (_) => sl<PlayerCubit>()),
      ],
      child: MaterialApp(
        title: 'Music',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomePage(),
      ),
    );
  }
}
