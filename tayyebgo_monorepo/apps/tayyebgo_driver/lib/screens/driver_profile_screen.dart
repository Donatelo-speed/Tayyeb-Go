import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Driver';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: context.successColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(initial, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 36, color: context.textPrimaryColor)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
                const SizedBox(height: 4),
                if (email.isNotEmpty)
                  Text(email, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(phone, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Platform Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.successColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _section(context, 'Account', [
            _row(context, Icons.person_rounded, 'Personal Information', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Personal information editing coming soon')),
              );
            }),
            _row(context, Icons.directions_car_rounded, 'Vehicle Details', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vehicle details coming soon')),
              );
            }),
            _row(context, Icons.badge_rounded, 'Documents', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document upload coming soon')),
              );
            }),
            _row(context, Icons.location_on_rounded, 'Delivery Zone', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delivery zone selection coming soon')),
              );
            }),
          ]),
          const SizedBox(height: 16),
          _section(context, 'Preferences', [
            _row(context, Icons.language_rounded, 'Language', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language selection coming soon')),
              );
            }),
            _row(context, Icons.notifications_outlined, 'Notifications', () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            }),
            _row(context, Icons.lock_outline_rounded, 'Change Password', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password change coming soon')),
              );
            }),
          ]),
          const SizedBox(height: 16),
          _section(context, 'Support', [
            _row(context, Icons.help_outline_rounded, 'Help Center', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon')),
              );
            }),
            _row(context, Icons.info_outline_rounded, 'About', () {
              showAboutDialog(
                context: context,
                applicationName: 'TayyebGo Driver',
                applicationVersion: '1.0.0',
                children: [
                  Text('Delivery platform driver app', style: GoogleFonts.inter()),
                ],
              );
            }),
          ]),
          const SizedBox(height: 16),
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
            child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textMutedColor)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
