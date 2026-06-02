import 'package:flutter/material.dart';

class TabItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge;
  final String? group;
  const TabItem(this.label, this.icon, {this.activeIcon, this.badge, this.group});
}
