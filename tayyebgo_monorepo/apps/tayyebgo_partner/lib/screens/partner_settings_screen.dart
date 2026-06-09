import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerSettingsScreen extends StatelessWidget {
  const PartnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Store';
    final email = user?.email.isNotEmpty == true ? user!.email : '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileHeader(context, initial, displayName, email),
          const SizedBox(height: 20),
          _section(context, 'Store', [
            _row(context, Icons.store_rounded, 'Store Details', () {}),
            _row(context, Icons.access_time_rounded, 'Business Hours', () {}),
            _row(context, Icons.delivery_dining_rounded, 'Delivery Settings', () {}),
            _row(context, Icons.payment_rounded, 'Payment Methods', () {}),
          ]),
          const SizedBox(height: 14),
          _section(context, 'Menu', [
            _row(context, Icons.restaurant_menu_rounded, 'Menu Management', () {}),
            _row(context, Icons.inventory_2_rounded, 'Inventory', () {}),
            _row(context, Icons.local_offer_rounded, 'Promotions', () {}),
          ]),
          const SizedBox(height: 14),
          _section(context, 'Preferences', [
            _row(context, Icons.notifications_outlined, 'Notifications', () {}),
            _row(context, Icons.language_rounded, 'Language', () {}),
            _row(context, Icons.print_rounded, 'Printer Settings', () {}),
          ]),
          const SizedBox(height: 14),
          _section(context, 'Account', [
            _row(context, Icons.person_rounded, 'Personal Info', () {}),
            _row(context, Icons.lock_outline_rounded, 'Change Password', () {}),
            _row(context, Icons.storefront_rounded, 'Add New Store', () {}),
          ]),
          const SizedBox(height: 14),
          _section(context, 'Support', [
            _row(context, Icons.help_outline_rounded, 'Help Center', () {}),
            _row(context, Icons.info_outline_rounded, 'About', () {}),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.errorColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.errorColor)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, String initial, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: context.warningColor, borderRadius: BorderRadius.circular(14)), child: Center(child: Text(initial, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: context.backgroundColor)))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                if (email.isNotEmpty)
                  Text(email, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 22),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textMutedColor)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.textMutedColor),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor))),
            Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}
