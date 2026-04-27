import 'package:intl/intl.dart';
import '../theme/omni_theme.dart';
import 'package:flutter/material.dart';

class CurrencyFormatter {
  static final _sypFormat = NumberFormat('#,###');

  static String formatUSD(double amount) => '\$${amount.toStringAsFixed(2)}';

  static String formatSYP(double syp) => '${_sypFormat.format(syp.toInt())} ₤';

  static double usdToSyp(double usd) => usd * 13000;

  static String formatDualPrice(double usd) {
    final syp = usdToSyp(usd);
    return '${formatUSD(usd)} · ${formatSYP(syp)}';
  }

  static Widget buildDualPrice(double usd, {TextStyle? usdStyle, TextStyle? sypStyle}) {
    final syp = usdToSyp(usd);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(formatUSD(usd), style: usdStyle ?? TextStyle(fontWeight: FontWeight.bold, color: OmniTheme.primaryColor)),
        const SizedBox(width: 6),
        Text(formatSYP(syp), style: sypStyle ?? TextStyle(fontSize: 11, color: OmniTheme.textMuted)),
      ],
    );
  }
}