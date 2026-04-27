import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import 'verify_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _sent = false;
  String _method = 'email';

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    }
  }

@override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    
    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Forgot Password', 'نسيت كلمة المرور')),
        backgroundColor: OmniTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _sent ? _buildSent(isArabic) : _buildForm(isArabic, (en, ar) => isArabic ? ar : en),
      ),
    );
  }

  Widget _buildSent(bool isArabic) {
    return Column(children: [
      SizedBox(height: 40),
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(color: OmniTheme.successColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.check_circle, size: 60, color: OmniTheme.successColor),
      ),
      SizedBox(height: 24),
      Text('Code Sent!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      Text(
        _method == 'email' 
          ? (isArabic ? 'تحقق من بريدك الإلكتروني' : 'Check your email for the code')
          : (isArabic ? 'تحقق من رسائلك النصية' : 'Check your SMS for the code'),
        style: TextStyle(color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 32),
      SizedBox(
        width: 200,
        height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyScreen(
            email: _emailController.text,
            isForgotPassword: true,
          ))),
          style: ElevatedButton.styleFrom(
            backgroundColor: OmniTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(isArabic ? 'أدخل الكود' : 'Enter Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  Widget _buildForm(bool isArabic, String t(String en, String ar)) {
    return Form(key: _formKey, child: Column(children: [
      SizedBox(height: 20),
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(color: OmniTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.lock_outline, size: 50, color: OmniTheme.primaryColor),
      ),
      SizedBox(height: 24),
      Text(t('Reset Password', 'إعادة تعيين كلمة المرور'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text(t('Choose how to receive the code', 'اختر طريقة استلام الكود'), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      SizedBox(height: 24),
      
      // Method Selection
      Row(
        children: [
          Expanded(child: _methodOption(Icons.email, 'Email', 'email', isArabic)),
          SizedBox(width: 12),
          Expanded(child: _methodOption(Icons.sms, 'SMS', 'sms', isArabic)),
        ],
      ),
      SizedBox(height: 20),
      
      // Input Field
      if (_method == 'email')
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: 14),
         decoration: InputDecoration(
            labelText: t('Email', 'البريد الإلكتروني'),
            prefixIcon: Icon(Icons.email, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        )
      else
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(fontSize: 14),
         decoration: InputDecoration(
            labelText: t('Phone Number', 'رقم الهاتف'),
            prefixIcon: Icon(Icons.phone, size: 20),
            hintText: '+963...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      SizedBox(height: 24),
      
      // Submit Button
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _sendCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: OmniTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading 
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(t('Send Code', 'إرسال الكود'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    ]));
  }

  Widget _methodOption(IconData icon, String label, String method, bool isArabic) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? OmniTheme.primaryColor.withOpacity(0.1) : Colors.white,
          border: Border.all(color: selected ? OmniTheme.primaryColor : Colors.grey[300]!, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? OmniTheme.primaryColor : Colors.grey[600], size: 24),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? OmniTheme.primaryColor : Colors.grey[600],
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}