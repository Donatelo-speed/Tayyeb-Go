import '../services/currency_service.dart';

class CurrencyHelper {
  static double get exchangeRate => CurrencyService.exchangeRate;
  static DateTime? get lastUpdated => CurrencyService.lastUpdated;
  
  static double usdToSyp(double usd) => CurrencyService.usdToSyp(usd);
  static double sypToUsd(double syp) => CurrencyService.sypToUsd(syp);
  
  static String formatSYP(double amount) => CurrencyService.formatSYP(amount);
  
  static String formatPrice(double usd, {bool showBoth = true}) {
    if (showBoth) {
      return CurrencyService.formatPrice(usd);
    }
    return '\$$usd';
  }
  
  static Future<void> refreshRate() => CurrencyService.fetchExchangeRate(forceRefresh: true);
}