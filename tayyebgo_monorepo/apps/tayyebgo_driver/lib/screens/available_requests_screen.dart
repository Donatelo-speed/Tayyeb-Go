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

    return AppScaffold(
      title: 'Available Requests',
      body: anything.isLoading
          ? const ShimmerLoading(itemCount: 3)
          : anything.availableRequests.isEmpty
              ? const Center(child: Text('No requests available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: anything.availableRequests.length,
                  itemBuilder: (_, i) {
                    final r = anything.availableRequests[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
              padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shopping_bag, color: TayyebGoTheme.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(r.storeName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...r.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('${item.quantity}x ${item.name}'),
                            )),
                            if (r.instructions.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Note: ${r.instructions}',
                                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                            ],
                            const Divider(),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Budget: SYP ${r.budget.toStringAsFixed(0)}'),
                                const Spacer(),
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(r.dropoffAddress, overflow: TextOverflow.ellipsis),
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
                                      .acceptRequest(r.id, user.id, user.displayName);
                                  if (success && mounted) {
                                    context.go('/active-delivery/${r.id}');
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
                  },
                ),
    );
  }
}
