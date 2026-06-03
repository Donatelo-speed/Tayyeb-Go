import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'admin_design.dart';
import 'sections/dashboard_section.dart';
import 'sections/stores_section.dart';
import 'sections/orders_section.dart';
import 'sections/customers_section.dart';
import 'sections/finance_section.dart';
import 'sections/marketing_section.dart';
import 'sections/notifications_section.dart';
import 'sections/support_section.dart';
import 'sections/ai_copilot_section.dart';
import 'sections/settings_section.dart';

final adminNavigatorKey = GlobalKey<NavigatorState>();

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
  final _simTimer = Timer.periodic(const Duration(seconds: 8), (_) => _simulateDriverLocations());

  static const _sections = [
    _NavItem('Dashboard', Icons.dashboard_rounded, 0),
    _NavItem('Stores', Icons.store_rounded, 1),
    _NavItem('Orders', Icons.receipt_long_rounded, 2),
    _NavItem('Drivers', Icons.delivery_dining_rounded, 3),
    _NavItem('Customers', Icons.group_rounded, 4),
    _NavItem('Finance', Icons.account_balance_wallet_rounded, 5),
    _NavItem('Marketing', Icons.campaign_rounded, 6),
    _NavItem('Notifications', Icons.notifications_active_rounded, 7),
    _NavItem('Support', Icons.headset_mic_rounded, 8),
    _NavItem('Analytics', Icons.insights_rounded, 9),
    _NavItem('AI Copilot', Icons.smart_toy_rounded, 10),
    _NavItem('Settings', Icons.settings_rounded, 11),
  ];

  final _views = const <Widget>[
    DashboardSection(),
    StoresSection(),
    OrdersSection(),
    DriversSection(),
    CustomersSection(),
    FinanceSection(),
    MarketingSection(),
    NotificationsSection(),
    SupportSection(),
    AnalyticsSection(),
    AICopilotSection(),
    SettingsSection(),
  ];

  static final _driverNames = const ['Ahmed H.', 'Khaled A.', 'Mohammad N.', 'Omar K.', 'Bilal H.', 'Youssef A.', 'Tarek R.', 'Samer J.', 'Fadi S.', 'Nabil M.'];

  static void _simulateDriverLocations() async {
    try {
      final driversSnap = await FirebaseFirestore.instance.collection('drivers').limit(10).get();
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      for (var i = 0; i < driversSnap.docs.length; i++) {
        final d = driversSnap.docs[i];
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
          'isOnline': true, 'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadTheme();
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
    p.setString('admin_theme', mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _simTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    final auth = context.watch<AuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_sidebarCollapsed || isMobile) _sidebarCollapsed = true;

    return Theme(
      data: isDark ? AdminTheme.dark() : AdminTheme.light(),
      child: Scaffold(
        backgroundColor: isDark ? AdminColors.bgDark : AdminColors.bgLight,
        body: Row(children: [
          if (!isMobile)
            _AdminSidebar(
              isDark: isDark,
              collapsed: _sidebarCollapsed,
              selected: _selectedSection,
              sections: _sections,
              onSelect: (i) => setState(() => _selectedSection = i),
              onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              onLogout: () => auth.logout(context),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.only(topLeft: Radius.circular(AdminRadius.xxl)),
              child: Container(
                color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLight,
                child: Column(children: [
                  _AdminTopBar(
                    isDark: isDark,
                    isMobile: isMobile,
                    title: _sections[_selectedSection].label,
                    searchCtrl: _searchCtrl,
                    themeMode: _themeMode,
                    onThemeChanged: _setTheme,
                    onMenuTap: isMobile ? () => _openMobileDrawer(context, isDark) : null,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                      child: KeyedSubtree(key: ValueKey('sec_$_selectedSection'), child: _views[_selectedSection]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  bool get _isDark {
    final brightness = MediaQuery.of(context).platformBrightness;
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return brightness == Brightness.dark;
  }

  void _openMobileDrawer(BuildContext context, bool isDark) {
    Scaffold.of(context).openDrawer();
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  const _NavItem(this.label, this.icon, this.index);
}

class _AdminSidebar extends StatefulWidget {
  final bool isDark, collapsed;
  final int selected;
  final List<_NavItem> sections;
  final VoidCallback onToggle, onLogout;
  final ValueChanged<int> onSelect;
  const _AdminSidebar({required this.isDark, required this.collapsed, required this.selected, required this.sections, required this.onSelect, required this.onToggle, required this.onLogout});

  @override
  State<_AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<_AdminSidebar> with TickerProviderStateMixin {
  late AnimationController _pulse;
  @override
  void initState() { super.initState(); _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true); }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final w = widget.collapsed ? 72.0 : 260.0;
    final isDark = widget.isDark;
    final bg = isDark ? AdminColors.bgDark : const Color(0xFF1E293B);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: w,
      decoration: BoxDecoration(color: bg, border: const Border(right: BorderSide(color: AdminColors.borderDark, width: 0.5))),
      child: Column(children: [
        const SizedBox(height: AdminSpacing.xl),
        _buildHeader(isDark),
        const SizedBox(height: AdminSpacing.sm),
        Divider(color: AdminColors.dividerDark, height: 1, indent: 16, endIndent: 16),
        const SizedBox(height: AdminSpacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md, vertical: AdminSpacing.sm),
            children: [
              ...widget.sections.map((s) => _NavButton(
                collapsed: widget.collapsed,
                isDark: isDark,
                label: s.label,
                icon: s.icon,
                selected: widget.selected == s.index,
                onTap: () => widget.onSelect(s.index),
              )),
              const SizedBox(height: AdminSpacing.md),
              Divider(color: AdminColors.dividerDark, height: 1, indent: 4, endIndent: 4),
              const SizedBox(height: AdminSpacing.sm),
              _NavButton(collapsed: widget.collapsed, isDark: isDark, label: 'Logout', icon: Icons.logout_rounded, selected: false, isDanger: true, onTap: widget.onLogout),
              const SizedBox(height: AdminSpacing.lg),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg),
      child: widget.collapsed
          ? Column(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AdminColors.primary, AdminColors.secondary]), borderRadius: BorderRadius.circular(AdminRadius.lg)), child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22)),
              const SizedBox(height: 8),
              IconButton(icon: const Icon(Icons.menu_rounded, color: AdminColors.textDarkMuted, size: 18), onPressed: widget.onToggle, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ])
          : Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AdminColors.primary, AdminColors.secondary]), borderRadius: BorderRadius.circular(AdminRadius.lg), boxShadow: [BoxShadow(color: AdminColors.primary.withValues(alpha: 0.3), blurRadius: 12)]), child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: AdminSpacing.md),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TayyebGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)), SizedBox(height: 2), Text('Admin Center', style: TextStyle(color: AdminColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5))])),
              IconButton(icon: const Icon(Icons.chevron_left_rounded, color: AdminColors.textDarkMuted, size: 18), onPressed: widget.onToggle, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
    );
  }
}

