// =====================================================
// TAYYEB-GO — lib/screens/cashier/cashier_dashboard_screen.dart
//
// CashierDashboard — complete production implementation.
//
// Brand palette: teal #16A085, matches Admin / Restaurant dashboards.
//
// Layout:
//   LayoutBuilder > 800 px → NavigationRail sidebar (220 px)
//   LayoutBuilder ≤ 800 px → BottomNavigationBar (5 tabs)
//
// Tab 0 — Overview  : live today-stats from Firestore
// Tab 1 — Incoming  : real-time stream of pending orders for this
//                     restaurant; [Accept] / [Reject] action buttons
// Tab 2 — POS       : menu_items grid + live basket + [Checkout]
//                     posts a walk-in order document to Firestore
//                     (AutomaticKeepAliveClientMixin — basket survives
//                     tab switches)
// Tab 3 — History   : placeholder
// Tab 4 — Settings  : placeholder
//
// Firestore collections touched:
//   /orders/{id}      — read (pending stream) + write (accept/reject/checkout)
//   /menu_items/{id}  — read (POS grid)
//   /restaurants/{id} — read (vendor name for checkout document)
// =====================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

// =============================================================================
// Brand palette — matches Admin / Restaurant dashboards exactly
// =============================================================================

const _kPrimary = Color(0xFF16A085);
const _kSidebar = Color(0xFF0F172A);
const _kSidebarSel = Color(0xFF1E293B);
const _kSurface = Color(0xFFF8FAFC);
const _kCard = Colors.white;
const _kDivider = Color(0xFFE2E8F0);
const _kHead = Color(0xFF0F172A);
const _kSub = Color(0xFF64748B);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF10B981);
const _kRed = Color(0xFFEF4444);
const _kBlue = Color(0xFF3B82F6);

/// Saudi VAT rate — adjust if deploying in another jurisdiction.
const _kVatRate = 0.15;

// =============================================================================
// Basket entry — pure Dart, no Firestore dependency
// =============================================================================

class _BasketEntry {
  final String id;
  final String name;
  final String nameAr;
  final double price;
  final String category;
  final String? imageUrl;
  int quantity = 1;

  _BasketEntry({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.price,
    required this.category,
    this.imageUrl,
  });

  double get lineTotal => price * quantity;
}

// =============================================================================
// Nav destinations
// =============================================================================

class _NavDest {
  final IconData icon, activeIcon;
  final String en, ar;
  const _NavDest(this.icon, this.activeIcon, this.en, this.ar);
}

const _navDests = [
  _NavDest(Icons.dashboard_outlined, Icons.dashboard, 'Overview', 'نظرة عامة'),
  _NavDest(Icons.inbox_outlined, Icons.inbox, 'Incoming', 'الواردة'),
  _NavDest(Icons.point_of_sale_outlined, Icons.point_of_sale, 'POS', 'الكاشير'),
  _NavDest(Icons.history_outlined, Icons.history, 'History', 'السجل'),
  _NavDest(Icons.settings_outlined, Icons.settings, 'Settings', 'الإعدادات'),
];

