import 'package:audio_session/audio_session.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/locale_cubit.dart';
import '../../features/music/data/datasources/artwork_loader.dart';
import '../../features/music/data/datasources/favorites_local_datasource.dart';
import '../../features/music/data/datasources/media_store_channel.dart';
import '../../features/music/data/datasources/music_local_datasource.dart';
import '../../features/music/data/repositories/music_repository_impl.dart';
import '../../features/music/data/repositories/player_repository_impl.dart';
import '../../features/music/domain/repositories/music_repository.dart';
import '../../features/music/domain/repositories/player_repository.dart';
import '../../features/music/domain/usecases/get_favorite_ids.dart';
import '../../features/music/domain/usecases/get_songs.dart';
import '../../features/music/domain/usecases/import_songs.dart';
import '../../features/music/domain/usecases/open_app_settings.dart';
import '../../features/music/domain/usecases/request_permission.dart';
import '../../features/music/domain/usecases/toggle_favorite.dart';
import '../../features/music/presentation/cubit/library/library_cubit.dart';
import '../../features/music/presentation/cubit/player/player_cubit.dart';

/// Service locator.
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Audio session: pause on calls, duck for navigation, etc.
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());

  // External
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerLazySingleton<SharedPreferences>(() => prefs)
    ..registerLazySingleton<MediaStoreChannel>(() => MediaStoreChannel())
    ..registerLazySingleton<ArtworkLoader>(() => ArtworkLoader(sl()))
    ..registerLazySingleton<AudioPlayer>(() => AudioPlayer());

  // Data sources
  sl
    ..registerLazySingleton<MusicLocalDataSource>(
        () => MusicLocalDataSourceImpl(sl()))
    ..registerLazySingleton<FavoritesLocalDataSource>(
        () => FavoritesLocalDataSourceImpl(sl()));

  // Repositories
  sl
    ..registerLazySingleton<MusicRepository>(
        () => MusicRepositoryImpl(music: sl(), favorites: sl()))
    ..registerLazySingleton<PlayerRepository>(
        () => PlayerRepositoryImpl(sl()));

  // Use cases
  sl
    ..registerLazySingleton(() => RequestPermission(sl()))
    ..registerLazySingleton(() => GetSongs(sl()))
    ..registerLazySingleton(() => ImportSongs(sl()))
    ..registerLazySingleton(() => GetFavoriteIds(sl()))
    ..registerLazySingleton(() => ToggleFavorite(sl()))
    ..registerLazySingleton(() => OpenAppSettings(sl()));

  // Cubits
  sl
    ..registerFactory(() => LocaleCubit(sl()))
    ..registerFactory(() => LibraryCubit(
          requestPermission: sl(),
          getSongs: sl(),
          importSongs: sl(),
          getFavoriteIds: sl(),
          toggleFavorite: sl(),
          openAppSettings: sl(),
        ))
    ..registerFactory(() => PlayerCubit(sl()));
}
