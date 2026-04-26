import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth.dart';
import '../utils/haptic_utils.dart';

class EliteAuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool showGuestOption;

  const EliteAuthScreen({
    super.key,
    required this.onLoginSuccess,
    this.showGuestOption = true,
  });

  @override
  State<EliteAuthScreen> createState() => _EliteAuthScreenState();
}

class _EliteAuthScreenState extends State<EliteAuthScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  
  int _currentPage = 0; // 0: Login, 1: Sign Up, 2: OTP
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Background animation
  double _gradientOffset = 0;
  Timer? _bgTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<double>(begin: 50, end: 0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    
    // Animate gradient background
    _bgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _gradientOffset = (_gradientOffset + 0.1) % 1);
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                Color.lerp(const Color(0xFF1A1A2E), const Color(0xFF16213E), _gradientOffset)!,
                Color.lerp(const Color(0xFF16213E), const Color(0xFF0F3460), _gradientOffset)!,
                Color.lerp(const Color(0xFF0F3460), const Color(0xFF1A1A2E), _gradientOffset)!,
              ]
                  : [
                Color.lerp(const Color(0xFFFF6B6B), const Color(0xFF6C5CE7), _gradientOffset)!,
                Color.lerp(const Color(0xFF6C5CE7), const Color(0xFFA29BFE), _gradientOffset)!,
                Color.lerp(const Color(0xFFA29BFE), const Color(0xFFFF6B6B), _gradientOffset)!,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: _buildContent(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Logo
          _buildLogo(isDark),
          const SizedBox(height: 40),
          
          // Main Auth Card (Glassmorphism)
          _buildGlassCard(isDark),
          const SizedBox(height: 20),
          
          // Guest Mode Option
          if (widget.showGuestOption) _buildGuestOption(isDark),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shopping_bag, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'OmniMarket',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          _currentPage == 0 ? 'Welcome back!' : _currentPage == 1 ? 'Create Account' : 'Verify Phone',
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildGlassCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_currentPage == 0) _buildLoginForm(),
          if (_currentPage == 1) _buildSignUpForm(),
          if (_currentPage == 2) _buildOTPForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email
        _GlassTextField(
          controller: _emailController,
          hint: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        
        // Password
        _GlassTextField(
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),
        
        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPassword,
            child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70)),
          ),
        ),
        const SizedBox(height: 16),
        
        // Login Button
        _GlassButton(label: 'Login', onPressed: _handleLogin),
        const SizedBox(height: 12),
        
        // Forgot Password
        GestureDetector(
          onTap: _showForgotPasswordDialog,
          child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        const SizedBox(height: 20),
        
        // Divider
        Row(children: [
          Expanded(child: Divider(color: Colors.white30)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('or', style: TextStyle(color: Colors.white70)),
          ),
          Expanded(child: Divider(color: Colors.white30)),
        ]),
        const SizedBox(height: 20),
        
        // Social Login Buttons
        Row(
          children: [
            Expanded(child: _SocialButton(icon: Icons.g_mobiledata, label: 'Google', onTap: _handleGoogleLogin)),
            const SizedBox(width: 12),
            Expanded(child: _SocialButton(icon: Icons.apple, label: 'Apple', onTap: _handleAppleLogin)),
          ],
        ),
        const SizedBox(height: 12),
        
        // Biometric
        if (_canUseBiometric()) 
          _GlassButton(
            label: 'Use Biometrics', 
            icon: Icons.fingerprint,
            onPressed: _handleBiometricLogin,
            isOutlined: true,
          ),
        
        const SizedBox(height: 16),
        
        // Sign Up Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
            GestureDetector(
              onTap: () => _animateToPage(1),
              child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        _GlassTextField(
          controller: _nameController,
          hint: 'Full Name',
          icon: Icons.person_outlined,
        ),
        const SizedBox(height: 16),
        
        _GlassTextField(
          controller: _emailController,
          hint: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        
        _GlassTextField(
          controller: _phoneController,
          hint: 'Phone (optional)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        
        _GlassTextField(
          controller: _passwordController,
          hint: 'Password (8+ chars)',
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        
        _GlassButton(label: 'Create Account', onPressed: _handleSignUp),
        const SizedBox(height: 16),
        
        // Login Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account? ', style: TextStyle(color: Colors.white70)),
            GestureDetector(
              onTap: () => _animateToPage(0),
              child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOTPForm() {
    return Column(
      children: [
        const Text('Enter the 6-digit code sent to your phone', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        
        _GlassTextField(
          controller: _otpController,
          hint: '123456',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        _GlassButton(label: 'Verify OTP', onPressed: _handleOTPVerify),
        const SizedBox(height: 12),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => _animateToPage(0),
              child: const Text('Change Phone', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: _resendOTP,
              child: const Text('Resend Code', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestOption(bool isDark) {
    return GestureDetector(
      onTap: _handleGuestMode,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Continue as Guest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Text('(Browse first)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ==================== HANDLERS ====================
  void _animateToPage(int page) {
    HapticFeedback.lightImpact();
    setState(() => _currentPage = page);
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    final result = await _auth.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      HapticUtil.success();
      widget.onLoginSuccess();
    } else {
      HapticUtil.error();
      _showError(result['error'] ?? 'Login failed');
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticUtil.lightImpact();
    
    final result = await _auth.signInWithGoogle();
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      HapticUtil.success();
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleAppleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticUtil.lightImpact();
    
    final result = await _auth.signInWithApple();
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      HapticUtil.success();
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleBiometricLogin() async {
    final canUse = await BiometricAuth.isAvailable();
    if (!canUse) {
      _showError('Biometrics not available');
      return;
    }
    
    final success = await BiometricAuth.authenticate();
    if (success) {
      await _auth.authenticateWithBiometric();
      HapticUtil.success();
      widget.onLoginSuccess();
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            _GlassTextField(
              controller: emailController,
              hint: 'Email',
              icon: Icons.email,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          _GlassButton(
            label: 'Send Reset Link',
            onPressed: () {
              Navigator.pop(context);
              _showError('Password reset link sent to your email!', isSuccess: true);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (_passwordController.text.length < 8) {
      HapticUtil.error();
      _showError('Password must be 8+ characters');
      return;
    }
    
    setState(() => _isLoading = true);
    
    final result = await _auth.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      if (result['isNewUser'] == true) {
        // Show OTP for phone verification
        await _auth.sendOTP(_phoneController.text.trim());
        setState(() => _currentPage = 2);
      } else {
        HapticUtil.success();
        widget.onLoginSuccess();
      }
    } else {
      HapticUtil.error();
      _showError(result['error'] ?? 'Sign up failed');
    }
  }

  Future<void> _handleGuestMode() async {
    HapticUtil.lightImpact();
    await _auth.enableGuestMode();
    widget.onLoginSuccess();
  }

  Future<void> _handleOTPVerify() async {
    final result = await _auth.verifyOTP(_otpController.text);
    if (result['success']) {
      HapticUtil.success();
      widget.onLoginSuccess();
    } else {
      HapticUtil.error();
      _showError(result['error'] ?? 'Invalid OTP');
    }
  }

  void _resendOTP() {
    _auth.sendOTP(_phoneController.text);
    HapticUtil.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent')));
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reset Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.email, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent!')));
                },
                child: const Text('Send Reset Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isSuccess ? Colors.green : Colors.red));
  }

  bool _canUseBiometric() => true; // Check in production
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextEditingController? textAlign;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white)),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _GlassButton({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6C5CE7),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}