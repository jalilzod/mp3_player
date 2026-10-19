import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the selected app language and remembers it between launches.
/// Default: Russian.
class LocaleCubit extends Cubit<Locale> {
  static const _key = 'app_language';
  static const defaultCode = 'ru';
  static const supportedLocales = [Locale('ru'), Locale('en')];

  final SharedPreferences _prefs;

  LocaleCubit(this._prefs)
      : super(Locale(_prefs.getString(_key) ?? defaultCode));

  Future<void> setLanguage(String code) async {
    if (code == state.languageCode) return;
    await _prefs.setString(_key, code);
    emit(Locale(code));
  }
}
