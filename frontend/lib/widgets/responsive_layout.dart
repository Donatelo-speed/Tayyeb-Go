import 'package:flutter/material.dart';
import '../theme/tayyebgo_theme.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) return desktop;
        if (constraints.maxWidth >= 600) return tablet ?? mobile;
        return mobile;
      },
    );
  }
}

class DashboardShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<DestItem> destinations;
  final List<Widget> screens;
  final Widget? header;

  const DashboardShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.screens,
    this.header,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class DestItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const DestItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _DashboardShellState extends State<DashboardShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(DashboardShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
    }
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onDestinationSelected(index);
  }

  List<NavigationRailDestination> get _railDests => widget.destinations
      .map((d) => NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ))
      .toList();

  List<NavigationDestination> get _navDests => widget.destinations
      .map((d) => NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: widget.header != null && widget.header is PreferredSizeWidget
            ? widget.header as PreferredSizeWidget
            : null,
        body: IndexedStack(
          index: _currentIndex,
          children: widget.screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTap,
          destinations: _navDests,
        ),
      ),
      desktop: Scaffold(
        appBar: widget.header != null
            ? widget.header as PreferredSizeWidget?
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTap,
              extended: true,
              minExtendedWidth: 200,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: TayyebGoTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.2)),
                          const Icon(Icons.delivery_dining,
                              size: 28, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tayyeb-Go',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: _railDests,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: widget.screens.isNotEmpty
                  ? widget.screens[_currentIndex]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
