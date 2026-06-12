import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

extension LocalizationsExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
