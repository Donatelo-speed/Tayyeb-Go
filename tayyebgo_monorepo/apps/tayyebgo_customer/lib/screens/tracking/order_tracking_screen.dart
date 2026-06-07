import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

/// Order Tracking Timeline — real-time status progression display.
///
/// Listens to Firestore for the order document and renders a vertical
/// step indicator showing: Order Placed → Confirmed → Being Prepared
/// → Out for Delivery → Delivered.
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Order Status',
      body: StreamScreenBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        onLoading: () => const ShimmerLoading(itemCount: 3),
        onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
        onSuccess: (context, snap) {
          if (!snap.exists) return const Center(child: Text('Order not found'));

          final d = snap.data() as Map<String, dynamic>;
          final currentStatusString = d['status'] as String? ?? 'placed';
          final currentStatus = OrderStatus.values.firstWhere(
            (s) => s.value == currentStatusString,
            orElse: () => OrderStatus.placed,
          );
          final driverId = d['driverId'] as String?;
          final dropLat = (d['dropoffLatitude'] as num?)?.toDouble();
          final dropLng = (d['dropoffLongitude'] as num?)?.toDouble();

          final cancellable = currentStatus == OrderStatus.placed || currentStatus == OrderStatus.accepted;
          final isDelivered = currentStatus == OrderStatus.delivered;
          final rated = d['customerRating'] != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: TayyebGoTheme.elevatedCard,
                child: Column(
                  children: [
                    Icon(
                      _statusIcon(currentStatus),
                      size: 56,
                      color: _statusIconColor(currentStatus),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusTitle(currentStatus),
                      style: TayyebGoTheme.heading2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                      style: TayyebGoTheme.caption,
                    ),
                    if (cancellable) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel Order'),
                          style: OutlinedButton.styleFrom(foregroundColor: TayyebGoTheme.errorColor, side: BorderSide(color: TayyebGoTheme.errorColor)),
                          onPressed: () => _confirmCancel(context, d),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Live ETA — shown when dispatched
              if (currentStatusString == 'dispatched' && driverId != null && dropLat != null && dropLng != null)
                _EtaCard(driverId: driverId, destination: GeoLocation(dropLat, dropLng)),

              // Timeline steps
              ...List.generate(6, (i) {
                final step = OrderStateMachine.buildTimeline(currentStatus, i);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            if (i > 0)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: step.isCompleted || (step.isCurrent && !step.isPending)
                                      ? TayyebGoTheme.successColor
                                      : TayyebGoTheme.dividerColor,
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                            Container(
                              width: step.isCurrent ? 16 : 12,
                              height: step.isCurrent ? 16 : 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: step.isCompleted
                                    ? TayyebGoTheme.successColor
                                    : step.isCurrent
                                        ? TayyebGoTheme.primaryColor
                                        : TayyebGoTheme.textMuted.withValues(alpha: 0.3),
                                border: step.isCurrent
                                    ? Border.all(
                                        color: TayyebGoTheme.primaryColor.withValues(alpha: 0.3),
                                        width: 4)
                                    : null,
                              ),
                            ),
                            if (i < 5)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: step.isCompleted
                                      ? TayyebGoTheme.successColor
                                      : TayyebGoTheme.dividerColor,
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: step.isCurrent
                                ? TayyebGoTheme.primaryColor.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  step.label,
                                  style: TextStyle(
                                    fontWeight: step.isCurrent ? FontWeight.w600 : FontWeight.w400,
                                    color: step.isCompleted || step.isCurrent
                                        ? TayyebGoTheme.textPrimary
                                        : TayyebGoTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (step.isCompleted)
                                Icon(Icons.check_circle,
                                    color: TayyebGoTheme.successColor, size: 18),
                              if (step.isCurrent)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: TayyebGoTheme.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Order details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: TayyebGoTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Details', style: TayyebGoTheme.heading3),
                    const SizedBox(height: 12),
                    _detailRow('Customer',
                        d['customerName'] as String? ?? 'Guest'),
                    _detailRow('Phone',
                        d['customerPhone'] as String? ?? '—'),
                    _detailRow('Type',
                        d['fulfillmentType'] as String? ?? 'delivery'),
                    _detailRow('Total',
                        '\$${(d['totalAmount'] as num?)?.toDouble() ?? 0.0}'),
                    if (d['deliveryAddress'] is Map)
                      _detailRow(
                        'Address',
                        (d['deliveryAddress'] as Map)['fullAddress'] as String? ??
                            '—',
                      ),
                  ],
                ),
              ),
              if (isDelivered && !rated) ...[
                const SizedBox(height: 16),
                OrderRating(orderId: orderId, restaurantId: d['restaurantId'] as String? ?? ''),
              ],
              if (isDelivered && rated) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: TayyebGoTheme.cardDecoration,
                  child: Row(children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => Icon(i < (d['customerRating'] as int? ?? 0) ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)),
                    ),
                    const SizedBox(width: 12),
                    Text('Your rating', style: TextStyle(color: TayyebGoTheme.textSecondary)),
                  ]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TayyebGoTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await OrderStateMachine.transition(
                  orderId: orderId,
                  newStatus: OrderStatus.cancelled,
                  actorId: context.read<AuthProvider>().user?.id ?? '',
                  note: 'Cancelled by customer',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel order. Please try again.'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    color: TayyebGoTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.pending:
        return Icons.receipt_long;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
      case OrderStatus.readyForDriver:
        return Icons.delivery_dining;
      case OrderStatus.dispatched:
      case OrderStatus.pickedUp:
        return Icons.pedal_bike;
      case OrderStatus.delivered:
      case OrderStatus.refunded:
        return Icons.verified;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _statusIconColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return TayyebGoTheme.successColor;
      case OrderStatus.cancelled:
        return TayyebGoTheme.errorColor;
      case OrderStatus.placed:
        return Colors.orange;
      default:
        return TayyebGoTheme.primaryColor;
    }
  }

  String _statusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Being Prepared';
      case OrderStatus.ready:
      case OrderStatus.readyForDriver:
        return 'Out for Delivery';
      case OrderStatus.dispatched:
      case OrderStatus.pickedUp:
        return 'On the Way';
      case OrderStatus.delivered:
      case OrderStatus.refunded:
        return 'Delivered!';
      case OrderStatus.cancelled:
        return 'Order Cancelled';
    }
  }
}

class _EtaCard extends StatelessWidget {
  final String driverId;
  final GeoLocation destination;

  const _EtaCard({required this.driverId, required this.destination});

  @override
  Widget build(BuildContext context) {
    final etaService = EtaService();
    return StreamBuilder<int>(
      stream: etaService.watchEtaMinutes(driverId: driverId, destination: destination),
      builder: (context, snap) {
        final eta = snap.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: TayyebGoTheme.elevatedCard,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delivery_dining, color: TayyebGoTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Arrival',
                        style: TextStyle(fontSize: 12, color: TayyebGoTheme.textSecondary)),
                    const SizedBox(height: 4),
                    if (eta == null || eta < 0)
                      const Text('Calculating...',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                    else ...[
                      Text('$eta min',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(eta <= 2 ? 'Almost there!' : 'Driver is on the way',
                          style: TextStyle(fontSize: 12, color: TayyebGoTheme.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (eta != null && eta > 0)
                Text('$eta', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: TayyebGoTheme.primaryColor)),
            ],
          ),
        );
      },
    );
  }
}
