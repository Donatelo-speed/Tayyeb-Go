import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
        Text('Store Overview', style: AppTypography.heading3),
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
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: context.textSecondaryColor))),
        Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: context.textPrimaryColor))),
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
            return empty.AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              subtitle: 'Products added in the store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Products', style: AppTypography.heading3),
              const Spacer(),
              Text('${docs.length} items', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...docs.map((pd) {
              final name = pd['name'] as String? ?? 'Unnamed';
              final price = (pd['price'] as num?)?.toDouble() ?? 0;
              final available = pd['isAvailable'] as bool? ?? true;
              return ListTile(
                dense: true,
                leading: Icon(Icons.shopping_bag_outlined, color: context.primaryColor, size: 20),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('\$${price.toStringAsFixed(2)}', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (available ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(available ? 'In stock' : 'Out', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: available ? AppColors.success : AppColors.error)),
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
            return empty.AppEmptyState(
              icon: Icons.category_outlined,
              title: 'No categories configured',
              subtitle: 'Menu categories added in the store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Menu Categories', style: AppTypography.heading3),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: docs.map((cd) {
              final name = cd['name'] as String? ?? 'Unnamed';
              return Chip(
                label: Text(name),
                backgroundColor: context.primaryColor.withValues(alpha: 0.08),
                side: BorderSide(color: context.primaryColor.withValues(alpha: 0.2)),
                labelStyle: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w500, fontSize: 12),
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
            return empty.AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Orders placed at this store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Recent Orders', style: AppTypography.heading3),
              const Spacer(),
              Text('${docs.length} total', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...docs.map((od) {
              final total = (od['total'] as num?)?.toDouble() ?? 0;
              final status = od['status'] as String? ?? 'unknown';
              final orderNum = od['orderNumber'] as String? ?? (od['id'] as String? ?? '').substring(0, 6);
              return ListTile(
                dense: true,
                leading: Icon(Icons.receipt_outlined, color: context.primaryColor, size: 20),
                title: Text('Order #$orderNum', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(status.toUpperCase(), style: TextStyle(color: context.textSecondaryColor, fontSize: 11)),
                trailing: Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
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
            return empty.AppEmptyState(
              icon: Icons.delivery_dining,
              title: 'No drivers assigned yet',
              subtitle: 'Drivers assigned to this store will appear here.',
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assigned Drivers', style: AppTypography.heading3),
            const SizedBox(height: 12),
            ...docs.map((dd) {
              final name = dd['driverName'] as String? ?? 'Unknown';
              final active = dd['isActive'] as bool? ?? true;
              return ListTile(
                dense: true,
                leading: Icon(Icons.delivery_dining, color: context.primaryColor, size: 20),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (active ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? AppColors.success : AppColors.error)),
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
            Text('Contracts & Subscriptions', style: AppTypography.heading3),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Text('No contracts found for this store.', style: TextStyle(color: context.textMutedColor))
            else
              ...docs.map((cd) {
                final status = cd['isActive'] as bool? ?? false;
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.description, color: context.primaryColor),
                  title: Text('Contract ${status ? '(Active)' : '(Inactive)'}', style: AppTypography.bodyBold),
                  trailing: Text(status ? 'Active' : 'Inactive', style: TextStyle(color: status ? AppColors.success : AppColors.error)),
                );
              }),
          ]);
        },
      ),
    );
  }
}
