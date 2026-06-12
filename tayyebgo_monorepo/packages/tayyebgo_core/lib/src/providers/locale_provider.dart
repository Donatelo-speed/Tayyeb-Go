import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale;
  static const String _key = 'app_locale';

  LocaleProvider(this._locale);

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  /// Load saved locale from SharedPreferences.
  static Future<LocaleProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    return LocaleProvider(Locale(code));
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  Future<void> toggleLocale() async {
    final newCode = isArabic ? 'en' : 'ar';
    await setLocale(newCode);
  }
}
