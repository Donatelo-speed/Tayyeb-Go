import 'package:flutter/material.dart';
import '../theme/omni_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'ar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اللغة'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _LanguageTile(
            flag: '🇸🇦',
            name: 'العربية',
            subtitle: 'Arabic',
            isSelected: _selectedLanguage == 'ar',
            onTap: () => setState(() => _selectedLanguage = 'ar'),
          ),
          _LanguageTile(
            flag: '🇺🇸',
            name: 'English',
            subtitle: 'الإنجليزية',
            isSelected: _selectedLanguage == 'en',
            onTap: () => setState(() => _selectedLanguage = 'en'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // Save language preference
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: OmniTheme.primaryColor,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('تأكيد', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      subtitle: Text(subtitle),
      trailing: isSelected 
        ? const Icon(Icons.check_circle, color: OmniTheme.primaryColor, size: 28)
        : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: onTap,
      selected: isSelected,
    );
  }
}