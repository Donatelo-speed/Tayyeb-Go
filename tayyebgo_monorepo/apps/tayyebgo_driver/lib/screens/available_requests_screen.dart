import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AvailableRequestsScreen extends StatefulWidget {
  const AvailableRequestsScreen({super.key});
  @override
  State<AvailableRequestsScreen> createState() => _AvailableRequestsScreenState();
}

class _AvailableRequestsScreenState extends State<AvailableRequestsScreen> {
  @override
  void initState() {
    super.initState();
    final user = AuthProvider.instance?.user;
    if (user != null) {
      context.read<AnythingProvider>().loadAvailableRequests(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anything = context.watch<AnythingProvider>();
    final dispatch = context.watch<DispatchProvider>();

    return AppScaffold(
      title: 'Available Requests',
      body: anything.isLoading
          ? const ShimmerLoading(itemCount: 3)
          : (anything.availableRequests.isEmpty &&
                  dispatch.assignedDispatches.isEmpty)
              ? const Center(child: Text('No requests available'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (dispatch.assignedDispatches.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('New Food Deliveries',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      ...dispatch.assignedDispatches.map((d) =>
                          _DispatchRequestCard(dispatch: d)),
                    ],
                    if (anything.availableRequests.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8, bottom: 8),
                        child: Text('Personal Shopping Requests',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      ...anything.availableRequests.map((r) =>
                          _AnythingRequestCard(request: r)),
                    ],
                  ],
                ),
    );
  }
}

class _DispatchRequestCard extends StatelessWidget {
  final Map<String, dynamic> dispatch;
  const _DispatchRequestCard({required this.dispatch});

  @override
  Widget build(BuildContext context) {
    final id = dispatch['id'] as String;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delivery_dining, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Food Delivery Order',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.receipt, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Order: ${(dispatch['orderId'] as String? ?? '').substring(0, 8)}...'),
              ],
            ),
            if (dispatch['dropoffLat'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('Delivery with GPS coordinates'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prov = context.read<DispatchProvider>();
                      await prov.acceptDispatch(id);
                      if (context.mounted) {
                        context.go('/active-delivery-food/$id');
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final prov = context.read<DispatchProvider>();
                      await prov.rejectDispatch(id);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnythingRequestCard extends StatelessWidget {
  final AnythingRequestModel request;
  const _AnythingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag,
                    color: TayyebGoTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(request.storeName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...request.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${item.quantity}x ${item.name}'),
                )),
            if (request.instructions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${request.instructions}',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
            const Divider(),
            Row(
              children: [
                const Icon(Icons.monetization_on,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Budget: SYP ${request.budget.toStringAsFixed(0)}'),
                const Spacer(),
                const Icon(Icons.location_on,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(request.dropoffAddress,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final user = context.read<AuthProvider>().user;
                  if (user == null) return;
                  final success = await context
                      .read<AnythingProvider>()
                      .acceptRequest(
                          request.id, user.id, user.displayName);
                  if (success && context.mounted) {
                    context.go('/active-delivery/${request.id}');
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Accept Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TayyebGoTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
