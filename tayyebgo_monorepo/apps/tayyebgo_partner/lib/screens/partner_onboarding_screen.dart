import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerOnboardingScreen extends StatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  State<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends State<PartnerOnboardingScreen> {
  int _step = 0;
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _businessType = 'Restaurant';
  String _role = 'Owner';
  bool _selfDelivery = true;
  bool _platformDrivers = true;
  bool _pickupOnly = false;
  bool _isSaving = false;

  final _picker = ImagePicker();
  final Map<String, String> _uploadedDocUrls = {};
  final Map<String, bool> _uploadingDocs = {};
  final Map<String, double> _uploadProgress = {};

  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
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
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'businessName': _businessNameCtrl.text.trim(),
        'displayName': _ownerNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'storeAddress': _addressCtrl.text.trim(),
        'businessType': _businessType,
        'role': _role.toLowerCase() == 'owner' ? 'restaurantOwner' : _role.toLowerCase(),
        'selfDelivery': _selfDelivery,
        'platformDrivers': _platformDrivers,
        'pickupOnly': _pickupOnly,
        'onboardingCompleted': true,
        'documents': _uploadedDocUrls,
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

  Future<void> _uploadDoc(String docType, String storageName, String firestoreField) async {
    if (_uploadedDocUrls.containsKey(firestoreField)) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _uploadingDocs[firestoreField] = true;
        _uploadProgress[firestoreField] = 0;
      });
      final ref = FirebaseStorage.instance.ref().child('partners/$_uid/$storageName');
      final uploadTask = ref.putFile(File(picked.path));
      uploadTask.snapshotEvents.listen((event) {
        if (mounted) setState(() => _uploadProgress[firestoreField] = event.bytesTransferred / event.totalBytes);
      });
      await uploadTask;
      final url = await ref.getDownloadURL();
      if (mounted) {
        setState(() {
          _uploadedDocUrls[firestoreField] = url;
          _uploadingDocs[firestoreField] = false;
        });
      }
    } catch (e) {
      setState(() => _uploadingDocs[firestoreField] = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload $docType: $e'), backgroundColor: Colors.red));
    }
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
                      color: i <= _step ? context.warningColor : context.surfaceAltColor,
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
                        backgroundColor: context.warningColor,
                        foregroundColor: context.backgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_step == 5 ? 'Go to Dashboard' : 'Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
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
          Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: context.warningColor.withValues(alpha: 0.1), borderRadius: AppRadius.brXl), child: Icon(Icons.store_rounded, color: context.warningColor, size: 40))),
          const SizedBox(height: 24),
          Center(child: Text('Partner Setup', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor))),
          const SizedBox(height: 8),
          Center(child: Text('Set up your business profile to start receiving orders.', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14), textAlign: TextAlign.center)),
        ];
      case 1:
        return [
          Text('Business Information', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Tell us about your business', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _darkField(context: context, controller: _businessNameCtrl, label: 'Business Name', icon: Icons.store_rounded),
          const SizedBox(height: 16),
          _darkField(context: context, controller: _ownerNameCtrl, label: 'Owner Name', icon: Icons.person_rounded),
          const SizedBox(height: 16),
          _darkField(context: context, controller: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _darkField(context: context, controller: _emailCtrl, label: 'Email', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
        ];
      case 2:
        return [
          Text('Business Type', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('What kind of business do you run?', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _typeOption(context, Icons.restaurant_rounded, 'Restaurant', 'Food & beverages'),
          const SizedBox(height: 12),
          _typeOption(context, Icons.local_grocery_store_rounded, 'Grocery', 'Everyday essentials'),
          const SizedBox(height: 12),
          _typeOption(context, Icons.local_pharmacy_rounded, 'Pharmacy', 'Medicine & health'),
          const SizedBox(height: 12),
          _typeOption(context, Icons.shopping_bag_rounded, 'Other', 'General store'),
        ];
      case 3:
        return [
          Text('Your Role', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Select your role in the business', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _roleOption(context, Icons.admin_panel_settings_rounded, 'Owner', 'Full control over store settings, menus, and finances'),
          const SizedBox(height: 12),
          _roleOption(context, Icons.point_of_sale_rounded, 'Cashier', 'Process orders, manage payouts, and handle walk-ins'),
          const SizedBox(height: 12),
          _roleOption(context, Icons.kitchen_rounded, 'Kitchen Staff', 'View orders, mark prep status, manage food ready'),
        ];
      case 4:
        return [
          Text('Business Verification', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Upload required documents', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _docUpload(context, 'Trade License', Icons.description_rounded, 'tradeLicense'),
          const SizedBox(height: 12),
          _docUpload(context, 'Tax Registration', Icons.receipt_rounded, 'taxRegistration'),
          const SizedBox(height: 12),
          _docUpload(context, 'Food Safety Certificate', Icons.health_and_safety_rounded, 'foodSafetyCert'),
          const SizedBox(height: 12),
          _docUpload(context, 'Store Photos', Icons.camera_alt_rounded, 'storePhotos'),
        ];
      case 5:
        return [
          Text('Location & Delivery', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Set your store location and delivery options', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _darkField(context: context, controller: _addressCtrl, label: 'Store Address', icon: Icons.location_on_rounded),
          const SizedBox(height: 16),
          _toggleOption(context, 'Self Delivery', 'Use your own drivers', _selfDelivery, (v) => setState(() => _selfDelivery = v)),
          const SizedBox(height: 12),
          _toggleOption(context, 'Platform Drivers', 'Use TayyebGo drivers', _platformDrivers, (v) => setState(() => _platformDrivers = v)),
          const SizedBox(height: 12),
          _toggleOption(context, 'Pickup Only', 'Customers pick up orders', _pickupOnly, (v) => setState(() => _pickupOnly = v)),
        ];
      default:
        return [];
    }
  }

  Widget _darkField({required BuildContext context, required TextEditingController controller, required String label, IconData? icon, TextInputType? keyboardType}) {
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
            focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.warningColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _typeOption(BuildContext context, IconData icon, String label, String subtitle) {
    final selected = _businessType == label;
    return GestureDetector(
      onTap: () => setState(() => _businessType = label),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: selected ? context.warningColor : context.borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? context.warningColor : context.textMutedColor, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
                  Text(subtitle, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: context.warningColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(BuildContext context, IconData icon, String label, String description) {
    final selected = _role == label;
    return GestureDetector(
      onTap: () => setState(() => _role = label),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: selected ? context.warningColor : context.borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? context.warningColor : context.textMutedColor, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
                  Text(description, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: context.warningColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _docUpload(BuildContext context, String label, IconData icon, String firestoreField) {
    final uploaded = _uploadedDocUrls.containsKey(firestoreField);
    final uploading = _uploadingDocs[firestoreField] == true;
    final progress = _uploadProgress[firestoreField] ?? 0;
    return GestureDetector(
      onTap: uploaded || uploading ? null : () => _uploadDoc(label, '${firestoreField}.jpg', firestoreField),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: uploaded ? context.warningColor : context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: uploaded ? context.warningColor : context.textMutedColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                      Text(uploaded ? 'Uploaded' : uploading ? 'Uploading...' : 'Tap to upload', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                    ],
                  ),
                ),
                if (uploaded)
                  Icon(Icons.check_circle_rounded, color: context.warningColor, size: 22)
                else if (uploading)
                  SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, value: progress, color: context.warningColor))
                else
                  Icon(Icons.upload_rounded, color: context.textMutedColor, size: 22),
              ],
            ),
            if (uploading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AppRadius.brSm,
                child: LinearProgressIndicator(value: progress, backgroundColor: context.borderColor, valueColor: AlwaysStoppedAnimation<Color>(context.warningColor), minHeight: 4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggleOption(BuildContext context, String title, String subtitle, bool enabled, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                Text(subtitle, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeColor: context.warningColor,
            activeTrackColor: context.warningColor.withValues(alpha: 0.3),
            inactiveThumbColor: context.textMutedColor,
            inactiveTrackColor: context.borderColor,
          ),
        ],
      ),
    );
  }
}
