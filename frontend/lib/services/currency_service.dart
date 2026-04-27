import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CurrencyService extends ChangeNotifier {
  static double _exchangeRate = 13000.0;
  static DateTime? _lastFetch;
  static bool _isLoading = false;

  static double get exchangeRate => _exchangeRate;
  static DateTime? get lastUpdated => _lastFetch;
  static bool get isLoading => _isLoading;

  static double usdToSyp(double usd) => usd * _exchangeRate;
  static double sypToUsd(double syp) => syp / _exchangeRate;

  static String formatSYP(double amount) => '${amount.toStringAsFixed(0)} ل.س';
  static String formatPrice(double usd) => '\$${usd.toStringAsFixed(2)}';

  static Future<void> fetchExchangeRate({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _lastFetch != null && DateTime.now().difference(_lastFetch!).inHours < 1) return;

    _isLoading = true;
    try {
      final resp = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['rates']?['SYP'] != null) {
          _exchangeRate = (data['rates']['SYP'] as num).toDouble();
          _lastFetch = DateTime.now();
        }
      }
    } catch (e) {
      // ignore errors
    } finally {
      _isLoading = false;
    }
  }
}