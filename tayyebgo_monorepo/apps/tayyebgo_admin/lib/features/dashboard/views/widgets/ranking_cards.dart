import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../../../../core/widgets/app_empty_state.dart' as empty;
import '../shared.dart';

class TopStoresCard extends StatelessWidget {
  const TopStoresCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Top Stores This Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Ranked by revenue', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminFirestoreService.instance.watchStoresRaw(filter: const StoreFilter(isActive: true), limit: 50),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const ShimmerLoading(itemCount: 5, itemHeight: 40);
              }
              final stores = [...?snap.data];
              stores.sort((a, b) {
                final ar = (a['revenue'] as num?) ?? 0;
                final br = (b['revenue'] as num?) ?? 0;
                return br.compareTo(ar);
              });
              if (stores.isEmpty) {
                return empty.AdminEmptyState(
                  icon: Icons.storefront,
                  title: 'No store data yet',
                  subtitle: 'Once stores generate revenue, they will appear here.',
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < stores.take(5).length; i++) ...[
                    rankingRow(
                      context,
                      rank: i + 1,
                      name: stores[i]['name'] as String? ?? 'Store',
                      value: 'SYP ${((stores[i]['revenue'] as num?) ?? 0).toStringAsFixed(0)}',
                      icon: medalIcon(i),
                    ),
                    if (i < 4) const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class TopDriversCard extends StatelessWidget {
  const TopDriversCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Top Drivers This Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Ranked by deliveries', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminFirestoreService.instance.watchDriversRaw(filter: const DriverFilter(status: 'active'), limit: 50),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const ShimmerLoading(itemCount: 5, itemHeight: 40);
              }
              final drivers = [...?snap.data];
              drivers.sort((a, b) {
                final ar = (a['deliveries'] as num?) ?? 0;
                final br = (b['deliveries'] as num?) ?? 0;
                return br.compareTo(ar);
              });
              if (drivers.isEmpty) {
                return empty.AdminEmptyState(
                  icon: Icons.delivery_dining,
                  title: 'No driver data yet',
                  subtitle: 'Once drivers complete deliveries, they will appear here.',
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < drivers.take(5).length; i++) ...[
                    rankingRow(
                      context,
                      rank: i + 1,
                      name: (drivers[i]['displayName'] as String?)
                          ?? (drivers[i]['name'] as String?)
                          ?? 'Driver',
                      value: '${drivers[i]['deliveries'] ?? 0} deliveries',
                      icon: medalIcon(i),
                    ),
                    if (i < 4) const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget rankingRow(BuildContext context, {required int rank, required String name, required String value, required IconData icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank <= 3 ? AppColors.warning.withValues(alpha: 0.15) : context.dividerColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rank <= 3 ? AppColors.warning : context.textMutedColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
        ),
        Text(value, style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
      ],
    ),
  );
}

IconData medalIcon(int rank) {
  return rank == 0 ? Icons.looks_one : rank == 1 ? Icons.looks_two : rank == 2 ? Icons.looks_3 : Icons.circle;
}
