import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  final String requestId;
  const ActiveDeliveryScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Active Delivery',
      body: StreamScreenBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('anything_requests')
            .doc(requestId)
            .snapshots(),
        onLoading: () => const ShimmerLoading(itemCount: 3),
        onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
        onSuccess: (context, snap) {
          if (!snap.exists) return const Center(child: Text('Request not found'));
          final d = snap.data() as Map<String, dynamic>;
          final status = AnythingRequestStatus.fromString(d['status'] as String?);
          final storeName = d['storeName'] as String? ?? '';
          final items = (d['items'] as List<dynamic>?)
                  ?.map((i) => i as Map<String, dynamic>)
                  .toList() ?? [];
          final instructions = d['instructions'] as String? ?? '';
          final dropoffAddress = d['dropoffAddress'] as String? ?? '';
          final customerName = d['customerName'] as String? ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusHeader(status),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.store), const SizedBox(width: 8),
                        Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                      const Divider(),
                      ...items.map((i) => ListTile(
                        dense: true,
                        title: Text('${i['quantity']}x ${i['name']}'),
                        contentPadding: EdgeInsets.zero,
                      )),
                      if (instructions.isNotEmpty)
                        Text('Note: $instructions', style: const TextStyle(fontStyle: FontStyle.italic)),
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
              _ActionButtons(context, status, requestId),
            ],
          );
        },
      ),
    );
  }

  Widget _StatusHeader(AnythingRequestStatus status) {
    final (icon, color, text) = switch (status) {
      AnythingRequestStatus.accepted => (Icons.check_circle, Colors.blue, 'Heading to store'),
      AnythingRequestStatus.shopping => (Icons.shopping_cart, Colors.amber, 'Shopping'),
      AnythingRequestStatus.enRoute => (Icons.delivery_dining, TayyebGoTheme.primaryColor, 'On the way to customer'),
      AnythingRequestStatus.delivered => (Icons.check_circle, Colors.green, 'Delivered'),
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
        Icon(icon, color: color), const SizedBox(width: 8),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _ActionButtons(BuildContext ctx, AnythingRequestStatus status, String requestId) {
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
          await ctx.read<AnythingProvider>().updateStatus(requestId, nextStatus);
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
