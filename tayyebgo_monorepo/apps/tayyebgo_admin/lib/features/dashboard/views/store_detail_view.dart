import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class StoreDetailView extends StatelessWidget {
  final String storeId;
  const StoreDetailView({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Store Detail', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('restaurants').doc(storeId).get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
            if (snap.hasError) return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                  const SizedBox(height: 12),
                  Text('Error loading store', style: GoogleFonts.inter(color: context.textMutedColor)),
                  const SizedBox(height: 8),
                  Text('${snap.error}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            );
            if (!snap.hasData || !snap.data!.exists) return Center(child: Text('Store not found', style: GoogleFonts.inter(color: context.textMutedColor)));
            final d = snap.data!.data() as Map<String, dynamic>;
            return _buildDetail(context, d);
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Map<String, dynamic> d) {
    final name = d['name'] as String? ?? 'Unnamed';
    final cuisine = d['cuisineType'] as String? ?? 'N/A';
    final phone = d['phone'] as String? ?? '—';
    final address = d['address'] as String? ?? '—';
    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
    final totalOrders = (d['totalOrders'] as num?)?.toInt() ?? 0;
    final isActive = d['isActive'] == true;
    final isOpen = d['isOpenNow'] == true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.store_rounded, color: context.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isActive ? context.successColor : context.textMutedColor).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isActive ? 'Active' : 'Inactive', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? context.successColor : context.textMutedColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(cuisine, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth < 500 ? 2 : 4;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _miniStat(context, Icons.star_rounded, 'Rating', rating > 0 ? rating.toStringAsFixed(1) : '—', context.warningColor),
                  _miniStat(context, Icons.receipt_long_rounded, 'Orders', '$totalOrders', context.primaryColor),
                  _miniStat(context, Icons.circle_rounded, 'Open', isOpen ? 'Yes' : 'No', isOpen ? context.successColor : context.textMutedColor),
                  _miniStat(context, Icons.phone_rounded, 'Phone', phone, context.textMutedColor),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _infoSection(context, 'Address', address),
          _buildRecentOrders(context),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
        ],
      ),
    );
  }

  Widget _infoSection(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Orders', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('restaurantId', isEqualTo: storeId).limit(10).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return Center(child: Text('No orders', style: GoogleFonts.inter(color: context.textMutedColor)));
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final status = d['status'] as String? ?? 'unknown';
                final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
                final createdAt = d['createdAt'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                            const SizedBox(height: 2),
                            Text('${amount.toStringAsFixed(0)} SYP · $status', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                          ],
                        ),
                      ),
                      if (createdAt is Timestamp)
                        Text(_formatDate(createdAt), style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}
