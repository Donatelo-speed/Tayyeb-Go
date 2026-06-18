import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});

  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String? get _restaurantId {
    final auth = context.read<AuthProvider>();
    return auth.user?.vendorId;
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurantId == null) {
      return const Scaffold(body: Center(child: Text('No restaurant found')));
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textMutedColor,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                prefixIcon: Icon(Icons.search_rounded, color: context.textMutedColor, size: 20),
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('restaurantId', isEqualTo: _restaurantId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final orders = snapshot.data?.docs ?? [];
                if (orders.isEmpty) {
                  return const TGEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No orders yet',
                    description: 'Orders from customers will appear here.',
                  );
                }
                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildOrderList(orders, ['pending', 'confirmed']),
                    _buildOrderList(orders, ['preparing', 'ready_for_pickup']),
                    _buildOrderList(orders, ['ready']),
                    _buildOrderList(orders, ['delivered', 'completed']),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<DocumentSnapshot> orders, List<String> statuses) {
    final filtered = orders.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? '';
      final matchesStatus = statuses.contains(status);
      if (_searchQuery.isEmpty) return matchesStatus;
      final customerName = (data['customerName'] as String?)?.toLowerCase() ?? '';
      final orderId = doc.id.toLowerCase();
      return matchesStatus && (customerName.contains(_searchQuery) || orderId.contains(_searchQuery));
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: context.textMutedColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No orders in this category', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];
        final data = doc.data() as Map<String, dynamic>;
        return _OrderCard(orderId: doc.id, data: data);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _OrderCard({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] as String?) ?? 'unknown';
    final customerName = data['customerName'] ?? 'Customer';
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final items = (data['items'] as List?) ?? [];
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusBadge(status),
              const Spacer(),
              Text(timeAgo, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: context.textMutedColor),
              const SizedBox(width: 6),
              Text(customerName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
              const Spacer(),
              Text('SYP ${total.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${items.length} item${items.length == 1 ? '' : 's'}', style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
          const SizedBox(height: 12),
          _buildActionButtons(context, status),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (color, label) = switch (status) {
      'pending' => (AppColors.warning, 'New'),
      'confirmed' => (AppColors.primary, 'Confirmed'),
      'preparing' => (const Color(0xFFF97316), 'Preparing'),
      'ready' => (AppColors.success, 'Ready'),
      'ready_for_pickup' => (AppColors.success, 'Ready'),
      'delivered' => (AppColors.textMuted, 'Delivered'),
      'completed' => (AppColors.textMuted, 'Completed'),
      'cancelled' => (AppColors.error, 'Cancelled'),
      _ => (AppColors.textMuted, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _actionBtn(context, 'Accept', AppColors.success, () => _updateStatus(context, 'confirmed')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(context, 'Reject', AppColors.error, () => _updateStatus(context, 'cancelled')),
          ),
        ],
      );
    }
    if (status == 'confirmed' || status == 'preparing') {
      return _actionBtn(context, 'Mark Ready', AppColors.success, () => _updateStatus(context, 'ready'));
    }
    if (status == 'ready' || status == 'ready_for_pickup') {
      return _actionBtn(context, 'Mark Picked Up', AppColors.primary, () => _updateStatus(context, 'delivered'));
    }
    return const SizedBox.shrink();
  }

  Widget _actionBtn(BuildContext context, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          elevation: 0,
        ),
        child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to $newStatus'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
