import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.customAction,
    this.iconColor,
    this.iconSize = 64,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return TGEmptyState(
      icon: icon,
      title: title,
      description: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
