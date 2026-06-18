import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_admin/features/dashboard/views/shared.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ProfileView extends StatelessWidget {
  const ProfileView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _HeroCard(user: user),
            const SizedBox(height: 16),
            _StatsCard(user: user),
            const SizedBox(height: 16),
            _ActivityCard(),
            const SizedBox(height: 16),
            _PermissionsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final UserModel? user;
  const _HeroCard({this.user});
  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'Admin';
    final email = user?.email ?? 'admin@tayyebgo.com';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.primaryColor, context.primaryColor],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surfaceColor, width: 4),
                    ),
                    child: Center(
                      child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 32, color: context.primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
                  const SizedBox(height: 2),
                  Text(email, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.brXl,
                    ),
                    child: Text(user?.role.displayName ?? 'Super Admin', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.primaryColor)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final UserModel? user;
  const _StatsCard({this.user});
  @override
  Widget build(BuildContext context) {
    final lastSignIn = user?.lastSignInAt;
    final createdAt = user?.createdAt;
    String signInText = 'Never';
    if (lastSignIn != null) {
      signInText = _fmtDate(lastSignIn);
    } else if (createdAt != null) {
      signInText = _fmtDate(createdAt);
    }
    String accountAge = '—';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inDays > 365) {
        accountAge = '${(diff.inDays / 365).floor()}y ${((diff.inDays % 365) / 30).floor()}m';
      } else if (diff.inDays > 30) {
        accountAge = '${(diff.inDays / 30).floor()}m ${diff.inDays % 30}d';
      } else {
        accountAge = '${diff.inDays}d ${diff.inHours % 24}h';
      }
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Account activity', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.login_rounded,
                  label: 'Last sign in',
                  value: signInText,
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _Stat(
                  icon: Icons.timelapse_rounded,
                  label: 'Account age',
                  value: accountAge,
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _Stat(
                  icon: Icons.verified_rounded,
                  label: 'Role',
                  value: (user?.role.displayName ?? 'Admin').split(' ').first,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m/$day ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Stat({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Icon(icon, size: 16, color: context.textMutedColor),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 18, color: context.successColor),
              const SizedBox(width: 8),
              Text('Recent actions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('activity_log').orderBy('createdAt', descending: true).limit(10).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return Text('No recent activity', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13));
              return Column(
                children: docs.asMap().entries.map((entry) {
                  final d = entry.value.data() as Map<String, dynamic>;
                  final action = d['action'] as String? ?? '';
                  final target = d['target'] as String? ?? '';
                  final ts = d['createdAt'] as Timestamp?;
                  final timeText = ts != null ? _formatActivityTime(ts.toDate()) : '';
                  final displayText = target.isNotEmpty ? '$action — $target' : action;
                  return Column(
                    children: [
                      if (entry.key > 0) Divider(height: 1, color: context.borderColor),
                      _ActivityRow(
                        icon: _iconForAction(action),
                        color: _colorForAction(context, d['color'] as String?),
                        title: displayText,
                        time: timeText,
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatActivityTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  IconData _iconForAction(String action) {
    if (action.contains('approved') || action.contains('verified')) return Icons.verified_rounded;
    if (action.contains('suspended') || action.contains('rejected')) return Icons.block_rounded;
    if (action.contains('campaign') || action.contains('notification')) return Icons.campaign_rounded;
    if (action.contains('invited') || action.contains('admin')) return Icons.person_add_rounded;
    if (action.contains('feature_flag') || action.contains('toggle')) return Icons.toggle_on_rounded;
    if (action.contains('store')) return Icons.store_rounded;
    if (action.contains('driver')) return Icons.delivery_dining_rounded;
    if (action.contains('order')) return Icons.receipt_long_rounded;
    if (action.contains('payout') || action.contains('settle')) return Icons.payments_rounded;
    return Icons.admin_panel_settings_rounded;
  }

  Color _colorForAction(BuildContext context, String? color) {
    switch (color) {
      case 'green': return context.successColor;
      case 'orange': return context.warningColor;
      case 'red': return context.errorColor;
      default: return context.primaryColor;
    }
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  const _ActivityRow({required this.icon, required this.color, required this.title, required this.time});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor)),
          ),
          Text(time, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final permissions = const [
      ('Dashboard', Icons.dashboard_rounded, true),
      ('Approve stores', Icons.verified_rounded, true),
      ('Manage orders', Icons.receipt_long_rounded, true),
      ('Manage drivers', Icons.delivery_dining_rounded, true),
      ('Finance & settlements', Icons.account_balance_rounded, true),
      ('Marketing', Icons.campaign_rounded, true),
      ('Send notifications', Icons.notifications_active_rounded, true),
      ('Feature flags', Icons.toggle_on_rounded, true),
      ('Delete data', Icons.delete_forever_rounded, false),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 18, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Permissions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < permissions.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(permissions[i].$2, size: 18, color: context.textMutedColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(permissions[i].$1, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (permissions[i].$3 ? context.successColor : context.errorColor).withValues(alpha: 0.1),
                      borderRadius: AppRadius.brXl,
                    ),
                    child: Text(
                      permissions[i].$3 ? 'Granted' : 'Restricted',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: permissions[i].$3 ? context.successColor : context.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
