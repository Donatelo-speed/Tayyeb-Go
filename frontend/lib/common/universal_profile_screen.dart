import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../theme/tayyebgo_theme.dart';
import '../screens/splash_screen.dart' show LoginScreen;

class UniversalProfileScreen extends StatefulWidget {
  final UserRole userRole;
  const UniversalProfileScreen({super.key, required this.userRole});

  @override
  State<UniversalProfileScreen> createState() => _UniversalProfileScreenState();
}

class _UniversalProfileScreenState extends State<UniversalProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.t('Settings', 'الإعدادات')),
        backgroundColor: TayyebGoTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 8),
          _buildSectionTitle(locale.t('Account Info', 'معلومات الحساب'), context),
          _buildInfoTile(icon: Icons.email_outlined, title: locale.t('Email', 'البريد الإلكتروني'), value: user?.email ?? 'Not set'),
          _buildInfoTile(icon: Icons.phone_outlined, title: locale.t('Phone', 'رقم الهاتف'), value: user?.phone ?? 'Not set'),
          _buildSectionTitle(locale.t('Language', 'اللغة'), context),
          _buildLanguageSelector(locale),
          _buildCustomerSettings(user, locale),
          _buildOwnerSettings(user, locale),
          _buildDriverSettings(user, locale),
          _buildCashierSettings(user, locale),
          _buildAdminSettings(user, locale),
          _buildAppSettings(locale),
          _buildSupportSection(locale),
          _LogoutButton(auth: auth),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildCustomerSettings(UserModel? user, LocaleProvider locale) {
    if (user?.role != UserRole.customer) return const SizedBox.shrink();
    return Column(children: [
      _buildSectionTitle(locale.t('Saved Addresses', 'العناوين المحفوظة'), context),
      _buildInfoTile(icon: Icons.home, title: locale.t('Home', 'المنزل'), value: '123 Main St, Riyadh', onTap: () => _showAddressEditor(context, 'Home')),
      _buildInfoTile(icon: Icons.work, title: locale.t('Work', 'العمل'), value: '456 Business Ave, Riyadh', onTap: () => _showAddressEditor(context, 'Work')),
      _buildSectionTitle(locale.t('Payment History', 'سجل الدفع'), context),
      _buildInfoTile(icon: Icons.credit_card, title: locale.t('Payment Methods', 'طرق الدفع'), value: 'Cash, Card'),
      _buildInfoTile(icon: Icons.receipt_long, title: locale.t('Order History', 'تاريخ الطلبات'), value: 'View all orders'),
    ]);
  }

  Widget _buildOwnerSettings(UserModel? user, LocaleProvider locale) {
    if (user?.role != UserRole.restaurantOwner) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: user?.vendorId != null
          ? FirebaseFirestore.instance.collection('restaurants').doc(user!.vendorId).snapshots()
          : null,
      builder: (context, snapshot) {
        final d = snapshot.hasData ? snapshot.data!.data() as Map<String, dynamic>? : null;
        return Column(children: [
          _buildSectionTitle(locale.t('Restaurant Settings', 'إعدادات المطعم'), context),
          _buildInfoTile(icon: Icons.store, title: locale.t('Store Name', 'اسم المتجر'), value: d?['name'] as String? ?? 'Not set'),
          _buildSwitchTile(icon: Icons.toggle_on, title: locale.t('Store Open', 'المتجر مفتوح'), value: d?['isOpen'] == true, onChanged: (v) async {
            if (user?.vendorId == null) return;
            try {
              await FirebaseFirestore.instance.collection('restaurants').doc(user!.vendorId).update({'isOpen': v, 'updatedAt': FieldValue.serverTimestamp()});
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: TayyebGoTheme.errorColor));
            }
          }),
          _buildInfoTile(icon: Icons.access_time, title: locale.t('Operating Hours', 'ساعات العمل'), value: d?['hours'] as String? ?? '9:00 AM - 10:00 PM'),
          _buildInfoTile(icon: Icons.phone, title: locale.t('Contact Phone', 'هاتف الاتصال'), value: d?['phone'] as String? ?? 'Not set'),
          _buildSectionTitle(locale.t('Payouts', 'المدفوعات'), context),
          _buildInfoTile(icon: Icons.account_balance, title: locale.t('Bank Account', 'الحساب البنكي'), value: '****1234'),
          _buildInfoTile(icon: Icons.trending_up, title: locale.t('Total Payouts', 'إجمالي المدفوعات'), value: '\$12,450'),
        ]);
      },
    );
  }

  Widget _buildDriverSettings(UserModel? user, LocaleProvider locale) {
    if (user?.role != UserRole.driver) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null ? FirebaseFirestore.instance.collection('drivers').doc(user.id).snapshots() : null,
      builder: (context, snapshot) {
        final d = snapshot.hasData ? snapshot.data!.data() as Map<String, dynamic>? : null;
        final isOnline = d?['isOnline'] == true;
        return Column(children: [
          _buildSectionTitle(locale.t('Driver Settings', 'إعدادات السائق'), context),
          _buildSwitchTile(icon: Icons.toggle_on, title: locale.t('Active Duty', 'المناوبة النشطة'), value: isOnline, onChanged: (v) async {
            try {
              await FirebaseFirestore.instance.collection('drivers').doc(user!.id).update({'isOnline': v, 'updatedAt': FieldValue.serverTimestamp()});
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: TayyebGoTheme.errorColor));
            }
          }),
          _buildInfoTile(icon: Icons.directions_car, title: locale.t('Vehicle', 'المركبة'), value: d?['vehicle'] as String? ?? 'Toyota - ABC 123', onTap: () => _showVehicleEditor(context)),
          _buildInfoTile(icon: Icons.verified_user, title: locale.t('License', 'رخصة القيادة'), value: d?['licenseStatus'] as String? ?? 'Valid'),
          _buildSectionTitle(locale.t('Earnings', 'الأرباح'), context),
          _buildInfoTile(icon: Icons.monetization_on, title: locale.t('Today', 'اليوم'), value: '\$85'),
          _buildInfoTile(icon: Icons.trending_up, title: locale.t('This Week', 'هذا الأسبوع'), value: '\$520'),
          _buildInfoTile(icon: Icons.account_balance_wallet, title: locale.t('Total Earned', 'الإجمالي'), value: '\$12,340'),
        ]);
      },
    );
  }

  Widget _buildCashierSettings(UserModel? user, LocaleProvider locale) {
    if (user?.role != UserRole.cashier) return const SizedBox.shrink();
    return Column(children: [
      _buildSectionTitle(locale.t('Terminal Settings', 'إعدادات المحطة'), context),
      _buildInfoTile(icon: Icons.qr_code, title: locale.t('Station Code', 'رمز المحطة'), value: 'T-001'),
      _buildSwitchTile(icon: Icons.print, title: locale.t('Auto Print Receipt', 'طباعة الإيصال تلقائياً'), value: true, onChanged: (v) {}),
      _buildSwitchTile(icon: Icons.receipt, title: locale.t('Thermal Receipt', 'إيصال حراري'), value: true, onChanged: (v) {}),
    ]);
  }

  Widget _buildAdminSettings(UserModel? user, LocaleProvider locale) {
    if (user?.role != UserRole.superAdmin) return const SizedBox.shrink();
    return Column(children: [
      _buildSectionTitle(locale.t('System Config', 'تكوين النظام'), context),
      _buildSwitchTile(icon: Icons.security, title: locale.t('Audit Log', 'سجل التدقيق'), value: true, onChanged: (v) {}),
      _buildSwitchTile(icon: Icons.build, title: locale.t('Maintenance Mode', 'وضع الصيانة'), value: false, onChanged: (v) {}),
      _buildSwitchTile(icon: Icons.person_add, title: locale.t('Allow Registrations', 'السماح بالتسجيل'), value: true, onChanged: (v) {}),
      _buildInfoTile(icon: Icons.flag, title: locale.t('Feature Flags', 'علامات الميزات'), value: 'Manage'),
    ]);
  }

  Widget _buildAppSettings(LocaleProvider locale) {
    return Column(children: [
      _buildSectionTitle(locale.t('App Settings', 'إعدادات التطبيق'), context),
      _buildSwitchTile(icon: Icons.notifications_outlined, title: locale.t('Push Notifications', 'الإشعارات'), value: true, onChanged: (v) {}),
      _buildSwitchTile(icon: Icons.location_on_outlined, title: locale.t('Location Services', 'خدمات الموقع'), value: true, onChanged: (v) {}),
      _buildSwitchTile(icon: Icons.wifi_off, title: locale.t('Offline Mode', 'الوضع غير المتصل'), value: false, onChanged: (v) {}),
    ]);
  }

  Widget _buildSupportSection(LocaleProvider locale) {
    return Column(children: [
      _buildSectionTitle(locale.t('Support', 'الدعم'), context),
      _buildInfoTile(icon: Icons.help_outline, title: locale.t('Help Center', 'مركز المساعدة'), value: ''),
      _buildInfoTile(icon: Icons.chat_outlined, title: locale.t('Contact Us', 'اتصل بنا'), value: ''),
      _buildInfoTile(icon: Icons.privacy_tip_outlined, title: locale.t('Privacy Policy', 'سياسة الخصوصية'), value: ''),
    ]);
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: TayyebGoTheme.dividerColor)),
      ]),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String value, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: TayyebGoTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: value.isNotEmpty ? Text(value, style: const TextStyle(color: TayyebGoTheme.textSecondary)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: TayyebGoTheme.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildLanguageSelector(LocaleProvider locale) {
    return ListTile(
      leading: const Icon(Icons.language, color: TayyebGoTheme.primaryColor),
      title: const Text('Language / اللغة', style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(locale.isEnglish ? 'English' : 'العربية'),
      trailing: const Icon(Icons.chevron_right, size: 20, color: TayyebGoTheme.textMuted),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: TayyebGoTheme.surfaceColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: locale.isEnglish ? const Icon(Icons.check, color: TayyebGoTheme.primaryColor) : null,
              onTap: () { locale.setLocale('en'); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Text('🇸🇾', style: TextStyle(fontSize: 24)),
              title: const Text('العربية'),
              trailing: locale.isArabic ? const Icon(Icons.check, color: TayyebGoTheme.primaryColor) : null,
              onTap: () { locale.setLocale('ar'); Navigator.pop(context); },
            ),
            const SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      secondary: Icon(icon, color: TayyebGoTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: TayyebGoTheme.primaryColor,
    );
  }

  void _showVehicleEditor(BuildContext context) {
    final plateCtrl = TextEditingController(text: 'ABC 123');
    final modelCtrl = TextEditingController(text: 'Toyota Corolla');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Vehicle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Vehicle Model', prefixIcon: Icon(Icons.directions_car))),
          const SizedBox(height: 12),
          TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'License Plate', prefixIcon: Icon(Icons.confirmation_number))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showAddressEditor(BuildContext context, String label) {
    final streetCtrl = TextEditingController(text: '123 Main St');
    final cityCtrl = TextEditingController(text: 'Riyadh');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $label Address'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: streetCtrl, decoration: const InputDecoration(labelText: 'Street', prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 12),
          TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final nameCtrl = TextEditingController(text: user?.displayName);
    final emailCtrl = TextEditingController(text: user?.email);
    final phoneCtrl = TextEditingController(text: user?.phone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await auth.updateProfile(displayName: nameCtrl.text, email: emailCtrl.text, phone: phoneCtrl.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'), backgroundColor: TayyebGoTheme.successColor));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: TayyebGoTheme.primaryGradient),
      child: Column(children: [
        CircleAvatar(radius: 50, backgroundColor: Colors.white,
          child: Text(user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor))),
        const SizedBox(height: 12),
        Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        _RoleBadge(role: user?.role),
      ]),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole? role;
  const _RoleBadge({this.role});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;
    switch (role) {
      case UserRole.superAdmin: label = 'Super Admin'; icon = Icons.admin_panel_settings; color = Colors.red;
      case UserRole.restaurantOwner: label = 'Restaurant Owner'; icon = Icons.store; color = Colors.blue;
      case UserRole.cashier: label = 'Cashier'; icon = Icons.point_of_sale; color = Colors.purple;
      case UserRole.driver: label = 'Driver'; icon = Icons.delivery_dining; color = Colors.orange;
      default: label = 'Customer'; icon = Icons.person; color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final AuthProvider auth;
  const _LogoutButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
