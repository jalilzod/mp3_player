import 'package:flutter/widgets.dart';

/// All user-visible texts. Add a getter here + in both languages below.
abstract class AppStrings {
  const AppStrings();

  /// Language code ('ru', 'en').
  String get code;
  String get languageName;

  // App / home
  String get appTitle;
  String get myMusic;
  String get sort;
  String get importSongs;
  String get language;
  String get searchHint;
  String get allSongs;
  String get favorites;
  String favoritesWithCount(int count);
  String songsCount(int count);
  String get shuffle;

  // Empty states
  String get noMusicFound;
  String get noResults;
  String get noMusicHint;
  String get tryDifferentSearch;
  String get noFavoritesYet;
  String get noFavoritesHint;
  String get somethingWentWrong;
  String get tryAgain;

  // Permission
  String get allowAccessTitle;
  String get allowAccessBody;
  String get grantAccess;
  String get openSettings;

  // Import messages
  String importedSongs(int count);
  String importedWithSkipped(int added, int skipped);
  String get allAlreadyInLibrary;
  String get importFailed;
  String get importing;

  // Greeting + actions
  String greeting(int hour);
  String get playAll;
  String get play;
  String get more;
  String get delete;
  String get songRemoved;
  String get undo;
  String get addToFavorites;
  String get removeFromFavorites;
  String get swipeHint;

  // Settings
  String get settings;
  String get restoreRemovedSongs;
  String restoreRemovedHint(int count);
  String restoredSongs(int count);

  // Sorting
  String get sortTitle;
  String get sortArtist;
  String get sortRecentlyAdded;
  String get sortDuration;

  // Player
  String get nothingPlaying;
  String get nowPlaying;
  String get stop;
  String get repeat;
  String get queue;
  String get upNext;
  String get sleep;
  String get sleepTimer;
  String get playbackSpeed;
  String get turnOffTimer;
  String stopsInMinutes(int minutes);
  String minutesShort(int minutes);
  String durationOption(Duration d);

  // Song placeholders
  String get unknownArtist;
  String get unknownAlbum;

  static const supported = <AppStrings>[RuStrings(), EnStrings()];

  static AppStrings forCode(String code) =>
      supported.firstWhere((s) => s.code == code, orElse: () => supported.first);

  /// Usage: `AppStrings.of(context).myMusic` or `context.s.myMusic`.
  /// Rebuilds automatically when the app language changes.
  static AppStrings of(BuildContext context) =>
      forCode(Localizations.localeOf(context).languageCode);
}

extension AppStringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}

// ─────────────────────────── Russian (default) ───────────────────────────

class RuStrings extends AppStrings {
  const RuStrings();

  /// Russian plural: 1 песня, 2 песни, 5 песен.
  static String _plural(int n, String one, String few, String many) {
    final mod10 = n % 10, mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    return many;
  }

  @override String get code => 'ru';
  @override String get languageName => 'Русский';

  @override String get appTitle => 'Музыка';
  @override String get myMusic => 'Марям музыка';
  @override String get sort => 'Сортировка';
  @override String get importSongs => 'Добавить песни';
  @override String get language => 'Язык';
  @override String get searchHint => 'Поиск песен, исполнителей, альбомов';
  @override String get allSongs => 'Все песни';
  @override String get favorites => 'Избранное';
  @override String favoritesWithCount(int count) => 'Избранное ($count)';
  @override String songsCount(int count) =>
      '$count ${_plural(count, 'песня', 'песни', 'песен')}';
  @override String get shuffle => 'Перемешать';

  @override String get noMusicFound => 'Maryam не найдена';
  @override String get noResults => 'Ничего не найдено';
  @override String get noMusicHint =>
      'Добавьте музыку на устройство или нажмите +, чтобы импортировать песни.';
  @override String get tryDifferentSearch => 'Попробуйте другой запрос.';
  @override String get noFavoritesYet => 'Пока нет избранного';
  @override String get noFavoritesHint =>
      'Нажмите на сердечко у песни, чтобы добавить её сюда.';
  @override String get somethingWentWrong => 'Что-то пошло не так';
  @override String get tryAgain => 'Повторить';

  @override String get allowAccessTitle => 'Разрешите доступ к музыке';
  @override String get allowAccessBody =>
      'Нам нужно разрешение, чтобы найти песни на вашем устройстве.';
  @override String get grantAccess => 'Разрешить';
  @override String get openSettings => 'Открыть настройки';

  @override String importedSongs(int count) =>
      '${_plural(count, 'Добавлена', 'Добавлено', 'Добавлено')} $count '
      '${_plural(count, 'песня', 'песни', 'песен')}';
  @override String importedWithSkipped(int added, int skipped) =>
      '${importedSongs(added)} · $skipped уже '
      '${_plural(skipped, 'была', 'были', 'были')} в библиотеке';
  @override String get allAlreadyInLibrary => 'Эти песни уже есть в библиотеке';
  @override String get importFailed => 'Не удалось добавить песни';
  @override String get importing => 'Добавление…';

