import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final auth = context.watch<AuthProvider>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(title: Text(t('Settings', 'الإعدادات')), backgroundColor: OmniTheme.surfaceColor, elevation: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('Account', 'الحساب'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OmniTheme.textMuted)),
          const SizedBox(height: 8),
          _buildSection([
            _MenuItem(icon: Icons.person_outline, title: t('Edit Profile', 'تعديل الملف'), subtitle: t('Update your info', 'تحديث معلوماتك'), onTap: () => _showEditDialog(context, isArabic)),
            _MenuDivider(),
            _MenuItem(icon: Icons.phone_outlined, title: t('Phone Number', 'رقم الهاتف'), subtitle: auth.user?.phone ?? t('Not set', 'غير مضاف'), onTap: () {}),
            _MenuDivider(),
            _MenuItem(icon: Icons.email_outlined, title: t('Email', 'البريد'), subtitle: auth.user?.email ?? '', onTap: () {}),
          ]),
          const SizedBox(height: 24),
          Text(t('Preferences', 'التفضيلات'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OmniTheme.textMuted)),
          const SizedBox(height: 8),
          _buildSection([
            _MenuItem(icon: Icons.language_outlined, title: t('Language', 'اللغة'), subtitle: isArabic ? 'العربية' : 'English', onTap: () => locale.toggle()),
            _MenuDivider(),
            _MenuItem(icon: Icons.notifications_outlined, title: t('Notifications', 'الإشعارات'), subtitle: t('Manage alerts', 'إدارة التنبيهات'), onTap: () {}),
          ]),
          const SizedBox(height: 24),
          Text(t('App', 'التطبيق'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OmniTheme.textMuted)),
          const SizedBox(height: 8),
          _buildSection([
            _MenuItem(icon: Icons.info_outline, title: t('About', 'حول'), subtitle: t('App version', 'نسخة التطبيق'), onTap: () {}),
            _MenuDivider(),
            _MenuItem(icon: Icons.privacy_tip_outlined, title: t('Privacy Policy', 'الخصوصية'), subtitle: t('Read our policy', 'اقرأ سياستنا'), onTap: () {}),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  void _showEditDialog(BuildContext context, bool isArabic) {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isArabic ? 'تعديل الملف' : 'Edit Profile', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: InputDecoration(labelText: isArabic ? 'الاسم' : 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () { Navigator.pop(context); }, child: Text(isArabic ? 'حفظ' : 'Save'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: OmniTheme.primaryColor, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: OmniTheme.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: OmniTheme.textMuted),
      onTap: onTap,
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 60, endIndent: 16);
}