class _NavButton extends StatefulWidget {
  final bool collapsed, isDark, selected, isDanger;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.collapsed, required this.isDark, required this.label, required this.icon, required this.selected, required this.onTap, this.isDanger = false});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.isDanger ? AdminColors.danger : widget.selected ? AdminColors.primary : AdminColors.textDarkMuted;
    final bg = widget.selected ? widget.isDanger ? AdminColors.danger.withValues(alpha: 0.12) : AdminColors.primary.withValues(alpha: 0.12) : _hovered ? AdminColors.bgDarkHover : Colors.transparent;
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
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 14),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AdminRadius.lg), border: widget.selected && !widget.isDanger ? Border.all(color: AdminColors.primary.withValues(alpha: 0.3)) : null),
              child: Row(mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 200), style: TextStyle(color: c), child: Icon(widget.icon, size: 20)),
                if (!widget.collapsed) ...[
                  const SizedBox(width: AdminSpacing.md),
                  Text(widget.label, style: TextStyle(color: c, fontSize: 13, fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400)),
                ],
              ]),
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
  const _AdminTopBar({required this.isDark, required this.isMobile, required this.title, required this.searchCtrl, required this.themeMode, required this.onThemeChanged, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard;
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, isMobile ? 12 : 16, isMobile ? 12 : 32, 12),
      decoration: BoxDecoration(color: bg, boxShadow: AdminShadows.topBar),
      child: Column(children: [
        Row(children: [
          if (onMenuTap != null) ...[IconButton(icon: Icon(Icons.menu_rounded, color: isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary), onPressed: onMenuTap), const SizedBox(width: 8)],
          Text(title, style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
          const Spacer(),
          if (!isMobile) SizedBox(width: 220, child: TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search everything...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: isDark ? AdminColors.bgDarkInput : AdminColors.bgLightInput,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
              hintStyle: TextStyle(color: isDark ? AdminColors.textDarkMuted : AdminColors.textLightMuted),
            ),
          )),
          const SizedBox(width: 8),
          _ThemeToggle(isDark: isDark, themeMode: themeMode, onChanged: onThemeChanged),
          const SizedBox(width: 4),
          _QuickActionButton(isDark: isDark, icon: Icons.notifications_outlined, badge: '3', onTap: () {}),
          const SizedBox(width: 4),
          _QuickActionButton(isDark: isDark, icon: Icons.person_outline_rounded, onTap: () {}),
        ]),
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
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)),
      itemBuilder: (_) => [
        PopupMenuItem(value: ThemeMode.light, child: Row(children: [Icon(Icons.light_mode_rounded, size: 18, color: themeMode == ThemeMode.light ? AdminColors.primary : null), const SizedBox(width: 8), const Text('Light')])),
        PopupMenuItem(value: ThemeMode.dark, child: Row(children: [Icon(Icons.dark_mode_rounded, size: 18, color: themeMode == ThemeMode.dark ? AdminColors.primary : null), const SizedBox(width: 8), const Text('Dark')])),
        PopupMenuItem(value: ThemeMode.system, child: Row(children: [Icon(Icons.settings_suggest_rounded, size: 18, color: themeMode == ThemeMode.system ? AdminColors.primary : null), const SizedBox(width: 8), const Text('System')])),
      ],
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AdminRadius.md), color: isDark ? AdminColors.bgDarkHover : AdminColors.bgLightSurface),
        child: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : themeMode == ThemeMode.light ? Icons.light_mode_rounded : Icons.settings_suggest_rounded, size: 18, color: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
  const _QuickActionButton({required this.isDark, required this.icon, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(
        icon: Icon(icon, size: 20, color: isDark ? AdminColors.textDarkSecondary : AdminColors.textLightSecondary),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        style: IconButton.styleFrom(backgroundColor: isDark ? AdminColors.bgDarkHover : AdminColors.bgLightSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.md))),
      ),
      if (badge != null) Positioned(right: 2, top: -2, child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(color: AdminColors.danger, shape: BoxShape.circle),
        child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
      )),
    ]);
  }
}