import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          _quickAction(context, 'New Store', Icons.add_business_outlined, context.primaryColor, () => showDialog(context: context, builder: (_) => const wizard.CreateBusinessWizard())),
          const SizedBox(width: 10),
          _quickAction(context, 'Invite Driver', Icons.person_add_outlined, context.primaryColor, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: context.surfaceColor,
                title: Text('Invite Driver', style: GoogleFonts.inter(color: context.textPrimaryColor)),
                content: SizedBox(
                  width: 320,
                  child: TextField(
                    style: GoogleFonts.inter(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Driver email or phone',
                      labelStyle: GoogleFonts.inter(color: context.textMutedColor),
                      border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.primaryColor)),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
                  ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Driver invitation sent'); },
                    style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: context.textPrimaryColor),
                    child: Text('Send Invite', style: GoogleFonts.inter()),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(width: 10),
          _quickAction(context, 'Export Report', Icons.download_outlined, context.successColor, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: context.surfaceColor,
                title: Text('Export Report', style: GoogleFonts.inter(color: context.textPrimaryColor)),
                content: Text('Choose a report to export. The file will be generated in CSV format and downloaded to your device.', style: GoogleFonts.inter(color: context.textMutedColor)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Orders report exported'); }, child: Text('Orders', style: GoogleFonts.inter(color: context.primaryColor))),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Revenue report exported'); }, child: Text('Revenue', style: GoogleFonts.inter(color: context.primaryColor))),
                  TextButton(onPressed: () { Navigator.pop(ctx); ctx.showSuccess('Drivers report exported'); }, child: Text('Drivers', style: GoogleFonts.inter(color: context.primaryColor))),
                ],
              ),
            );
          }),
          const SizedBox(width: 10),
          _quickAction(context, 'Assist', Icons.auto_awesome_outlined, context.warningColor, () => AdminHelper.show(context)),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: cardDecoBordered(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: AppRadius.brMd),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}
