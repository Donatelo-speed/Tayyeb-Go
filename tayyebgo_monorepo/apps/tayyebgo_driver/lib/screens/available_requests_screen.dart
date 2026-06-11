import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Available Requests', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: anything.isLoading
          ? Center(child: CircularProgressIndicator(color: context.successColor))
          : (anything.availableRequests.isEmpty && dispatch.assignedDispatches.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Icon(Icons.inbox_rounded, size: 36, color: context.textMutedColor),
                      ),
                      const SizedBox(height: 16),
                      Text('No requests available', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Check back later for new delivery requests', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: context.successColor,
                  backgroundColor: context.surfaceColor,
                  onRefresh: () async {
                    final user = AuthProvider.instance?.user;
                    if (user != null) {
                      await context.read<AnythingProvider>().loadAvailableRequests(user.id);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (dispatch.assignedDispatches.isNotEmpty) ...[
                        Text('Food Deliveries', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textMutedColor, letterSpacing: 0.3)),
                        const SizedBox(height: 10),
                        ...dispatch.assignedDispatches.map((d) => _DispatchRequestCard(dispatch: d)),
                      ],
                      if (anything.availableRequests.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Anything Requests', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textMutedColor, letterSpacing: 0.3)),
                        const SizedBox(height: 10),
                        ...anything.availableRequests.map((r) => _AnythingRequestCard(request: r)),
                      ],
                    ],
                  ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.warningColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delivery_dining_rounded, color: context.warningColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Food Delivery', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('NEW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: context.warningColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.receipt_rounded, size: 16, color: context.textMutedColor),
              const SizedBox(width: 6),
              Text('Order: ${(dispatch['orderId'] as String? ?? '').substring(0, 8)}...', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
            ],
          ),
          if (dispatch['dropoffLat'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 16, color: context.textMutedColor),
                const SizedBox(width: 6),
                Text('GPS delivery', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prov = context.read<DispatchProvider>();
                      try {
                        await prov.acceptDispatch(id);
                        if (context.mounted) context.push('/active-delivery-food/$id');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to accept: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Accept', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () async {
                      final prov = context.read<DispatchProvider>();
                      await prov.rejectDispatch(id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textMutedColor,
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnythingRequestCard extends StatelessWidget {
  final AnythingRequestModel request;
  const _AnythingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.successColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_bag_rounded, color: context.successColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(request.storeName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...request.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${item.quantity}x ${item.name}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
          )),
          if (request.instructions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: ${request.instructions}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(color: context.borderColor)),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, size: 16, color: context.textMutedColor),
              const SizedBox(width: 4),
              Text('Budget: SYP ${request.budget.toStringAsFixed(0)}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              const Spacer(),
              Icon(Icons.location_on_rounded, size: 16, color: context.textMutedColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(request.dropoffAddress, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final user = context.read<AuthProvider>().user;
                if (user == null) return;
                try {
                  final success = await context.read<AnythingProvider>().acceptRequest(request.id, user.id, user.displayName);
                  if (success && context.mounted) context.push('/active-delivery/${request.id}');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to accept request: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Accept Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