  @override String greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Доброе утро';
    if (hour >= 12 && hour < 18) return 'Добрый день';
    if (hour >= 18 && hour < 23) return 'Добрый вечер';
    return 'Доброй ночи';
  }
  @override String get playAll => 'Слушать';
  @override String get play => 'Воспроизвести';
  @override String get more => 'Ещё';
  @override String get delete => 'Удалить';
  @override String get songRemoved => 'Песня удалена';
  @override String get undo => 'Отменить';
  @override String get addToFavorites => 'Добавить в избранное';
  @override String get removeFromFavorites => 'Убрать из избранного';
  @override String get swipeHint => 'Смахните влево, чтобы удалить';

  @override String get settings => 'Настройки';
  @override String get restoreRemovedSongs => 'Вернуть удалённые песни';
  @override String restoreRemovedHint(int count) =>
      '$count ${_plural(count, 'песня', 'песни', 'песен')} из памяти телефона';
  @override String restoredSongs(int count) =>
      '${_plural(count, 'Возвращена', 'Возвращено', 'Возвращено')} $count '
      '${_plural(count, 'песня', 'песни', 'песен')}';

  @override String get sortTitle => 'Название';
  @override String get sortArtist => 'Исполнитель';
  @override String get sortRecentlyAdded => 'Недавно добавленные';
  @override String get sortDuration => 'Длительность';

  @override String get nothingPlaying => 'Ничего не играет';
  @override String get nowPlaying => 'СЕЙЧАС ИГРАЕТ';
  @override String get stop => 'Стоп';
  @override String get repeat => 'Повтор';
  @override String get queue => 'Очередь';
  @override String get upNext => 'Далее';
  @override String get sleep => 'Сон';
  @override String get sleepTimer => 'Таймер сна';
  @override String get playbackSpeed => 'Скорость воспроизведения';
  @override String get turnOffTimer => 'Выключить таймер';
  @override String stopsInMinutes(int minutes) => 'Остановится через $minutes мин';
  @override String minutesShort(int minutes) => '$minutes мин';
  @override String durationOption(Duration d) => d.inMinutes >= 60
      ? '${d.inHours} ${_plural(d.inHours, 'час', 'часа', 'часов')}'
      : '${d.inMinutes} ${_plural(d.inMinutes, 'минута', 'минуты', 'минут')}';

  @override String get unknownArtist => 'Неизвестный исполнитель';
  @override String get unknownAlbum => 'Неизвестный альбом';
}

// ─────────────────────────────── English ───────────────────────────────

class EnStrings extends AppStrings {
  const EnStrings();

  static String _s(int n) => n == 1 ? '' : 's';

  @override String get code => 'en';
  @override String get languageName => 'English';

  @override String get appTitle => 'Music';
  @override String get myMusic => 'Maryam Music';
  @override String get sort => 'Sort';
  @override String get importSongs => 'Import songs';
  @override String get language => 'Language';
  @override String get searchHint => 'Search songs, artists, albums';
  @override String get allSongs => 'All songs';
  @override String get favorites => 'Favorites';
  @override String favoritesWithCount(int count) => 'Favorites ($count)';
  @override String songsCount(int count) => '$count song${_s(count)}';
  @override String get shuffle => 'Shuffle';

  @override String get noMusicFound => 'No music found';
  @override String get noResults => 'No results';
  @override String get noMusicHint =>
      'Add music to your device or tap + to import songs.';
  @override String get tryDifferentSearch => 'Try a different search.';
  @override String get noFavoritesYet => 'No favorites yet';
  @override String get noFavoritesHint => 'Tap the heart on any song to add it here.';
  @override String get somethingWentWrong => 'Something went wrong';
  @override String get tryAgain => 'Try again';

  @override String get allowAccessTitle => 'Allow access to your music';
  @override String get allowAccessBody =>
      'We need permission to find the songs stored on your device.';
  @override String get grantAccess => 'Grant access';
  @override String get openSettings => 'Open settings';

  @override String importedSongs(int count) => 'Imported $count song${_s(count)}';
  @override String importedWithSkipped(int added, int skipped) =>
      '${importedSongs(added)} · $skipped already in library';
  @override String get allAlreadyInLibrary => 'These songs are already in your library';
  @override String get importFailed => 'Import failed';
  @override String get importing => 'Importing…';

  @override String greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    if (hour >= 18 && hour < 23) return 'Good evening';
    return 'Good night';
  }
  @override String get playAll => 'Play';
  @override String get play => 'Play';
  @override String get more => 'More';
  @override String get delete => 'Delete';
  @override String get songRemoved => 'Song deleted';
  @override String get undo => 'Undo';
  @override String get addToFavorites => 'Add to favorites';
  @override String get removeFromFavorites => 'Remove from favorites';
  @override String get swipeHint => 'Swipe left to delete';

  @override String get settings => 'Settings';
  @override String get restoreRemovedSongs => 'Restore deleted songs';
  @override String restoreRemovedHint(int count) =>
      '$count song${_s(count)} from phone storage';
  @override String restoredSongs(int count) => 'Restored $count song${_s(count)}';

  @override String get sortTitle => 'Title';
  @override String get sortArtist => 'Artist';
  @override String get sortRecentlyAdded => 'Recently added';
  @override String get sortDuration => 'Duration';

  @override String get nothingPlaying => 'Nothing playing';
  @override String get nowPlaying => 'NOW PLAYING';
  @override String get stop => 'Stop';
  @override String get repeat => 'Repeat';
  @override String get queue => 'Queue';
  @override String get upNext => 'Up next';
  @override String get sleep => 'Sleep';
  @override String get sleepTimer => 'Sleep timer';
  @override String get playbackSpeed => 'Playback speed';
  @override String get turnOffTimer => 'Turn off timer';
  @override String stopsInMinutes(int minutes) => 'Stops in $minutes min';
  @override String minutesShort(int minutes) => '${minutes}m';
  @override String durationOption(Duration d) => d.inMinutes >= 60
      ? '${d.inHours} hour${_s(d.inHours)}'
      : '${d.inMinutes} minutes';

  @override String get unknownArtist => 'Unknown artist';
  @override String get unknownAlbum => 'Unknown album';
}
