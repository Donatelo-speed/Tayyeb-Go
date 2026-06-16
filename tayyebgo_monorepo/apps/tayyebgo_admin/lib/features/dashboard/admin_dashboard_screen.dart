import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'views/shared.dart';
import 'views/dashboard_view.dart';
import 'views/orders_view.dart';
import 'views/stores_view.dart';
import 'views/drivers_view.dart';
import 'views/customers_view.dart';
import 'views/finance_view.dart';
import 'views/support_view.dart';
import 'views/system_health_view.dart';
import 'views/settings_view.dart';
import 'views/profile_view.dart';
import 'views/approvals_view.dart';
import 'views/zones_view.dart';
import 'views/notifications_view.dart';
import 'views/marketing_view.dart';
import 'views/settlements_view.dart';
import 'views/operations_center_view.dart';
import 'views/subscriptions_view.dart';
import '../../../core/widgets/app_command_bar.dart' as cmdbar_impl;
import '../../../core/widgets/responsive_builder.dart' as resp;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarOpen = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int> _navHistory = [0];

  // Total tabs = 17 (Operations + Dashboard + 15 others).
  static const int _kTabCount = 17;

  // 6+6 grouped sidebar: indices 0..5 in MENU, 6..11 in MORE.
  // 12..15 are Operations, System Health, Settings, Profile (deep-linkable aliases).
  static const List<int> _moreIndices = [6, 7, 8, 9, 10, 11];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabRead) {
      _tabRead = true;
      _readTabFromRoute();
    }
  }

  bool _tabRead = false;

  void _readTabFromRoute() {
    final location = GoRouterState.of(context).uri.toString();
    final match = RegExp(r'tab=(\d+)').firstMatch(location);
    if (match != null) {
      final idx = int.tryParse(match.group(1)!) ?? 0;
      final mapped = _mapLegacyIndex(idx);
      if (mapped >= 0 && mapped < _kTabCount) {
        if (_selectedIndex != mapped) {
          setState(() {
            _selectedIndex = mapped;
            _navHistory.clear();
            _navHistory.add(0);
          });
        }
      }
    }
  }

  // Old query params (pre-grouping) map to the same logical destination.
  int _mapLegacyIndex(int idx) => idx;

  final List<TabItem> _tabs = const [
    TabItem('Dashboard', Icons.dashboard_rounded, activeIcon: Icons.dashboard_rounded),
    TabItem('Approvals', Icons.verified_outlined, activeIcon: Icons.verified_rounded),
    TabItem('Orders', Icons.receipt_long_rounded, activeIcon: Icons.receipt_rounded),
    TabItem('Stores', Icons.storefront_rounded, activeIcon: Icons.store_rounded),
    TabItem('Drivers', Icons.delivery_dining_rounded, activeIcon: Icons.delivery_dining),
    TabItem('Finance', Icons.account_balance_rounded, activeIcon: Icons.account_balance),
    TabItem('Customers', Icons.people_alt_rounded, activeIcon: Icons.people_alt),
    TabItem('Settlements', Icons.account_balance_wallet_rounded, activeIcon: Icons.account_balance_wallet),
    TabItem('Marketing', Icons.campaign_rounded, activeIcon: Icons.campaign),
    TabItem('Notifications', Icons.notifications_active_rounded, activeIcon: Icons.notifications),
    TabItem('Zones', Icons.location_on_rounded, activeIcon: Icons.location_on),
    TabItem('Support', Icons.support_agent_rounded, activeIcon: Icons.support_agent),
    TabItem('Operations', Icons.monitor_heart_rounded, activeIcon: Icons.monitor_heart),
    TabItem('System Health', Icons.health_and_safety_outlined, activeIcon: Icons.health_and_safety),
    TabItem('Settings', Icons.settings_rounded, activeIcon: Icons.settings),
    TabItem('Subscriptions', Icons.card_membership_rounded, activeIcon: Icons.card_membership),
    TabItem('Profile', Icons.person_rounded, activeIcon: Icons.person),
  ];

  void _onTabSelected(int i) {
    if (i == _selectedIndex) return;
    setState(() {
      if (_navHistory.isEmpty || _navHistory.last != _selectedIndex) {
        _navHistory.add(_selectedIndex);
      }
      _selectedIndex = i;
    });
  }

  void _onBack() {
    if (_navHistory.isEmpty) return;
    setState(() {
      _selectedIndex = _navHistory.removeLast();
    });
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
  }

  String _breadcrumbPath() {
    if (_selectedIndex == 0) return '';
    final visible = <String>['Dashboard'];
    for (final i in _navHistory) {
      if (i >= 0 && i < _tabs.length) visible.add(_tabs[i].label);
    }
    visible.add(_tabs[_selectedIndex].label);
    return visible.join(' › ');
  }

  @override
  Widget build(BuildContext context) {
    return cmdbar_impl.AppCommandBarHotkey(
      child: resp.ResponsiveBuilder(
        builder: (context, layout) {
          if (layout == resp.AppLayout.mobile) return _buildMobileLayout();
          if (layout == resp.AppLayout.tablet) return _buildTabletLayout();
          return _buildDesktopLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            SideNav(
              tabs: _tabs,
              selectedIndex: _selectedIndex,
              onTap: _onTabSelected,
              collapsed: !_sidebarOpen,
              onToggle: _toggleSidebar,
              moreIndices: _moreIndices,
            ),
            Expanded(
              child: Column(
                children: [
                  GlobalAppBar(
                    title: _tabs[_selectedIndex].label,
                    breadcrumb: _selectedIndex == 0 ? null : _breadcrumbPath(),
                    onBack: _selectedIndex == 0 ? null : _onBack,
                    onMenu: _toggleSidebar,
                  ),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) {
          _onBack();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.backgroundColor,
        drawer: Drawer(
          child: SideNav(
            tabs: _tabs,
            selectedIndex: _selectedIndex,
            onTap: (i) {
              _onTabSelected(i);
              _scaffoldKey.currentState?.closeDrawer();
            },
            onCloseDrawer: () => _scaffoldKey.currentState?.closeDrawer(),
            moreIndices: _moreIndices,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              GlobalAppBar(
                title: _tabs[_selectedIndex].label,
                breadcrumb: _selectedIndex == 0 ? null : _breadcrumbPath(),
                onBack: _selectedIndex == 0 ? null : _onBack,
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  static const _mobilePrimaryTabs = [0, 1, 2, 3, 4];

  Widget _buildMobileLayout() {
    final inPrimaryTab = _mobilePrimaryTabs.contains(_selectedIndex);
    final effectiveIndex = inPrimaryTab ? _mobilePrimaryTabs.indexOf(_selectedIndex) : 5;
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) {
          _onBack();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.backgroundColor,
        drawer: Drawer(
          child: SafeArea(
            child: SideNav(
              tabs: _tabs,
              selectedIndex: _selectedIndex,
              onTap: (i) {
                _onTabSelected(i);
                _scaffoldKey.currentState?.closeDrawer();
              },
              onCloseDrawer: () => _scaffoldKey.currentState?.closeDrawer(),
              moreIndices: _moreIndices,
            ),
          ),
        ),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tabs[_selectedIndex].label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              if (_selectedIndex != 0)
                Text(_breadcrumbPath(), style: TextStyle(fontSize: 11, color: context.textMutedColor)),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.menu, color: context.textPrimaryColor),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildBody(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: effectiveIndex,
          onDestinationSelected: (i) {
            if (i < _mobilePrimaryTabs.length) {
              _onTabSelected(_mobilePrimaryTabs[i]);
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          destinations: [
            for (final i in _mobilePrimaryTabs)
              NavigationDestination(
                icon: Icon(_tabs[i].icon, size: 22, color: context.textMutedColor),
                selectedIcon: Icon(_tabs[i].icon, size: 22, color: context.primaryColor),
                label: _tabs[_selectedIndex == i ? i : i].label,
              ),
            const NavigationDestination(
              icon: Icon(Icons.menu_open_rounded),
              selectedIcon: Icon(Icons.menu_open_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      sizing: StackFit.expand,
      children: const [
        DashboardView(),
        ApprovalsView(),
        OrdersView(),
        StoresView(),
        DriversView(),
        FinanceView(),
        CustomersView(),
        SettlementsView(),
        MarketingView(),
        NotificationsView(),
        ZonesView(),
        SupportView(),
        OperationsCenterView(),
        SystemHealthView(),
        SettingsView(),
        SubscriptionsView(),
        ProfileView(),
      ],
    );
  }
}
