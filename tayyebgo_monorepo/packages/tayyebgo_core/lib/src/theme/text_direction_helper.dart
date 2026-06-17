import 'package:flutter/widgets.dart';
import '../localization/app_localizations.dart';

TextDirection getTextDirection() {
  return AppLocalizations.currentLocale.isRtl
      ? TextDirection.rtl
      : TextDirection.ltr;
}

TextDirection getTextDirectionForLocale(AppLocale locale) {
  return locale.isRtl ? TextDirection.rtl : TextDirection.ltr;
}

class RTLWrapper extends StatelessWidget {
  final Widget child;
  final AppLocale? locale;

  const RTLWrapper({
    super.key,
    required this.child,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLocale = locale ?? AppLocalizations.currentLocale;
    return Directionality(
      textDirection: getTextDirectionForLocale(effectiveLocale),
      child: child,
    );
  }
}
