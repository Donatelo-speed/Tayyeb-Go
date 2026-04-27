import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/root_wrapper.dart';
import 'theme/omni_theme.dart';
import 'services/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  CurrencyService.fetchExchangeRate();
  
  final prefs = await SharedPreferences.getInstance();
  String savedLocale = prefs.getString('app_locale') ?? 'en';
  if (savedLocale != 'en' && savedLocale != 'ar') savedLocale = 'en';
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  runApp(OmniMarketApp(savedLocale: savedLocale));
}

class OmniMarketApp extends StatelessWidget {
  final String savedLocale;
  const OmniMarketApp({super.key, required this.savedLocale});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => LocaleBox(savedLocale)),
      ],
      child: Builder(
        builder: (context) {
          return Consumer<LocaleBox>(
            builder: (context, localeBox, _) {
              return ScrollConfiguration(
                behavior: _OmniScrollBehavior(),
                child: MaterialApp(
                  title: 'OmniMarket',
                  debugShowCheckedModeBanner: false,
                  locale: Locale(localeBox.locale),
                  theme: OmniTheme.lightTheme.copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: OmniTheme.primaryColor,
                      selectionColor: OmniTheme.primaryColor.withOpacity(0.3),
                      selectionHandleColor: OmniTheme.primaryColor,
                    ),
                  ),
                  darkTheme: OmniTheme.darkTheme,
                  themeMode: ThemeMode.system,
                  home: const RootWrapper(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LocaleBox extends ChangeNotifier {
  String _locale;
  
  LocaleBox(this._locale);
  
  String get locale => _locale;
  bool get isArabic => _locale == 'ar';
  bool get isEnglish => _locale == 'en';
  
  String t(String en, String ar) => isArabic ? ar : en;
  
  void setLocale(String locale, {bool persist = true}) async {
    _locale = locale == 'ar' ? 'ar' : 'en';
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', _locale);
    }
    notifyListeners();
  }
  
  void toggle() {
    setLocale(_locale == 'en' ? 'ar' : 'en');
  }
}

class _OmniScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}