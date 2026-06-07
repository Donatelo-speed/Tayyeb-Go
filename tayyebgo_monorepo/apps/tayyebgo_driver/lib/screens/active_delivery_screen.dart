import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  final String requestId;
  final String? deliveryType;
  const ActiveDeliveryScreen({
    super.key,
    required this.requestId,
    this.deliveryType,
  });

  bool get _isFoodOrder => deliveryType == 'food';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isFoodOrder ? 'Active Food Delivery' : 'Active Delivery',
      body: _isFoodOrder
          ? _FoodDeliveryView(requestId: requestId)
          : _AnythingDeliveryView(requestId: requestId),
    );
  }
}

class _FoodDeliveryView extends StatelessWidget {
  final String requestId;
  const _FoodDeliveryView({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dispatch_requests')
          .doc(requestId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(itemCount: 3);
        }
        if (snap.hasError) {
          return ErrorRetryWidget(
              message: snap.error.toString(), onRetry: () {});
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('Delivery not found'));
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        final orderId = d['orderId'] as String? ?? '';

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .snapshots(),
          builder: (ctx, orderSnap) {
            final orderData = orderSnap.hasData && orderSnap.data!.exists
                ? orderSnap.data!.data() as Map<String, dynamic>
                : <String, dynamic>{};

            final restaurantName =
                orderData['restaurantName'] as String? ?? d['restaurantName'] as String? ?? '';
            final dropoffLat = d['dropoffLat'] as double?;
            final dropoffLon = d['dropoffLon'] as double?;
            final dispatchStatus = d['status'] as String? ?? '';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FoodStatusHeader(dispatchStatus),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.restaurant),
                          const SizedBox(width: 8),
                          Text(restaurantName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const Divider(),
                        if (orderData['items'] != null)
                          ...(orderData['items'] as List<dynamic>)
                              .map((i) => ListTile(
                                    dense: true,
                                    title: Text(
                                        '${i['quantity'] ?? 1}x ${i['name'] ?? ''}'),
                                    contentPadding: EdgeInsets.zero,
                                  )),
                        if (orderData['note'] != null)
                          Text('Note: ${orderData['note']}',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
                if (dropoffLat != null && dropoffLon != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Dropoff Location'),
                      subtitle: Text('$dropoffLat, $dropoffLon'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _FoodActionButtons(ctx, dispatchStatus, requestId, orderId),
              ],
            );
          },
        );
      },
    );
  }

  Widget _FoodStatusHeader(String status) {
    final (icon, color, text) = switch (status) {
      'accepted' => (Icons.check_circle, Colors.blue, 'Heading to restaurant'),
      'pickedUp' => (Icons.delivery_dining, TayyebGoTheme.primaryColor, 'On the way to customer'),
      'delivered' => (Icons.check_circle, Colors.green, 'Delivered'),
      _ => (Icons.info, Colors.grey, 'Status: $status'),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _FoodActionButtons(
      BuildContext ctx, String status, String dispatchId, String orderId) {
    if (status == 'delivered') {
      return ElevatedButton.icon(
        onPressed: () => GoRouter.of(ctx).go('/dashboard'),
        icon: const Icon(Icons.home),
        label: const Text('Back to Dashboard'),
      );
    }

    if (status == 'pickedUp') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            final prov = ctx.read<DispatchProvider>();
            await prov.completeDelivery(dispatchId, orderId);
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Delivered'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (status == 'accepted' || status == 'enRoute') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            final prov = ctx.read<DispatchProvider>();
            await prov.markPickedUp(dispatchId, orderId);
          },
          icon: const Icon(Icons.shopping_basket),
          label: const Text('Picked Up from Restaurant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TayyebGoTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _AnythingDeliveryView extends StatelessWidget {
  final String requestId;
  const _AnythingDeliveryView({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('anything_requests')
          .doc(requestId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(itemCount: 3);
        }
        if (snap.hasError) {
          return ErrorRetryWidget(
              message: snap.error.toString(), onRetry: () {});
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('Request not found'));
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        final status =
            AnythingRequestStatus.fromString(d['status'] as String?);
        final storeName = d['storeName'] as String? ?? '';
        final items = (d['items'] as List<dynamic>?)
                ?.map((i) => i as Map<String, dynamic>)
                .toList() ??
            [];
        final instructions = d['instructions'] as String? ?? '';
        final dropoffAddress = d['dropoffAddress'] as String? ?? '';
        final customerName = d['customerName'] as String? ?? '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AnythingStatusHeader(status),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.store),
                      const SizedBox(width: 8),
                      Text(storeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const Divider(),
                    ...items.map((i) => ListTile(
                          dense: true,
                          title: Text('${i['quantity']}x ${i['name']}'),
                          contentPadding: EdgeInsets.zero,
                        )),
                    if (instructions.isNotEmpty)
                      Text('Note: $instructions',
                          style:
                              const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('Deliver to: $customerName'),
                subtitle: Text(dropoffAddress),
              ),
            ),
            const SizedBox(height: 16),
            _AnythingActionButtons(context, status, requestId),
          ],
        );
      },
    );
  }

  Widget _AnythingStatusHeader(AnythingRequestStatus status) {
    final (icon, color, text) = switch (status) {
      AnythingRequestStatus.accepted =>
        (Icons.check_circle, Colors.blue, 'Heading to store'),
      AnythingRequestStatus.shopping =>
        (Icons.shopping_cart, Colors.amber, 'Shopping'),
      AnythingRequestStatus.enRoute => (Icons.delivery_dining,
          TayyebGoTheme.primaryColor, 'On the way to customer'),
      AnythingRequestStatus.delivered =>
        (Icons.check_circle, Colors.green, 'Delivered'),
      _ => (Icons.info, Colors.grey, 'Status: ${status.firestoreValue}'),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _AnythingActionButtons(
      BuildContext ctx, AnythingRequestStatus status, String requestId) {
    final text = switch (status) {
      AnythingRequestStatus.accepted => 'I arrived at store',
      AnythingRequestStatus.shopping => 'Purchased — on the way',
      AnythingRequestStatus.enRoute => 'Delivered',
      _ => '',
    };
    final icon = switch (status) {
      AnythingRequestStatus.accepted => Icons.shopping_cart,
      AnythingRequestStatus.shopping => Icons.delivery_dining,
      AnythingRequestStatus.enRoute => Icons.check_circle,
      _ => Icons.check_circle,
    };
    final nextStatus = switch (status) {
      AnythingRequestStatus.accepted => AnythingRequestStatus.shopping,
      AnythingRequestStatus.shopping => AnythingRequestStatus.enRoute,
      AnythingRequestStatus.enRoute => AnythingRequestStatus.delivered,
      _ => AnythingRequestStatus.delivered,
    };

    if (status == AnythingRequestStatus.delivered) {
      return ElevatedButton.icon(
        onPressed: () => GoRouter.of(ctx).go('/dashboard'),
        icon: const Icon(Icons.home),
        label: const Text('Back to Dashboard'),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          await ctx
              .read<AnythingProvider>()
              .updateStatus(requestId, nextStatus);
        },
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: TayyebGoTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
