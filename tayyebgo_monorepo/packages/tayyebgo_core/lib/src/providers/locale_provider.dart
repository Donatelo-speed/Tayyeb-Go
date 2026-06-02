import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale;

  LocaleProvider(this._locale);

  String get locale => _locale;
  bool get isArabic => _locale == 'ar';

  Future<void> setLocale(String code) async {
    _locale = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', code);
  }
}
