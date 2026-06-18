import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerEmployeesScreen extends StatefulWidget {
  const PartnerEmployeesScreen({super.key});

  @override
  State<PartnerEmployeesScreen> createState() => _PartnerEmployeesScreenState();
}

class _PartnerEmployeesScreenState extends State<PartnerEmployeesScreen> {
  String? get _restaurantId {
    final auth = context.read<AuthProvider>();
    return auth.user?.vendorId;
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurantId == null) {
      return const Scaffold(body: Center(child: Text('No restaurant found')));
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Team Members', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('restaurantId', isEqualTo: _restaurantId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final members = snapshot.data?.docs ?? [];
          if (members.isEmpty) {
            return const TGEmptyState(
              icon: Icons.group_rounded,
              title: 'No team members',
              description: 'Invite your team to manage the store together.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final doc = members[index];
              final data = doc.data() as Map<String, dynamic>;
              return _MemberCard(
                memberId: doc.id,
                data: data,
                restaurantId: _restaurantId!,
                onRemove: () => _removeMember(doc.id),
              );
            },
          );
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    String selectedRole = 'cashier';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: context.borderColor, borderRadius: AppRadius.brSm),
                ),
              ),
              const SizedBox(height: 20),
              Text('Invite Team Member', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'Email address',
                  labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                  filled: true,
                  fillColor: context.backgroundColor,
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                ),
              ),
              const SizedBox(height: 16),
              Text('Role', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _roleChip('Manager', 'manager', selectedRole, (v) => setModalState(() => selectedRole = v)),
                  const SizedBox(width: 8),
                  _roleChip('Cashier', 'cashier', selectedRole, (v) => setModalState(() => selectedRole = v)),
                  const SizedBox(width: 8),
                  _roleChip('Kitchen', 'kitchen_staff', selectedRole, (v) => setModalState(() => selectedRole = v)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _inviteMember(emailCtrl.text, selectedRole),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    elevation: 0,
                  ),
                  child: Text('Send Invite', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label, String value, String selected, Function(String) onTap) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : context.surfaceColor,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 13,
          color: isSelected ? AppColors.primary : context.textPrimaryColor,
        )),
      ),
    );
  }

  Future<void> _inviteMember(String email, String role) async {
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: AppColors.error),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('contract_requests').add({
        'email': email,
        'role': role,
        'restaurantId': _restaurantId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite sent to $email'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this team member?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(memberId).update({
          'restaurantId': FieldValue.delete(),
          'role': 'customer',
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _MemberCard extends StatelessWidget {
  final String memberId;
  final Map<String, dynamic> data;
  final String restaurantId;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.memberId,
    required this.data,
    required this.restaurantId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] ?? data['email'] ?? 'Member';
    final email = data['email'] ?? '';
    final role = data['role'] ?? 'unknown';
    final photoUrl = data['photoUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          TGUserAvatar(imageUrl: photoUrl, name: name, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(email, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
                const SizedBox(height: 4),
                _roleBadge(role),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert_rounded, color: context.textMutedColor),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_rounded, size: 18, color: context.textPrimaryColor),
                  const SizedBox(width: 8),
                  Text('Edit Role', style: GoogleFonts.inter(fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(children: [
                  const Icon(Icons.person_remove_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Remove', style: GoogleFonts.inter(fontSize: 14, color: AppColors.error)),
                ]),
              ),
            ],
            onSelected: (v) {
              if (v == 'remove') onRemove();
            },
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    final (label, color) = switch (role) {
      'restaurantOwner' || 'owner' => ('Owner', AppColors.primary),
      'manager' => ('Manager', AppColors.adminAccent),
      'cashier' => ('Cashier', AppColors.warning),
      'kitchen_staff' => ('Kitchen', AppColors.driverAccent),
      _ => ('Staff', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
