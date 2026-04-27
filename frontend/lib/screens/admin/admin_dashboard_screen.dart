import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/omni_theme.dart';
import '../../main.dart';
import 'admin_products_screen.dart';
import 'admin_delivery_applications_screen.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    _stats = {
      'totalOrders': 156, 'totalRevenue': 4520.0, 'totalProducts': 45, 'totalUsers': 89,
      'totalDrivers': 12, 'pendingOrders': 8, 'deliveredOrders': 142, 'dailySales': 320.0,
      'ordersByDay': [
        {'revenue': 340.0}, {'revenue': 520.0}, {'revenue': 420.0}, {'revenue': 680.0},
        {'revenue': 550.0}, {'revenue': 720.0}, {'revenue': 810.0},
      ],
    };
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final auth = context.watch<AuthProvider>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 800;
    final isTablet = w > 500 && w <= 800;

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('Admin Panel', 'لوحة المسؤول')),
        backgroundColor: OmniTheme.surfaceColor,
        foregroundColor: OmniTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context, auth, isArabic)),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(onRefresh: _loadStats, child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isWide ? 24 : 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('Dashboard', 'لوحة التحكم'), style: TextStyle(fontSize: isWide ? 28 : 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(t('Welcome back!', 'مرحباً بعودتك!'), style: TextStyle(color: OmniTheme.textSecondary)),
                SizedBox(height: isWide ? 28 : 20),

                GridView.count(
                  crossAxisCount: isWide ? 4 : (isTablet ? 2 : 2),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.3 : 1.4,
                  children: [
                    _StatCard(title: t('Revenue', 'الإيرادات'), value: '\$${(_stats?['totalRevenue'] ?? 0).toStringAsFixed(0)}', icon: Icons.attach_money, color: OmniTheme.successColor),
                    _StatCard(title: t('Orders', 'الطلبات'), value: '${_stats?['totalOrders'] ?? 0}', icon: Icons.shopping_bag, color: OmniTheme.primaryColor),
                    _StatCard(title: t('Products', 'المنتجات'), value: '${_stats?['totalProducts'] ?? 0}', icon: Icons.inventory_2, color: Colors.purple),
                    _StatCard(title: t('Drivers', 'السائقين'), value: '${_stats?['totalDrivers'] ?? 0}', icon: Icons.delivery_dining, color: Colors.teal),
                  ],
                ),
                SizedBox(height: isWide ? 32 : 24),

                Text(t('Revenue (Last 7 Days)', 'الإيرادات (آخر 7 أيام)'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  height: isWide ? 250 : 180,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: ((_stats?['ordersByDay'] as List?)?.map((e) => (e['revenue'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a > b ? a : b) ?? 0.0) * 1.2 + 100,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(show: true, bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt() % 7], style: TextStyle(fontSize: 10, color: OmniTheme.textMuted))))),
                      barGroups: (_stats?['ordersByDay'] as List?)?.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value['revenue'] as num?)?.toDouble() ?? 0, color: OmniTheme.primaryColor, width: isWide ? 24 : 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])).toList() ?? [],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                Row(children: [
                  Expanded(child: _QuickStat(label: t('Pending', 'قيد'), value: '${_stats?['pendingOrders'] ?? 0}', color: Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickStat(label: t('Delivered', 'مكتمل'), value: '${_stats?['deliveredOrders'] ?? 0}', color: Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickStat(label: t('Today', 'اليوم'), value: '\$${(_stats?['dailySales'] ?? 0).toStringAsFixed(0)}', color: Colors.blue)),
                ]),
                SizedBox(height: 24),

                Text(t('Quick Actions', 'إجراءات سريعة'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _MenuItem(icon: Icons.inventory_2, title: t('Products', 'المنتجات'), subtitle: t('Manage products', 'إدارة المنتجات'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsScreen()))),
                _MenuItem(icon: Icons.people, title: t('Drivers', 'السائقين'), subtitle: t('Delivery applications', 'طلبات التوصيل'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDeliveryApplicationsScreen()))),
                _MenuItem(icon: Icons.analytics, title: t('Analytics', 'التحليلات'), subtitle: t('View detailed stats', 'عرض الإحصائيات'), onTap: () {}),
              ]),
            )),
    );
  }

  void _logout(BuildContext context, AuthProvider auth, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'Logout' : 'تسجيل الخروج'),
        content: Text(isArabic ? 'Are you sure?' : 'هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'Cancel' : 'إلغاء')),
          FilledButton(onPressed: () { auth.logout(); Navigator.pop(ctx); Navigator.pushAndRemoveUntil(context, SmoothPageTransition(page: const LoginScreen()), (route) => false); }, style: FilledButton.styleFrom(backgroundColor: OmniTheme.errorColor), child: Text(isArabic ? 'Logout' : 'خروج')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 12, color: OmniTheme.textSecondary)),
      ]),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)), Text(label, style: TextStyle(fontSize: 11, color: OmniTheme.textSecondary))]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: OmniTheme.primaryColor, size: 22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: OmniTheme.textMuted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: OmniTheme.textMuted),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}