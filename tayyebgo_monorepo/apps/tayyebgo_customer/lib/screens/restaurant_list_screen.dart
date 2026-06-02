import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nearby Restaurants',
      body: StreamBuilder<QuerySnapshot>(
        key: ValueKey('restaurant_list_$_retryKey'),
        stream: FirebaseFirestore.instance
            .collection('Restaurants')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snap) {
          final friendlyError = snap.hasError
              ? 'Unable to load restaurants right now. Please try again.'
              : null;
          return TripleStateWidget(
            state: snap.hasError
                ? TripleState.error
                : !snap.hasData
                    ? TripleState.loading
                    : TripleState.success,
            errorMessage: friendlyError,
            onRetry: () => setState(() => _retryKey++),
            shimmerItemCount: 5,
            child: snap.hasData
                ? _buildContent(context, snap.data!)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, QuerySnapshot snap) {
    if (snap.docs.isEmpty) {
      return const EmptyState(
        icon: Icons.store_outlined,
        title: 'No restaurants available',
        subtitle: 'Check back later for new restaurants in your area',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: snap.docs.length,
      itemBuilder: (_, i) {
        final d = snap.docs[i].data() as Map<String, dynamic>;
        final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: TayyebGoTheme.cardDecoration,
          child: InkWell(
            borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
            onTap: () => context.go('/restaurant/${snap.docs[i].id}', extra: {
              'name': d['name'] ?? '',
              'commissionPercent': commission,
            }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.restaurant, color: TayyebGoTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['name'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(d['cuisineType'] as String? ?? '',
                          style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
              ]),
            ),
          ),
        );
      },
    );
  }
}
