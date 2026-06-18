import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:url_launcher/url_launcher.dart';

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
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 10),
          _SafetyCard(
            icon: Icons.phone_rounded,
            iconColor: context.successColor,
            title: 'Emergency Contact',
            subtitle: 'Call TayyebGo support',
            onTap: () async {
              final uri = Uri.parse('tel:+963982118585');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch phone dialer')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.brLg,
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
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
            onPressed: () async {
              Navigator.pop(context);
              final user = AuthProvider.instance?.user;
              if (user == null) return;
              try {
                await FirebaseFirestore.instance.collection('sos_alerts').add({
                  'driverId': user.id,
                  'driverName': user.displayName,
                  'driverPhone': user.phone,
                  'type': 'sos',
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('SOS alert sent to support', style: GoogleFonts.inter()),
                      backgroundColor: context.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send SOS: $e')),
                  );
                }
              }
            },
            child: Text('Send SOS', style: GoogleFonts.inter(color: context.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    String selectedType = 'general';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
          title: Text('Report Issue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _reportChip('general', 'General', Icons.flag_rounded, selectedType, setDialogState),
                  _reportChip('harassment', 'Harassment', Icons.person_off_rounded, selectedType, setDialogState),
                  _reportChip('unsafe_area', 'Unsafe Area', Icons.warning_amber_rounded, selectedType, setDialogState),
                  _reportChip('accident', 'Accident', Icons.car_crash_rounded, selectedType, setDialogState),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe the issue...',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.primaryColor)),
                  filled: true,
                  fillColor: context.backgroundColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (ctrl.text.trim().isEmpty) return;
                final user = AuthProvider.instance?.user;
                if (user == null) return;
                try {
                  await FirebaseFirestore.instance.collection('driver_reports').add({
                    'driverId': user.id,
                    'driverName': user.displayName,
                    'type': selectedType,
                    'description': ctrl.text.trim(),
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report submitted', style: GoogleFonts.inter()),
                        backgroundColor: context.successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit report: $e')),
                    );
                  }
                }
              },
              child: Text('Submit', style: GoogleFonts.inter(color: context.primaryColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportChip(String value, String label, IconData icon, String selectedType, StateSetter setDialogState) {
    return GestureDetector(
      onTap: () => setDialogState(() => selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedType == value ? AppColors.driverAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: AppRadius.brXl,
          border: Border.all(
            color: selectedType == value ? AppColors.driverAccent : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selectedType == value ? AppColors.driverAccent : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(
              fontSize: 12,
              color: selectedType == value ? AppColors.driverAccent : Colors.grey,
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
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
          borderRadius: AppRadius.brLg,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.brMd,
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
