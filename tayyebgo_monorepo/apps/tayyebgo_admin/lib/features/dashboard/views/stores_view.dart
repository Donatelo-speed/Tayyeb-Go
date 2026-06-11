import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'store_detail_view.dart';
import 'shared.dart';

class StoresView extends StatelessWidget {
  const StoresView({super.key});

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Stores', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('restaurants').orderBy('name').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
            if (snap.hasError) return Center(child: Text('Error loading stores', style: GoogleFonts.inter(color: context.textMutedColor)));
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store_outlined, size: 64, color: context.borderColor),
                    const SizedBox(height: 12),
                    Text('No stores yet', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Stores will appear here once registered', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                  ],
                ),
              );
            }
            return _buildStoreList(context, docs);
          },
        ),
      ),
    );
  }

  Widget _buildStoreList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    int active = 0, inactive = 0;
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['isActive'] == true) active++;
      else inactive++;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth < 500 ? 1 : constraints.maxWidth < 900 ? 2 : 3;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _statCard(context, Icons.store_rounded, 'Total', '${docs.length}', context.primaryColor),
                  _statCard(context, Icons.check_circle_outline, 'Active', '$active', context.successColor),
                  _statCard(context, Icons.pause_circle_outline, 'Inactive', '$inactive', context.textMutedColor),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          ...docs.map((doc) => _storeRow(context, doc)),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storeRow(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? 'Unnamed';
    final cuisine = d['cuisineType'] as String? ?? 'N/A';
    final isActive = d['isActive'] == true;
    final isOpen = d['isOpenNow'] == true;
    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailView(storeId: doc.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? context.primaryColor.withValues(alpha: 0.3) : context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.store_rounded, color: context.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isOpen ? context.successColor : context.textMutedColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isOpen ? context.successColor : context.textMutedColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(cuisine, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                      if (rating > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star_rounded, size: 14, color: context.warningColor),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.warningColor)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: context.textMutedColor),
              onSelected: (v) async {
                try {
                  if (v == 'toggle') {
                    await FirebaseFirestore.instance.collection('restaurants').doc(doc.id).update({'isActive': !isActive});
                  } else if (v == 'open') {
                    await FirebaseFirestore.instance.collection('restaurants').doc(doc.id).update({'isOpenNow': !isOpen});
                  } else if (v == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Store?'),
                        content: Text('This will permanently delete "${name}".'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: context.errorColor))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance.collection('restaurants').doc(doc.id).delete();
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate', style: GoogleFonts.inter())),
                PopupMenuItem(value: 'open', child: Text(isOpen ? 'Set Closed' : 'Set Open', style: GoogleFonts.inter())),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: GoogleFonts.inter(color: context.errorColor))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
