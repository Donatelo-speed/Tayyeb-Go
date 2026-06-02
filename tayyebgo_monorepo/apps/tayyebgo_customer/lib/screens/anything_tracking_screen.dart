import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AnythingTrackingScreen extends StatelessWidget {
  final String requestId;
  const AnythingTrackingScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Anything Request',
      body: StreamScreenBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('anything_requests')
            .doc(requestId)
            .snapshots(),
        onLoading: () => const ShimmerLoading(itemCount: 4),
        onError: (msg, retry) => ErrorRetryWidget(message: msg, onRetry: retry),
        onSuccess: (context, snap) {
          if (!snap.exists) return const Center(child: Text('Request not found'));

          final d = snap.data() as Map<String, dynamic>;
          final status = AnythingRequestStatus.fromString(d['status'] as String?);
          final driverName = d['driverName'] as String?;
          final driverLat = (d['driverLatitude'] as num?)?.toDouble();
          final driverLng = (d['driverLongitude'] as num?)?.toDouble();
          final storeName = d['storeName'] as String? ?? 'Store';
          final items = (d['items'] as List<dynamic>?)
                  ?.map((i) => i as Map<String, dynamic>)
                  .toList() ??
              [];
          final instructions = d['instructions'] as String? ?? '';
          final budget = (d['budget'] as num?)?.toDouble() ?? 0;
          final isCancellable = status == AnythingRequestStatus.pending;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusBanner(status: status, isCancellable: isCancellable, requestId: requestId),
              const SizedBox(height: 16),
              _buildInfoCard(context, storeName, items, instructions, budget),
              if (driverName != null) ...[
                const SizedBox(height: 12),
                _buildDriverCard(context, driverName, driverLat, driverLng),
              ],
              if (driverLat != null && driverLng != null) ...[
                const SizedBox(height: 12),
                _buildMapCard(driverLat, driverLng),
              ],
              const SizedBox(height: 12),
              _buildTimeline(status),
            ],
          );
        },
      ),
    );
  }

  Widget _StatusBanner({
    required AnythingRequestStatus status,
    required bool isCancellable,
    required String requestId,
  }) {
    final (icon, color, text) = switch (status) {
      AnythingRequestStatus.pending => (Icons.hourglass_empty, Colors.orange, 'Looking for a driver'),
      AnythingRequestStatus.accepted => (Icons.check_circle, Colors.blue, 'Driver accepted'),
      AnythingRequestStatus.shopping => (Icons.shopping_cart, Colors.amber, 'Driver is shopping'),
      AnythingRequestStatus.enRoute => (Icons.delivery_dining, TayyebGoTheme.primaryColor, 'On the way'),
      AnythingRequestStatus.delivered => (Icons.check_circle, Colors.green, 'Delivered'),
      AnythingRequestStatus.cancelled => (Icons.cancel, Colors.red, 'Cancelled'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
          if (isCancellable)
            Builder(builder: (ctx) => TextButton(
              onPressed: () {
                ctx.read<AnythingProvider>().cancelRequest(requestId);
                ctx.go('/home');
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String storeName, List<Map<String, dynamic>> items, String instructions, double budget) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, size: 20),
                const SizedBox(width: 8),
                Text(storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${i['quantity']}x ${i['name']}'),
            )),
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: $instructions', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
            const SizedBox(height: 8),
            Text('Budget: SYP ${budget.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, String driverName, double? lat, double? lng) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text('Driver: $driverName'),
        subtitle: lat != null && lng != null ? Text('Live location available') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.message), onPressed: () {}),
            IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(double lat, double lng) {
    return Card(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text('Driver location: $lat, $lng'),
              const Text('(Live map placeholder)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(AnythingRequestStatus status) {
    final steps = [
      (status: AnythingRequestStatus.pending, icon: Icons.hourglass_empty, label: 'Request Sent'),
      (status: AnythingRequestStatus.accepted, icon: Icons.check_circle, label: 'Driver Accepted'),
      (status: AnythingRequestStatus.shopping, icon: Icons.shopping_cart, label: 'Shopping'),
      (status: AnythingRequestStatus.enRoute, icon: Icons.delivery_dining, label: 'On the Way'),
      (status: AnythingRequestStatus.delivered, icon: Icons.check_circle, label: 'Delivered'),
    ];

    final currentIndex = steps.indexWhere((s) => s.status == status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final isComplete = i <= currentIndex;
              final isCurrent = i == currentIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      step.icon,
                      size: 20,
                      color: isComplete ? TayyebGoTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : null,
                        color: isComplete ? TayyebGoTheme.primaryColor : Colors.grey,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: TayyebGoTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Current', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
