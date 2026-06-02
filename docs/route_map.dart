// =====================================================
// TAYYEB-GO: FLUTTER ROUTE MAP
// Complete Navigation Architecture
// =====================================================

/*
ROUTE STRUCTURE:

├── SplashScreen (/)
├── AuthFlow (/auth)
│   ├── LoginScreen (/auth/login)
│   ├── RegisterScreen (/auth/register)
│   │   ├── Step1: PhoneInput (/auth/register/phone)
│   │   ├── Step2: OTPVerification (/auth/register/otp)
│   │   └── Step3: ProfileSetup (/auth/register/profile)
│   ├── ForgotPasswordScreen (/auth/forgot-password)
│   └── GoogleOAuthCallback (/auth/google/callback)
│
├── MainWrapper (/app)
│   ├── CustomerApp (/app/customer)
│   │   ├── CustomerHome (/app/customer/home)
│   │   ├── VendorsScreen (/app/customer/vendors)
│   │   ├── VendorDetailScreen (/app/customer/vendor/:id)
│   │   ├── ProductDetailScreen (/app/customer/product/:id)
│   │   ├── CartScreen (/app/customer/cart)
│   │   ├── CheckoutScreen (/app/customer/checkout)
│   │   ├── OrderTrackingScreen (/app/customer/order/:id)
│   │   ├── OrdersHistoryScreen (/app/customer/orders)
│   │   ├── CustomerProfileScreen (/app/customer/profile)
│   │   ├── AddressesScreen (/app/customer/addresses)
│   │   ├── AddAddressScreen (/app/customer/addresses/add)
│   │   ├── SettingsScreen (/app/customer/settings)
│   │   ├── ChatScreen (/app/customer/chat/:orderId)
│   │   └── SearchScreen (/app/customer/search)
│   │
│   ├── RestaurantApp (/app/restaurant)
│   │   ├── RestaurantDashboard (/app/restaurant/dashboard)
│   │   ├── KitchenTabletScreen (/app/restaurant/kitchen)
│   │   │   └── OrderDetailScreen (/app/restaurant/kitchen/order/:id)
│   │   ├── MenuEditorScreen (/app/restaurant/menu)
│   │   │   ├── CategoryEditorScreen (/app/restaurant/menu/category)
│   │   │   ├── ProductEditorScreen (/app/restaurant/menu/product)
│   │   │   └── ModifierEditorScreen (/app/restaurant/menu/modifier)
│   │   ├── OrdersManagementScreen (/app/restaurant/orders)
│   │   ├── RestaurantSettingsScreen (/app/restaurant/settings)
│   │   ├── RevenueAnalyticsScreen (/app/restaurant/analytics)
│   │   ├── StaffManagementScreen (/app/restaurant/staff)
│   │   └── RestaurantProfileScreen (/app/restaurant/profile)
│   │
│   ├── DriverApp (/app/driver)
│   │   ├── DriverDashboard (/app/driver/dashboard)
│   │   ├── AvailableOrdersScreen (/app/driver/orders/available)
│   │   ├── ActiveDeliveryScreen (/app/driver/delivery/active)
│   │   ├── DeliveryHistoryScreen (/app/driver/delivery/history)
│   │   ├── EarningsScreen (/app/driver/earnings)
│   │   ├── DriverProfileScreen (/app/driver/profile)
│   │   ├── DriverSettingsScreen (/app/driver/settings)
│   │   └── NavigationMapScreen (/app/driver/navigation/:orderId)
│   │
│   └── AdminApp (/app/admin)
│       ├── AdminDashboard (/app/admin/dashboard)
│       ├── UserManagementScreen (/app/admin/users)
│       │   ├── UserDetailScreen (/app/admin/users/:id)
│       │   └── BanUserScreen (/app/admin/users/:id/ban)
│       ├── RestaurantManagementScreen (/app/admin/restaurants)
│       │   ├── RestaurantDetailScreen (/app/admin/restaurants/:id)
│       │   ├── AddRestaurantScreen (/app/admin/restaurants/add)
│       │   └── EditRestaurantScreen (/app/admin/restaurants/:id/edit)
│       ├── DriverManagementScreen (/app/admin/drivers)
│       ├── AnalyticsDashboard (/app/admin/analytics)
│       ├── LiveMapScreen (/app/admin/map)
│       ├── SystemSettingsScreen (/app/admin/settings)
│       ├── KillSwitchScreen (/app/admin/kill-switch)
│       ├── CommissionsScreen (/app/admin/commissions)
│       ├── ReportsScreen (/app/admin/reports)
│       └── AdminProfileScreen (/app/admin/profile)
│
└── SharedRoutes
    ├── WebViewScreen (/web/:url)
    ├── ImageViewerScreen (/image-viewer)
    └── ErrorScreen (/error)
*/