// =============================================================================
// CashierDashboardScreen
// =============================================================================

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  int _currentTab = 2; // Default to POS — the cashier's primary workflow

  late final String _uid;
  late final String _restaurantId;
  late final String _displayName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fbUser = FirebaseAuth.instance.currentUser;
    final appUser = context.read<AuthProvider>().user;
    _uid = fbUser?.uid ?? appUser?.id ?? '';
    _restaurantId = appUser?.vendorId?.toString() ?? '';
    _displayName = appUser?.displayName ?? fbUser?.displayName ?? 'Cashier';
  }

  void _select(int i) => setState(() => _currentTab = i);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: _buildAppBar(context, locale),
      body: LayoutBuilder(
        builder: (ctx, c) => c.maxWidth > 800
            ? Row(
                children: [
                  _buildSidebar(locale),
                  const VerticalDivider(width: 1, color: _kDivider),
                  Expanded(child: _buildContent(locale)),
                ],
              )
            : _buildContent(locale),
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (ctx, c) {
          if (c.maxWidth > 800) return const SizedBox.shrink();
          return _buildBottomBar(locale);
        },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext ctx, LocaleProvider locale) {
    final auth = ctx.read<AuthProvider>();
    return AppBar(
      backgroundColor: _kSidebar,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.point_of_sale,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            locale.t('Cashier Station', 'محطة الكاشير'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      actions: [
        // Pending orders badge in AppBar (always visible)
        if (_restaurantId.isNotEmpty)
          _AppBarPendingBadge(
            restaurantId: _restaurantId,
            locale: locale,
            onTap: () => _select(1),
          ),
        TextButton(
          onPressed: locale.toggle,
          child: Text(
            locale.isArabic ? 'EN' : 'ع',
            style: const TextStyle(
              color: _kPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          tooltip: locale.t('Logout', 'خروج'),
          onPressed: () => auth.logout(ctx),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────────

  Widget _buildSidebar(LocaleProvider locale) {
    return Container(
      width: 220,
      color: _kSidebar,
      child: Column(
        children: [
          // Station identity block
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        locale.t('Cashier', 'كاشير'),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 6),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _navDests.length,
              itemBuilder: (ctx, i) {
                final sel = _currentTab == i;
                final dest = _navDests[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _select(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? _kPrimary.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: sel
                              ? Border.all(
                                  color: _kPrimary.withValues(alpha: 0.35),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sel ? dest.activeIcon : dest.icon,
                              size: 19,
                              color: sel ? _kPrimary : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                locale.isArabic ? dest.ar : dest.en,
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (i == 1 && _restaurantId.isNotEmpty)
                              _SidebarPendingBadge(restaurantId: _restaurantId),
                            if (sel && i != 1)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _kPrimary,
                                  shape: BoxShape.circle,
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

          // Today's quick stat at bottom of sidebar
          _SidebarTodayStat(restaurantId: _restaurantId, locale: locale),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(LocaleProvider locale) {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: _select,
      selectedItemColor: _kPrimary,
      unselectedItemColor: _kSub,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      elevation: 8,
      items: _navDests
          .map(
            (d) => BottomNavigationBarItem(
              icon: d.icon == Icons.inbox_outlined
                  ? _MobileIncomingIcon(
                      restaurantId: _restaurantId,
                      icon: d.icon,
                    )
                  : Icon(d.icon),
              activeIcon: Icon(d.activeIcon),
              label: locale.isArabic ? d.ar : d.en,
            ),
          )
          .toList(),
    );
  }

  // ── Content router ─────────────────────────────────────────────────────────

  Widget _buildContent(LocaleProvider locale) {
    return switch (_currentTab) {
      0 => _OverviewPane(
        restaurantId: _restaurantId,
        displayName: _displayName,
        locale: locale,
      ),
      1 => _IncomingOrdersPane(restaurantId: _restaurantId, locale: locale),
      2 => _POSPane(
        restaurantId: _restaurantId,
        cashierId: _uid,
        locale: locale,
      ),
      3 => _PlaceholderPane(
        icon: Icons.history,
        titleEn: 'Order History',
        titleAr: 'سجل الطلبات',
      ),
      4 => _PlaceholderPane(
        icon: Icons.settings,
        titleEn: 'Settings',
        titleAr: 'الإعدادات',
      ),
      _ => _POSPane(
        restaurantId: _restaurantId,
        cashierId: _uid,
        locale: locale,
      ),
    };
  }
}

// =============================================================================
// AppBar pending badge — taps to navigate to Incoming tab
// =============================================================================

class _AppBarPendingBadge extends StatelessWidget {
  final String restaurantId;
  final LocaleProvider locale;
  final VoidCallback onTap;
  const _AppBarPendingBadge({
    required this.restaurantId,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get(),
      builder: (ctx, snap) {
        final count = snap.data?.count ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: count > 0
                    ? _kAmber.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: count > 0
                    ? Border.all(color: _kAmber.withValues(alpha: 0.6))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 16,
                    color: count > 0 ? _kAmber : Colors.white38,
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: _kAmber,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Sidebar pending badge (compact circle)
class _SidebarPendingBadge extends StatelessWidget {
  final String restaurantId;
  const _SidebarPendingBadge({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get(),
      builder: (ctx, snap) {
        final count = snap.data?.count ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: _kAmber,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Mobile bottom-bar icon with badge overlay
class _MobileIncomingIcon extends StatelessWidget {
  final String restaurantId;
  final IconData icon;
  const _MobileIncomingIcon({required this.restaurantId, required this.icon});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get(),
      builder: (ctx, snap) {
        final count = snap.data?.count ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            if (count > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: _kAmber,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Sidebar today-stat footer
// =============================================================================

class _SidebarTodayStat extends StatelessWidget {
  final String restaurantId;
  final LocaleProvider locale;
  const _SidebarTodayStat({required this.restaurantId, required this.locale});

  @override
  Widget build(BuildContext context) {
    final startOfDay = DateTime.now();
    final midnight = DateTime(
      startOfDay.year,
      startOfDay.month,
      startOfDay.day,
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: restaurantId.isEmpty
          ? null
          : FirebaseFirestore.instance
                .collection('orders')
                .where('vendorId', isEqualTo: restaurantId)
                .where('status', isEqualTo: 'delivered')
                .where(
                  'createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(midnight),
                )
                .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        final revenue = docs.fold<double>(
          0,
          (s, d) => s + _toDouble(d.data()['totalAmount']),
        );
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSidebarSel,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SidebarStat(
                  label: locale.t("Today's Sales", 'مبيعات اليوم'),
                  value: '${docs.length}',
                  color: _kPrimary,
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white12),
              Expanded(
                child: _SidebarStat(
                  label: locale.t('Revenue', 'الإيرادات'),
                  value: '${revenue.toStringAsFixed(0)} ﷼',
                  color: _kGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SidebarStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 0 — Overview
// =============================================================================

class _OverviewPane extends StatelessWidget {
  final String restaurantId;
  final String displayName;
  final LocaleProvider locale;

  const _OverviewPane({
    required this.restaurantId,
    required this.displayName,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final midnight = DateTime.now();
    final startOfDay = DateTime(midnight.year, midnight.month, midnight.day);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, Color(0xFF2ECC71)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.point_of_sale, color: Colors.white, size: 48),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.t(
                          'Good shift, $displayName!',
                          'وردية موفقة، $displayName!',
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locale.t(
                          'Your POS station is live.',
                          'محطة الكاشير جاهزة.',
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _Label(locale.t("Today's Overview", 'ملخص اليوم')),
          const SizedBox(height: 14),

          // Live stats
          LayoutBuilder(
            builder: (ctx, c) {
              final cols = c.maxWidth > 500 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _LiveCountCard(
                    restaurantId: restaurantId,
                    status: 'pending',
                    title: locale.t('Pending', 'قيد الانتظار'),
                    icon: Icons.pending_actions,
                    color: _kAmber,
                  ),
                  _LiveCountCard(
                    restaurantId: restaurantId,
                    status: 'accepted',
                    title: locale.t('Accepted', 'مقبولة'),
                    icon: Icons.check_circle_outline,
                    color: _kBlue,
                  ),
                  _LiveCountCard(
                    restaurantId: restaurantId,
                    status: 'delivered',
                    title: locale.t('Delivered', 'مُوصَّلة'),
                    icon: Icons.done_all,
                    color: _kGreen,
                  ),
                  _LiveCountCard(
                    restaurantId: restaurantId,
                    status: 'cancelled',
                    title: locale.t('Cancelled', 'مُلغاة'),
                    icon: Icons.cancel_outlined,
                    color: _kRed,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),
          _Label(locale.t("Today's Revenue", 'إيرادات اليوم')),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: restaurantId.isEmpty
                ? null
                : FirebaseFirestore.instance
                      .collection('orders')
                      .where('vendorId', isEqualTo: restaurantId)
                      .where(
                        'createdAt',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
                      )
                      .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              final completed = docs
                  .where((d) => d.data()['status'] == 'delivered')
                  .toList();
              final revenue = completed.fold<double>(
                0,
                (s, d) => s + _toDouble(d.data()['totalAmount']),
              );
              final walkIn = docs
                  .where((d) => d.data()['orderType'] == 'walk_in')
                  .length;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kDivider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RevStat(
                        icon: Icons.payments_outlined,
                        label: locale.t('Total Revenue', 'إجمالي الإيرادات'),
                        value: '${revenue.toStringAsFixed(2)} ﷼',
                        color: _kPrimary,
                      ),
                    ),
                    Container(width: 1, height: 48, color: _kDivider),
                    Expanded(
                      child: _RevStat(
                        icon: Icons.receipt_long_outlined,
                        label: locale.t('Completed Orders', 'طلبات مكتملة'),
                        value: '${completed.length}',
                        color: _kGreen,
                      ),
                    ),
                    Container(width: 1, height: 48, color: _kDivider),
                    Expanded(
                      child: _RevStat(
                        icon: Icons.storefront_outlined,
                        label: locale.t('Walk-in Sales', 'مبيعات مباشرة'),
                        value: '$walkIn',
                        color: _kBlue,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Revenue stat tile
class _RevStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _RevStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: _kSub),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 1 — Incoming Orders (pending stream)
// =============================================================================

class _IncomingOrdersPane extends StatelessWidget {
  final String restaurantId;
  final LocaleProvider locale;
  const _IncomingOrdersPane({required this.restaurantId, required this.locale});

  @override
  Widget build(BuildContext context) {
    if (restaurantId.isEmpty) {
      return _EmptyPane(
        icon: Icons.warning_amber_rounded,
        titleEn: 'Restaurant not configured',
        titleAr: 'لم يُعيَّن مطعم',
        bodyEn: 'Link your cashier account to a restaurant.',
        bodyAr: 'اربط حسابك بمطعم.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingPane();
        }
        if (snap.hasError) {
          return _ErrorPane(message: snap.error.toString());
        }

        final docs = snap.data?.docs ?? [];

        return Column(
          children: [
            _PaneHeader(
              icon: Icons.inbox,
              titleEn: 'Incoming Orders',
              titleAr: 'الطلبات الواردة',
              subtitleEn: '${docs.length} order(s) awaiting action',
              subtitleAr: '${docs.length} طلب بانتظار الإجراء',
            ),

            if (docs.isEmpty)
              Expanded(
                child: _EmptyPane(
                  icon: Icons.inbox_outlined,
                  titleEn: 'Queue is clear',
                  titleAr: 'الطابور فارغ',
                  bodyEn: 'New orders appear here the moment they are placed.',
                  bodyAr: 'تظهر الطلبات الجديدة هنا فور إرسالها.',
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) =>
                      _IncomingOrderCard(doc: docs[i], locale: locale),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Incoming order card ─────────────────────────────────────────────────────────

class _IncomingOrderCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final LocaleProvider locale;
  const _IncomingOrderCard({required this.doc, required this.locale});

  @override
  State<_IncomingOrderCard> createState() => _IncomingOrderCardState();
}

class _IncomingOrderCardState extends State<_IncomingOrderCard> {
  bool _accepting = false;
  bool _rejecting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.doc.id)
          .update({
            'status': 'accepted',
            'acceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.locale.t('✅ Order accepted!', '✅ تم قبول الطلب!'),
            ),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _accepting = false);
      }
    }
  }

  Future<void> _reject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(widget.locale.t('Reject Order?', 'رفض الطلب؟')),
        content: Text(
          widget.locale.t(
            'This will cancel the order and notify the customer.',
            'سيُلغى الطلب ويُخطَر العميل.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.locale.t('Back', 'رجوع')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kRed),
            child: Text(widget.locale.t('Reject', 'رفض')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _rejecting = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.doc.id)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _rejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final locale = widget.locale;

    final String orderId = widget.doc.id.length > 8
        ? widget.doc.id.substring(0, 8).toUpperCase()
        : widget.doc.id.toUpperCase();
    final String customerName = data['customerName'] as String? ?? '—';
    final String? phone = data['customerPhone'] as String?;
    final double total = _toDouble(data['totalAmount']);
    final String? note = data['customerNote'] as String?;
    final dynamic createdAt = data['createdAt'];
    final String orderType = data['orderType'] as String? ?? 'delivery';

    final List<Map<String, dynamic>> items = _extractItems(data['items']);

    final String elapsed = _elapsed(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: const BorderSide(color: _kAmber, width: 4),
          top: BorderSide(color: _kDivider),
          right: BorderSide(color: _kDivider),
          bottom: BorderSide(color: _kDivider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#$orderId',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _kHead,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TypePill(type: orderType, locale: locale),
                        ],
                      ),
                      Text(
                        customerName,
                        style: const TextStyle(fontSize: 13, color: _kSub),
                      ),
                      if (phone != null && phone.isNotEmpty)
                        Text(
                          phone,
                          style: const TextStyle(fontSize: 11, color: _kSub),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _kAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _kAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            locale.t('Pending', 'انتظار'),
                            style: const TextStyle(
                              color: _kAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 11,
                          color: _kSub,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          elapsed,
                          style: const TextStyle(fontSize: 11, color: _kSub),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: _kDivider, height: 1),
            const SizedBox(height: 12),

            // ── Items preview ─────────────────────────────────────────
            ...items.take(4).map((item) {
              final n = item['name'] as String? ?? '—';
              final q = item['quantity'] as int? ?? 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$q',
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        n,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _kHead),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (items.length > 4)
              Text(
                '+${items.length - 4} ${locale.t('more items', 'أصناف أخرى')}',
                style: const TextStyle(fontSize: 11, color: _kSub),
              ),

            // ── Customer note ─────────────────────────────────────────
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 13,
                      color: _kAmber,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(fontSize: 11, color: _kHead),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(color: _kDivider, height: 1),
            const SizedBox(height: 12),

            // ── Footer: total + actions ───────────────────────────────
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.t('Total', 'الإجمالي'),
                      style: const TextStyle(fontSize: 11, color: _kSub),
                    ),
                    Text(
                      'SAR ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: _kHead,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Reject
                _rejecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kRed,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: _accepting ? null : _reject,
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: Text(
                          locale.t('Reject', 'رفض'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kRed,
                          side: BorderSide(color: _kRed.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                const SizedBox(width: 10),
                // Accept
                _accepting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kGreen,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _rejecting ? null : _accept,
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: Text(
                          locale.t('Accept', 'قبول'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Order type pill
class _TypePill extends StatelessWidget {
  final String type;
  final LocaleProvider locale;
  const _TypePill({required this.type, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isWalkIn = type == 'walk_in';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isWalkIn ? _kBlue : _kPrimary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isWalkIn ? locale.t('Walk-in', 'حضوري') : locale.t('Delivery', 'توصيل'),
        style: TextStyle(
          color: isWalkIn ? _kBlue : _kPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 2 — POS (Point of Sale)
// =============================================================================

class _POSPane extends StatefulWidget {
  final String restaurantId;
  final String cashierId;
  final LocaleProvider locale;

  const _POSPane({
    required this.restaurantId,
    required this.cashierId,
    required this.locale,
  });

  @override
  State<_POSPane> createState() => _POSPaneState();
}

class _POSPaneState extends State<_POSPane> with AutomaticKeepAliveClientMixin {
  // ── Basket state ───────────────────────────────────────────────────────────
  final Map<String, _BasketEntry> _basket = {};

  // ── Filter state ───────────────────────────────────────────────────────────
  String _selectedCategory = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Checkout form state ────────────────────────────────────────────────────
  String _customerName = '';
  String _paymentMethod = 'cash'; // cash | card | wallet

  // ── Basket arithmetic ──────────────────────────────────────────────────────
  double get _subtotal => _basket.values.fold(0.0, (s, e) => s + e.lineTotal);
  double get _taxAmount => _subtotal * _kVatRate;
  double get _totalAmount => _subtotal + _taxAmount;
  int get _itemCount => _basket.values.fold(0, (s, e) => s + e.quantity);

  // ── Basket operations ──────────────────────────────────────────────────────

  void _addItem(Map<String, dynamic> data, String id) {
    setState(() {
      if (_basket.containsKey(id)) {
        _basket[id]!.quantity++;
      } else {
        _basket[id] = _BasketEntry(
          id: id,
          name: data['name'] as String? ?? 'Item',
          nameAr: data['nameAr'] as String? ?? '',
          price: _toDouble(data['price']),
          category: data['category'] as String? ?? '',
          imageUrl: data['imageUrl'] as String?,
        );
      }
    });
  }

  void _increment(String id) {
    setState(() => _basket[id]?.quantity++);
  }

  void _decrement(String id) {
    setState(() {
      if (_basket[id]!.quantity <= 1) {
        _basket.remove(id);
      } else {
        _basket[id]!.quantity--;
      }
    });
  }

  void _clearBasket() => setState(_basket.clear);

  // ── Checkout ───────────────────────────────────────────────────────────────

  Future<void> _checkout(BuildContext ctx) async {
    if (_basket.isEmpty) return;

    final confirmed = await _showCheckoutSheet(ctx);
    if (confirmed != true) return;

    try {
      final items = _basket.values
          .map(
            (e) => {
              'productId': e.id,
              'name': e.name,
              'nameAr': e.nameAr,
              'imageUrl': e.imageUrl,
              'basePrice': e.price,
              'quantity': e.quantity,
              'selectedModifiers': [],
            },
          )
          .toList();

      await FirebaseFirestore.instance.collection('orders').add({
        'vendorId': widget.restaurantId,
        'cashierId': widget.cashierId,
        'customerId': 'walk-in',
        'customerName': _customerName.trim().isEmpty
            ? 'Walk-in Customer'
            : _customerName.trim(),
        'orderType': 'walk_in',
        'status': 'accepted', // walk-in = immediately accepted
        'paymentMethod': _paymentMethod,
        'isPaid': true,
        'items': items,
        'subtotal': _subtotal,
        'taxAmount': _taxAmount,
        'deliveryFee': 0.0,
        'discount': 0.0,
        'totalAmount': _totalAmount,
        'loyaltyPointsUsed': 0,
        'loyaltyPointsEarned': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      _clearBasket();
      setState(() {
        _customerName = '';
        _paymentMethod = 'cash';
      });

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              widget.locale.t(
                '🧾 Order posted! SAR ${_totalAmount.toStringAsFixed(2)}',
                '🧾 تم تسجيل الطلب! ${_totalAmount.toStringAsFixed(2)} ﷼',
              ),
            ),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool?> _showCheckoutSheet(BuildContext ctx) {
    return showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(
        subtotal: _subtotal,
        taxAmount: _taxAmount,
        totalAmount: _totalAmount,
        itemCount: _itemCount,
        customerName: _customerName,
        paymentMethod: _paymentMethod,
        locale: widget.locale,
        onCustomerName: (v) => setState(() => _customerName = v),
        onPayment: (v) => setState(() => _paymentMethod = v),
      ),
    );
  }

  // ── Mobile basket bottom sheet ─────────────────────────────────────────────

  void _openMobileBasket(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSheet) => _MobileBasketSheet(
          basket: _basket,
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          totalAmount: _totalAmount,
          locale: widget.locale,
          onIncrement: (id) {
            _increment(id);
            setSheet(() {});
          },
          onDecrement: (id) {
            _decrement(id);
            setSheet(() {});
          },
          onClear: () {
            _clearBasket();
            setSheet(() {});
          },
          onCheckout: () async {
            Navigator.pop(ctx2);
            await _checkout(ctx);
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final locale = widget.locale;

    if (widget.restaurantId.isEmpty) {
      return _EmptyPane(
        icon: Icons.warning_amber_rounded,
        titleEn: 'Restaurant not configured',
        titleAr: 'لم يُعيَّن مطعم',
        bodyEn: 'Your cashier account is not linked to a restaurant.',
        bodyAr: 'حسابك غير مرتبط بمطعم.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('menu_items')
          .where('vendorId', isEqualTo: widget.restaurantId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('category')
          .orderBy('name')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingPane();
        }
        if (snap.hasError) {
          return _ErrorPane(message: snap.error.toString());
        }

        final allDocs = snap.data?.docs ?? [];

        // Extract categories
        final cats = <String>{'All'};
        for (final d in allDocs) {
          final c = d.data()['category'] as String?;
          if (c != null && c.isNotEmpty) cats.add(c);
        }
        final categories = cats.toList();

        // Apply filters
        final filtered = allDocs.where((d) {
          final data = d.data();
          final cat = data['category'] as String? ?? '';
          final name = (data['name'] as String? ?? '').toLowerCase();
          final catOk = _selectedCategory == 'All' || cat == _selectedCategory;
          final searchOk =
              _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
          return catOk && searchOk;
        }).toList();

        return LayoutBuilder(
          builder: (ctx, c) {
            final isWide = c.maxWidth > 800;

            if (isWide) {
              // Desktop: side-by-side menu + basket
              return Row(
                children: [
                  Expanded(
                    flex: 65,
                    child: _MenuSection(
                      docs: filtered,
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      searchCtrl: _searchCtrl,
                      basket: _basket,
                      locale: locale,
                      onCategoryChange: (c) =>
                          setState(() => _selectedCategory = c),
                      onSearchChange: (q) => setState(() => _searchQuery = q),
                      onAdd: (data, id) => _addItem(data, id),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _kDivider),
                  SizedBox(
                    width: 340,
                    child: _BasketPanel(
                      basket: _basket,
                      subtotal: _subtotal,
                      taxAmount: _taxAmount,
                      totalAmount: _totalAmount,
                      customerName: _customerName,
                      paymentMethod: _paymentMethod,
                      locale: locale,
                      onIncrement: _increment,
                      onDecrement: _decrement,
                      onClear: _clearBasket,
                      onCustomerName: (v) => setState(() => _customerName = v),
                      onPayment: (v) => setState(() => _paymentMethod = v),
                      onCheckout: () => _checkout(ctx),
                    ),
                  ),
                ],
              );
            }

            // Mobile: full-width menu + FAB for basket
            return Stack(
              children: [
                _MenuSection(
                  docs: filtered,
                  categories: categories,
                  selectedCategory: _selectedCategory,
                  searchCtrl: _searchCtrl,
                  basket: _basket,
                  locale: locale,
                  onCategoryChange: (c) =>
                      setState(() => _selectedCategory = c),
                  onSearchChange: (q) => setState(() => _searchQuery = q),
                  onAdd: (data, id) => _addItem(data, id),
                ),
                // Basket FAB
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    onPressed: _itemCount == 0
                        ? null
                        : () => _openMobileBasket(ctx),
                    icon: Badge(
                      isLabelVisible: _itemCount > 0,
                      label: Text('$_itemCount'),
                      backgroundColor: _kAmber,
                      textColor: Colors.white,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    label: Text(
                      _itemCount == 0
                          ? locale.t('Basket', 'السلة')
                          : '${_totalAmount.toStringAsFixed(2)} ﷼',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// Menu Section (left panel on desktop, full-width on mobile)
// =============================================================================

class _MenuSection extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final List<String> categories;
  final String selectedCategory;
  final TextEditingController searchCtrl;
  final Map<String, _BasketEntry> basket;
  final LocaleProvider locale;
  final ValueChanged<String> onCategoryChange;
  final ValueChanged<String> onSearchChange;
  final void Function(Map<String, dynamic> data, String id) onAdd;

  const _MenuSection({
    required this.docs,
    required this.categories,
    required this.selectedCategory,
    required this.searchCtrl,
    required this.basket,
    required this.locale,
    required this.onCategoryChange,
    required this.onSearchChange,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearchChange,
            decoration: InputDecoration(
              hintText: locale.t('Search menu…', 'ابحث في القائمة…'),
              hintStyle: const TextStyle(fontSize: 13, color: _kSub),
              prefixIcon: const Icon(Icons.search, color: _kSub, size: 20),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: _kSub),
                      onPressed: () {
                        searchCtrl.clear();
                        onSearchChange('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: _kCard,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
        ),

        // ── Category chips ────────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final sel = cat == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onCategoryChange(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? _kPrimary : _kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _kPrimary : _kDivider),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _kSub,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // ── Grid ──────────────────────────────────────────────────────
        if (docs.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                locale.t('No items found', 'لا توجد أصناف'),
                style: const TextStyle(color: _kSub, fontSize: 14),
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, c) {
                final cols = c.maxWidth > 900
                    ? 4
                    : c.maxWidth > 600
                    ? 3
                    : 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    final qty = basket[doc.id]?.quantity ?? 0;
                    return _MenuItemTile(
                      data: data,
                      id: doc.id,
                      qty: qty,
                      locale: locale,
                      onTap: () => onAdd(data, doc.id),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// Menu item tile (POS grid card)
class _MenuItemTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  final int qty;
  final LocaleProvider locale;
  final VoidCallback onTap;

  const _MenuItemTile({
    required this.data,
    required this.id,
    required this.qty,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Item';
    final price = _toDouble(data['price']);
    final imageUrl = data['imageUrl'] as String?;
    final category = data['category'] as String? ?? '';
    final inBasket = qty > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inBasket ? _kPrimary : _kDivider,
            width: inBasket ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: inBasket
                  ? _kPrimary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: inBasket ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image zone
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _ItemImgPlaceholder(name: name),
                          )
                        : _ItemImgPlaceholder(name: name),
                  ),
                ),

                // Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category.isNotEmpty)
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 9,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kHead,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${price.toStringAsFixed(2)} ﷼',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Basket quantity badge (top-right)
            if (inBasket)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

            // Tap ripple overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  splashColor: _kPrimary.withValues(alpha: 0.15),
                  highlightColor: _kPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemImgPlaceholder extends StatelessWidget {
  final String name;
  const _ItemImgPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kPrimary.withValues(alpha: 0.07),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 28,
              color: _kPrimary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 4),
            Text(
              name.length > 10 ? '${name.substring(0, 10)}…' : name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: _kPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Desktop Basket Panel (right column, always visible)
// =============================================================================

class _BasketPanel extends StatelessWidget {
  final Map<String, _BasketEntry> basket;
  final double subtotal, taxAmount, totalAmount;
  final String customerName, paymentMethod;
  final LocaleProvider locale;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;
  final VoidCallback onClear;
  final ValueChanged<String> onCustomerName;
  final ValueChanged<String> onPayment;
  final VoidCallback onCheckout;

  const _BasketPanel({
    required this.basket,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.customerName,
    required this.paymentMethod,
    required this.locale,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClear,
    required this.onCustomerName,
    required this.onPayment,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = basket.isEmpty;
    return Container(
      color: _kSurface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: _kCard,
              border: Border(bottom: BorderSide(color: _kDivider)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: _kPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  locale.t('Basket', 'سلة المشتريات'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kHead,
                  ),
                ),
                const Spacer(),
                if (!isEmpty)
                  TextButton(
                    onPressed: onClear,
                    child: Text(
                      locale.t('Clear', 'مسح'),
                      style: const TextStyle(color: _kRed),
                    ),
                  ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: _kDivider,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          locale.t(
                            'Tap items to add',
                            'اضغط على الأصناف للإضافة',
                          ),
                          style: const TextStyle(color: _kSub, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: basket.values
                        .map(
                          (e) => _BasketRow(
                            entry: e,
                            locale: locale,
                            onIncrement: () => onIncrement(e.id),
                            onDecrement: () => onDecrement(e.id),
                          ),
                        )
                        .toList(),
                  ),
          ),

          // Totals + form + checkout
          if (!isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: _kCard,
                border: Border(top: BorderSide(color: _kDivider)),
              ),
              child: Column(
                children: [
                  // Customer name
                  TextField(
                    onChanged: onCustomerName,
                    decoration: InputDecoration(
                      hintText: locale.t(
                        'Customer name (optional)',
                        'اسم العميل (اختياري)',
                      ),
                      hintStyle: const TextStyle(fontSize: 12, color: _kSub),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: _kSub,
                      ),
                      filled: true,
                      fillColor: _kSurface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kDivider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kDivider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: _kPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Payment method
                  _PaymentMethodSelector(
                    selected: paymentMethod,
                    locale: locale,
                    onChanged: onPayment,
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: _kDivider, height: 1),
                  const SizedBox(height: 10),

                  // Arithmetic
                  _TotalRow(
                    locale.t('Subtotal', 'المجموع الفرعي'),
                    subtotal,
                    bold: false,
                  ),
                  const SizedBox(height: 4),
                  _TotalRow(
                    locale.t('VAT (15%)', 'ضريبة القيمة المضافة (15%)'),
                    taxAmount,
                    bold: false,
                    small: true,
                  ),
                  const Divider(color: _kDivider, height: 16),
                  _TotalRow(
                    locale.t('Total', 'الإجمالي'),
                    totalAmount,
                    bold: true,
                  ),

                  const SizedBox(height: 14),

                  // Checkout
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: onCheckout,
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: Text(
                        locale.t('Checkout', 'إتمام الطلب'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Basket row (one item line in the basket panel)
class _BasketRow extends StatelessWidget {
  final _BasketEntry entry;
  final LocaleProvider locale;
  final VoidCallback onIncrement, onDecrement;

  const _BasketRow({
    required this.entry,
    required this.locale,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kHead,
                  ),
                ),
                Text(
                  '${entry.price.toStringAsFixed(2)} ﷼ × ${entry.quantity} = ${entry.lineTotal.toStringAsFixed(2)} ﷼',
                  style: const TextStyle(fontSize: 10, color: _kSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty stepper
          _QtyButton(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${entry.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _kHead,
              ),
            ),
          ),
          _QtyButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: _kPrimary, size: 14),
      ),
    );
  }
}

// =============================================================================
// Mobile Basket Bottom Sheet
// =============================================================================

class _MobileBasketSheet extends StatelessWidget {
  final Map<String, _BasketEntry> basket;
  final double subtotal, taxAmount, totalAmount;
  final LocaleProvider locale;
  final ValueChanged<String> onIncrement, onDecrement;
  final VoidCallback onClear, onCheckout;

  const _MobileBasketSheet({
    required this.basket,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.locale,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClear,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: _kDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    locale.t('Basket', 'السلة'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _kHead,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onClear,
                    child: Text(
                      locale.t('Clear', 'مسح'),
                      style: const TextStyle(color: _kRed),
                    ),
                  ),
                ],
              ),
            ),
            // Items
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: basket.values
                    .map(
                      (e) => _BasketRow(
                        entry: e,
                        locale: locale,
                        onIncrement: () => onIncrement(e.id),
                        onDecrement: () => onDecrement(e.id),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Totals + checkout
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              decoration: const BoxDecoration(
                color: _kCard,
                border: Border(top: BorderSide(color: _kDivider)),
              ),
              child: Column(
                children: [
                  _TotalRow(
                    locale.t('Subtotal', 'الفرعي'),
                    subtotal,
                    bold: false,
                  ),
                  const SizedBox(height: 4),
                  _TotalRow(
                    locale.t('VAT 15%', 'ضريبة 15%'),
                    taxAmount,
                    bold: false,
                    small: true,
                  ),
                  const Divider(color: _kDivider, height: 14),
                  _TotalRow(
                    locale.t('Total', 'الإجمالي'),
                    totalAmount,
                    bold: true,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: onCheckout,
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: Text(
                        locale.t('Checkout', 'إتمام الطلب'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Checkout confirmation bottom sheet
// =============================================================================

class _CheckoutSheet extends StatefulWidget {
  final double subtotal, taxAmount, totalAmount;
  final int itemCount;
  final String customerName, paymentMethod;
  final LocaleProvider locale;
  final ValueChanged<String> onCustomerName, onPayment;

  const _CheckoutSheet({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.itemCount,
    required this.customerName,
    required this.paymentMethod,
    required this.locale,
    required this.onCustomerName,
    required this.onPayment,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late String _method;

  @override
  void initState() {
    super.initState();
    _method = widget.paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.locale;
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _kDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Receipt icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long, color: _kPrimary, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              l.t('Confirm Order', 'تأكيد الطلب'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kHead,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.t(
                '${widget.itemCount} item(s) · SAR ${widget.totalAmount.toStringAsFixed(2)}',
                '${widget.itemCount} صنف · ${widget.totalAmount.toStringAsFixed(2)} ﷼',
              ),
              style: const TextStyle(fontSize: 13, color: _kSub),
            ),

            const SizedBox(height: 20),

            // Customer name
            TextField(
              onChanged: (v) {
                widget.onCustomerName(v);
              },
              decoration: InputDecoration(
                hintText: l.t(
                  'Customer name (optional)',
                  'اسم العميل (اختياري)',
                ),
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                filled: true,
                fillColor: _kSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kDivider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _PaymentMethodSelector(
              selected: _method,
              locale: l,
              onChanged: (v) {
                setState(() => _method = v);
                widget.onPayment(v);
              },
            ),

            const SizedBox(height: 14),
            const Divider(color: _kDivider),
            const SizedBox(height: 10),

            _TotalRow(l.t('Subtotal', 'الفرعي'), widget.subtotal, bold: false),
            const SizedBox(height: 4),
            _TotalRow(
              l.t('VAT (15%)', 'ضريبة (15%)'),
              widget.taxAmount,
              bold: false,
              small: true,
            ),
            const Divider(color: _kDivider, height: 14),
            _TotalRow(l.t('Total', 'الإجمالي'), widget.totalAmount, bold: true),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _kDivider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l.t('Cancel', 'إلغاء'),
                      style: const TextStyle(color: _kSub),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l.t('Post Order', 'تسجيل الطلب'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Payment method selector
// =============================================================================

class _PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final LocaleProvider locale;
  final ValueChanged<String> onChanged;

  const _PaymentMethodSelector({
    required this.selected,
    required this.locale,
    required this.onChanged,
  });

  static const _methods = [
    ('cash', Icons.payments_outlined, 'Cash', 'نقد'),
    ('card', Icons.credit_card_outlined, 'Card', 'بطاقة'),
    ('wallet', Icons.account_balance_wallet_outlined, 'Wallet', 'محفظة'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _methods.map((m) {
        final sel = selected == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(m.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: m == _methods.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: sel ? _kPrimary : _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? _kPrimary : _kDivider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.$2, size: 18, color: sel ? Colors.white : _kSub),
                  const SizedBox(height: 3),
                  Text(
                    locale.isArabic ? m.$4 : m.$3,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : _kSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// Shared utility widgets
// =============================================================================

// Live count card (Firestore aggregation)
class _LiveCountCard extends StatelessWidget {
  final String restaurantId, status, title;
  final IconData icon;
  final Color color;

  const _LiveCountCard({
    required this.restaurantId,
    required this.status,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurantId.isEmpty) {
      return _countCard(count: 0);
    }
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: restaurantId)
          .where('status', isEqualTo: status)
          .count()
          .get(),
      builder: (ctx, snap) {
        final count = snap.data?.count ?? 0;
        return _countCard(count: count);
      },
    );
  }

  Widget _countCard({required int count}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kHead,
                  ),
                ),
                Text(title, style: const TextStyle(fontSize: 10, color: _kSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pane header
class _PaneHeader extends StatelessWidget {
  final IconData icon;
  final String titleEn, titleAr, subtitleEn, subtitleAr;

  const _PaneHeader({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.isArabic ? titleAr : titleEn,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _kHead,
                ),
              ),
              Text(
                locale.isArabic ? subtitleAr : subtitleEn,
                style: const TextStyle(fontSize: 11, color: _kSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Total row in basket / checkout
class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold, small;
  const _TotalRow(
    this.label,
    this.amount, {
    required this.bold,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: small ? 11 : 13,
            color: bold ? _kHead : _kSub,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          '${amount.toStringAsFixed(2)} ﷼',
          style: TextStyle(
            fontSize: bold ? 17 : (small ? 11 : 13),
            color: bold ? _kPrimary : _kSub,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Section label
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _kHead,
    ),
  );
}

// Loading, Error, Empty, Placeholder panes
class _LoadingPane extends StatelessWidget {
  const _LoadingPane();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _kPrimary),
        SizedBox(height: 16),
        Text('Loading…', style: TextStyle(color: _kSub)),
      ],
    ),
  );
}

class _ErrorPane extends StatelessWidget {
  final String message;
  const _ErrorPane({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off, size: 48, color: _kRed),
        const SizedBox(height: 12),
        const Text(
          'Firestore Error',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kHead),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _kSub),
          ),
        ),
      ],
    ),
  );
}

class _EmptyPane extends StatelessWidget {
  final IconData icon;
  final String titleEn, titleAr, bodyEn, bodyAr;
  const _EmptyPane({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: _kPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              locale.isArabic ? titleAr : titleEn,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kHead,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              locale.isArabic ? bodyAr : bodyEn,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPane extends StatelessWidget {
  final IconData icon;
  final String titleEn, titleAr;
  const _PlaceholderPane({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: _kPrimary),
          ),
          const SizedBox(height: 20),
          Text(
            locale.isArabic ? titleAr : titleEn,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kHead,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locale.t('Coming soon', 'قريباً'),
            style: const TextStyle(fontSize: 14, color: _kSub),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private helpers
// =============================================================================

List<Map<String, dynamic>> _extractItems(dynamic raw) {
  if (raw is List) {
    return raw.whereType<Map<String, dynamic>>().toList();
  }
  return [];
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

String _elapsed(dynamic raw) {
  if (raw == null) return '—';
  DateTime? dt;
  if (raw is Timestamp) dt = raw.toDate();
  if (raw is String) dt = DateTime.tryParse(raw);
  if (dt == null) return '—';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
}
