import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'design/design.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stores_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/marketing_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/support_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/ai_copilot_screen.dart';
import 'screens/settings_screen.dart';

final adminNavigatorKey = GlobalKey<NavigatorState>();

class _NavSection {
  final String label;
  final IconData icon;
  final int index;
  const _NavSection(this.label, this.icon, this.index);
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});
  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> with TickerProviderStateMixin {
  late ThemeMode _themeMode;
  int _selectedSection = 0;
  bool _sidebarCollapsed = false;
  final _searchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _simTimer;

  static const _sections = [
    _NavSection('Dashboard', Icons.dashboard_rounded, 0),
    _NavSection('Orders', Icons.receipt_long_rounded, 1),
    _NavSection('Stores', Icons.store_rounded, 2),
    _NavSection('Drivers', Icons.delivery_dining_rounded, 3),
    _NavSection('Customers', Icons.group_rounded, 4),
    _NavSection('Finance', Icons.account_balance_wallet_rounded, 5),
    _NavSection('Marketing', Icons.campaign_rounded, 6),
    _NavSection('Notifications', Icons.notifications_active_rounded, 7),
    _NavSection('Support', Icons.headset_mic_rounded, 8),
    _NavSection('Analytics', Icons.insights_rounded, 9),
    _NavSection('AI Copilot', Icons.smart_toy_rounded, 10),
    _NavSection('Settings', Icons.settings_rounded, 11),
  ];

  static final _driverNames = const [
    'Ahmed H.', 'Khaled A.', 'Mohammad N.', 'Omar K.', 'Bilal H.',
    'Youssef A.', 'Tarek R.', 'Samer J.', 'Fadi S.', 'Nabil M.',
  ];

  void _simulateDriverLocations() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('drivers').limit(10).get();
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      for (var i = 0; i < snap.docs.length; i++) {
        final d = snap.docs[i];
        final data = d.data();
        if (data['isOnline'] != true) continue;
        final t = now.millisecondsSinceEpoch / 1000.0;
        final lat = 34.733 + sin(t * 0.3 + i * 0.7) * 0.012;
        final lng = 36.715 + cos(t * 0.25 + i * 0.6) * 0.012;
        batch.set(FirebaseFirestore.instance.collection('driver_locations').doc(d.id), {
          'driverId': d.id,
          'driverName': _driverNames[i % _driverNames.length],
          'lat': lat, 'lng': lng,
          'heading': (now.second * 6.0 + i * 45) % 360,
          'isOnline': true, 'status': 'online',
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _simTimer = Timer.periodic(const Duration(seconds: 8), (_) => _simulateDriverLocations());

    final adminProv = context.read<AdminProvider>();
    adminProv.init();
  }

  Future<void> _loadTheme() async {
    final p = await SharedPreferences.getInstance();
    final mode = p.getString('admin_theme') ?? 'system';
    setState(() {
      _themeMode = mode == 'dark' ? ThemeMode.dark : mode == 'light' ? ThemeMode.light : ThemeMode.system;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final p = await SharedPreferences.getInstance();
    await p.setString('admin_theme', mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _simTimer?.cancel();
    super.dispose();
  }

  bool get _isDark {
    final b = MediaQuery.of(context).platformBrightness;
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return b == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (isMobile) _sidebarCollapsed = true;

    return Theme(
      data: isDark ? AdminTheme.dark() : AdminTheme.light(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AdminColors.bg(isDark),
        drawer: isMobile ? _buildDrawer(isDark, auth) : null,
        body: Row(children: [
          if (!isMobile)
            _AdminSidebar(
              isDark: isDark,
              collapsed: _sidebarCollapsed || isTablet,
              selected: _selectedSection,
              sections: _sections,
              onSelect: (i) => setState(() => _selectedSection = i),
              onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              onLogout: () => auth.logout(context),
            ),
          Expanded(
            child: Column(children: [
              _AdminTopBar(
                isDark: isDark,
                isMobile: isMobile,
                title: _sections[_selectedSection].label,
                searchCtrl: _searchCtrl,
                themeMode: _themeMode,
                onThemeChanged: _setTheme,
                onMenuTap: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
              ),
              _buildBreadcrumbs(isDark),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AdminDuration.page,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                  child: KeyedSubtree(key: ValueKey('sec_$_selectedSection'), child: _buildSection()),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSection() {
    switch (_selectedSection) {
      case 0: return const DashboardScreen();
      case 1: return const OrdersScreen();
      case 2: return const StoresScreen();
      case 3: return const DriversScreen();
      case 4: return const CustomersScreen();
      case 5: return const FinanceScreen();
      case 6: return const MarketingScreen();
      case 7: return const NotificationsScreen();
      case 8: return const SupportScreen();
      case 9: return const AnalyticsScreen();
      case 10: return const AICopilotScreen();
      case 11: return const SettingsScreen();
      default: return const DashboardScreen();
    }
  }

  Widget _buildBreadcrumbs(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xl, vertical: AdminSpacing.sm),
      decoration: BoxDecoration(
        color: AdminColors.bg(isDark),
        border: Border(bottom: BorderSide(color: AdminColors.border(isDark))),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => setState(() => _selectedSection = 0),
          child: Text('Dashboard', style: AdminTypography.breadcrumb(isDark)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
          child: Icon(Icons.chevron_right_rounded, size: 14, color: AdminColors.textMuted(isDark)),
        ),
        Text(_sections[_selectedSection].label, style: AdminTypography.breadcrumbActive(isDark)),
      ]),
    );
  }

  Widget _buildDrawer(bool isDark, AuthProvider auth) {
    return Drawer(
      backgroundColor: isDark ? AdminColors.darkSurface : AdminColors.slate900,
      child: SafeArea(
        child: Column(children: [
          _buildDrawerHeader(isDark),
          const SizedBox(height: AdminSpacing.sm),
          Divider(color: AdminColors.darkBorder, height: 1, indent: 16, endIndent: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md, vertical: AdminSpacing.sm),
              children: [
                ..._sections.map((s) => _NavButton(
                  collapsed: false,
                  isDark: isDark,
                  label: s.label,
                  icon: s.icon,
                  selected: _selectedSection == s.index,
                  onTap: () {
                    setState(() => _selectedSection = s.index);
                    Navigator.pop(context);
                  },
                )),
                const SizedBox(height: AdminSpacing.md),
                Divider(color: AdminColors.darkBorder, height: 1, indent: 4, endIndent: 4),
                const SizedBox(height: AdminSpacing.sm),
                _NavButton(collapsed: false, isDark: isDark, label: 'Logout', icon: Icons.logout_rounded, selected: false, isDanger: true, onTap: () => auth.logout(context)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AdminColors.primary, Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(AdminRadius.lg),
            boxShadow: [BoxShadow(color: AdminColors.primary.withValues(alpha: 0.4), blurRadius: 16)],
          ),
          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: AdminSpacing.md),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TayyebGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          SizedBox(height: 2),
          Text('Admin Center', style: TextStyle(color: AdminColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ])),
      ]),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final bool isDark, collapsed;
  final int selected;
  final List<_NavSection> sections;
  final VoidCallback onToggle, onLogout;
  final ValueChanged<int> onSelect;
  const _AdminSidebar({
    required this.isDark, required this.collapsed, required this.selected,
    required this.sections, required this.onSelect, required this.onToggle, required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? 72.0 : 260.0;
    final bg = isDark ? AdminColors.darkSurface : AdminColors.slate900;

    return AnimatedContainer(
      duration: AdminDuration.normal,
      curve: Curves.easeInOut,
      width: w,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: isDark ? AdminColors.darkBorder : AdminColors.slate800, width: 0.5)),
      ),
      child: Column(children: [
        const SizedBox(height: AdminSpacing.xl),
        _buildHeader(),
        const SizedBox(height: AdminSpacing.sm),
        Divider(color: isDark ? AdminColors.darkBorder : AdminColors.slate700, height: 1, indent: 16, endIndent: 16),
        const SizedBox(height: AdminSpacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md, vertical: AdminSpacing.sm),
            children: [
              ...sections.map((s) => _NavButton(
                collapsed: collapsed,
                isDark: isDark,
                label: s.label,
                icon: s.icon,
                selected: selected == s.index,
                onTap: () => onSelect(s.index),
              )),
              const SizedBox(height: AdminSpacing.md),
              Divider(color: isDark ? AdminColors.darkBorder : AdminColors.slate700, height: 1, indent: 4, endIndent: 4),
              const SizedBox(height: AdminSpacing.sm),
              _NavButton(collapsed: collapsed, isDark: isDark, label: 'Logout', icon: Icons.logout_rounded, selected: false, isDanger: true, onTap: onLogout),
              const SizedBox(height: AdminSpacing.lg),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg),
      child: collapsed
          ? Column(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AdminColors.primary, Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(AdminRadius.lg),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AdminColors.darkBorder, borderRadius: BorderRadius.circular(AdminRadius.sm)),
                  child: const Icon(Icons.menu_rounded, color: AdminColors.slate400, size: 16),
                ),
              ),
            ])
          : Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AdminColors.primary, Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(AdminRadius.lg),
                  boxShadow: [BoxShadow(color: AdminColors.primary.withValues(alpha: 0.3), blurRadius: 12)],
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AdminSpacing.md),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TayyebGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                SizedBox(height: 2),
                Text('Admin Center', style: TextStyle(color: AdminColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ])),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AdminColors.darkBorder, borderRadius: BorderRadius.circular(AdminRadius.sm)),
                  child: const Icon(Icons.chevron_left_rounded, color: AdminColors.slate400, size: 16),
                ),
              ),
            ]),
    );
  }
}

class _NavButton extends StatefulWidget {
  final bool collapsed, isDark, selected, isDanger;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({
    required this.collapsed, required this.isDark, required this.label,
    required this.icon, required this.selected, required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.isDanger
        ? AdminColors.danger
        : widget.selected
            ? AdminColors.primary
            : AdminColors.slate400;

    final bg = widget.selected
        ? (widget.isDanger ? AdminColors.danger.withValues(alpha: 0.12) : AdminColors.primary.withValues(alpha: 0.12))
        : _hovered
            ? (widget.isDark ? AdminColors.darkCardHover : AdminColors.slate800)
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AdminRadius.lg),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AdminRadius.lg),
            child: AnimatedContainer(
              duration: AdminDuration.fast,
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AdminRadius.lg),
                border: widget.selected && !widget.isDanger
                    ? Border.all(color: AdminColors.primary.withValues(alpha: 0.3))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: AdminDuration.fast,
                    style: TextStyle(color: c),
                    child: Icon(widget.icon, size: 20),
                  ),
                  if (!widget.collapsed) ...[
                    const SizedBox(width: AdminSpacing.md),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: c,
                        fontSize: 13,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final bool isDark, isMobile;
  final String title;
  final TextEditingController searchCtrl;
  final ThemeMode themeMode;
  final VoidCallback? onMenuTap;
  final ValueChanged<ThemeMode> onThemeChanged;
  const _AdminTopBar({
    required this.isDark, required this.isMobile, required this.title,
    required this.searchCtrl, required this.themeMode, required this.onThemeChanged,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AdminSpacing.lg : AdminSpacing.xxxl,
        isMobile ? AdminSpacing.md : AdminSpacing.lg,
        isMobile ? AdminSpacing.md : AdminSpacing.xxxl,
        AdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AdminColors.card(isDark),
        boxShadow: AdminShadows.top,
      ),
      child: Row(children: [
        if (onMenuTap != null) ...[
          IconButton(
            icon: Icon(Icons.menu_rounded, color: AdminColors.textPrimary(isDark)),
            onPressed: onMenuTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: AdminSpacing.md),
        ],
        if (isMobile) Expanded(child: Text(title, style: AdminTypography.h3(isDark)))
        else Text(title, style: AdminTypography.h2(isDark)),
        const Spacer(),
        if (!isMobile) ...[
          SizedBox(
            width: 240,
            height: 38,
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search everything...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: AdminSpacing.md),
        ],
        _ThemeToggle(isDark: isDark, themeMode: themeMode, onChanged: onThemeChanged),
        const SizedBox(width: AdminSpacing.sm),
        _ActionButton(isDark: isDark, icon: Icons.notifications_outlined, badge: '3', onTap: () {}),
        const SizedBox(width: AdminSpacing.sm),
        _ActionButton(isDark: isDark, icon: Icons.person_outline_rounded, onTap: () {}),
      ]),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeToggle({required this.isDark, required this.themeMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        side: BorderSide(color: AdminColors.border(isDark)),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(value: ThemeMode.light, child: Row(children: [
          Icon(Icons.light_mode_rounded, size: 18, color: themeMode == ThemeMode.light ? AdminColors.primary : null),
          const SizedBox(width: 8), const Text('Light'),
        ])),
        PopupMenuItem(value: ThemeMode.dark, child: Row(children: [
          Icon(Icons.dark_mode_rounded, size: 18, color: themeMode == ThemeMode.dark ? AdminColors.primary : null),
          const SizedBox(width: 8), const Text('Dark'),
        ])),
        PopupMenuItem(value: ThemeMode.system, child: Row(children: [
          Icon(Icons.settings_suggest_rounded, size: 18, color: themeMode == ThemeMode.system ? AdminColors.primary : null),
          const SizedBox(width: 8), const Text('System'),
        ])),
      ],
      onSelected: onChanged,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AdminRadius.md),
          color: isDark ? AdminColors.darkCardHover : AdminColors.lightSurface,
        ),
        child: Icon(
          themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : themeMode == ThemeMode.light ? Icons.light_mode_rounded : Icons.settings_suggest_rounded,
          size: 18,
          color: AdminColors.textSecondary(isDark),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
  const _ActionButton({required this.isDark, required this.icon, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AdminRadius.md),
          color: isDark ? AdminColors.darkCardHover : AdminColors.lightSurface,
        ),
        child: IconButton(
          icon: Icon(icon, size: 18, color: AdminColors.textSecondary(isDark)),
          onPressed: onTap,
          padding: EdgeInsets.zero,
        ),
      ),
      if (badge != null)
        Positioned(right: 2, top: -2, child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: AdminColors.danger, shape: BoxShape.circle),
          child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
        )),
    ]);
  }
}