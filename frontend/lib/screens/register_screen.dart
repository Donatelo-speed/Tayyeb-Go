import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _verificationMethod = 'email';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
      phone: _phoneController.text,
    );
    
    if (success && mounted) {
      // Navigate to verification
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyScreen(
            email: _emailController.text,
            phone: _phoneController.text,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    
    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Create Account', 'إنشاء حساب')),
        backgroundColor: OmniTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t('Full Name', 'الاسم الكامل'),
                  prefixIcon: const Icon(Icons.person, color: OmniTheme.primaryColor),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t('Email', 'البريد الإلكتروني'),
                  prefixIcon: const Icon(Icons.email, color: OmniTheme.primaryColor),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t('Phone Number', 'رقم الهاتف'),
                  prefixIcon: const Icon(Icons.phone, color: OmniTheme.primaryColor),
                  hintText: '+963...',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Verification preference
              Text(t('Verify through:', 'تحقق عبر:'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _verificationMethod = 'email'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _verificationMethod == 'email' ? OmniTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _verificationMethod == 'email' ? OmniTheme.primaryColor : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email, color: _verificationMethod == 'email' ? OmniTheme.primaryColor : Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text('Email', style: TextStyle(color: _verificationMethod == 'email' ? OmniTheme.primaryColor : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _verificationMethod = 'phone'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _verificationMethod == 'phone' ? OmniTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _verificationMethod == 'phone' ? OmniTheme.primaryColor : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sms, color: _verificationMethod == 'phone' ? OmniTheme.primaryColor : Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text('SMS', style: TextStyle(color: _verificationMethod == 'phone' ? OmniTheme.primaryColor : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: t('Password', 'كلمة المرور'),
                  prefixIcon: const Icon(Icons.lock, color: OmniTheme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: OmniTheme.primaryColor),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : v.length < 6 ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 16),
              
              // Confirm Password
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: t('Confirm Password', 'تأكيد كلمة المرور'),
                  prefixIcon: const Icon(Icons.lock_outline, color: OmniTheme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: OmniTheme.primaryColor),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              
              // Terms
              Row(
                children: [
                  Checkbox(value: true, onChanged: (v) {}, activeColor: OmniTheme.primaryColor),
                  Expanded(
                    child: Text(
                      t('I agree to the Terms & Conditions', 'أوافق على الشروط والأحكام'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Register Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          t('Create Account', 'إنشاء حساب'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t('Already have account?', 'لديك حساب بالفعل؟')),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t('Sign In', 'تسجيل الدخول'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: OmniTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}