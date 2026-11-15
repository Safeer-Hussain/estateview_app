import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedMode = _prefs.getString(AppConstants.prefThemeMode);
    if (savedMode == 'light') {
      emit(ThemeMode.light);
    } else {
      emit(ThemeMode.dark);
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setString(
      AppConstants.prefThemeMode,
      newMode == ThemeMode.light ? 'light' : 'dark',
    );
    emit(newMode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _prefs.setString(
      AppConstants.prefThemeMode,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
    emit(mode);
  }
}
