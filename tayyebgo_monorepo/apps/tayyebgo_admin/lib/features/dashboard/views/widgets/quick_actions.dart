import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../shared.dart';
import '../create_business_wizard.dart' as wizard;

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _quickAction(context, 'New Store', Icons.add_business_outlined, AppColors.primary, () => showDialog(context: context, builder: (_) => const wizard.CreateBusinessWizard())),
          const SizedBox(width: 10),
          _quickAction(context, 'Invite Driver', Icons.person_add_outlined, AppColors.info, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Invite Driver'),
                content: const SizedBox(
                  width: 320,
                  child: TextField(decoration: InputDecoration(labelText: 'Driver email or phone', border: OutlineInputBorder())),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Driver invitation sent'); }, child: const Text('Send Invite')),
                ],
              ),
            );
          }),
          const SizedBox(width: 10),
          _quickAction(context, 'Export Report', Icons.download_outlined, AppColors.success, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Export Report'),
                content: const Text('Choose a report to export. The file will be generated in CSV format and downloaded to your device.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Orders report exported'); }, child: const Text('Orders')),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Revenue report exported'); }, child: const Text('Revenue')),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Drivers report exported'); }, child: const Text('Drivers')),
                ],
              ),
            );
          }),
          const SizedBox(width: 10),
          _quickAction(context, 'Assist', Icons.auto_awesome_outlined, AppColors.warning, () => AdminHelper.show(context)),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: cardDecoBordered(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}
