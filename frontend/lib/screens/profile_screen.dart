import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'wishlist_screen.dart';
import 'orders_screen.dart';
import 'address_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('Profile', 'الملف الشخصي')),
        backgroundColor: OmniTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: OmniTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(t('Please login', 'لم تسجل الدخول'), style: TextStyle(fontSize: 18, color: OmniTheme.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(context, SmoothPageTransition(page: const LoginScreen())),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(t('Login', 'تسجيل الدخول')),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: OmniTheme.primaryColor,
                    child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text(user.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email ?? '', style: TextStyle(color: OmniTheme.textSecondary)),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(user.phone!, style: TextStyle(color: OmniTheme.textMuted, fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: _roleColor(user.role ?? 'customer').withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_roleLabel(user.role ?? 'customer', isArabic), style: TextStyle(color: _roleColor(user.role ?? 'customer'), fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              _buildSection([
                _MenuItem(icon: Icons.favorite_outline, title: t('Wishlist', 'المفضلة'), subtitle: t('Your favorites', 'قائمة أمنياتك'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()))),
                _MenuDivider(),
                _MenuItem(icon: Icons.receipt_long_outlined, title: t('Orders', 'الطلبات'), subtitle: t('Your orders', 'سجل طلباتك'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
                _MenuDivider(),
                _MenuItem(icon: Icons.location_on_outlined, title: t('Addresses', 'العناوين'), subtitle: t('Delivery addresses', 'عناوين التوصيل'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen()))),
                _MenuDivider(),
                _MenuItem(icon: Icons.language_outlined, title: t('Language', 'اللغة'), subtitle: t('Switch language', 'تغيير اللغة'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: OmniTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isArabic ? Icons.arrow_back : Icons.arrow_forward, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(isArabic ? 'عربي' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ]),
                  ),
                  onTap: () => locale.toggle(),
                ),
              ]),

              const SizedBox(height: 16),

              _buildSection([
                _MenuItem(icon: Icons.help_outline, title: t('Help & Support', 'الدعم'), subtitle: t('Contact us', 'تواصل معنا'), onTap: () {}),
                _MenuDivider(),
                _MenuItem(icon: Icons.description_outlined, title: t('Terms & Privacy', 'الشروط والخصوصية'), subtitle: t('Privacy policy', 'سياسة الخصوصية'), onTap: () {}),
              ]),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context, isArabic),
                  icon: const Icon(Icons.logout, color: OmniTheme.errorColor),
                  label: Text(t('Logout', 'تسجيل الخروج'), style: const TextStyle(color: OmniTheme.errorColor)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: OmniTheme.errorColor), padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  String _roleLabel(String role, bool isArabic) {
    switch (role) { case 'admin': return isArabic ? 'مسؤول' : 'Admin'; case 'delivery': return isArabic ? 'سائق' : 'Driver'; default: return isArabic ? 'عميل' : 'Customer'; }
  }

  Color _roleColor(String role) {
    switch (role) { case 'admin': return Colors.purple; case 'delivery': return Colors.orange; default: return OmniTheme.primaryColor; }
  }

  void _logout(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'Logout' : 'تسجيل الخروج'),
        content: Text(isArabic ? 'Are you sure?' : 'هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'Cancel' : 'إلغاء')),
          FilledButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<CartProvider>().clearCart();
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(context, SmoothPageTransition(page: const LoginScreen()), (route) => false);
            },
            style: FilledButton.styleFrom(backgroundColor: OmniTheme.errorColor),
            child: Text(isArabic ? 'Logout' : 'خروج'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: OmniTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: OmniTheme.textMuted, fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: OmniTheme.textMuted),
      onTap: onTap,
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 60, endIndent: 16);
}