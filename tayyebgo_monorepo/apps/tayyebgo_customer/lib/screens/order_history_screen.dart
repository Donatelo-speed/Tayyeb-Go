import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final customerId = auth.user?.id;
    return AppScaffold(
      title: 'Order History',
      body: customerId == null
          ? const EmptyState(
              icon: Icons.error_outline, title: 'Not logged in')
          : StreamBuilder<QuerySnapshot>(
              key: ValueKey('order_history_$_retryKey'),
              stream: FirebaseFirestore.instance
                  .collection('Orders')
                  .where('customerId', isEqualTo: customerId)
                  .where('status',
                      whereIn: ['delivered', 'cancelled'])
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                final friendlyError = snap.hasError
                    ? 'Unable to load orders right now.'
                    : null;
                return TripleStateWidget(
                  state: snap.hasError
                      ? TripleState.error
                      : !snap.hasData
                          ? TripleState.loading
                          : TripleState.success,
                  errorMessage: friendlyError,
                  onRetry: () =>
                      setState(() => _retryKey++),
                  shimmerItemCount: 4,
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
        icon: Icons.receipt_long_outlined,
        title: 'No past orders',
        subtitle:
            'Your completed and cancelled orders will appear here',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: snap.docs.length,
        itemBuilder: (_, i) {
          final d = snap.docs[i].data()
              as Map<String, dynamic>;
          final status =
              d['status'] as String? ?? '';
          final isDelivered = status == 'delivered';
          return Container(
            margin:
                const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(16),
              onTap: () => context.go(
                  '/tracking/${snap.docs[i].id}'),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (isDelivered
                              ? TayyebGoTheme
                                  .successColor
                              : TayyebGoTheme.errorColor)
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(
                              12),
                    ),
                    child: Icon(
                      isDelivered
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isDelivered
                          ? TayyebGoTheme.successColor
                          : TayyebGoTheme.errorColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                            d['restaurantName']
                                    as String? ??
                                'Order',
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          isDelivered
                              ? 'Delivered'
                              : 'Cancelled',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDelivered
                                  ? TayyebGoTheme
                                      .successColor
                                  : TayyebGoTheme
                                      .errorColor,
                              fontWeight:
                                  FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                      '\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      color:
                          TayyebGoTheme.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}