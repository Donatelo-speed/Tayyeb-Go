import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverEditProfileScreen extends StatefulWidget {
  const DriverEditProfileScreen({super.key});

  @override
  State<DriverEditProfileScreen> createState() => _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState extends State<DriverEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _vehiclePlateCtrl;

  VehicleType _selectedVehicleType = VehicleType.motorcycle;
  bool _saving = false;
  bool _uploadingPhoto = false;

  static const _vehicleTypes = [
    VehicleType.motorcycle,
    VehicleType.car,
    VehicleType.bicycle,
    VehicleType.van,
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _displayNameCtrl = TextEditingController(text: user?.displayName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _vehiclePlateCtrl = TextEditingController();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('drivers').doc(user.id).get();
    if (doc.exists && mounted) {
      final data = doc.data();
      setState(() {
        _selectedVehicleType = VehicleType.fromString(data?['vehicleType'] as String?);
        _vehiclePlateCtrl.text = data?['vehiclePlate'] as String? ?? '';
      });
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _vehiclePlateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await auth.pickAndUploadProfileImage();
      if (url != null) {
        await auth.updateProfile(photoUrl: url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile photo updated', style: GoogleFonts.inter()),
              backgroundColor: context.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo', style: GoogleFonts.inter()),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      if (mounted) setState(() => _uploadingPhoto = false);
    } catch (e) {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    try {
      // Update basic profile fields via AuthProvider
      await auth.updateProfile(
        displayName: _displayNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      // Update driver-specific fields in drivers collection
      await FirebaseFirestore.instance.collection('drivers').doc(user.id).set({
        'vehicleType': _selectedVehicleType.firestoreValue,
        'vehiclePlate': _vehiclePlateCtrl.text.trim(),
        'name': _displayNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (user.photoUrl != null) 'photoUrl': user.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully', style: GoogleFonts.inter()),
          backgroundColor: context.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (context.mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile', style: GoogleFonts.inter()),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initial = (user?.displayName.isNotEmpty == true)
        ? user!.displayName[0].toUpperCase()
        : 'D';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 16),
            _buildAvatarSection(initial, user),
            const SizedBox(height: 32),
            Text('Personal Information', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMutedColor, letterSpacing: 0.3)),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _displayNameCtrl,
              label: 'Display Name',
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Phone',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 28),
            Text('Vehicle Details', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMutedColor, letterSpacing: 0.3)),
            const SizedBox(height: 12),
            _buildVehicleTypeDropdown(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _vehiclePlateCtrl,
              label: 'Vehicle Plate Number',
              icon: Icons.badge_outlined,
              capitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.successColor,
                  foregroundColor: context.backgroundColor,
                  disabledBackgroundColor: context.successColor.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: context.backgroundColor),
                      )
                    : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String initial, UserModel? user) {
    return Center(
      child: GestureDetector(
        onTap: _uploadingPhoto ? null : _pickImage,
        child: Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.successColor.withValues(alpha: 0.15),
              ),
              child: user?.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoUrl!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(initial, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 36, color: context.successColor)),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: context.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.backgroundColor, width: 2.5),
                ),
                child: _uploadingPhoto
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: context.backgroundColor))
                    : Icon(Icons.camera_alt_rounded, size: 14, color: context.backgroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor),
          prefixIcon: Icon(icon, size: 20, color: context.textMutedColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: GoogleFonts.inter(fontSize: 12, color: context.errorColor),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<VehicleType>(
          value: _selectedVehicleType,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.textMutedColor, size: 22),
          dropdownColor: context.surfaceColor,
          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
          decoration: InputDecoration(
            labelText: 'Vehicle Type',
            labelStyle: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor),
            prefixIcon: Icon(Icons.directions_car_outlined, size: 20, color: context.textMutedColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          items: _vehicleTypes.map((type) {
            return DropdownMenuItem<VehicleType>(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedVehicleType = value);
          },
        ),
      ),
    );
  }
}
