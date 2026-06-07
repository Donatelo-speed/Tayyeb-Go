import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../services/auth_listenable.dart';

enum _AuthMode { login, signUp, phone }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;
  bool _agreeToTerms = false;
  String? _avatarUrl;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _triggerRedirect() {
    AuthListenable.instance?.forceNotify();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mode == _AuthMode.signUp && !_agreeToTerms) {
      _showSnack('Please accept the terms and conditions', AppColors.warning);
      return;
    }
    final auth = context.read<AuthProvider>();
    if (_mode == _AuthMode.login) {
      await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text, context);
      if (mounted) _triggerRedirect();
    } else if (_mode == _AuthMode.signUp) {
      final success = await auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        photoUrl: _avatarUrl,
        address: _addressCtrl.text.trim(),
      );
      if (mounted && success) _triggerRedirect();
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter a phone number', AppColors.warning);
      return;
    }
    final success = await context.read<AuthProvider>().verifyPhoneNumber(phone);
    if (mounted && success) setState(() => _otpSent = true);
  }

  Future<void> _verifyOtp(String code) async {
    final auth = context.read<AuthProvider>();
    await auth.verifyOtpCode(code);
    if (mounted) _triggerRedirect();
  }

  Future<void> _pickProfileImage() async {
    final url = await context.read<AuthProvider>().pickAndUploadProfileImage();
    if (url != null && mounted) setState(() => _avatarUrl = url);
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    await auth.loginWithGoogle();
    if (mounted) _triggerRedirect();
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Signed in as ${auth.user?.email ?? ''}'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F6F3), Color(0xFFF0EBE6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildCard(auth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final subtitle = _mode == _AuthMode.login
        ? 'Welcome back'
        : _mode == _AuthMode.signUp
            ? 'Create your account'
            : 'Verify your phone';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'TayyebGo',
          style: AppTypography.hero.copyWith(
            color: AppColors.textPrimary,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeToggle(),
            const SizedBox(height: 24),
            if (_mode == _AuthMode.login) _buildLoginFields(auth),
            if (_mode == _AuthMode.signUp) _buildSignUpFields(auth),
            if (_mode == _AuthMode.phone) _buildPhoneFields(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildTab('Login', _AuthMode.login),
          _buildTab('Sign Up', _AuthMode.signUp),
          _buildTab('Phone', _AuthMode.phone),
        ],
      ),
    );
  }

  Widget _buildTab(String label, _AuthMode mode) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _mode = mode;
          _otpSent = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFields(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildField(
          controller: _emailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          hint: 'e.g. customer@test.com',
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildField(
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
            if (v == null || v.isEmpty) return 'Enter your password';
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final email = _emailCtrl.text.trim();
              if (email.isEmpty) {
                _showSnack('Enter your email first', AppColors.warning);
                return;
              }
              await auth.resetPassword(email);
              if (mounted && auth.error == null) {
                _showSnack('Password reset email sent', AppColors.success);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot Password?',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Sign In'),
          ),
        ),
        const SizedBox(height: 20),
        _buildDivider(),
        const SizedBox(height: 20),
        _buildGoogleButton(auth),
        if (auth.error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(auth.error!),
        ],
      ],
    );
  }

  Widget _buildSignUpFields(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatarPicker(),
        const SizedBox(height: 24),
        _buildField(
          controller: _nameCtrl,
          label: 'Full Name',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your full name';
            if (v.trim().split(' ').length < 2) return 'Enter first and last name';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _emailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _phoneCtrl,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          hint: '+1 555 123 4567',
        ),
        const SizedBox(height: 16),
        _buildField(
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
            if (v == null || v.isEmpty) return 'Create a password';
            if (v.length < 6) return 'At least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _confirmCtrl,
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
            if (v != _passwordCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _addressCtrl,
          label: 'Delivery Address',
          icon: Icons.location_on_outlined,
          hint: 'Street, city, building',
        ),
        const SizedBox(height: 16),
        _buildTermsCheckbox(),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Create Account'),
          ),
        ),
        const SizedBox(height: 20),
        _buildDivider(),
        const SizedBox(height: 20),
        _buildGoogleButton(auth),
        if (auth.error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(auth.error!),
        ],
      ],
    );
  }

  Widget _buildPhoneFields(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.phone_android_rounded, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          _otpSent ? 'Enter the code sent to your phone' : 'Verify with your phone',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (!_otpSent) ...[
          _buildField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: '+1 555 123 4567',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Send Verification Code'),
            ),
          ),
        ] else ...[
          _buildOtpField(),
          const SizedBox(height: 12),
          if (auth.otpCountdown > 0)
            Text(
              'Resend in ${auth.otpCountdownText}',
              style: AppTypography.caption,
            )
          else
            TextButton(
              onPressed: _sendOtp,
              child: Text(
                'Resend Code',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        if (auth.error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(auth.error!),
        ],
      ],
    );
  }

  Widget _buildOtpField() {
    return TextFormField(
      maxLength: 6,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        counterText: '',
        hintText: '------',
        hintStyle: TextStyle(color: AppColors.divider, fontSize: 28, letterSpacing: 12),
        filled: true,
        fillColor: const Color(0xFFF8F6F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      onChanged: (v) {
        if (v.length == 6) _verifyOtp(v);
      },
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F6F3),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 32, color: AppColors.textMuted),
                      ),
                    )
                  : const Icon(Icons.camera_alt_outlined, size: 28, color: AppColors.textMuted),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.small,
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: AppTypography.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppTypography.caption,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F6F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        labelStyle: AppTypography.label,
        floatingLabelStyle: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider.withValues(alpha: 0.5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with', style: AppTypography.small),
        ),
        Expanded(child: Divider(color: AppColors.divider.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildGoogleButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: auth.isLoading ? null : _handleGoogleSignIn,
        icon: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)],
              stops: [0.0, 0.33, 0.66, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text('G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        label: Text(
          auth.isLoading ? 'Signing in...' : 'Continue with Google',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
