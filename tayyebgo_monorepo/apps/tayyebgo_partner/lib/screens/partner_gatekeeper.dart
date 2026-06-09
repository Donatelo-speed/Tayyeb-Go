import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../providers/partner_role_controller.dart';
import 'cashier_terminal_screen.dart';
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
    } else {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: const Center(child: AppLoader()),
      );
    }
  }
}
