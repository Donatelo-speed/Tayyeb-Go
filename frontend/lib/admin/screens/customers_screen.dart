import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';

  Future<void> _toggleActive(String id, bool isActive) async {
    try { await FirebaseFirestore.instance.collection('users').doc(id).update({'isActive': !isActive}); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoadingState();
        if (snap.hasError) return AdminErrorState(message: snap.error.toString(), onRetry: () => setState(() {}));
        if (!snap.hasData) return const AdminLoadingState();

        var docs = snap.data!.docs;
        if (_search.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map;
            final name = (data['displayName'] as String? ?? '').toLowerCase();
            final email = (data['email'] as String? ?? '').toLowerCase();
            final q = _search.toLowerCase();
            return name.contains(q) || email.contains(q);
          }).toList();
        }

        return Column(children: [
          AdminSectionHeader(
            title: 'Customer Management', count: docs.length,
            searchHint: 'Search by name or email...',
            onSearch: (v) => setState(() => _search = v),
          ),
          Expanded(
            child: docs.isEmpty
                ? const AdminEmptyState(icon: Icons.group_rounded, title: 'No customers found')
                : ListView.builder(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final name = d['displayName'] as String? ?? 'Unknown';
                      final email = d['email'] as String? ?? '';
                      final phone = d['phone'] as String?;
                      final role = d['role'] as String? ?? 'customer';
                      final isActive = d['isActive'] == true;
                      final points = d['loyaltyPoints'] ?? 0;
                      final created = (d['createdAt'] as Timestamp?)?.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        padding: const EdgeInsets.all(AdminSpacing.lg),
                        decoration: cardDecoration(isDark),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AdminColors.roleColor(role).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AdminRadius.full),
                            ),
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: AdminColors.roleColor(role), fontWeight: FontWeight.w700, fontSize: 16))),
                          ),
                          const SizedBox(width: AdminSpacing.lg),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(name, style: AdminTypography.h4(isDark)),
                              const SizedBox(width: AdminSpacing.sm),
                              AdminBadge(label: role.toUpperCase(), color: AdminColors.roleColor(role)),
                              if (!isActive) const AdminBadge(label: 'SUSPENDED', color: AdminColors.danger),
                            ]),
                            const SizedBox(height: 4),
                            Text('$email${phone != null ? '  ·  $phone' : ''}', style: AdminTypography.bodySmall(isDark)),
                            if (created != null) Text('Joined ${timeAgo(created)}  ·  $points points', style: AdminTypography.caption(isDark)),
                          ])),
                          Switch(value: isActive, onChanged: (_) => _toggleActive(docs[i].id, isActive), activeTrackColor: AdminColors.success.withValues(alpha: 0.3), activeThumbColor: AdminColors.success),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}