import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverSafetyScreen extends StatelessWidget {
  const DriverSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Safety Hub', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SafetyCard(
            icon: Icons.emergency_rounded,
            iconColor: context.errorColor,
            title: 'SOS Emergency',
            subtitle: 'Alert support team immediately',
            onTap: () => _showSosDialog(context),
          ),
          const SizedBox(height: 10),
          _SafetyCard(
            icon: Icons.report_problem_rounded,
            iconColor: context.warningColor,
            title: 'Report an Issue',
            subtitle: 'Harassment, unsafe area, accident',
            onTap: () => _showReportDialog(context),
          ),
          const SizedBox(height: 10),
          _SafetyCard(
            icon: Icons.verified_user_rounded,
            iconColor: context.primaryColor,
            title: 'Identity Verification',
            subtitle: 'Verify your identity for safety',
            onTap: () => context.go('/profile'),
          ),
          const SizedBox(height: 10),
          _SafetyCard(
            icon: Icons.phone_rounded,
            iconColor: context.successColor,
            title: 'Emergency Contact',
            subtitle: 'Call support: 0XX-XXX-XXX',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety Tips', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
                const SizedBox(height: 12),
                _tip(context, 'Always verify customer identity before handoff'),
                _tip(context, 'Keep your phone charged during deliveries'),
                _tip(context, 'Share your live location with emergency contact'),
                _tip(context, 'Trust your instincts — avoid unsafe areas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: context.successColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13))),
        ],
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('SOS Emergency', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.errorColor)),
        content: Text(
          'Your location and details will be sent to our support team immediately. Do you want to proceed?',
          style: GoogleFonts.inter(color: context.textMutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('SOS alert sent to support', style: GoogleFonts.inter()),
                  backgroundColor: context.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text('Send SOS', style: GoogleFonts.inter(color: context.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Report Issue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            hintStyle: GoogleFonts.inter(color: context.textMutedColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.primaryColor)),
            filled: true,
            fillColor: context.backgroundColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report submitted', style: GoogleFonts.inter()),
                    backgroundColor: context.successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: Text('Submit', style: GoogleFonts.inter(color: context.primaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SafetyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}
