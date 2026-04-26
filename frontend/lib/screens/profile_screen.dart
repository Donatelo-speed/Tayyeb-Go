import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/omni_theme.dart';
import 'login_screen.dart';
import 'language_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Not logged in'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Login'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                CircleAvatar(
                  radius: 50,
                  backgroundColor: OmniTheme.primaryColor,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(user.email, style: TextStyle(color: Colors.grey[600])),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.phone!, style: TextStyle(color: Colors.grey[500])),
                ],
                const SizedBox(height: 8),
                Chip(
                  label: Text(_getRoleLabel(user.role)),
                  backgroundColor: _getRoleColor(user.role),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Divider(),

                // Menu Items
                _MenuItem(
                  icon: Icons.edit,
                  title: 'تعديل الملف الشخصي',
                  subtitle: 'تغيير الاسم ورقم الهاتف',
                  onTap: () => _editProfile(context),
                ),
                _MenuItem(
                  icon: Icons.favorite,
                  title: 'المفضلة',
                  subtitle: 'المنتجات المحفوظة',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                  badge: Consumer<WishlistProvider>(
                    builder: (context, wishlist, _) => wishlist.itemCount > 0 
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('${wishlist.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        )
                      : const SizedBox.shrink(),
                  ),
                ),
                _MenuItem(
                  icon: Icons.history,
                  title: 'سجل الطلبات',
                  subtitle: 'شاهد طلباتك السابقة',
                  onTap: () => Navigator.pushNamed(context, '/orders'),
                ),
                _MenuItem(
                  icon: Icons.location_on,
                  title: 'العناوين',
                  subtitle: 'إدارة عناوين التوصيل',
                  onTap: () => Navigator.pushNamed(context, '/addresses'),
                ),
                _MenuItem(
                  icon: Icons.language,
                  title: 'اللغة',
                  subtitle: 'العربية / English',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'المساعدة والدعم',
                  subtitle: 'تواصل معنا عبر واتساب',
                  onTap: () => _openWhatsapp(context),
                ),
                _MenuItem(
                  icon: Icons.description,
                  title: 'سياسة الخصوصية',
                  subtitle: 'قراءةالشروط والأحكام',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: 'حول التطبيق',
                  subtitle: 'الإصدار 1.0.0',
                  onTap: () => _showAbout(context),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin': return 'مسؤول';
      case 'delivery': return 'سائق توصيل';
      default: return 'عميل';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'delivery': return Colors.orange;
      default: return OmniTheme.primaryColor;
    }
  }

  void _editProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const EditProfileSheet(),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  void _openWhatsapp(BuildContext context) {
    // In production, open WhatsApp
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم فتح الواتساب للتواصل')),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'OmniMarket',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 OmniMarket\nسوق إلكتروني سوري',
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? badge;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: OmniTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: OmniTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) badge!,
          const Icon(Icons.chevron_left),
        ],
      ),
      onTap: onTap,
    );
  }
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('تعديل الملف', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveProfile,
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    // In production, save to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التغييرات'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlist, _) {
          if (wishlist.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد منتجات في المفضلة'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: wishlist.products.length,
            itemBuilder: (context, index) {
              final product = wishlist.products[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag),
                ),
                title: Text(product.name),
                subtitle: Text('\$${product.price}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => wishlist.removeFromWishlist(product.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}