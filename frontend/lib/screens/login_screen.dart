import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'delivery_job_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailController.text.trim(), _passwordController.text);
    
    if (success && mounted) {
      context.read<CartProvider>().loadCart();
      Navigator.pushReplacement(context, SmoothPageTransition(page: const HomeScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Invalid credentials'), backgroundColor: OmniTheme.errorColor),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 400;
    
    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isSmall ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isArabic ? 16 : 32),
                    
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Transform.rotate(
                              angle: (1 - value) * 0.3,
                              child: Container(
                                width: isSmall ? 80 : 100,
                                height: isSmall ? 80 : 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [OmniTheme.primaryColor, OmniTheme.primaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isSmall ? 20 : 25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: OmniTheme.primaryColor.withOpacity(0.35),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.shopping_bag, color: Colors.white, size: isSmall ? 35 : 45),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: isSmall ? 20 : 28),
                    
                    Text(t('Welcome Back', 'مرحباً بعودتك'), textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isSmall ? 20 : 24, fontWeight: FontWeight.bold, color: OmniTheme.textPrimary)),
                    SizedBox(height: 6),
                    Text(t('Sign in to continue', 'سجل للمتابعة'), textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isSmall ? 13 : 14, color: OmniTheme.textSecondary)),
                    SizedBox(height: isSmall ? 20 : 28),
                    
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(fontSize: isSmall ? 14 : 15),
                      decoration: InputDecoration(
                        hintText: t('Email', 'البريد الإلكتروني'),
                        labelText: t('Email', 'البريد الإلكتروني'),
                        prefixIcon: Icon(Icons.email_outlined, color: OmniTheme.primaryColor, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: OmniTheme.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (v) => v == null || v.isEmpty ? t('Required', 'مطلوب') : null,
                    ),
                    SizedBox(height: isSmall ? 10 : 12),
                    
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      style: TextStyle(fontSize: isSmall ? 14 : 15),
                      decoration: InputDecoration(
                        hintText: t('Password', 'كلمة المرور'),
                        labelText: t('Password', 'كلمة المرور'),
                        prefixIcon: Icon(Icons.lock_outline, color: OmniTheme.primaryColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: OmniTheme.textMuted, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: OmniTheme.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (v) => v == null || v.isEmpty ? t('Required', 'مطلوب') : null,
                    ),
                    SizedBox(height: 6),
                    
                    Align(
                      alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: Text(t('Forgot Password?', 'نسيت كلمة المرور؟'), style: TextStyle(color: OmniTheme.primaryColor, fontSize: 13)),
                      ),
                    ),
                    SizedBox(height: isSmall ? 8 : 12),
                    
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(t('Sign In', 'دخول'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(height: isSmall ? 16 : 22),
                    
                    Row(children: [
                      const Expanded(child: Divider(color: OmniTheme.borderColor)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(t('OR', 'أو'), style: TextStyle(color: OmniTheme.textMuted, fontSize: 12))),
                      const Expanded(child: Divider(color: OmniTheme.borderColor)),
                    ]),
                    SizedBox(height: isSmall ? 14 : 18),
                    
                    Text(t('Sign in with', 'سجل بالدخول باستخدام'), textAlign: TextAlign.center,
                      style: TextStyle(color: OmniTheme.textMuted, fontSize: 12)),
                    SizedBox(height: isSmall ? 10 : 14),
                    
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Column(
                        children: [
                          _SocialButton(icon: Icons.g_mobiledata, label: 'Google', color: Colors.blue[700]!, onPressed: () => _showComingSoon(context, isArabic), isSmall: isSmall),
                          SizedBox(height: isSmall ? 8 : 10),
                          _SocialButton(icon: Icons.apple, label: 'Apple', color: Colors.black87, onPressed: () => _showComingSoon(context, isArabic), isSmall: isSmall),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isSmall ? 18 : 22),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t("Don't have account?", 'ما عندك حساب؟'), style: TextStyle(color: OmniTheme.textSecondary, fontSize: 13)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text(t('Sign Up', 'سجل الآن'), style: TextStyle(fontWeight: FontWeight.bold, color: OmniTheme.primaryColor, fontSize: 13)),
                        ),
                      ],
                    ),
                    
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: OmniTheme.primaryColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryJobScreen())),
                        icon: Icon(Icons.delivery_dining, color: OmniTheme.primaryColor, size: 18),
                        label: Text(t('Delivery Driver?', 'سائق توصيل؟'), style: TextStyle(color: OmniTheme.primaryColor, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, bool isArabic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.construction, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(isArabic ? 'قيد التطوير!' : 'Coming Soon!'),
        ]),
        backgroundColor: OmniTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmall;

  const _SocialButton({required this.icon, required this.label, required this.color, required this.onPressed, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmniTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            border: Border.all(color: OmniTheme.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: OmniTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}