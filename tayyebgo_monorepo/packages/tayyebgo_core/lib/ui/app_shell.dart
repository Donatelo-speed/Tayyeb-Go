import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../presentation/theme/app_colors.dart';
import '../src/providers/auth_provider.dart';

class AppShellItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const AppShellItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class AppShell extends StatelessWidget {
  final List<AppShellItem> items;
  final int selectedIndex;
  final Widget child;
  final String title;
  final String? primaryActionRoute;
  final IconData primaryActionIcon;
  final String primaryActionTooltip;

  const AppShell({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.child,
    required this.title,
    this.primaryActionRoute,
    this.primaryActionIcon = Icons.add_rounded,
    this.primaryActionTooltip = 'Create',
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1280;

    if (isMobile) return _buildMobileLayout(context);
    if (isTablet) return _buildTabletLayout(context);
    return _buildDesktopLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          const _NotificationBell(),
          const _ProfileMenu(),
        ],
      ),
      body: child,
      bottomNavigationBar: _CustomBottomNav(
        selectedIndex: selectedIndex,
        items: items,
        primaryActionRoute: primaryActionRoute,
        primaryActionIcon: primaryActionIcon,
        primaryActionTooltip: primaryActionTooltip,
        onTap: (i) => context.go(items[i].route),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          const _NotificationBell(),
          const _ProfileMenu(),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(items[i].route),
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface,
            selectedIconTheme:
                const IconThemeData(color: AppColors.primary, size: 22),
            unselectedIconTheme:
                IconThemeData(color: AppColors.textMuted, size: 22),
            selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
            unselectedLabelTextStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _SideNav(
            items: items,
            selectedIndex: selectedIndex,
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(
            child: Column(
              children: [
                _DesktopAppBar(title: title),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final List<AppShellItem> items;
  final int selectedIndex;

  const _SideNav({required this.items, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant_menu_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'TayyebGo',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isSelected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          const _ProfileMenu(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _DesktopAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const _NotificationBell(),
              const SizedBox(width: 8),
              const _ProfileMenu(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined, size: 22),
      color: AppColors.textSecondary,
      onPressed: () {},
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial =
        (auth.user?.displayName ?? auth.user?.email ?? 'A')
            .characters.first
            .toUpperCase();
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
      onSelected: (value) async {
        if (value == 'profile') {
          context.go('/profile');
        } else if (value == 'settings') {
          context.go('/settings');
        } else if (value == 'logout') {
          await context.read<AuthProvider>().logout();
          if (context.mounted) context.go('/login');
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'profile', child: Text('Profile')),
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Sign Out', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class _CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<AppShellItem> items;
  final String? primaryActionRoute;
  final IconData primaryActionIcon;
  final String primaryActionTooltip;
  final ValueChanged<int> onTap;

  const _CustomBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.primaryActionRoute,
    required this.primaryActionIcon,
    required this.primaryActionTooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const fabSize = 56.0;
    const navHeight = 80.0;
    final hasPrimaryAction = primaryActionRoute != null;
    final visibleItems = items.length > 5 ? items.take(5).toList() : items;

    return SizedBox(
      height: navHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: navHeight,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < visibleItems.length; i++) ...[
                  _buildNavItem(i),
                  if (hasPrimaryAction && i == 1)
                    const SizedBox(width: fabSize + 16),
                ],
              ],
            ),
          ),
          if (hasPrimaryAction)
            Positioned(
              top: -8,
              child: Tooltip(
                message: primaryActionTooltip,
                child: GestureDetector(
                  onTap: () => context.go(primaryActionRoute!),
                  child: Container(
                    width: fabSize,
                    height: fabSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      primaryActionIcon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    if (index >= items.length) return const Expanded(child: SizedBox.shrink());
    final item = items[index];
    final isSelected = index == selectedIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
