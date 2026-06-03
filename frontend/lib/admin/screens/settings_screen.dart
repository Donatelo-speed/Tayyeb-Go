import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _maintenanceMode = false;
  bool _registrationsOpen = true;
  bool _auditLogging = true;
  double _commissionRate = 15;
  int _maxDrivers = 50;
  bool _killSwitch = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('platform_settings').doc('main').get();
      if (doc.exists) {
        final d = doc.data() ?? {};
        setState(() {
          _maintenanceMode = d['maintenanceMode'] ?? false;
          _registrationsOpen = d['registrationsOpen'] ?? true;
          _auditLogging = d['auditLoggingEnabled'] ?? true;
          _commissionRate = (d['defaultCommissionRate'] as num?)?.toDouble() ?? 15;
          _maxDrivers = d['maxDriversPerZone'] ?? 50;
          _killSwitch = d['killSwitchEnabled'] ?? false;
        });
      }
    } catch (_) {}
    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    try {
      await FirebaseFirestore.instance.collection('platform_settings').doc('main').set({
        'maintenanceMode': _maintenanceMode,
        'registrationsOpen': _registrationsOpen,
        'auditLoggingEnabled': _auditLogging,
        'defaultCommissionRate': _commissionRate,
        'maxDriversPerZone': _maxDrivers,
        'killSwitchEnabled': _killSwitch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved'), backgroundColor: AdminColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger));
    }
  }

  Future<void> _confirmKillSwitch() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AdminConfirmDialog(
      title: 'Emergency Kill Switch',
      message: 'This will immediately shut down the entire platform. All operations will stop. This action is logged and irreversible without admin intervention.',
      confirmLabel: 'Shut Down Platform',
      danger: true,
    ));
    if (ok == true) {
      setState(() => _killSwitch = true);
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const AdminLoadingState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Platform Settings', style: AdminTypography.h1(isDark)),
        const SizedBox(height: AdminSpacing.xxxl),

        _SettingsSection(title: 'General', icon: Icons.settings_rounded, children: [
          _ToggleRow(isDark: isDark, label: 'Maintenance Mode', subtitle: 'Show maintenance page to all users', value: _maintenanceMode, onChanged: (v) => setState(() => _maintenanceMode = v)),
          _ToggleRow(isDark: isDark, label: 'Open Registrations', subtitle: 'Allow new users to register', value: _registrationsOpen, onChanged: (v) => setState(() => _registrationsOpen = v)),
          _ToggleRow(isDark: isDark, label: 'Audit Logging', subtitle: 'Track all admin actions', value: _auditLogging, onChanged: (v) => setState(() => _auditLogging = v)),
        ]),

        const SizedBox(height: AdminSpacing.xxl),
        _SettingsSection(title: 'Commission & Limits', icon: Icons.percent_rounded, children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Default Commission Rate', style: AdminTypography.h4(isDark)),
                Text('Applied to new stores', style: AdminTypography.bodySmall(isDark)),
              ])),
              SizedBox(width: 200, child: Row(children: [
                Expanded(child: Slider(value: _commissionRate, min: 0, max: 30, divisions: 30, label: '${_commissionRate.round()}%', onChanged: (v) => setState(() => _commissionRate = v))),
                SizedBox(width: 40, child: Text('${_commissionRate.round()}%', style: AdminTypography.mono(isDark))),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Max Drivers Per Zone', style: AdminTypography.h4(isDark)),
                Text('Limit concurrent drivers in any zone', style: AdminTypography.bodySmall(isDark)),
              ])),
              SizedBox(width: 200, child: Row(children: [
                Expanded(child: Slider(value: _maxDrivers.toDouble(), min: 10, max: 200, divisions: 19, label: '$_maxDrivers', onChanged: (v) => setState(() => _maxDrivers = v.round()))),
                SizedBox(width: 36, child: Text('$_maxDrivers', style: AdminTypography.mono(isDark))),
              ])),
            ]),
          ),
        ]),

        const SizedBox(height: AdminSpacing.xxl),
        _SettingsSection(title: 'Language & Region', icon: Icons.language_rounded, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Default Language', style: AdminTypography.h4(isDark)),
            subtitle: Text('English', style: AdminTypography.bodySmall(isDark)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Region', style: AdminTypography.h4(isDark)),
            subtitle: Text('Homs, Syria', style: AdminTypography.bodySmall(isDark)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ]),

        const SizedBox(height: AdminSpacing.xxxl),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Settings'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
        ),

        const SizedBox(height: AdminSpacing.xxxl),
        Container(
          padding: const EdgeInsets.all(AdminSpacing.xxl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminRadius.xl),
            border: Border.all(color: AdminColors.danger.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.warning_rounded, color: AdminColors.danger, size: 24),
              const SizedBox(width: AdminSpacing.md),
              Text('Danger Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AdminColors.danger)),
            ]),
            const SizedBox(height: AdminSpacing.lg),
            Text('The kill switch immediately disables all platform operations. No orders can be placed, no drivers can go online, and all stores are paused.', style: AdminTypography.bodySmall(isDark)),
            const SizedBox(height: AdminSpacing.lg),
            Row(children: [
              OutlinedButton.icon(
                onPressed: _killSwitch ? null : _confirmKillSwitch,
                icon: const Icon(Icons.power_settings_new_rounded, color: AdminColors.danger, size: 18),
                label: Text(_killSwitch ? 'Platform Shut Down' : 'Shut Down Platform', style: const TextStyle(color: AdminColors.danger)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AdminColors.danger)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
      decoration: cardDecoration(isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: AdminColors.primary),
          const SizedBox(width: AdminSpacing.md),
          Text(title, style: AdminTypography.h2(isDark)),
        ]),
        const SizedBox(height: AdminSpacing.lg),
        ...children,
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final bool isDark, value;
  final String label, subtitle;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.isDark, required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AdminTypography.h4(isDark)),
          Text(subtitle, style: AdminTypography.bodySmall(isDark)),
        ])),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}