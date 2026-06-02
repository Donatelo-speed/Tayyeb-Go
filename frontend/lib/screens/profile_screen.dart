import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../models/user_model.dart';
import '../theme/tayyebgo_theme.dart';
import 'splash_screen.dart';
import 'tracking/profile_tab_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: TayyebGoTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TayyebGoTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: TayyebGoTheme.primaryColor,
                    child: Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: TayyebGoTheme.textSecondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role.displayName ?? 'customer',
                      style: const TextStyle(color: TayyebGoTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ProfileMenuItem(
              icon: Icons.favorite_outline, title: 'Wishlist', subtitle: 'Your favorite items',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.receipt_long_outlined, title: 'Orders', subtitle: 'Your order history',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.location_on_outlined, title: 'Addresses', subtitle: 'Delivery addresses',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileTabScreen(tab: 'addresses'))),
            ),
            _ProfileMenuItem(
              icon: Icons.payment_outlined, title: 'Payment Methods', subtitle: 'Manage payment options',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline, title: 'Help & Support', subtitle: 'Contact us',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.description_outlined, title: 'Terms & Privacy', subtitle: 'Privacy policy',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
              auth.logout(context);
                },
                icon: const Icon(Icons.logout, color: TayyebGoTheme.errorColor),
                label: const Text('Logout', style: TextStyle(color: TayyebGoTheme.errorColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: TayyebGoTheme.errorColor),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ProfileMenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: TayyebGoTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: TayyebGoTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _smsUpdates = true;
  bool _emailPromotions = false;
  bool _darkMode = false;
  String _selectedLocale = 'en';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final role = auth.user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: TayyebGoTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Notifications'),
          _settingsCard([
            _switchTile('Push Notifications', 'Order updates and offers', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
            _switchTile('SMS Updates', 'Delivery status via SMS', _smsUpdates, (v) => setState(() => _smsUpdates = v)),
            _switchTile('Email Promotions', 'Weekly deals and news', _emailPromotions, (v) => setState(() => _emailPromotions = v)),
          ]),
          const SizedBox(height: 16),
          _sectionHeader('Appearance'),
          _settingsCard([
            _switchTile('Dark Mode', 'Switch to dark theme', _darkMode, (v) => setState(() => _darkMode = v)),
            ListTile(
              leading: const Icon(Icons.language, color: TayyebGoTheme.primaryColor),
              title: const Text('Language'),
              subtitle: Text(_selectedLocale == 'ar' ? 'Arabic' : 'English'),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'ar', label: Text('AR')),
                ],
                selected: {_selectedLocale},
                onSelectionChanged: (v) {
                  setState(() => _selectedLocale = v.first);
                  locale.setLocale(v.first);
                },
              ),
            ),
          ]),
          // Role-specific settings
          if (role != null) ...[
            const SizedBox(height: 16),
            _sectionHeader('${role.displayName} Preferences'),
            if (role == UserRole.driver) _driverSettings(),
            if (role == UserRole.customer) _customerSettings(),
            if (role == UserRole.restaurantOwner) _vendorSettings(),
            if (role == UserRole.superAdmin) _adminSettings(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _driverSettings() {
    return _settingsCard([
      _switchTile('Auto-Accept Orders', 'Automatically accept new deliveries', false, (_) {}),
      _switchTile('Show Earnings on Map', 'Display trip earnings on map', true, (_) {}),
      ListTile(
        leading: const Icon(Icons.maximize, color: TayyebGoTheme.primaryColor),
        title: const Text('Max Delivery Radius'),
        subtitle: const Text('15 km'),
        trailing: const Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
      ),
    ]);
  }

  Widget _customerSettings() {
    return _settingsCard([
      _switchTile('Save Recent Orders', 'Remember your recent orders', true, (_) {}),
      _switchTile('Location-Based Suggestions', 'Show nearby restaurants', true, (_) {}),
      ListTile(
        leading: const Icon(Icons.location_on_outlined, color: TayyebGoTheme.primaryColor),
        title: const Text('Default Delivery Address'),
        subtitle: const Text('Set your default address'),
        trailing: const Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
      ),
    ]);
  }

  Widget _vendorSettings() {
    return _settingsCard([
      _switchTile('Auto-Print Orders', 'Print new orders automatically', false, (_) {}),
      _switchTile('Notify on Low Stock', 'Alert when inventory is low', true, (_) {}),
      ListTile(
        leading: const Icon(Icons.schedule, color: TayyebGoTheme.primaryColor),
        title: const Text('Business Hours'),
        subtitle: const Text('9:00 AM – 11:00 PM'),
        trailing: const Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
      ),
    ]);
  }

  Widget _adminSettings() {
    return _settingsCard([
      _switchTile('Audit Log', 'Track all admin actions', true, (_) {}),
      _switchTile('Maintenance Mode', 'Disable all user operations', false, (_) {}),
      ListTile(
        leading: const Icon(Icons.people_outline, color: TayyebGoTheme.primaryColor),
        title: const Text('Max Admins Per Session'),
        subtitle: const Text('5 concurrent sessions'),
        trailing: const Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
      ),
    ]);
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor)),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: TayyebGoTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }

  SwitchListTile _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: TayyebGoTheme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
