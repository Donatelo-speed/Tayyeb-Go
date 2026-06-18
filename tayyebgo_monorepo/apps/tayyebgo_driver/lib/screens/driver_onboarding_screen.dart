import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  String _vehicleType = 'Motorcycle';
  String _zone = 'Al-Waer';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 5) {
      setState(() => _step++);
    } else {
      _saveAndContinue();
    }
  }

  Future<void> _saveAndContinue() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name and phone number.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'vehicleType': _vehicleType,
        'zone': _zone,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _back,
                      icon: Icon(Icons.arrow_back_ios_rounded, color: context.textMutedColor, size: 20),
                    ),
                  const Spacer(),
                  Text('Step ${_step + 1} of 6', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(6, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _step ? context.successColor : context.borderColor,
                      borderRadius: AppRadius.brSm,
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ..._buildStepContent(context),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.successColor,
                        foregroundColor: context.textPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                        elevation: 0,
                      ),
                      child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_step == 5 ? 'Get Started' : 'Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return [
          const SizedBox(height: 40),
          Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: context.successColor.withValues(alpha: 0.1), borderRadius: AppRadius.brXl), child: Icon(Icons.person_add_rounded, color: context.successColor, size: 40))),
          const SizedBox(height: 24),
          Center(child: Text('Welcome, Driver!', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor))),
          const SizedBox(height: 8),
          Center(child: Text('Let\'s set up your account in a few quick steps.', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14), textAlign: TextAlign.center)),
        ];
      case 1:
        return [
          Text('Personal Information', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Tell us about yourself', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _darkField(context, controller: _nameCtrl, label: 'Full Name', icon: Icons.person_rounded),
          const SizedBox(height: 16),
          _darkField(context, controller: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _darkField(context, controller: _emailCtrl, label: 'Email (optional)', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
        ];
      case 2:
        return [
          Text('Vehicle Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('What do you deliver with?', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _vehicleOption(context, Icons.two_wheeler_rounded, 'Motorcycle'),
          const SizedBox(height: 12),
          _vehicleOption(context, Icons.directions_car_rounded, 'Car'),
          const SizedBox(height: 12),
          _vehicleOption(context, Icons.pedal_bike_rounded, 'Bicycle'),
          const SizedBox(height: 12),
          _vehicleOption(context, Icons.local_shipping_rounded, 'Van/Truck'),
        ];
      case 3:
        return [
          Text('Documents', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Upload required documents', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _docUpload(context, 'Driving License', Icons.badge_rounded, true),
          const SizedBox(height: 12),
          _docUpload(context, 'Vehicle Registration', Icons.description_rounded, false),
          const SizedBox(height: 12),
          _docUpload(context, 'Insurance', Icons.security_rounded, false),
          const SizedBox(height: 12),
          _docUpload(context, 'Profile Photo', Icons.camera_alt_rounded, true),
        ];
      case 4:
        return [
          Text('Your Zone', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Select your primary delivery zone', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _zoneOption(context, 'Al-Waer', '120 SYP fee'),
          const SizedBox(height: 12),
          _zoneOption(context, 'Bab Amr', '100 SYP fee'),
          const SizedBox(height: 12),
          _zoneOption(context, 'New City', '150 SYP fee'),
          const SizedBox(height: 12),
          _zoneOption(context, 'Al-Hamidiyah', '80 SYP fee'),
        ];
      case 5:
        return [
          const SizedBox(height: 40),
          Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: context.successColor.withValues(alpha: 0.1), borderRadius: AppRadius.brXl), child: Icon(Icons.check_circle_rounded, color: context.successColor, size: 40))),
          const SizedBox(height: 24),
          Center(child: Text('You\'re All Set!', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor))),
          const SizedBox(height: 8),
          Center(child: Text('Start accepting deliveries and earning money.', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14), textAlign: TextAlign.center)),
        ];
      default:
        return [];
    }
  }

  Widget _darkField(BuildContext context, {required TextEditingController controller, required String label, IconData? icon, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: context.textPrimaryColor),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: context.textMutedColor, size: 20) : null,
            filled: true,
            fillColor: context.surfaceColor,
            border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.successColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _vehicleOption(BuildContext context, IconData icon, String label) {
    final selected = _vehicleType == label;
    return GestureDetector(
      onTap: () => setState(() => _vehicleType = label),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: selected ? context.successColor : context.borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? context.successColor : context.textMutedColor, size: 28),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
            const Spacer(),
            if (selected) Icon(Icons.check_circle_rounded, color: context.successColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _docUpload(BuildContext context, String label, IconData icon, bool uploaded) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: uploaded ? context.successColor : context.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: uploaded ? context.successColor : context.textMutedColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                Text(uploaded ? 'Uploaded' : 'Tap to upload', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Icon(uploaded ? Icons.check_circle_rounded : Icons.upload_rounded, color: uploaded ? context.successColor : context.textMutedColor, size: 22),
        ],
      ),
    );
  }

  Widget _zoneOption(BuildContext context, String name, String fee) {
    final selected = _zone == name;
    return GestureDetector(
      onTap: () => setState(() => _zone = name),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: selected ? context.successColor : context.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: selected ? context.successColor : context.textMutedColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                  Text(fee, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: context.successColor, size: 22),
          ],
        ),
      ),
    );
  }
}
