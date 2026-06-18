import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_typography.dart';
import '../../presentation/shared_widgets/brand_logo.dart';
import '../providers/auth_provider.dart';
import '../services/auth_listenable.dart';

enum _AuthMode { phone, email }

class LoginScreen extends StatefulWidget {
  final bool showSignUpLink;
  final String subtitle;

  const LoginScreen({
    super.key,
    this.showSignUpLink = true,
    this.subtitle = 'Fresh meals, daily errands, and local delivery.',
  });
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.phone;
  bool _obscurePassword = true;
  bool _otpSent = false;
  bool _rememberMe = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final remember = prefs.getBool('remember_me') ?? false;
    if (mounted && remember && savedEmail != null) {
      _emailCtrl.text = savedEmail;
      _rememberMe = true;
      setState(() {});
    }
  }

  Future<void> _saveRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailCtrl.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  bool _redirecting = false;

  void _triggerRedirect() {
    if (_redirecting) return;
    _redirecting = true;
    // forceNotify triggers GoRouter's redirect function which handles
    // all role-based navigation. We must NOT call context.go() here
    // because the portal's route structure (/customer/home, /admin/dashboard)
    // differs from mobile apps (/home, /dashboard), and a mismatched
    // context.go() fights the redirect and lands on a non-existent route.
    AuthListenable.instance?.forceNotify();
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
    final success = await auth.verifyOtpCode(code);
    if (mounted && success) _triggerRedirect();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      context,
    );
    if (!mounted) return;
    if (success) {
      await _saveRemembered();
      _triggerRedirect();
    } else if (auth.error != null) {
      _showSnack(auth.error!, AppColors.error);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (!mounted) return;
    if (success) {
      _triggerRedirect();
    } else if (auth.error != null) {
      _showSnack(auth.error!, AppColors.error);
    }
  }

  Future<void> _handleAppleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithApple();
    if (!mounted) return;
    if (success) {
      _triggerRedirect();
    } else if (auth.error != null) {
      _showSnack(auth.error!, AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── BUILD ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w >= 960;

    if (auth.isAuthenticated && auth.user != null) {
      _triggerRedirect();
      return _buildLoadingState(auth);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout(auth) : _buildMobileLayout(auth),
    );
  }

  Widget _buildLoadingState(AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Signing you in...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDE LAYOUT (WEB / TABLET) ───────────────────

  Widget _buildWideLayout(AuthProvider auth) {
    return Row(
      children: [
        // Left branding panel
        Expanded(flex: 5, child: _buildBrandingPanel()),
        // Right form panel
        Expanded(flex: 4, child: _buildFormPanel(auth)),
      ],
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1117), AppColors.surface],
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TayyebGoLogo(size: 64, showText: true),
                  const SizedBox(height: 48),
                  Text(
                    'Deliver anything\nfrom anywhere.',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      fontSize: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Food, groceries, pharmacy, and retail — all in one platform.\nJoin thousands of customers, drivers, and restaurants.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _FeatureRow(
                    icon: Icons.delivery_dining_rounded,
                    label: 'Real-time delivery tracking',
                    color: AppColors.driverAccent,
                  ),
                  const SizedBox(height: 14),
                  _FeatureRow(
                    icon: Icons.store_rounded,
                    label: 'Multi-vertical marketplace',
                    color: AppColors.partnerAccent,
                  ),
                  const SizedBox(height: 14),
                  _FeatureRow(
                    icon: Icons.shield_rounded,
                    label: 'Secure payments & safety',
                    color: AppColors.adminAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel(AuthProvider auth) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (auth.error != null) ...[
                      _buildErrorBanner(auth.error!),
                      const SizedBox(height: 20),
                    ],
                    if (_mode == _AuthMode.phone) _buildPhoneForm(auth),
                    if (_mode == _AuthMode.email) _buildEmailForm(auth),
                    const SizedBox(height: 24),
                    _buildModeToggle(),
                    const SizedBox(height: 28),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildSocialButtons(auth),
                    if (widget.showSignUpLink) ...[
                      const SizedBox(height: 24),
                      _buildSignUpLink(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── MOBILE LAYOUT ────────────────────────────────

  Widget _buildMobileLayout(AuthProvider auth) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandLogo(markSize: 64, fontSize: 22),
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      if (auth.error != null) ...[
                        _buildErrorBanner(auth.error!),
                        const SizedBox(height: 16),
                      ],
                      if (_mode == _AuthMode.phone) _buildPhoneForm(auth),
                      if (_mode == _AuthMode.email) _buildEmailForm(auth),
                      const SizedBox(height: 20),
                      _buildModeToggle(),
                      const SizedBox(height: 24),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildSocialButtons(auth),
                      if (widget.showSignUpLink) ...[
                        const SizedBox(height: 20),
                        _buildSignUpLink(),
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

  // ─── FORM BUILDERS ────────────────────────────────

  Widget _buildPhoneForm(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_otpSent) ...[
          Text(
            'Enter your phone number',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll send you a verification code",
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 28),
          _buildField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: '+963 9XX XXX XXX',
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton(
            label: 'Continue',
            onPressed: auth.isLoading ? null : _sendOtp,
            isLoading: auth.isLoading,
          ),
        ] else ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter the code sent to',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            _phoneCtrl.text,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          _buildOtpField(),
          const SizedBox(height: 16),
          if (auth.otpCountdown > 0)
            Text(
              'Resend in ${auth.otpCountdownText}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            GestureDetector(
              onTap: _sendOtp,
              child: Text(
                'Resend Code',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEmailForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sign in with email',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
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
            child: GestureDetector(
              onTap: () => context.go('/forgot-password'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Forgot Password?',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  activeColor: AppColors.primary,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPrimaryButton(
            label: 'Sign In',
            onPressed: auth.isLoading ? null : _submitEmail,
            isLoading: auth.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeChip('Phone', _AuthMode.phone),
          _buildModeChip('Email', _AuthMode.email),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, _AuthMode mode) {
    final isActive = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        _otpSent = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.brFull,
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textMuted,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brButton),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: AppTypography.button.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildOtpField() {
    return TextFormField(
      maxLength: 6,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        letterSpacing: 8,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '- - - - - -',
        hintStyle: TextStyle(
          color: AppColors.border,
          fontSize: 28,
          letterSpacing: 8,
        ),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      onChanged: (v) {
        if (v.length == 6) _verifyOtp(v);
      },
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
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
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

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
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
            onPressed: auth.isLoading ? null : _handleGoogleSignIn,
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
            label: Text(
              'Continue with Google',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
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
            onPressed: auth.isLoading ? null : _handleAppleSignIn,
            icon: const Icon(Icons.apple, color: AppColors.textPrimary, size: 22),
            label: Text(
              'Continue with Apple',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
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

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        GestureDetector(
          onTap: () => context.go('/signup'),
          child: Text(
            'Create Account',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WIDE PANEL FEATURE ROW ─────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.brMd,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
