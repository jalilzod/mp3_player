import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/l10n/app_strings.dart';
import 'core/l10n/locale_cubit.dart';
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
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
        BlocProvider<LibraryCubit>(create: (_) => sl<LibraryCubit>()..load()),
        BlocProvider<PlayerCubit>(create: (_) => sl<PlayerCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) => MaterialApp(
          title: AppStrings.forCode(locale.languageCode).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: locale,
          supportedLocales: LocaleCubit.supportedLocales,
          // Translates built-in widgets (tooltips, text selection menus, etc.)
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomePage(),
        ),
      ),
    );
  }
}
