import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppState extends ChangeNotifier {
  final Box settingsBox;

  late Locale _locale;
  late ThemeMode _themeMode;

  AppState({required this.settingsBox}) {
    final localeCode = settingsBox.get('locale', defaultValue: 'en') as String;
    final themeModeName =
        settingsBox.get('themeMode', defaultValue: 'dark') as String;
    _locale = Locale(localeCode);
    _themeMode = themeModeName == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    settingsBox.put('locale', locale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    setLocale(
        _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en'));
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    settingsBox.put('themeMode', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
