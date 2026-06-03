import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState
    extends State<RestaurantListScreen> {
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
          return TripleStateWidget(
            state: snap.hasError
                ? TripleState.error
                : !snap.hasData
                    ? TripleState.loading
                    : TripleState.success,
            errorMessage: snap.hasError
                ? 'Unable to load restaurants.'
                : null,
            onRetry: () =>
                setState(() => _retryKey++),
            shimmerItemCount: 5,
            child: snap.hasData
                ? _buildContent(
                    context, snap.data!)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, QuerySnapshot snap) {
    if (snap.docs.isEmpty) {
      return const EmptyState(
        icon: Icons.store_outlined,
        title: 'No restaurants available',
        subtitle:
            'Check back later for new restaurants in your area',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: snap.docs.length,
      itemBuilder: (_, i) {
        final d = snap.docs[i].data()
            as Map<String, dynamic>;
        final name =
            d['name'] as String? ?? '';
        final cuisine =
            d['cuisineType'] as String? ?? '';
        final commission =
            (d['commissionPercent'] as num?)
                    ?.toDouble() ??
                15.0;
        final rating =
            (d['rating'] as num?)?.toDouble();
        final imageUrl =
            d['imageUrl'] as String?;
        return Container(
          margin:
              const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(18),
            onTap: () => context.go(
                '/restaurant/${snap.docs[i].id}',
                extra: {
                  'name': name,
                  'commissionPercent':
                      commission,
                }),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(16),
                  color: TayyebGoTheme
                      .primaryColor
                      .withValues(alpha: 0.1),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(
                              imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Icon(Icons.restaurant_rounded,
                        color: TayyebGoTheme
                            .primaryColor,
                        size: 26)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (cuisine.isNotEmpty)
                          Text(cuisine,
                              style: const TextStyle(
                                  color: Color(
                                      0xFF94A3B8),
                                  fontSize: 12)),
                        if (rating != null) ...[
                          if (cuisine.isNotEmpty)
                            const SizedBox(
                                width: 10),
                          const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(
                                  0xFFFBBF24)),
                          const SizedBox(width: 2),
                          Text(
                              rating
                                  .toStringAsFixed(
                                      1),
                              style: const TextStyle(
                                  color: Color(
                                      0xFF94A3B8),
                                  fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color:
                      TayyebGoTheme.textMuted),
            ]),
          ),
        );
      },
    );
  }
}