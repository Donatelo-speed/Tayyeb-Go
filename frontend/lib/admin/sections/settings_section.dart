import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin_design.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});
  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool _maintenanceMode = false, _registrations = true, _auditLog = true;
  double _commissionRate = 15;
  int _maxDriversPerZone = 10;
  String _language = 'en';
  bool _loaded = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _maintenanceMode = p.getBool('admin_maintenance') ?? false;
      _registrations = p.getBool('admin_registrations') ?? true;
      _auditLog = p.getBool('admin_audit') ?? true;
      _commissionRate = p.getDouble('admin_commission') ?? 15;
      _maxDriversPerZone = p.getInt('admin_max_drivers') ?? 10;
      _language = p.getString('admin_language') ?? 'en';
      _loaded = true;
    });
  }

  Future<void> _save(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    switch (key) {
      case 'maintenance': p.setBool('admin_maintenance', _maintenanceMode); break;
      case 'registrations': p.setBool('admin_registrations', _registrations); break;
      case 'audit': p.setBool('admin_audit', _auditLog); break;
      case 'commission': p.setDouble('admin_commission', _commissionRate); break;
      case 'max_drivers': p.setInt('admin_max_drivers', _maxDriversPerZone); break;
    }
    setState(() {});
  }

  void _executeKillSwitch() {
    showDialog(context: context, builder: (ctx) {
      final reasonCtrl = TextEditingController();
      bool confirmed = false;
      return StatefulBuilder(builder: (ctx, setDState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.xxl)),
        title: const Row(children: [Icon(Icons.warning_rounded, color: AdminColors.danger, size: 24), SizedBox(width: 8), Text('Kill Switch')]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This will disable the entire platform. All users will be logged out.'),
          const SizedBox(height: 16),
          TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason for shutdown', hintText: 'e.g., Critical system failure')),
          const SizedBox(height: 12),
          Row(children: [
            Checkbox(value: confirmed, onChanged: (v) => setDState(() => confirmed = v ?? false), activeColor: AdminColors.danger),
            const Expanded(child: Text('I understand this will shut down the platform', style: TextStyle(fontSize: 12))),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: confirmed ? () async {
            await FirebaseFirestore.instance.collection('platform_config').doc('status').set({'active': false, 'disabledAt': FieldValue.serverTimestamp(), 'reason': reasonCtrl.text.trim()});
            if (ctx.mounted) Navigator.pop(ctx);
          } : null, style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger), child: const Text('Disable Platform')),
        ],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Platform Settings', style: isDark ? AdminTypography.h2(true) : AdminTypography.h2(false)),
        const SizedBox(height: 24),
        _settingSection(isDark, 'General', [
          _switchRow('Maintenance Mode', 'Disable all customer operations', _maintenanceMode, (v) { _maintenanceMode = v; _save('maintenance', v); }),
          _switchRow('Allow Registrations', 'Enable new user sign-ups', _registrations, (v) { _registrations = v; _save('registrations', v); }),
          _switchRow('Audit Logging', 'Track all admin actions', _auditLog, (v) { _auditLog = v; _save('audit', v); }),
        ]),
        const SizedBox(height: 20),
        _settingSection(isDark, 'Operations', [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Commission Rate: ${_commissionRate.toStringAsFixed(0)}%', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
            Slider(value: _commissionRate, min: 5, max: 40, divisions: 35, label: '${_commissionRate.toStringAsFixed(0)}%', onChanged: (v) { _commissionRate = v; }, onChangeEnd: (_) => _save('commission', _commissionRate), activeColor: AdminColors.primary),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Max Drivers Per Zone: $_maxDriversPerZone', style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)),
            Slider(value: _maxDriversPerZone.toDouble(), min: 5, max: 50, divisions: 45, label: '$_maxDriversPerZone', onChanged: (v) { _maxDriversPerZone = v.round(); }, onChangeEnd: (_) => _save('max_drivers', _maxDriversPerZone), activeColor: AdminColors.primary),
          ]),
        ]),
        const SizedBox(height: 20),
        _settingSection(isDark, 'Language', [
          DropdownButtonFormField<String>(initialValue: _language, decoration: const InputDecoration(labelText: 'Language', prefixIcon: Icon(Icons.language_rounded)), items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'ar', child: Text('العربية (Arabic)'))], onChanged: (v) { if (v != null) { _language = v; setState(() {}); } }),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: isDark ? AdminColors.danger.withValues(alpha: 0.05) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(AdminRadius.xl), border: Border.all(color: AdminColors.danger.withValues(alpha: 0.2))),
          child: Row(children: [
            const Icon(Icons.warning_rounded, color: AdminColors.danger, size: 24),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, color: AdminColors.danger)), Text('Emergency platform shutdown', style: TextStyle(fontSize: 12, color: AdminColors.danger))])),
            ElevatedButton.icon(onPressed: _executeKillSwitch, icon: const Icon(Icons.power_off_rounded, size: 16), label: const Text('Kill Switch'), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)))),
          ]),
        ),
      ]),
    );
  }

  Widget _settingSection(bool isDark, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, borderRadius: BorderRadius.circular(AdminRadius.xl), boxShadow: AdminShadows.card(isDark)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: isDark ? AdminTypography.h3(true) : AdminTypography.h3(false)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _switchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(title: Text(title, style: isDark ? AdminTypography.h4(true) : AdminTypography.h4(false)), subtitle: Text(subtitle, style: isDark ? AdminTypography.bodySmall(true) : AdminTypography.bodySmall(false)), value: value, onChanged: onChanged, activeThumbColor: AdminColors.primary, contentPadding: EdgeInsets.zero);
  }
}