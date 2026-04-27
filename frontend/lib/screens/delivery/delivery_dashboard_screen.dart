import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/omni_theme.dart';
import '../../main.dart';
import '../login_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isOnline = true;
  int _selectedTab = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final auth = context.watch<AuthProvider>();
    final isArabic = locale.isArabic;
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 400;

    String t(String en, String ar) => isArabic ? ar : en;

    // Demo stats
    final stats = {
      'todayEarnings': 45.0,
      'weekEarnings': 320.0,
      'monthEarnings': 1250.0,
      'totalOrders': 89,
      'completedToday': 8,
      'rating': 4.8,
      'onlineHours': 6,
    };

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(
        title: Row(children: [
          TweenAnimationBuilder<double>(tween: Tween(begin: 0.8, end: 1.0), duration: Duration(milliseconds: 1000), curve: Curves.elasticOut, builder: (context, value, child) => Transform.scale(scale: value, child: Icon(Icons.delivery_dining, size: 26))),
          const SizedBox(width: 8),
          Text(t('Driver Dashboard', 'لوحة السائق')),
        ]),
        backgroundColor: OmniTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Row(children: [
              Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _isOnline ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(_isOnline ? Icons.circle : Icons.circle, size: 8, color: Colors.white), SizedBox(width: 4), Text(_isOnline ? 'ON' : 'OFF', style: TextStyle(fontSize: 10, color: Colors.white))])),
              Switch(value: _isOnline, onChanged: (v) => setState(() => _isOnline = v), activeColor: Colors.greenAccent),
            ]),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: OmniTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(children: [
                // Stats Cards
                Container(
                  padding: EdgeInsets.all(isSmall ? 12 : 16),
                  child: Column(children: [
                    // Earnings Row
                    Row(children: [
                      _StatCard(title: t("Today's Earnings", 'أرباح اليوم'), value: '\$${stats['todayEarnings']}', icon: Icons.today, color: Colors.green),
                      SizedBox(width: 10),
                      _StatCard(title: t("This Week", 'هذا الأسبوع'), value: '\$${stats['weekEarnings']}', icon: Icons.date_range, color: Colors.blue),
                    ]),
                    SizedBox(height: 10),
                    Row(children: [
                      _StatCard(title: t("Total Orders", 'إجمالي الطلبات'), value: '${stats['totalOrders']}', icon: Icons.shopping_bag, color: Colors.purple),
                      SizedBox(width: 10),
                      _StatCard(title: t("Rating", 'التقييم'), value: '${stats['rating']}', icon: Icons.star, color: Colors.amber, iconColor: Colors.amber),
                    ]),
                  ]),
                ),
                SizedBox(height: 8),
                
                // Quick Actions
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
                  child: Row(children: [
                    _QuickAction(icon: Icons.history, label: t('History', 'السجل'), onTap: () {}),
                    _QuickAction(icon: Icons.wallet, label: t('Wallet', 'المحفظة'), onTap: () {}),
                    _QuickAction(icon: Icons.chat, label: t('Support', 'الدعم'), onTap: () {}),
                    _QuickAction(icon: Icons.settings, label: t('Settings', 'الإعدادات'), onTap: () {}),
                  ]),
                ),
                SizedBox(height: 16),

                // Tab Selector
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    _TabButton(label: t('New Orders', 'طلبات جديدة'), selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                    _TabButton(label: t('Active Orders', 'نشطة'), selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                    _TabButton(label: t('Completed', 'مكتملة'), selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
                  ]),
                ),
                SizedBox(height: 12),

                // Orders List
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
                    children: [
                      _OrderCard(
                        id: '#ORD-2847',
                        customer: 'Ahmed K.',
                        address: 'Al-Midan, Damascus',
                        items: 3,
                        total: 25.50,
                        distance: '2.5 km',
                        time: '15 min',
                        status: 'new',
                      ),
                      _OrderCard(
                        id: '#ORD-2846',
                        customer: 'Sara M.',
                        address: 'Al-Merjeh, Aleppo',
                        items: 2,
                        total: 18.00,
                        distance: '1.2 km',
                        time: '10 min',
                        status: 'new',
                      ),
                      _OrderCard(
                        id: '#ORD-2845',
                        customer: 'Omar R.',
                        address: 'Al-Hamra, Homs',
                        items: 5,
                        total: 42.00,
                        distance: '3.8 km',
                        time: '20 min',
                        status: 'new',
                      ),
                    ],
                  ),
                ),
              ]),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? iconColor;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor ?? color, size: 16)), Spacer()]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ]),
    ));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: OmniTheme.primaryColor, size: 22)),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ]),
    ));
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: selected ? OmniTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey[600])),
      ),
    ));
  }
}

class _OrderCard extends StatelessWidget {
  final String id;
  final String customer;
  final String address;
  final int items;
  final double total;
  final String distance;
  final String time;
  final String status;

  const _OrderCard({required this.id, required this.customer, required this.address, required this.items, required this.total, required this.distance, required this.time, required this.status});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(id, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Spacer(),
          Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(t('New', 'جديد'), style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600))),
        ]),
        SizedBox(height: 10),
        Row(children: [Icon(Icons.person, size: 16, color: Colors.grey), SizedBox(width: 8), Text(customer, style: TextStyle(fontWeight: FontWeight.w500))]),
        SizedBox(height: 6),
        Row(children: [Icon(Icons.location_on, size: 16, color: Colors.grey), SizedBox(width: 8), Expanded(child: Text(address, style: TextStyle(color: Colors.grey[600], fontSize: 12)))]),
        SizedBox(height: 10),
        Row(children: [
          _MiniChip(icon: Icons.shopping_bag, label: '$items items'),
          SizedBox(width: 8),
          _MiniChip(icon: Icons.straighten, label: distance),
          SizedBox(width: 8),
          _MiniChip(icon: Icons.access_time, label: time),
          Spacer(),
          Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OmniTheme.primaryColor)),
        ]),
        SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 40, child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: OmniTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(t('Accept Order', 'قبول الطلب'), style: TextStyle(fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.grey), SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey))]));
  }
}