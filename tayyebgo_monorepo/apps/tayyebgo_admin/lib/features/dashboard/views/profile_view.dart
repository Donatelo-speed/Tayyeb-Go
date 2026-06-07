import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_admin/core/design_system/design_system.dart' as ds;
import 'package:tayyebgo_admin/core/widgets/widgets.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ProfileView extends StatelessWidget {
  const ProfileView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return ResponsiveContent(
      padding: EdgeInsets.zero,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: ds.AppSpacing.lg,
          vertical: ds.AppSpacing.lg,
        ),
        children: [
          _HeroCard(user: user),
          const SizedBox(height: ds.AppSpacing.md),
          _StatsCard(user: user),
          const SizedBox(height: ds.AppSpacing.md),
          _ActivityCard(user: user),
          const SizedBox(height: ds.AppSpacing.md),
          _PermissionsCard(user: user),
          const SizedBox(height: ds.AppSpacing.xl),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final dynamic user;
  const _HeroCard({this.user});
  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'Admin';
    final email = user?.email ?? 'admin@tayyebgo.com';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.primaryColor,
                  context.primaryColor.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(ds.AppRadius.lg),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: ds.AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.surfaceColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.primaryColor,
                      ),
                      child: Center(
                        child: Text(initials,
                            style: ds.AppTypography.number
                                .copyWith(color: Colors.white, fontSize: 32)),
                      ),
                    ),
                  ),
                  const SizedBox(height: ds.AppSpacing.sm),
                  Text(name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 2),
                  Text(email,
                      style: ds.AppTypography.caption
                          .copyWith(color: context.textSecondaryColor)),
                  const SizedBox(height: ds.AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role.displayName ?? 'Super Admin',
                      style: ds.AppTypography.label
                          .copyWith(color: context.primaryColor),
                    ),
                  ),
                  const SizedBox(height: ds.AppSpacing.md),
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
  final dynamic user;
  const _StatsCard({this.user});
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ds.AppRadius.md),
                ),
                child: Icon(Icons.bar_chart, color: context.primaryColor, size: 18),
              ),
              const SizedBox(width: ds.AppSpacing.sm),
              Text('Account activity', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: ds.AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.login,
                  label: 'Last sign in',
                  value: _fmtDate(DateTime.now().subtract(const Duration(hours: 2))),
                ),
              ),
              Container(width: 1, height: 40, color: context.dividerColor),
              Expanded(
                child: _Stat(
                  icon: Icons.timelapse,
                  label: 'Session',
                  value: '2h 14m',
                ),
              ),
              Container(width: 1, height: 40, color: context.dividerColor),
              Expanded(
                child: _Stat(
                  icon: Icons.devices,
                  label: 'Active devices',
                  value: '1',
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
          Icon(icon, size: 16, color: context.textSecondaryColor),
          const SizedBox(height: 4),
          Text(value,
              style: ds.AppTypography.bodyBold
                  .copyWith(color: context.textPrimaryColor)),
          const SizedBox(height: 2),
          Text(label,
              style: ds.AppTypography.caption
                  .copyWith(color: context.textMutedColor, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final dynamic user;
  const _ActivityCard({this.user});
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ds.AppRadius.md),
                ),
                child: Icon(Icons.check_circle_outline,
                    color: context.successColor, size: 18),
              ),
              const SizedBox(width: ds.AppSpacing.sm),
              Text('Recent actions', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: ds.AppSpacing.sm),
          _ActivityRow(
            icon: Icons.verified,
            color: context.successColor,
            title: 'Approved 3 stores',
            time: '2h ago',
          ),
          const Divider(height: 1),
          _ActivityRow(
            icon: Icons.campaign,
            color: context.primaryColor,
            title: 'Sent campaign to 12,450 customers',
            time: '5h ago',
          ),
          const Divider(height: 1),
          _ActivityRow(
            icon: Icons.person_add,
            color: context.warningColor,
            title: 'Invited new admin operator',
            time: 'Yesterday',
          ),
          const Divider(height: 1),
          _ActivityRow(
            icon: Icons.toggle_on,
            color: context.successColor,
            title: 'Enabled free delivery platform-wide',
            time: '2d ago',
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });
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
              borderRadius: BorderRadius.circular(ds.AppRadius.sm),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: ds.AppSpacing.sm),
          Expanded(
            child: Text(title,
                style: ds.AppTypography.caption
                    .copyWith(color: context.textPrimaryColor, fontSize: 13)),
          ),
          Text(time,
              style: ds.AppTypography.caption
                  .copyWith(color: context.textMutedColor)),
        ],
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  final dynamic user;
  const _PermissionsCard({this.user});
  @override
  Widget build(BuildContext context) {
    final permissions = const [
      ('Dashboard', Icons.dashboard_rounded, true),
      ('Approve stores', Icons.verified, true),
      ('Manage orders', Icons.receipt_long, true),
      ('Manage drivers', Icons.delivery_dining, true),
      ('Finance & settlements', Icons.account_balance, true),
      ('Marketing', Icons.campaign, true),
      ('Send notifications', Icons.notifications_active, true),
      ('Feature flags', Icons.toggle_on, true),
      ('Delete data', Icons.delete_forever, false),
    ];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ds.AppRadius.md),
                ),
                child: Icon(Icons.admin_panel_settings,
                    color: context.primaryColor, size: 18),
              ),
              const SizedBox(width: ds.AppSpacing.sm),
              Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: ds.AppSpacing.sm),
          for (var i = 0; i < permissions.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _PermissionRow(
              icon: permissions[i].$2,
              title: permissions[i].$1,
              granted: permissions[i].$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool granted;
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.granted,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.textSecondaryColor),
          const SizedBox(width: ds.AppSpacing.sm),
          Expanded(
            child: Text(title,
                style: ds.AppTypography.caption.copyWith(
                  color: context.textPrimaryColor,
                  fontSize: 13,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (granted ? context.successColor : context.errorColor)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              granted ? 'Granted' : 'Restricted',
              style: ds.AppTypography.label.copyWith(
                color: granted ? context.successColor : context.errorColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
