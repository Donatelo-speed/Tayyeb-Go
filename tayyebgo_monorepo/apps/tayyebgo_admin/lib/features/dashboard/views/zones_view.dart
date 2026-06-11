import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class ZonesView extends StatelessWidget {
  const ZonesView({super.key});

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Zones', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: () => _showAddZone(context),
              icon: Icon(Icons.add_rounded, color: context.primaryColor),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('zones').orderBy('name').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
            if (snap.hasError) return Center(child: Text('Error loading zones', style: GoogleFonts.inter(color: context.textMutedColor)));
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 64, color: context.borderColor),
                    const SizedBox(height: 12),
                    Text('No zones defined', style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Add delivery zones to configure coverage areas', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (_, i) => _zoneCard(context, docs[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _zoneCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? 'Unnamed';
    final isActive = d['isActive'] == true;
    final fee = (d['deliveryFee'] as num?)?.toDouble() ?? 0;
    final minOrder = (d['minOrder'] as num?)?.toDouble() ?? 0;
    return Container(
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
              color: (isActive ? context.primaryColor : context.textMutedColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.map_rounded, color: isActive ? context.primaryColor : context.textMutedColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isActive ? context.successColor : context.textMutedColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? context.successColor : context.textMutedColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Fee: ${fee.toStringAsFixed(0)} SYP · Min order: ${minOrder.toStringAsFixed(0)} SYP', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.textMutedColor),
            onSelected: (v) async {
              try {
                if (v == 'toggle') {
                  await FirebaseFirestore.instance.collection('zones').doc(doc.id).update({'isActive': !isActive});
                } else if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Zone?'),
                      content: Text('This will permanently delete zone "$name".'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: context.errorColor))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance.collection('zones').doc(doc.id).delete();
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
              PopupMenuItem(value: 'delete', child: Text('Delete', style: GoogleFonts.inter(color: context.errorColor))),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddZone(BuildContext context) {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '0');
    final minCtrl = TextEditingController(text: '0');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Zone', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Zone name',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                filled: true,
                fillColor: context.surfaceAltColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: feeCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'Delivery fee',
                      hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                      filled: true,
                      fillColor: context.surfaceAltColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'Min order',
                      hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                      filled: true,
                      fillColor: context.surfaceAltColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.primaryColor)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await FirebaseFirestore.instance.collection('zones').add({
                    'name': nameCtrl.text.trim(),
                    'deliveryFee': double.tryParse(feeCtrl.text) ?? 0,
                    'minOrder': double.tryParse(minCtrl.text) ?? 0,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: context.textPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Add Zone', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
