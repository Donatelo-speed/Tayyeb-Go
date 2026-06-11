import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/partner_role_controller.dart';
import 'cashier_terminal_screen.dart';
import 'kitchen_mode_screen.dart';
import 'owner_dashboard_screen.dart';

class PartnerGatekeeper extends StatelessWidget {
  const PartnerGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<PartnerRoleController>().currentRole;

    if (userRole == 'cashier') {
      return const CashierTerminalView();
    } else if (userRole == 'owner') {
      return const OwnerDashboardScreen();
    } else if (userRole == 'kitchen_staff') {
      final restaurantId = context.read<AuthProvider>().user?.vendorId ?? '';
      return KitchenModeScreen(restaurantId: restaurantId);
    } else {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_rounded, size: 64, color: context.textMutedColor),
              const SizedBox(height: 16),
              Text('Welcome to TayyebGo Partner', style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor,
              )),
              const SizedBox(height: 8),
              Text('Your role is being set up.', style: GoogleFonts.inter(
                color: context.textMutedColor, fontSize: 14,
              )),
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
