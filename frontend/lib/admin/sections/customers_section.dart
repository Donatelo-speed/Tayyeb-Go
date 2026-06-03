import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_design.dart';

class CustomersSection extends StatefulWidget {
  const CustomersSection({super.key});
  @override
  State<CustomersSection> createState() => _CustomersSectionState();
}

class _CustomersSectionState extends State<CustomersSection> {
  String _search = '';

  Future<void> _toggleActive(String id, bool active) async {
    try { await FirebaseFirestore.instance.collection('users').doc(id).update({'isActive': !active}); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AdminColors.primary));
        var docs = snap.data!.docs;
        if (_search.isNotEmpty) docs = docs.where((d) => ((d.data() as Map)['displayName'] as String? ?? '').toLowerCase().contains(_search.toLowerCase()) || ((d.data() as Map)['email'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

        return Column(children: [
          Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, child: Row(children: [
            Text('Customers', style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AdminColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('${docs.length}', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
            const Spacer(),
            SizedBox(width: 220, child: TextField(onChanged: (v) => setState(() => _search = v), decoration: InputDecoration(hintText: 'Search customers...', prefixIcon: const Icon(Icons.search_rounded, size: 18), filled: true, fillColor: isDark ? AdminColors.bgDarkInput : AdminColors.bgLightInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
          ])),
          Expanded(
            child: docs.isEmpty
                ? Center(child: Text('No customers found', style: isDark ? AdminTypography.body(true) : AdminTypography.body(false)))
                : ListView.builder(padding: const EdgeInsets.all(20), itemCount: docs.length, itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final active = d['isActive'] != false;
                    final role = d['role'] as String? ?? 'customer';
                    final c = AdminColors.roleColors(role)[0];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
                      child: Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: c.withValues(alpha: 0.1), child: Icon(Icons.person_rounded, color: c)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['displayName'] as String? ?? 'Unknown', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
                          const SizedBox(height: 2),
                          Text('${d['email'] ?? ''} · ${d['phone'] ?? 'N/A'}', style: isDark ? AdminTypography.bodySmall(true) : AdminTypography.bodySmall(false)),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c))),
                        Switch(value: active, onChanged: (_) => _toggleActive(docs[i].id, active), activeThumbColor: AdminColors.success),
                      ]),
                    );
                  }),
          ),
        ]);
      },
    );
  }
}