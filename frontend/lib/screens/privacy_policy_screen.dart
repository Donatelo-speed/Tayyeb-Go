import 'package:flutter/material.dart';
import '../theme/omni_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سياسة الخصوصية والأحكام',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'آخر تحديث: يناير 2026',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 32),
            
            _PolicySection(
              title: 'مقدمة',
              content: '''
مرحباً بك في تطبيق OmniMarket. نحن نقدر خصوصيتك ونلتزم بحماية بياناتك الشخصية. هذه السياسة تشرح كيفية جمع واستخدام وحماية معلوماتك.
              ''',
            ),
            
            _PolicySection(
              title: 'المعلومات التي نجمعها',
              content: '''
• معلومات الحساب (الاسم، البريد الإلكتروني، رقم الهاتف)
• معلومات التوصيل (العنوان، الموقع)
• سجل عمليات الشراء
• بيانات الموقع التقني
              ''',
            ),
            
            _PolicySection(
              title: 'كيفية استخدام معلوماتك',
              content: '''
• تقديم خدمات التوصيل
• معالجة الطلبات والدفعات
• التواصل معك بشان طلباتك
• تحسين خدماتنا
• حماية حسابك
              ''',
            ),
            
            _PolicySection(
              title: 'حماية البيانات',
              content: '''
نستخدم تقنيات تشفير متقدمة لحماية بياناتك. لا نبيع معلوماتك الشخصية لأي طرف ثالث.
              ''',
            ),
            
            _PolicySection(
              title: 'حقوقك',
              content: '''
• الوصول إلى بياناتك
• تصحيح المعلومات
• حذف الحساب
• الاعتراض على معالجة البيانات
              ''',
            ),
            
            _PolicySection(
              title: 'التواصل',
              content: '''
لأي استفسار حول الخصوصية، تواصل معنا عبر الواتساب أو البريد الإلكتروني.

OmniMarket - سوق إلكتروني سوري موثوق
              ''',
            ),
            
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 OmniMarket. جميع الحقوق محفوظة.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.grey[700], height: 1.6),
          ),
        ],
      ),
    );
  }
}