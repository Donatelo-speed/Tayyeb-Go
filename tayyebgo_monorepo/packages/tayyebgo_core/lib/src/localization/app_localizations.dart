import 'package:flutter/material.dart';

/// Comprehensive localization for TayyebGo — supports English and Arabic.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  // ─── Navigation ───
  String get home => _t('Home', 'الرئيسية');
  String get explore => _t('Explore', 'استكشف');
  String get orders => _t('Orders', 'الطلبات');
  String get profile => _t('Profile', 'الملف الشخصي');
  String get settings => _t('Settings', 'الإعدادات');
  String get wallet => _t('Wallet', 'المحفظة');
  String get notifications => _t('Notifications', 'الإشعارات');
  String get helpSupport => _t('Help & Support', 'المساعدة والدعم');

  // ─── Auth ───
  String get login => _t('Login', 'تسجيل الدخول');
  String get signup => _t('Sign Up', 'إنشاء حساب');
  String get logout => _t('Logout', 'تسجيل الخروج');
  String get email => _t('Email', 'البريد الإلكتروني');
  String get password => _t('Password', 'كلمة المرور');
  String get confirmPassword => _t('Confirm Password', 'تأكيد كلمة المرور');
  String get phoneNumber => _t('Phone Number', 'رقم الهاتف');
  String get fullName => _t('Full Name', 'الاسم الكامل');
  String get forgotPassword => _t('Forgot Password', 'نسيت كلمة المرور');
  String get orContinueWith => _t('Or continue with', 'أو تابع باستخدام');
  String get google => _t('Google', 'جوجل');
  String get apple => _t('Apple', 'آبل');
  String get rememberMe => _t('Remember Me', 'تذكرني');
  String get dontHaveAccount => _t("Don't have an account?", 'ليس لديك حساب؟');
  String get alreadyHaveAccount => _t('Already have an account?', 'لديك حساب بالفعل؟');
  String get signUpWith => _t('Sign up with', 'سجّل باستخدام');
  String get createPassword => _t('Create a password', 'أنشئ كلمة مرور');
  String get termsAgree => _t('I agree to the Terms & Conditions and Privacy Policy', 'أوافق على الشروط والأحكام وسياسة الخصوصية');
  String get loginButton => _t('LOG IN', 'تسجيل الدخول');
  String get signupButton => _t('SIGN UP', 'إنشاء حساب');

  // ─── Cart & Checkout ───
  String get cart => _t('Cart', 'سلة التسوق');
  String get checkout => _t('Checkout', 'الدفع');
  String get addItem => _t('Add to Cart', 'أضف إلى السلة');
  String get total => _t('Total', 'المجموع');
  String get subtotal => _t('Subtotal', 'المجموع الفرعي');
  String get deliveryFee => _t('Delivery Fee', 'رسوم التوصيل');
  String get tip => _t('Tip', 'بقشيش');
  String get promoCode => _t('Promo Code', 'كود الخصم');
  String get apply => _t('Apply', 'تطبيق');
  String get placeOrder => _t('Place Order', 'تأكيد الطلب');
  String get paymentMethod => _t('Payment Method', 'طريقة الدفع');
  String get cashOnDelivery => _t('Cash on Delivery', 'الدفع عند الاستلام');
  String get creditCard => _t('Credit Card', 'بطاقة ائتمان');
  String get walletPay => _t('Wallet', 'المحفظة');
  String get orderPlaced => _t('Order Placed!', 'تم الطلب!');
  String get orderConfirmed => _t('Order Confirmed', 'تم تأكيد الطلب');
  String get preparing => _t('Preparing', 'جاري التحضير');
  String get onTheWay => _t('On the Way', 'في الطريق');
  String get delivered => _t('Delivered', 'تم التوصيل');
  String get scheduleOrder => _t('Schedule Order', 'جدولة الطلب');
  String get selectTime => _t('Select Time', 'اختر الوقت');
  String get asap => _t('ASAP', 'في أسرع وقت');
  String get scheduled => _t('Scheduled', 'مجدول');

  // ─── Delivery ───
  String get trackOrder => _t('Track Order', 'تتبع الطلب');
  String get driverArriving => _t('Driver is on the way', 'السائق في الطريق');
  String get estimatedArrival => _t('Estimated Arrival', 'الوقت المتوقع للوصول');
  String get callDriver => _t('Call Driver', 'اتصل بالسائق');
  String get messageDriver => _t('Message Driver', 'راسل السائق');
  String get cancelOrder => _t('Cancel Order', 'إلغاء الطلب');
  String get rateDriver => _t('Rate Driver', 'قيّم السائق');
  String get rateStore => _t('Rate Store', 'قيّم المتجر');

  // ─── Addresses ───
  String get deliveryAddress => _t('Delivery Address', 'عنوان التوصيل');
  String get addAddress => _t('Add Address', 'إضافة عنوان');
  String get editAddress => _t('Edit Address', 'تعديل العنوان');
  String get homeAddress => _t('Home', 'المنزل');
  String get workAddress => _t('Work', 'العمل');
  String get other => _t('Other', 'أخرى');
  String get savedAddresses => _t('Saved Addresses', 'العناوين المحفوظة');
  String get searchAddress => _t('Search address...', 'ابحث عن عنوان...');

  // ─── Orders ───
  String get currentOrders => _t('Current Orders', 'الطلبات الحالية');
  String get pastOrders => _t('Past Orders', 'الطلبات السابقة');
  String get orderDetails => _t('Order Details', 'تفاصيل الطلب');
  String get reorder => _t('Reorder', 'إعادة الطلب');
  String get noOrdersYet => _t('No orders yet', 'لا توجد طلبات بعد');
  String get orderNumber => _t('Order Number', 'رقم الطلب');
  String get orderDate => _t('Order Date', 'تاريخ الطلب');

  // ─── Stores ───
  String get restaurants => _t('Restaurants', 'المطاعم');
  String get stores => _t('Stores', 'المتاجر');
  String get menu => _t('Menu', 'القائمة');
  String get categories => _t('Categories', 'الفئات');
  String get popularItems => _t('Popular Items', 'الأصناف الشائعة');
  String get allItems => _t('All Items', 'جميع الأصناف');
  String get openNow => _t('Open Now', 'مفتوح الآن');
  String get closed => _t('Closed', 'مغلق');
  String get deliveryTime => _t('Delivery Time', 'وقت التوصيل');
  String get minOrder => _t('Min. Order', 'الحد الأدنى للطلب');
  String get rating => _t('Rating', 'التقييم');
  String get reviews => _t('Reviews', 'التقييمات');
  String get writeReview => _t('Write a Review', 'اكتب تقييم');
  String get noReviewsYet => _t('No reviews yet', 'لا توجد تقييمات بعد');

  // ─── Wallet ───
  String get balance => _t('Balance', 'الرصيد');
  String get topUp => _t('Top Up', 'شحن الرصيد');
  String get sendMoney => _t('Send', 'إرسال');
  String get receiveMoney => _t('Receive', 'استلام');
  String get transactionHistory => _t('Transaction History', 'سجل المعاملات');
  String get noTransactions => _t('No transactions yet', 'لا توجد معاملات بعد');

  // ─── Profile ───
  String get editProfile => _t('Edit Profile', 'تعديل الملف الشخصي');
  String get savedCards => _t('Saved Cards', 'البطاقات المحفوظة');
  String get language => _t('Language', 'اللغة');
  String get english => _t('English', 'English');
  String get arabic => _t('Arabic', 'العربية');
  String get darkMode => _t('Dark Mode', 'الوضع الداكن');
  String get about => _t('About', 'حول');
  String get privacyPolicy => _t('Privacy Policy', 'سياسة الخصوصية');
  String get termsConditions => _t('Terms & Conditions', 'الشروط والأحكام');
  String get deleteAccount => _t('Delete Account', 'حذف الحساب');

  // ─── Driver ───
  String get online => _t('Online', 'متصل');
  String get offline => _t('Offline', 'غير متصل');
  String get acceptOrder => _t('Accept Order', 'قبول الطلب');
  String get rejectOrder => _t('Reject Order', 'رفض الطلب');
  String get pickUp => _t('Pick Up', 'الاستلام');
  String get dropOff => _t('Drop Off', 'التسليم');
  String get earnings => _t('Earnings', 'الأرباح');
  String get dailyEarnings => _t('Daily Earnings', 'الأرباح اليومية');
  String get totalEarnings => _t('Total Earnings', 'إجمالي الأرباح');
  String get completedDeliveries => _t('Completed Deliveries', 'التوصيلات المكتملة');
  String get vehicleInfo => _t('Vehicle Info', 'معلومات المركبة');
  String get documents => _t('Documents', 'الوثائق');
  String get goOnline => _t('Go Online', 'اذهب لوضع الاتصال');
  String get goOffline => _t('Go Offline', 'اذهب لوضع عدم الاتصال');
  String get navigation => _t('Navigation', 'الملاحة');
  String get arrived => _t('Arrived', 'وصلت');

  // ─── Partner ───
  String get dashboard => _t('Dashboard', 'لوحة التحكم');
  String get storeManagement => _t('Store Management', 'إدارة المتجر');
  String get menuManagement => _t('Menu Management', 'إدارة القائمة');
  String get activeOrders => _t('Active Orders', 'الطلبات النشطة');
  String get orderHistory => _t('Order History', 'سجل الطلبات');
  String get analytics => _t('Analytics', 'التحليلات');
  String get promotions => _t('Promotions', 'الترويجات');
  String get staff => _t('Staff', 'الموظفون');
  String get storeSettings => _t('Store Settings', 'إعدادات المتجر');
  String get storeStatus => _t('Store Status', 'حالة المتجر');
  String get openStore => _t('Open Store', 'فتح المتجر');
  String get closeStore => _t('Close Store', 'إغلاق المتجر');

  // ─── Admin ───
  String get finance => _t('Finance', 'المالية');
  String get users => _t('Users', 'المستخدمون');
  String get drivers => _t('Drivers', 'السائقون');
  String get partners => _t('Partners', 'الشركاء');
  String get campaigns => _t('Campaigns', 'الحملات');
  String get zones => _t('Zones', 'المناطق');
  String get coupons => _t('Coupons', 'الكوبونات');
  String get reports => _t('Reports', 'التقارير');
  String get grossRevenue => _t('Gross Revenue', 'الإيرادات الإجمالية');
  String get platformCommission => _t('Platform Commission', 'عمولة المنصة');
  String get refunds => _t('Refunds', 'المبالغ المستردة');
  String get driverPayouts => _t('Driver Payouts', 'مدفوعات السائقين');
  String get storePayouts => _t('Store Payouts', 'مدفوعات المتاجر');

  // ─── General ───
  String get save => _t('Save', 'حفظ');
  String get cancel => _t('Cancel', 'إلغاء');
  String get confirm => _t('Confirm', 'تأكيد');
  String get delete => _t('Delete', 'حذف');
  String get edit => _t('Edit', 'تعديل');
  String get add => _t('Add', 'إضافة');
  String get search => _t('Search', 'بحث');
  String get filter => _t('Filter', 'تصفية');
  String get sort => _t('Sort', 'ترتيب');
  String get loading => _t('Loading...', 'جاري التحميل...');
  String get error => _t('Error', 'خطأ');
  String get retry => _t('Retry', 'إعادة المحاولة');
  String get noResults => _t('No results found', 'لم يتم العثور على نتائج');
  String get tryAgain => _t('Try Again', 'حاول مرة أخرى');
  String get somethingWentWrong => _t('Something went wrong', 'حدث خطأ ما');
  String get required_ => _t('Required', 'مطلوب');
  String get mandatory => _t('Mandatory', 'إلزامي');
  String get optional => _t('Optional', 'اختياري');
  String get next => _t('Next', 'التالي');
  String get previous => _t('Previous', 'السابق');
  String get done => _t('Done', 'تم');
  String get yes => _t('Yes', 'نعم');
  String get no => _t('No', 'لا');
  String get ok => _t('OK', 'موافق');
  String get share => _t('Share', 'مشاركة');
  String get copy => _t('Copy', 'نسخ');
  String get copied => _t('Copied', 'تم النسخ');
  String get close => _t('Close', 'إغلاق');
  String get back => _t('Back', 'رجوع');
  String get refresh => _t('Refresh', 'تحديث');
  String get send => _t('Send', 'إرسال');
  String get typeMessage => _t('Type a message...', 'اكتب رسالة...');
  String get today => _t('Today', 'اليوم');
  String get yesterday => _t('Yesterday', 'أمس');
  String get min => _t('min', 'دقيقة');
  String get km => _t('km', 'كم');
  String get free => _t('Free', 'مجاني');
  String get comingSoon => _t('Coming Soon', 'قريباً');
  String get underMaintenance => _t('Under Maintenance', 'تحت الصيانة');
  String get noInternet => _t('No Internet Connection', 'لا يوجد اتصال بالإنترنت');
  String get reconnecting => _t('Reconnecting...', 'جاري إعادة الاتصال...');

  String _t(String en, String ar) => locale.languageCode == 'ar' ? ar : en;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
