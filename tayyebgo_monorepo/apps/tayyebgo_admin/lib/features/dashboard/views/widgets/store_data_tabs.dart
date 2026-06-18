import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../../../../core/widgets/app_empty_state.dart' as empty;
import '../shared.dart';

class StoreOverviewTab extends StatelessWidget {
  final Map<String, dynamic> store;
  const StoreOverviewTab({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Store Overview', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
        const SizedBox(height: 16),
        _infoRow(context, 'Phone', store['phone'] as String? ?? '-'),
        _infoRow(context, 'Street', store['street'] as String? ?? '-'),
        _infoRow(context, 'City', store['city'] as String? ?? '-'),
        _infoRow(context, 'Owner ID', store['ownerId'] as String? ?? '-'),
        _infoRow(context, 'Created', store['createdAt'] != null ? _formatDate((store['createdAt'] as Timestamp).toDate()) : '-'),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor))),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: context.textPrimaryColor))),
      ]),
    );
  }

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class StoreProductsTab extends StatelessWidget {
  final String storeId;
  const StoreProductsTab({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchStoreProducts(storeId, limit: 50),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AdminEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              subtitle: 'Products added in the store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Products', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
              const Spacer(),
              Text('${docs.length} items', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...docs.map((pd) {
              final name = pd['name'] as String? ?? 'Unnamed';
              final price = (pd['price'] as num?)?.toDouble() ?? 0;
              final available = pd['isAvailable'] as bool? ?? true;
              return ListTile(
                dense: true,
                leading: Icon(Icons.shopping_bag_outlined, color: context.primaryColor, size: 20),
                title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
                subtitle: Text('\$${price.toStringAsFixed(2)}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (available ? context.successColor : context.errorColor).withValues(alpha: 0.1),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(available ? 'In stock' : 'Out', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: available ? context.successColor : context.errorColor)),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }
}

class StoreCategoriesTab extends StatelessWidget {
  final String storeId;
  const StoreCategoriesTab({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchStoreCategories(storeId, limit: 50),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AdminEmptyState(
              icon: Icons.category_outlined,
              title: 'No categories configured',
              subtitle: 'Menu categories added in the store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Menu Categories', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: docs.map((cd) {
              final name = cd['name'] as String? ?? 'Unnamed';
              return Chip(
                label: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12)),
                backgroundColor: context.primaryColor.withValues(alpha: 0.08),
                side: BorderSide(color: context.primaryColor.withValues(alpha: 0.2)),
                labelStyle: GoogleFonts.inter(color: context.primaryColor),
              );
            }).toList()),
          ]);
        },
      ),
    );
  }
}

class StoreOrdersTab extends StatelessWidget {
  final String storeId;
  const StoreOrdersTab({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchOrdersRaw(filter: OrderFilter(storeId: storeId), limit: 20),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AdminEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Orders placed at this store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Recent Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
              const Spacer(),
              Text('${docs.length} total', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...docs.map((od) {
              final total = (od['total'] as num?)?.toDouble() ?? 0;
              final status = od['status'] as String? ?? 'unknown';
              final orderNum = od['orderNumber'] as String? ?? (od['id'] as String? ?? '').substring(0, 6);
              return ListTile(
                dense: true,
                leading: Icon(Icons.receipt_outlined, color: context.primaryColor, size: 20),
                title: Text('Order #$orderNum', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
                subtitle: Text(status.toUpperCase(), style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
                trailing: Text('\$${total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
              );
            }),
          ]);
        },
      ),
    );
  }
}

class StoreDriversTab extends StatelessWidget {
  final String storeId;
  const StoreDriversTab({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchDriverAssignments(storeId, limit: 20),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 3);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return empty.AdminEmptyState(
              icon: Icons.delivery_dining,
              title: 'No drivers assigned yet',
              subtitle: 'Drivers assigned to this store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assigned Drivers', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
            const SizedBox(height: 12),
            ...docs.map((dd) {
              final name = dd['driverName'] as String? ?? 'Unknown';
              final active = dd['isActive'] as bool? ?? true;
              return ListTile(
                dense: true,
                leading: Icon(Icons.delivery_dining, color: context.primaryColor, size: 20),
                title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (active ? context.successColor : context.errorColor).withValues(alpha: 0.1),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(active ? 'Active' : 'Inactive', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: active ? context.successColor : context.errorColor)),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }
}

class StoreContractsTab extends StatelessWidget {
  final String storeName;
  const StoreContractsTab({required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminFirestoreService.instance.watchContractsForStore(storeName, limit: 10),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const ShimmerLoading(itemCount: 2);
          }
          final docs = snap.data ?? const [];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Contracts & Subscriptions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Text('No contracts found for this store.', style: GoogleFonts.inter(color: context.textMutedColor))
            else
              ...docs.map((cd) {
                final status = cd['isActive'] as bool? ?? false;
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.description, color: context.primaryColor),
                  title: Text('Contract ${status ? '(Active)' : '(Inactive)'}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                  trailing: Text(status ? 'Active' : 'Inactive', style: GoogleFonts.inter(color: status ? context.successColor : context.errorColor)),
                );
              }),
          ]);
        },
      ),
    );
  }
}
