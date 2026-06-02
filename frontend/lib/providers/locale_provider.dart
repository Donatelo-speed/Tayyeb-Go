import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';
  bool _isRTL = false;
  
  LocaleProvider(this._locale) {
    _isRTL = _locale == 'ar';
  }
  
  String get locale => _locale;
  bool get isRTL => _isRTL;
  bool get isArabic => _locale == 'ar';
  bool get isEnglish => _locale == 'en';
  
  Locale get localeObject => Locale(_locale);
  
  // Translation helper
  String t(String en, String ar) => isArabic ? ar : en;
  
  Future<void> setLocale(String locale) async {
    if (locale != 'en' && locale != 'ar') return;
    
    _locale = locale;
    _isRTL = locale == 'ar';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale);
    
    notifyListeners();
  }
  
  void toggle() {
    setLocale(_locale == 'en' ? 'ar' : 'en');
  }
}

// =====================================================
// TRANSLATIONS
// =====================================================

class AppTranslations {
  static final Map<String, Map<String, String>> _translations = {
    // Auth
    'login': {'en': 'Login', 'ar': 'تسجيل الدخول'},
    'register': {'en': 'Register', 'ar': 'إنشاء حساب'},
    'logout': {'en': 'Logout', 'ar': 'تسجيل الخروج'},
    'email': {'en': 'Email', 'ar': 'البريد الإلكتروني'},
    'password': {'en': 'Password', 'ar': 'كلمة المرور'},
    'phone': {'en': 'Phone', 'ar': 'رقم الهاتف'},
    'name': {'en': 'Name', 'ar': 'الاسم'},
    
    // Navigation
    'home': {'en': 'Home', 'ar': 'الرئيسية'},
    'vendors': {'en': 'Vendors', 'ar': 'المتاجر'},
    'cart': {'en': 'Cart', 'ar': 'السلة'},
    'orders': {'en': 'Orders', 'ar': 'الطلبات'},
    'profile': {'en': 'Profile', 'ar': 'الحساب'},
    'settings': {'en': 'Settings', 'ar': 'الإعدادات'},
    
    // Customer
    'search': {'en': 'Search', 'ar': 'بحث'},
    'categories': {'en': 'Categories', 'ar': 'الفئات'},
    'popular': {'en': 'Popular', 'ar': 'الشائع'},
    'checkout': {'en': 'Checkout', 'ar': 'الدفع'},
    'addresses': {'en': 'Addresses', 'ar': 'العناوين'},
    'add_address': {'en': 'Add Address', 'ar': 'إضافة عنوان'},
    'track_order': {'en': 'Track Order', 'ar': 'تتبع الطلب'},
    
    // Restaurant
    'menu': {'en': 'Menu', 'ar': 'القائمة'},
    'products': {'en': 'Products', 'ar': 'المنتجات'},
    'categories_editor': {'en': 'Categories', 'ar': 'الفئات'},
    'modifiers': {'en': 'Modifiers', 'ar': 'الخيارات'},
    'kitchen': {'en': 'Kitchen', 'ar': 'المطبخ'},
    'analytics': {'en': 'Analytics', 'ar': 'التحليلات'},
    'staff': {'en': 'Staff', 'ar': 'الموظفين'},
    
    // Driver
    'deliveries': {'en': 'Deliveries', 'ar': 'التسليمات'},
    'earnings': {'en': 'Earnings', 'ar': 'الأرباح'},
    'available_orders': {'en': 'Available Orders', 'ar': 'الطلبات المتاحة'},
    'active_delivery': {'en': 'Active Delivery', 'ar': 'التسليم النشط'},
    
    // Admin
    'dashboard': {'en': 'Dashboard', 'ar': 'لوحة التحكم'},
    'users': {'en': 'Users', 'ar': 'المستخدمون'},
    'restaurants': {'en': 'Restaurants', 'ar': 'المطاعم'},
    'drivers': {'en': 'Drivers', 'ar': 'السائقون'},
    'commissions': {'en': 'Commissions', 'ar': 'العمولات'},
    'reports': {'en': 'Reports', 'ar': 'التقارير'},
    'system_settings': {'en': 'System Settings', 'ar': 'إعدادات النظام'},
    'kill_switch': {'en': 'Kill Switch', 'ar': 'إيقاف الطوارئ'},
    'live_map': {'en': 'Live Map', 'ar': 'الخريطة المباشرة'},
    
    // Common
    'save': {'en': 'Save', 'ar': 'حفظ'},
    'cancel': {'en': 'Cancel', 'ar': 'إلغاء'},
    'delete': {'en': 'Delete', 'ar': 'حذف'},
    'edit': {'en': 'Edit', 'ar': 'تعديل'},
    'confirm': {'en': 'Confirm', 'ar': 'تأكيد'},
    'success': {'en': 'Success', 'ar': 'نجاح'},
    'error': {'en': 'Error', 'ar': 'خطأ'},
    'loading': {'en': 'Loading', 'ar': 'جاري التحميل'},
    'no_data': {'en': 'No Data', 'ar': 'لا توجد بيانات'},
    'retry': {'en': 'Retry', 'ar': 'إعادة المحاولة'},
  };
  
  static String get(String key, String locale) {
    return _translations[key]?[locale] ?? key;
  }
}