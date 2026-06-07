import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart' as core;
import '../providers/offline_queue_provider.dart';

class KitchenModeScreen extends StatefulWidget {
  final String restaurantId;
  const KitchenModeScreen({super.key, required this.restaurantId});
  @override
  State<KitchenModeScreen> createState() => _KitchenModeScreenState();
}

class _KitchenModeScreenState extends State<KitchenModeScreen> {
  @override
  Widget build(BuildContext context) {
    final actorId = context.watch<AuthProvider>().user?.id ?? '';

    return AppScaffold(
      title: 'Kitchen Mode',
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('restaurantId', isEqualTo: widget.restaurantId)
            .where('status', whereIn: ['accepted', 'preparing'])
            .orderBy('status')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const ShimmerLoading(itemCount: 3);

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No active orders'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: docs.length,
            itemBuilder: (_, idx) {
              final d = docs[idx].data() as Map<String, dynamic>;
              final s = d['status'] as String? ?? '';
              final statusIsAccepted = s == 'accepted';
              final items = (d['items'] as List<dynamic>?)
                      ?.map((it) => it as Map<String, dynamic>)
                      .toList() ?? [];
              final customerName = d['customerName'] as String? ?? 'Guest';

              return Card(
                color: statusIsAccepted
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: statusIsAccepted
                                ? Colors.blue : Colors.orange,
                            child: Text('${idx + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(customerName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusIsAccepted
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusIsAccepted ? 'New' : 'Prep',
                              style: TextStyle(
                                fontSize: 11,
                                color: statusIsAccepted ? Colors.blue : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          children: items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${item['quantity']}x ${item['name']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () async {
                            final nextStatus = statusIsAccepted ? 'preparing' : 'ready_for_driver';
                            try {
                              await OrderStateMachine.transition(
                                orderId: docs[idx].id,
                                newStatus: core.OrderStatus.fromValue(nextStatus),
                                actorId: actorId,
                                note: statusIsAccepted
                                    ? 'Started preparing' : 'Order ready',
                              );
                            } catch (_) {
                              await context.read<OfflineQueueProvider>().enqueue(
                                PendingOperation(
                                  id: '${docs[idx].id}_${DateTime.now().millisecondsSinceEpoch}',
                                  type: PendingOperationType.transitionOrder,
                                  orderId: docs[idx].id,
                                  newStatus: core.OrderStatus.fromValue(nextStatus),
                                  actorId: actorId,
                                  createdAt: DateTime.now(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusIsAccepted ? Colors.blue : Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            statusIsAccepted ? 'Start Prep' : 'Mark Ready',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
