import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class CustomersView extends StatefulWidget {
  const CustomersView();
  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _roles = [
    ('all', 'All Roles'),
    ('customer', 'Customer'),
    ('driver', 'Driver'),
    ('restaurantOwner', 'Restaurant Owner'),
    ('cashier', 'Cashier'),
    ('superAdmin', 'Super Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('User Management', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.textMutedColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _roles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _roles[i];
                final selected = _roleFilter == value;
                return ChoiceChip(
                  label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                  selected: selected,
                  onSelected: (_) => setState(() => _roleFilter = value),
                  selectedColor: context.primaryColor.withValues(alpha: 0.15),
                  side: BorderSide(color: selected ? context.primaryColor.withValues(alpha: 0.3) : context.borderColor),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _roleFilter == 'all'
                  ? FirebaseFirestore.instance.collection('users').limit(500).snapshots()
                  : FirebaseFirestore.instance.collection('users').where('role', isEqualTo: _roleFilter).limit(500).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: context.primaryColor));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
                }
                var docs = snap.data?.docs ?? [];
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = (d['displayName'] as String? ?? '').toLowerCase();
                    final email = (d['email'] as String? ?? '').toLowerCase();
                    return name.contains(q) || email.contains(q);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
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
                          child: Icon(Icons.people_outlined, size: 36, color: context.textMutedColor),
                        ),
                        const SizedBox(height: 16),
                        Text('No users found', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final displayName = d['displayName'] as String? ?? d['email'] as String? ?? 'Unknown';
                    final email = d['email'] as String? ?? '';
                    final phone = d['phone'] as String? ?? '-';
                    final isActive = d['isActive'] as bool? ?? true;
                    final role = d['role'] as String? ?? 'customer';
                    final ordersCount = (d['ordersCount'] as num?)?.toInt() ?? 0;
                    final totalSpending = (d['totalSpending'] as num?)?.toDouble() ?? 0;
                    return _CustomerCard(
                      id: id,
                      displayName: displayName,
                      email: email,
                      phone: phone,
                      isActive: isActive,
                      role: role,
                      ordersCount: ordersCount,
                      totalSpending: totalSpending,
                      data: d,
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final String id;
  final String displayName;
  final String email;
  final String phone;
  final bool isActive;
  final String role;
  final int ordersCount;
  final double totalSpending;
  final Map<String, dynamic> data;

  const _CustomerCard({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.role,
    required this.ordersCount,
    required this.totalSpending,
    required this.data,
  });

  Color _roleColor(BuildContext context) {
    switch (role) {
      case 'superAdmin': return const Color(0xFFEF4444);
      case 'restaurantOwner': return const Color(0xFFF59E0B);
      case 'cashier': return const Color(0xFF8B5CF6);
      case 'driver': return const Color(0xFF10B981);
      default: return context.primaryColor;
    }
  }

  String _roleLabel() {
    switch (role) {
      case 'superAdmin': return 'Admin';
      case 'restaurantOwner': return 'Owner';
      case 'cashier': return 'Cashier';
      case 'driver': return 'Driver';
      default: return 'Customer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.primaryColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _roleColor(context).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(_roleLabel(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: _roleColor(context))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(email, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                  ],
                ),
              ),
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: context.errorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('Suspended', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: context.errorColor)),
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: context.textMutedColor),
                onSelected: (v) {
                  if (v == 'view') _showCustomerDetails(context, id, data);
                  if (v == 'suspend') _toggleCustomerStatus(id, !isActive, context);
                  if (v == 'role') _showChangeRoleDialog(context, id, data);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'view', child: Text('View Profile', style: GoogleFonts.inter(fontSize: 13))),
                  PopupMenuItem(value: 'role', child: Text('Change Role', style: GoogleFonts.inter(fontSize: 13, color: context.primaryColor))),
                  PopupMenuItem(value: 'suspend', child: Text(isActive ? 'Suspend' : 'Activate', style: GoogleFonts.inter(fontSize: 13, color: isActive ? context.errorColor : context.successColor))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, Icons.shopping_bag_rounded, '$ordersCount', 'Orders', context.primaryColor),
              const SizedBox(width: 20),
              _stat(context, Icons.attach_money_rounded, '\$${totalSpending.toStringAsFixed(0)}', 'Spent', context.successColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
      ],
    );
  }

  void _showCustomerDetails(BuildContext context, String uid, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(d['displayName'] as String? ?? 'Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: SizedBox(
          width: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('customerId', isEqualTo: uid).orderBy('createdAt', descending: true).limit(20).snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.hasError) return Text('Error loading orders', style: GoogleFonts.inter(color: context.errorColor, fontSize: 13));
              int refundCount = 0;
              if (orderSnap.hasData) {
                refundCount = orderSnap.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'refunded').length;
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${d['email'] ?? 'N/A'}', style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 13)),
                  Text('Phone: ${d['phone'] ?? 'N/A'}', style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 13)),
                  Divider(color: context.borderColor),
                  Text('Orders: ${orderSnap.data?.docs.length ?? 0}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                  Text('Refunds: $refundCount', style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 13)),
                  Text('Total Spent: \$${((d['totalSpending'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                ],
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(color: context.primaryColor)))],
      ),
    );
  }

  Future<void> _toggleCustomerStatus(String docId, bool active, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({'isActive': active});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(active ? 'Account activated' : 'Account suspended', style: GoogleFonts.inter()),
            backgroundColor: active ? context.successColor : context.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed', style: GoogleFonts.inter()), backgroundColor: context.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    }
  }

  void _showChangeRoleDialog(BuildContext context, String uid, Map<String, dynamic> d) {
    final currentRole = d['role'] as String? ?? 'customer';
    String selectedRole = currentRole;

    const roles = {
      'customer': 'Customer',
      'driver': 'Driver',
      'restaurantOwner': 'Restaurant Owner',
      'cashier': 'Cashier',
      'superAdmin': 'Super Admin',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Change Role', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d['displayName'] ?? d['email'] ?? 'User'}', style: GoogleFonts.inter(fontSize: 14, color: context.textMutedColor)),
                const SizedBox(height: 4),
                Text('Current role: ${roles[currentRole] ?? currentRole}', style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
                const SizedBox(height: 16),
                Text('Assign new role:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
                const SizedBox(height: 8),
                ...roles.entries.map((entry) => RadioListTile<String>(
                  title: Text(entry.value, style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor)),
                  value: entry.key,
                  groupValue: selectedRole,
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  activeColor: context.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
            ElevatedButton(
              onPressed: selectedRole == currentRole
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': selectedRole});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Role changed to ${roles[selectedRole]}', style: GoogleFonts.inter()),
                              backgroundColor: context.successColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to change role', style: GoogleFonts.inter()), backgroundColor: context.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white),
              child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
