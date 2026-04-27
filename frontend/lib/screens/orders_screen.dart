import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/omni_theme.dart';
import '../main.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final List<_Order> _orders = [];
  int _selectedFilter = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animController.forward();
    _loadOrders();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.addAll([
      _Order(id: '#ORD-2847', date: DateTime.now().subtract(const Duration(hours: 2)), status: 'processing', total: 45.50, items: 3),
      _Order(id: '#ORD-2846', date: DateTime.now().subtract(const Duration(days: 1)), status: 'shipped', total: 28.00, items: 2),
      _Order(id: '#ORD-2845', date: DateTime.now().subtract(const Duration(days: 2)), status: 'delivered', total: 62.00, items: 5, rating: 5),
      _Order(id: '#ORD-2844', date: DateTime.now().subtract(const Duration(days: 5)), status: 'delivered', total: 35.00, items: 3, rating: 4),
      _Order(id: '#ORD-2843', date: DateTime.now().subtract(const Duration(days: 7)), status: 'delivered', total: 89.00, items: 7, rating: 5),
    ]);
    setState(() => _isLoading = false);
  }

  List<_Order> get _filtered {
    if (_selectedFilter == 0) return _orders;
    if (_selectedFilter == 1) return _orders.where((o) => o.status == 'processing' || o.status == 'shipped').toList();
    return _orders.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;
    final filters = [t('All', 'الكل'), t('Active', 'نشطة'), t('Completed', 'مكتملة')];

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('My Orders', 'طلباتي')),
        backgroundColor: OmniTheme.surfaceColor,
        foregroundColor: OmniTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [OmniTheme.primaryColor, OmniTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Stat(label: t('Total', 'الإجمالي'), value: '${_orders.length}'),
            _Stat(label: t('Delivered', 'مكتملة'), value: '${_orders.where((o) => o.status == 'delivered').length}'),
            _Stat(label: t('In Progress', 'قيد'), value: '${_orders.where((o) => o.status != 'delivered').length}'),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(12)),
          child: Row(children: filters.asMap().entries.map((e) => Expanded(child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _selectedFilter == e.key ? OmniTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
              child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _selectedFilter == e.key ? Colors.white : OmniTheme.textMuted)),
            ),
          ))).toList()),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const LoadingWidget()
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 64, color: OmniTheme.textMuted), const SizedBox(height: 12), Text(t('No orders', 'لا توجد طلبات'), style: TextStyle(color: OmniTheme.textSecondary))]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) => _OrderCard(order: _filtered[index], isArabic: isArabic, onTap: () => _showDetails(context, _filtered[index], isArabic)),
                    ),
        ),
      ]),
    );
  }

  void _showDetails(BuildContext context, _Order order, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(controller: scrollController, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: OmniTheme.borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(order.id, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _StatusTracker(status: order.status, isArabic: isArabic),
            const SizedBox(height: 24),
            _DetailRow(label: isArabic ? 'التاريخ' : 'Date', value: '${order.date.day}/${order.date.month}/${order.date.year}'),
            _DetailRow(label: isArabic ? 'عدد المنتجات' : 'Items', value: '${order.items}'),
            _DetailRow(label: isArabic ? 'المجموع' : 'Total', value: '\$${order.total.toStringAsFixed(2)}'),
            _DetailRow(label: isArabic ? 'الحالة' : 'Status', value: _statusLabel(order.status, isArabic)),
            if (order.status == 'delivered' && order.rating == null) ...[
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () {}, child: Text(isArabic ? 'قيّم الطلب' : 'Rate Order'))),
            ],
          ]),
        ),
      ),
    );
  }

  String _statusLabel(String status, bool isArabic) {
    switch (status) { case 'processing': return isArabic ? 'قيد التحضير' : 'Processing'; case 'shipped': return isArabic ? 'شحن' : 'Shipped'; case 'delivered': return isArabic ? 'تم التوصيل' : 'Delivered'; case 'cancelled': return isArabic ? 'ملغى' : 'Cancelled'; default: return status; }
  }
}

class _Order {
  final String id, status;
  final DateTime date;
  final double total;
  final int items;
  final int? rating;
  _Order({required this.id, required this.date, required this.status, required this.total, required this.items, this.rating});
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70))]);
}

class _OrderCard extends StatelessWidget {
  final _Order order;
  final bool isArabic;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(_statusLabel(order.status, isArabic), style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.shopping_bag, size: 16, color: OmniTheme.textMuted),
            const SizedBox(width: 8),
            Text('${order.items} ${isArabic ? 'منتجات' : 'items'}', style: TextStyle(color: OmniTheme.textSecondary)),
            const Spacer(),
            Text('\$${order.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: OmniTheme.primaryColor)),
          ]),
          if (order.rating != null) ...[const SizedBox(height: 8), Row(children: List.generate(5, (i) => Icon(i < order.rating! ? Icons.star : Icons.star_border, size: 16, color: Colors.amber)))],
        ]),
      ),
    );
  }

  String _statusLabel(String status, bool isArabic) {
    switch (status) { case 'processing': return isArabic ? 'قيد التحضير' : 'Processing'; case 'shipped': return isArabic ? 'شحن' : 'Shipped'; case 'delivered': return isArabic ? 'تم التوصيل' : 'Delivered'; case 'cancelled': return isArabic ? 'ملغى' : 'Cancelled'; default: return status; }
  }

  Color _getStatusColor(String status) {
    switch (status) { case 'processing': return Colors.orange; case 'shipped': return Colors.blue; case 'delivered': return Colors.green; case 'cancelled': return Colors.red; default: return Colors.grey; }
  }
}

class _StatusTracker extends StatelessWidget {
  final String status;
  final bool isArabic;
  const _StatusTracker({required this.status, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final steps = ['processing', 'shipped', 'delivered'];
    final idx = steps.indexOf(status);
    return Row(children: steps.asMap().entries.map((e) => Expanded(child: Column(children: [
      Container(height: 4, decoration: BoxDecoration(color: idx >= e.key ? Colors.green : OmniTheme.borderColor, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 4),
      Text(['Processing', 'Shipped', 'Delivered'][e.key], style: TextStyle(fontSize: 10, color: idx >= e.key ? Colors.green : OmniTheme.textMuted)),
    ]))).toList());
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: OmniTheme.textSecondary)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500))]));
}