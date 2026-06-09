import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'tab_item.dart';

class SideNav extends StatefulWidget {
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
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> {
  bool _moreExpanded = false;

  @override
  Widget build(BuildContext context) {
    final width = widget.collapsed ? 72.0 : 248.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: context.sidebarBgColor,
        border: Border(right: BorderSide(color: context.sidebarBorderColor, width: 1)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            _buildBrand(),
            const SizedBox(height: 16),
            Expanded(child: _buildNavList()),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 12 : 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.brSm,
            ),
            child: const Center(child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20)),
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TayyebGo',
                    style: AppTypography.bodyBold.copyWith(
                      color: context.sidebarTextColor,
                    ),
                  ),
                  Text(
                    'Admin Console',
                    style: AppTypography.label.copyWith(
                      color: context.sidebarMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavList() {
    final primary = <int>[];
    final more = <int>[];
    for (int i = 0; i < widget.tabs.length; i++) {
      if (widget.moreIndices.contains(i)) {
        more.add(i);
      } else {
        primary.add(i);
      }
    }

    final moreFirst = widget.moreIndices.isNotEmpty ? widget.moreIndices.first : 999;
    final showMore = _moreExpanded || widget.selectedIndex >= moreFirst;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        if (!widget.collapsed)
          _navLabel('MENU'),
        const SizedBox(height: 4),
        ...primary.map((i) => _buildNavItem(i, widget.tabs[i])),
        const SizedBox(height: 8),
        if (more.isNotEmpty) ...[
          if (!widget.collapsed)
            InkWell(
              onTap: () => setState(() => _moreExpanded = !_moreExpanded),
              borderRadius: AppRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Text('MORE', style: AppTypography.label.copyWith(color: context.sidebarMutedColor)),
                    const Spacer(),
                    Icon(showMore ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: context.sidebarMutedColor, size: 16),
                  ],
                ),
              ),
            ),
          if (showMore || widget.collapsed) ...more.map((i) => _buildNavItem(i, widget.tabs[i])),
        ],
      ],
    );
  }

  Widget _navLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Text(text, style: AppTypography.label.copyWith(color: context.sidebarMutedColor)),
    );
  }

  Widget _buildNavItem(int i, TabItem t) {
    final selected = widget.selectedIndex == i;
    final hasBadge = widget.badges.contains(i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onTap(i);
            if (widget.onCloseDrawer != null) widget.onCloseDrawer!();
          },
          borderRadius: AppRadius.brSm,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 12 : 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? context.sidebarActiveBgColor : Colors.transparent,
              borderRadius: AppRadius.brSm,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? (t.activeIcon ?? t.icon) : t.icon,
                  size: 20,
                  color: selected ? context.sidebarActiveColor : context.sidebarMutedColor,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.label,
                      style: AppTypography.body.copyWith(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? context.sidebarTextColor : context.sidebarMutedColor,
                      ),
                    ),
                  ),
                  if (hasBadge) TGBadge.count(count: int.tryParse(t.badge ?? '0') ?? 0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottom() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (widget.onToggle != null)
            InkWell(
              onTap: widget.onToggle,
              borderRadius: AppRadius.brSm,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.sidebarMutedColor.withValues(alpha: 0.04),
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(widget.collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: context.sidebarMutedColor, size: 18),
                    if (!widget.collapsed) ...[
                      const SizedBox(width: 8),
                      Text('Collapse', style: AppTypography.caption.copyWith(color: context.sidebarMutedColor)),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (!widget.collapsed) const _UserFooter(),
        ],
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.displayName ?? auth.user?.email ?? 'Admin';
    final initial = name.characters.first.toUpperCase();
    return InkWell(
      onTap: () => context.go('/dashboard?tab=14'),
      borderRadius: AppRadius.brSm,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.sidebarMutedColor.withValues(alpha: 0.04),
          borderRadius: AppRadius.brSm,
        ),
        child: Row(
          children: [
            TGAvatar(
              initials: initial,
              size: TGAvatarSize.sm,
              backgroundColor: context.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: AppTypography.caption.copyWith(color: context.sidebarTextColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  Text(auth.user?.email ?? 'admin', style: AppTypography.label.copyWith(color: context.sidebarMutedColor), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Semantics(
              label: 'Log out',
              button: true,
              child: InkWell(
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
                child: Icon(Icons.logout_rounded, size: 16, color: context.sidebarMutedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
