import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color? _primaryColor;
  Color? _accentColor;
  
  ThemeMode get themeMode => _themeMode;
  Color? get primaryColor => _primaryColor;
  Color? get accentColor => _accentColor;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString('theme_mode') ?? 'system';
    _themeMode = _themeModeFromString(themeModeStr);
    
    final primaryColorStr = prefs.getString('primary_color');
    if (primaryColorStr != null) {
      _primaryColor = Color(int.parse(primaryColorStr.replaceFirst('#', '0xFF')));
    }
    
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primary_color', '#${color.value.toRadixString(16).substring(2)}');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Get the appropriate theme based on current mode
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor ?? const Color(0xFF16A085),
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor ?? const Color(0xFF16A085),
        brightness: Brightness.dark,
      ),
    );
  }
}

// =====================================================
// THEME SELECTION DIALOG
// =====================================================

class ThemeSelectorSheet extends StatelessWidget {
  final ThemeProvider themeProvider;
  
  const ThemeSelectorSheet({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Theme',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Light Mode
          _ThemeOption(
            icon: Icons.light_mode,
            title: 'Light',
            subtitle: 'Always use light theme',
            isSelected: themeProvider.isLightMode,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          
          // Dark Mode
          _ThemeOption(
            icon: Icons.dark_mode,
            title: 'Dark',
            subtitle: 'Always use dark theme',
            isSelected: themeProvider.isDarkMode,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          
          // System Mode
          _ThemeOption(
            icon: Icons.settings_suggest,
            title: 'System',
            subtitle: 'Follow device settings',
            isSelected: themeProvider.isSystemMode,
            onTap: () {
              themeProvider.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}