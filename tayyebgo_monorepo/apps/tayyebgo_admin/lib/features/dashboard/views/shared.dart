import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart' as top_bar_impl;
import '../../../core/widgets/responsive_builder.dart' as resp_impl;
import '../../../core/widgets/tab_item.dart' as tab_impl;
import '../../../core/widgets/app_kpi_card.dart' as kpi_impl;
import '../../../core/widgets/app_card.dart' as card_impl;
import '../../../core/widgets/app_empty_state.dart' as empty_impl;
import '../../../core/widgets/app_activity_feed.dart' as feed_impl;
import '../../../core/widgets/stagger_item.dart' as stagger_impl;
import '../../../core/widgets/side_nav.dart' as nav_impl;

export '../admin_helper.dart';
export '../../../core/widgets/widgets.dart';
export '../../../core/error_handling/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Legacy aliases — keep old view files compiling while pointing at the
// new design-system widgets. Constructor signatures match the originals so
// existing call sites keep working.
// ─────────────────────────────────────────────────────────────────────────────

class TabItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge;
  const TabItem(this.label, this.icon, {this.activeIcon, this.badge});

  tab_impl.TabItem toNew() => tab_impl.TabItem(
        label,
        icon,
        activeIcon: activeIcon,
        badge: badge,
      );
}

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? breadcrumb;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const GlobalAppBar({
    super.key,
    required this.title,
    this.breadcrumb,
    this.actions,
    this.onBack,
    this.onMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => top_bar_impl.AppTopBar(
        title: title,
        breadcrumb: breadcrumb,
        actions: actions,
        onBack: onBack,
        onMenu: onMenu,
      );
}

class SideNav extends StatelessWidget {
  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool collapsed;
  final VoidCallback? onToggle;
  final VoidCallback? onCloseDrawer;
  final List<int> moreIndices;
  final Set<int> badges;

  const SideNav({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.collapsed = false,
    this.onToggle,
    this.onCloseDrawer,
    this.moreIndices = const [],
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) => nav_impl.SideNav(
        tabs: tabs.map((t) => t.toNew()).toList(),
        selectedIndex: selectedIndex,
        onTap: onTap,
        collapsed: collapsed,
        onToggle: onToggle,
        onCloseDrawer: onCloseDrawer,
        moreIndices: moreIndices,
        badges: badges,
      );
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final String? subtitle;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return kpi_impl.AppKpiCard(
      title: title,
      value: value,
      icon: icon,
      gradient: gradient.colors,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => empty_impl.AppEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class RecentActivityFeed extends StatelessWidget {
  final int limit;
  const RecentActivityFeed({super.key, this.limit = 10});

  @override
  Widget build(BuildContext context) => feed_impl.AppActivityFeed(limit: limit);
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => resp_impl.ResponsiveBuilder(
        builder: (ctx, layout) => builder(ctx, layout.isMobile, layout.isTablet),
      );
}

class StaggerItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggerItem({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) => stagger_impl.StaggerItem(index: index, child: child);
}

BoxDecoration cardDeco(BuildContext context) {
  return card_impl.appCardDecoration(context);
}

BoxDecoration cardDecoBordered(BuildContext context, {Color? borderColor}) {
  return card_impl.appCardBorderedDecoration(context, borderColor: borderColor);
}

Container pageContainer(BuildContext context, {required Widget child}) {
  return card_impl.pageContainer(context, child: child);
}
