import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double full = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));

  static const BorderRadius brCard = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brButton = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brInput = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brChip = BorderRadius.all(Radius.circular(full));
  static const BorderRadius brAvatar = BorderRadius.all(Radius.circular(full));
  static const BorderRadius brDialog = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brBottomSheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
  static const BorderRadius brBadge = BorderRadius.all(Radius.circular(full));
}
