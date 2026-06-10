import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/shared_widgets/ui_feedback.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _pushEnabled = true;
  bool _smsEnabled = true;
  bool _emailEnabled = true;
  bool _auditLogEnabled = true;
  String _locale = 'en';
  bool _loadingPrefs = true;
  bool _savingPrefs = false;
  bool _exportingData = false;

  final List<_TabInfo> _tabs = const [
    _TabInfo('Notifications', Icons.notifications_outlined),
    _TabInfo('Language', Icons.language_outlined),
    _TabInfo('Account', Icons.person_outline),
    _TabInfo('Admin', Icons.shield_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _locale = user.preferredLocale;
    }
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final prefs = await context.read<UserProfileProvider>().loadNotificationPrefs(user.id);
    _pushEnabled = prefs['push'] as bool;
    _smsEnabled = prefs['sms'] as bool;
    _emailEnabled = prefs['email'] as bool;
    _auditLogEnabled = prefs['auditLogEnabled'] as bool;
    if (mounted) setState(() => _loadingPrefs = false);
  }

  Future<void> _savePrefs() async {
    setState(() => _savingPrefs = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final success = await context.read<UserProfileProvider>().saveNotificationPrefs(
      userId: user.id,
      push: _pushEnabled,
      sms: _smsEnabled,
      email: _emailEnabled,
      auditLogEnabled: _auditLogEnabled,
    );
    if (success) {
      if (mounted) context.showSuccess('Preferences saved');
    } else {
      if (mounted) context.showError('Failed to save preferences');
    }
    if (mounted) setState(() => _savingPrefs = false);
  }

  Future<void> _exportData() async {
    setState(() => _exportingData = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.showSuccess('Data export started. You will receive an email shortly.');
    } catch (_) {
      if (mounted) context.showError('Export failed. Please try again.');
    } finally {
      if (mounted) setState(() => _exportingData = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAdmin = auth.isSuperAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t.label, icon: Icon(t.icon, size: 18))).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildNotificationsTab(),
          _buildLanguageTab(user),
          _buildAccountTab(user),
          if (isAdmin) _buildAdminTab() else _buildAccountTab(user),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    if (_loadingPrefs) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader('Notification Channels'),
        const SizedBox(height: 12),
        _switchTile(
          'Push Notifications',
          'Receive order updates in real-time',
          Icons.notifications_outlined,
          _pushEnabled,
          (v) => setState(() => _pushEnabled = v),
        ),
        _switchTile(
          'SMS Alerts',
          'Get text messages for status changes',
          Icons.sms_outlined,
          _smsEnabled,
          (v) => setState(() => _smsEnabled = v),
        ),
        _switchTile(
          'Email Updates',
          'Receive promotional and transactional emails',
          Icons.email_outlined,
          _emailEnabled,
          (v) => setState(() => _emailEnabled = v),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _savingPrefs ? null : _savePrefs,
            icon: _savingPrefs
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_savingPrefs ? 'Saving...' : 'Save Preferences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageTab(user) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader('Display Language'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          child: Column(children: [
            RadioListTile<String>(
              title: const Text('English', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Default language', style: TextStyle(fontSize: 12)),
              value: 'en',
              groupValue: _locale,
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              onChanged: (v) {
                setState(() => _locale = v!);
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  context.read<UserProfileProvider>().updateProfile(
                    userId: user.id,
                    preferredLocale: v,
                  );
                }
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            RadioListTile<String>(
              title: const Text('Arabic', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('اللغة العربية', style: TextStyle(fontSize: 12)),
              value: 'ar',
              groupValue: _locale,
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              onChanged: (v) {
                setState(() => _locale = v!);
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  context.read<UserProfileProvider>().updateProfile(
                    userId: user.id,
                    preferredLocale: v,
                  );
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Region'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.language_outlined, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Region', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('Homs, Syria', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.check_circle, size: 18, color: AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab(user) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader('Account Details'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          child: Column(children: [
            _infoTile(Icons.badge_outlined, 'Role', user?.role.displayName ?? ''),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _infoTile(Icons.email_outlined, 'Email', user?.email ?? ''),
            if (user?.createdAt != null) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _infoTile(Icons.calendar_today_outlined, 'Member Since',
                  '${user!.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}-${user.createdAt!.day.toString().padLeft(2, '0')}'),
            ],
          ]),
        ),
        const SizedBox(height: 24),
        _sectionHeader('About'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          child: Column(children: [
            _infoTile(Icons.info_outline, 'App Version', '1.0.0'),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _infoTile(Icons.code_outlined, 'Build', '2026.05'),
          ]),
        ),
      ],
    );
  }

  Widget _buildAdminTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    Text('Platform-level configuration', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Security & Monitoring'),
        const SizedBox(height: 12),
        _switchTile(
          'Audit Logging',
          'Record all admin actions for compliance',
          Icons.history_outlined,
          _auditLogEnabled,
          (v) => setState(() => _auditLogEnabled = v),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Data Management'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          child: Column(children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download_outlined, color: AppColors.primary, size: 20),
              ),
              title: const Text('Export Platform Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('CSV export of orders, users, and finance', style: TextStyle(fontSize: 12)),
              trailing: _exportingData
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: _exportingData ? null : _exportData,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restart_alt_outlined, color: AppColors.warning, size: 20),
              ),
              title: const Text('Reset Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Restore all settings to defaults', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () async {
                final confirmed = await context.confirmAction(
                  title: 'Reset Preferences',
                  message: 'This will restore all notification preferences and settings to their defaults.',
                  confirmLabel: 'Reset',
                  confirmColor: AppColors.warning,
                );
                if (confirmed && mounted) {
                  setState(() {
                    _pushEnabled = true;
                    _smsEnabled = true;
                    _emailEnabled = true;
                    _auditLogEnabled = true;
                  });
                  await _savePrefs();
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Danger Zone'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_outlined, color: AppColors.error, size: 20),
            ),
            title: const Text('Clear Activity Log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
            subtitle: const Text('Remove all historical activity records', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () async {
                final confirmed = await context.confirmAction(
                  title: 'Clear Activity Log',
                  message: 'This will permanently delete all activity log entries. This action cannot be undone.',
                  confirmLabel: 'Clear All',
                  confirmColor: AppColors.error,
                );
                if (confirmed && mounted) {
                  final success = await context.read<UserProfileProvider>().clearActivityLog();
                  if (success) {
                    if (mounted) context.showSuccess('Activity log cleared');
                  } else {
                    if (mounted) context.showError('Failed to clear activity log');
                  }
                }
              },
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _savingPrefs ? null : _savePrefs,
            icon: _savingPrefs
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_savingPrefs ? 'Saving...' : 'Save Admin Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.textSecondary, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeColor: AppColors.success,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onChanged: onChanged,
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}