// =====================================================
// ROUTE NAMES (Constants)
// =====================================================

class AppRoutes {
  // Splash
  static const String splash = '/';
  
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String registerPhone = '/auth/register/phone';
  static const String registerOtp = '/auth/register/otp';
  static const String registerProfile = '/auth/register/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String googleCallback = '/auth/google/callback';
  
  // Customer
  static const String customerHome = '/app/customer/home';
  static const String vendors = '/app/customer/vendors';
  static const String vendorDetail = '/app/customer/vendor';
  static const String productDetail = '/app/customer/product';
  static const String cart = '/app/customer/cart';
  static const String checkout = '/app/customer/checkout';
  static const String orderTracking = '/app/customer/order';
  static const String ordersHistory = '/app/customer/orders';
  static const String customerProfile = '/app/customer/profile';
  static const String addresses = '/app/customer/addresses';
  static const String addAddress = '/app/customer/addresses/add';
  static const String customerSettings = '/app/customer/settings';
  static const String customerChat = '/app/customer/chat';
  static const String customerSearch = '/app/customer/search';
  
  // Restaurant
  static const String restaurantDashboard = '/app/restaurant/dashboard';
  static const String kitchenTablet = '/app/restaurant/kitchen';
  static const String kitchenOrderDetail = '/app/restaurant/kitchen/order';
  static const String menuEditor = '/app/restaurant/menu';
  static const String categoryEditor = '/app/restaurant/menu/category';
  static const String productEditor = '/app/restaurant/menu/product';
  static const String modifierEditor = '/app/restaurant/menu/modifier';
  static const String restaurantOrders = '/app/restaurant/orders';
  static const String restaurantSettings = '/app/restaurant/settings';
  static const String restaurantAnalytics = '/app/restaurant/analytics';
  static const String restaurantStaff = '/app/restaurant/staff';
  static const String restaurantProfile = '/app/restaurant/profile';
  
  // Driver
  static const String driverDashboard = '/app/driver/dashboard';
  static const String driverOrders = '/app/driver/orders/available';
  static const String activeDelivery = '/app/driver/delivery/active';
  static const String deliveryHistory = '/app/driver/delivery/history';
  static const String driverEarnings = '/app/driver/earnings';
  static const String driverProfile = '/app/driver/profile';
  static const String driverSettings = '/app/driver/settings';
  static const String driverNavigation = '/app/driver/navigation';
  
  // Admin
  static const String adminDashboard = '/app/admin/dashboard';
  static const String adminUsers = '/app/admin/users';
  static const String userDetail = '/app/admin/users';
  static const String adminRestaurants = '/app/admin/restaurants';
  static const String restaurantDetail = '/app/admin/restaurants';
  static const String addRestaurant = '/app/admin/restaurants/add';
  static const String editRestaurant = '/app/admin/restaurants/edit';
  static const String adminDrivers = '/app/admin/drivers';
  static const String adminAnalytics = '/app/admin/analytics';
  static const String adminMap = '/app/admin/map';
  static const String adminSettings = '/app/admin/settings';
  static const String killSwitch = '/app/admin/kill-switch';
  static const String adminCommissions = '/app/admin/commissions';
  static const String adminReports = '/app/admin/reports';
  static const String adminProfile = '/app/admin/profile';
}

