import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_typography.dart';
import '../../presentation/shared_widgets/brand_logo.dart';
import '../providers/auth_provider.dart';
import '../services/auth_listenable.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _triggerRedirect() {
    AuthListenable.instance?.forceNotify();
  }

  Future<void> _submitSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnack('Please agree to the Terms & Conditions', AppColors.warning);
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
    );
    if (mounted && success) {
      _triggerRedirect();
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final auth = context.read<AuthProvider>();
    await auth.loginWithGoogle();
    if (!mounted) return;
    final user = auth.user;
    if (user != null && (user.phone == null || user.phone!.isEmpty)) {
      _showPhoneCollectionDialog();
    } else if (user != null) {
      _triggerRedirect();
    }
  }

  Future<void> _handleAppleSignUp() async {
    final auth = context.read<AuthProvider>();
    await auth.loginWithApple();
    if (!mounted) return;
    final user = auth.user;
    if (user != null && (user.phone == null || user.phone!.isEmpty)) {
      _showPhoneCollectionDialog();
    } else if (user != null) {
      _triggerRedirect();
    }
  }

  void _showPhoneCollectionDialog() {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        title: Text(
          'Add Your Phone Number',
          style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We need your phone number for deliveries and order updates.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+963 9XX XXX XXX',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brInput,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brInput,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brInput,
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _triggerRedirect();
            },
            child: Text('Skip', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (phoneCtrl.text.trim().isEmpty) return;
              final auth = context.read<AuthProvider>();
              await auth.updateProfile(phone: phoneCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) _triggerRedirect();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
            ),
            child: Text('Save', style: AppTypography.button.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Account created successfully!',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF0F1713), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 36),
                      _buildNameField(),
                      const SizedBox(height: 14),
                      _buildPhoneField(),
                      const SizedBox(height: 14),
                      _buildEmailField(),
                      const SizedBox(height: 14),
                      _buildPasswordField(),
                      const SizedBox(height: 14),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 16),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 24),
                      _buildSignUpButton(auth),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildSocialButtons(auth),
                      const SizedBox(height: 24),
                      _buildSignInLink(),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(auth.error!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(markSize: 64, fontSize: 22),
        const SizedBox(height: 16),
        Text(
          'Create Your Account',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join TayyebGo for fast delivery and local services.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return _buildField(
      controller: _nameCtrl,
      label: 'Full Name',
      icon: Icons.person_outline_rounded,
      keyboardType: TextInputType.name,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter your name';
        if (v.trim().length < 2) return 'Name must be at least 2 characters';
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return _buildField(
      controller: _phoneCtrl,
      label: 'Phone Number',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      hint: '+963 9XX XXX XXX',
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter your phone number';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return _buildField(
      controller: _emailCtrl,
      label: 'Email Address',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter your email';
        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _buildField(
      controller: _passwordCtrl,
      label: 'Password',
      icon: Icons.lock_outlined,
      obscure: _obscurePassword,
      suffix: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter a password';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return _buildField(
      controller: _confirmPasswordCtrl,
      label: 'Confirm Password',
      icon: Icons.lock_outlined,
      obscure: _obscureConfirm,
      suffix: IconButton(
        icon: Icon(
          _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirm your password';
        if (v != _passwordCtrl.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              children: [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Open Terms & Conditions URL
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Open Privacy Policy URL
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _submitSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        ),
        child: auth.isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text('Create Account', style: AppTypography.button.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or continue with', style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          )),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildSocialButtons(AuthProvider auth) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: auth.isLoading ? null : _handleGoogleSignUp,
            icon: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: const Center(
                child: Text('G', style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
              ),
            ),
            label: Text('Continue with Google', style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: auth.isLoading ? null : _handleAppleSignUp,
            icon: const Icon(Icons.apple, color: AppColors.textPrimary, size: 22),
            label: Text('Continue with Apple', style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        )),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text('Sign In', style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          )),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brInput,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        floatingLabelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: validator,
    );
  }
}
