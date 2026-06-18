import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/theme_provider.dart';
import '../../ui/cached_image.dart';
import '../../presentation/theme/app_radius.dart';

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
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    setState(() => _uploadingPhoto = true);
    final url = await context.read<UserProfileProvider>().pickAndUploadProfileImage(userId);
    if (url != null) {
      await auth.updateProfile(photoUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile photo updated', style: GoogleFonts.inter()), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo', style: GoogleFonts.inter()), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
      );
    }
    if (mounted) setState(() => _uploadingPhoto = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    await context.read<UserProfileProvider>().updateProfile(
      userId: user.id,
      displayName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _edited = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated', style: GoogleFonts.inter()), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600)), backgroundColor: context.backgroundColor, elevation: 0, surfaceTintColor: Colors.transparent),
        body: Center(child: Text('Please log in', style: GoogleFonts.inter(color: context.textMutedColor))),
      );
    }
    final isAdmin = auth.isSuperAdmin;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_edited)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : Text('Save', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          _buildAvatarSection(user, isAdmin),
          const SizedBox(height: 28),
          if (isAdmin) ...[
            _buildAdminCard(),
            const SizedBox(height: 20),
          ],
          _buildSection('Personal Information'),
          const SizedBox(height: 12),
          _buildField('Display Name', Icons.person_outline_rounded, _nameCtrl, TextCapitalization.words),
          const SizedBox(height: 12),
          _buildField('Phone', Icons.phone_rounded, _phoneCtrl, null, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildField('Default Address', Icons.location_on_outlined, _addressCtrl, TextCapitalization.sentences, maxLines: 2),
          const SizedBox(height: 28),
          _buildSection('Account'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.mail_outline_rounded, 'Email', user.email),
          _buildInfoRow(Icons.badge_outlined, 'Role', user.role.displayName, valueColor: isAdmin ? AppColors.primary : null),
          if (user.createdAt != null)
            _buildInfoRow(Icons.calendar_today_outlined, 'Member Since', '${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}-${user.createdAt!.day.toString().padLeft(2, '0')}'),
          const SizedBox(height: 28),
          _buildSection('Settings'),
          const SizedBox(height: 12),
          _buildSettingsRow(Icons.notifications_outlined, 'Notifications'),
          _buildSettingsRow(Icons.language_rounded, 'Language'),
          _buildSettingsRow(Icons.help_outline_rounded, 'Help & Support'),
          _buildSettingsRow(Icons.info_outline_rounded, 'About'),
          _buildSettingsRow(Icons.star_rounded, 'TayyebGo Plus', isSubscription: true),
          const SizedBox(height: 20),
          _buildLogoutButton(),
          const SizedBox(height: 32),
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
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isAdmin ? const LinearGradient(colors: [AppColors.primary, Color(0xFF818CF8)]) : null,
              ),
              padding: isAdmin ? const EdgeInsets.all(3) : null,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.surfaceColor,
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: user.photoUrl != null
                      ? CachedImage(
                          imageUrl: user.photoUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            (user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
                            style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: context.textPrimaryColor),
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.backgroundColor, width: 2.5),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)],
                ),
                child: _uploadingPhoto
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Access', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Text('Full platform management', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: AppRadius.brXl,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Active', style: GoogleFonts.inter(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMutedColor, letterSpacing: 0.3),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController ctrl, TextCapitalization? cap, {TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: cap ?? TextCapitalization.none,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor),
          prefixIcon: Icon(icon, size: 20, color: context.textMutedColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(bottom: BorderSide(color: context.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.textMutedColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: context.textMutedColor))),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? context.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(IconData icon, String label, {bool isSubscription = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSubscription
            ? AppColors.premium.withValues(alpha: 0.06)
            : context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: isSubscription
            ? Border.all(color: AppColors.premium.withValues(alpha: 0.15), width: 0.5)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSubscription ? AppColors.premium : context.textMutedColor,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSubscription ? FontWeight.w600 : FontWeight.w400,
            color: isSubscription ? AppColors.premium : context.textPrimaryColor,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: context.textMutedColor),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        onTap: () {
          if (isSubscription) {
            context.push('/subscription');
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () async {
          await context.read<AuthProvider>().logout();
          if (context.mounted) context.go('/login');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
        child: Text('Sign Out', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