// =====================================================
// NAVIGATOR KEYS (For deep linking)
// =====================================================

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> authNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> customerNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> restaurantNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> driverNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> adminNavigatorKey = GlobalKey<NavigatorState>();

// =====================================================
// ROUTE GENERATOR
// =====================================================

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    // Splash
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    
    // Auth
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());
    case AppRoutes.registerPhone:
      return MaterialPageRoute(builder: (_) => const PhoneInputScreen());
    case AppRoutes.registerOtp:
      return MaterialPageRoute(builder: (_) => const OTPVerificationScreen());
    case AppRoutes.registerProfile:
      return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
    case AppRoutes.forgotPassword:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
    
    // Customer
    case AppRoutes.customerHome:
      return MaterialPageRoute(builder: (_) => const CustomerHomeScreen());
    case AppRoutes.vendors:
      return MaterialPageRoute(builder: (_) => const VendorsScreen());
    case AppRoutes.vendorDetail:
      final vendorId = settings.arguments as String;
      return MaterialPageRoute(builder: (_) => VendorDetailScreen(vendorId: vendorId));
    case AppRoutes.cart:
      return MaterialPageRoute(builder: (_) => const CartScreen());
    case AppRoutes.checkout:
      return MaterialPageRoute(builder: (_) => const CheckoutScreen());
    
    // ... Continue with other routes
    default:
      return MaterialPageRoute(
        builder: (_) => ErrorScreen(message: 'Route not found: ${settings.name}'),
      );
  }
}

// =====================================================
// SCREEN LIST (To be implemented)
// =====================================================

/*
SCREENS TO IMPLEMENT:

1. Auth Screens:
   - SplashScreen ✓ (Exists)
   - LoginScreen ✓ (Exists)
   - RegisterScreen (New)
   - PhoneInputScreen (New)
   - OTPVerificationScreen (New)
   - ProfileSetupScreen (New)
   - ForgotPasswordScreen (New)

2. Customer Screens:
   - CustomerHomeScreen ✓ (Exists)
   - VendorsScreen ✓ (Exists)
   - VendorDetailScreen (Need upgrade)
   - ProductDetailScreen (New)
   - CartScreen ✓ (Exists)
   - CheckoutScreen (Need upgrade)
   - OrderTrackingScreen (New)
   - OrdersHistoryScreen ✓ (Exists)
   - CustomerProfileScreen ✓ (Exists)
   - AddressesScreen (New)
   - AddAddressScreen (New)
   - SettingsScreen ✓ (Exists)
   - ChatScreen (New)
   - SearchScreen (New)

3. Restaurant Screens:
   - RestaurantDashboard ✓ (Exists)
   - KitchenTabletScreen (New)
   - OrderDetailScreen (New)
   - MenuEditorScreen (New)
   - CategoryEditorScreen (New)
   - ProductEditorScreen (New)
   - ModifierEditorScreen (New)
   - OrdersManagementScreen (New)
   - RestaurantSettingsScreen (New)
   - RevenueAnalyticsScreen (New)
   - StaffManagementScreen (New)
   - RestaurantProfileScreen (New)

4. Driver Screens:
   - DriverDashboard ✓ (Exists)
   - AvailableOrdersScreen (New)
   - ActiveDeliveryScreen (New)
   - DeliveryHistoryScreen (New)
   - EarningsScreen (New)
   - DriverProfileScreen (New)
   - DriverSettingsScreen (New)
   - NavigationMapScreen (New)

5. Admin Screens:
   - AdminDashboard ✓ (Exists)
   - UserManagementScreen (New)
   - UserDetailScreen (New)
   - RestaurantManagementScreen (New)
   - DriverManagementScreen (New)
   - AnalyticsDashboard (New)
   - LiveMapScreen (New)
   - SystemSettingsScreen (New)
   - KillSwitchScreen (New)
   - CommissionsScreen (New)
   - ReportsScreen (New)
   - AdminProfileScreen (New)

6. Shared Screens:
   - WebViewScreen (New)
   - ImageViewerScreen (New)
   - ErrorScreen (New)
*/