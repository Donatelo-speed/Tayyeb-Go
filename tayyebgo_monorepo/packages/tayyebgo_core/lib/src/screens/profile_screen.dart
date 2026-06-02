import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/auth_provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_gradients.dart';
import '../../presentation/shared_widgets/ui_feedback.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;
  bool _edited = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.displayName;
      _phoneCtrl.text = user.phone ?? '';
      _addressCtrl.text = user.address ?? '';
    }
    _nameCtrl.addListener(_onEdit);
    _phoneCtrl.addListener(_onEdit);
    _addressCtrl.addListener(_onEdit);
  }

  void _onEdit() {
    if (!_edited) setState(() => _edited = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pics/$userId.jpg');
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(picked.path));
      }
      final url = await ref.getDownloadURL();
      await auth.updateProfile(photoUrl: url);
      if (mounted) {
        context.showSuccess('Profile photo updated');
      }
    } catch (_) {
      if (mounted) {
        context.showError('Failed to upload photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            displayName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _edited = false);
      context.showSuccess('Profile updated');
    } catch (_) {
      if (mounted) context.showError('Failed to save profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view your profile')),
      );
    }
    final isAdmin = auth.isSuperAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_edited)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAvatarSection(user, isAdmin),
          const SizedBox(height: 24),
          if (isAdmin) ...[
            _buildAdminActivityCard(user),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('Personal Information'),
          const SizedBox(height: 12),
          _buildField('Display Name', Icons.person_outline, _nameCtrl, TextCapitalization.words),
          const SizedBox(height: 14),
          _buildField('Phone', Icons.phone_outlined, _phoneCtrl, null, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _buildField('Default Address', Icons.location_on_outlined, _addressCtrl, TextCapitalization.sentences, maxLines: 2),
          const SizedBox(height: 24),
          _buildSectionHeader('Account Info'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, 'Email', user.email),
          const Divider(height: 1, indent: 16),
          _buildInfoRow(Icons.badge_outlined, 'Role', user.role.displayName,
              valueColor: isAdmin ? AppColors.primary : null,
              trailing: isAdmin
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryToAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                      ),
                    )
                  : null),
          if (user.createdAt != null) ...[
            const Divider(height: 1, indent: 16),
            _buildInfoRow(Icons.calendar_today_outlined, 'Member Since',
                '${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}-${user.createdAt!.day.toString().padLeft(2, '0')}'),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_edited && !_saving) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                elevation: 0,
              ),
              child: Text(_edited ? 'Save Changes' : 'No Changes'),
            ),
          ),
          if (_edited)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'You have unsaved changes',
                  style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(user, bool isAdmin) {
    return Center(
      child: GestureDetector(
        onTap: _uploadingPhoto ? null : _pickImage,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isAdmin
                    ? Border.all(color: AppColors.accent, width: 2.5)
                    : null,
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!) as ImageProvider
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        (user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _uploadingPhoto ? AppColors.textMuted : AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: _uploadingPhoto
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActivityCard(user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Access', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  'Full platform management privileges',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Active', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController ctrl, TextCapitalization? cap, {TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: cap ?? TextCapitalization.none,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          if (trailing != null)
            trailing
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
