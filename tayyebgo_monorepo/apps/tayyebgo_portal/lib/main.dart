import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
// Dashboard screens from each app
import 'package:tayyebgo_customer/screens/customer_main_screen.dart';
import 'package:tayyebgo_customer/screens/cart/cart_screen.dart';
import 'package:tayyebgo_customer/screens/checkout/checkout_screen.dart';
import 'package:tayyebgo_customer/screens/menu/restaurant_menu_screen.dart';
import 'package:tayyebgo_customer/screens/order_history_screen.dart';
import 'package:tayyebgo_customer/screens/address_management_screen.dart';
import 'package:tayyebgo_customer/screens/tracking/order_tracking_screen.dart';
import 'package:tayyebgo_customer/screens/explore_screen.dart';
import 'package:tayyebgo_customer/screens/customer_wallet_screen.dart';
import 'package:tayyebgo_customer/screens/anything_request_screen.dart';
import 'package:tayyebgo_customer/providers/subscription_provider.dart';
import 'package:tayyebgo_partner/screens/partner_gatekeeper.dart';
import 'package:tayyebgo_partner/screens/partner_settings_screen.dart';
import 'package:tayyebgo_partner/screens/partner_menu_management_screen.dart';
import 'package:tayyebgo_partner/screens/partner_dispatch_center_screen.dart';
import 'package:tayyebgo_partner/screens/partner_analytics_screen.dart';
import 'package:tayyebgo_partner/screens/partner_payouts_screen.dart';
import 'package:tayyebgo_partner/screens/partner_orders_screen.dart';
import 'package:tayyebgo_partner/providers/offline_queue_provider.dart';
import 'package:tayyebgo_partner/providers/partner_role_controller.dart';
import 'package:tayyebgo_driver/screens/driver_dashboard_screen.dart';
import 'package:tayyebgo_driver/screens/driver_shell_screen.dart';
import 'package:tayyebgo_driver/screens/available_requests_screen.dart';
import 'package:tayyebgo_driver/screens/driver_earnings_screen.dart';
import 'package:tayyebgo_driver/screens/driver_wallet_screen.dart';
import 'package:tayyebgo_driver/screens/driver_safety_screen.dart';
import 'package:tayyebgo_driver/screens/driver_profile_screen.dart';
import 'package:tayyebgo_driver/screens/delivery_history_screen.dart';
import 'package:tayyebgo_driver/screens/active_delivery_screen.dart';
import 'package:tayyebgo_admin/features/dashboard/admin_dashboard_screen.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
    AppLocator.instance.init();
    runApp(const TayyebGoPortal());
  } catch (e, s) {
    if (kDebugMode) print('[PORTAL ERROR] $e\n$s');
    runApp(_ErrorApp(message: 'Unable to start. Please check your connection.'));
  }
}

class _ErrorApp extends StatelessWidget {
  final String message;
  const _ErrorApp({required this.message});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text('Initialization Error', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class TayyebGoPortal extends StatefulWidget {
  const TayyebGoPortal({super.key});
  @override
  State<TayyebGoPortal> createState() => _TayyebGoPortalState();
}

class _TayyebGoPortalState extends State<TayyebGoPortal> {
  late final AuthListenable _authListenable;
  late final GoRouter _router;
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _authListenable = AuthListenable();
    _router = _buildRouter();
    _themeProvider = ThemeProvider();
  }

  @override
  void dispose() {
    _authListenable.dispose();
    _router.dispose();
    _themeProvider.dispose();
    super.dispose();
  }

  GoRouter _buildRouter() {
    return AppRouter.create(
      refreshListenable: _authListenable,
      initialLocation: '/',
      routes: [
        AppRouter.route('/', const LandingScreen(), name: 'landing'),
        AppRouter.route('/login', const LoginScreen(
          showSignUpLink: true,
          subtitle: 'Sign in to access your TayyebGo dashboard.',
        ), name: 'login'),
        AppRouter.route('/signup', const SignUpScreen(), name: 'signup'),
        AppRouter.route('/forgot-password', const ForgotPasswordScreen(), name: 'forgotPassword'),
        AppRouter.route('/privacy-policy', const PrivacyPolicyScreen(), name: 'privacyPolicy'),
        AppRouter.route('/terms-conditions', const TermsConditionsScreen(), name: 'termsConditions'),
        AppRouter.route('/help-support', const HelpSupportScreen(), name: 'helpSupport'),
        AppRouter.route('/access-denied', const AccessDeniedScreen(), name: 'accessDenied'),
        // Customer routes
        AppRouter.route('/customer/home', AuthStateRedirector(allowedRoles: UserRole.customerRoles, child: const CustomerMainScreen()), name: 'customerHome'),
        AppRouter.route('/customer/checkout', const CheckoutScreen(), name: 'customerCheckout'),
        AppRouter.route('/customer/cart', const CartScreen(), name: 'customerCart'),
        AppRouter.route('/customer/order-history', const OrderHistoryScreen(), name: 'customerOrderHistory'),
        AppRouter.route('/customer/addresses', const AddressManagementScreen(), name: 'customerAddresses'),
        AppRouter.route('/customer/explore', const ExploreScreen(), name: 'customerExplore'),
        AppRouter.route('/customer/wallet', const CustomerWalletScreen(), name: 'customerWallet'),
        AppRouter.route('/customer/settings', const SettingsScreen(), name: 'customerSettings'),
        AppRouter.route('/customer/notifications', const NotificationsScreen(), name: 'customerNotifications'),
        AppRouter.route('/customer/anything-request', const AnythingRequestScreen(), name: 'customerAnythingRequest'),
        GoRoute(
          path: '/customer/tracking/:orderId',
          name: 'customerTracking',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
          ),
        ),
        GoRoute(
          path: '/customer/restaurant/:id',
          name: 'customerRestaurant',
          pageBuilder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return SlideTransitionPage(
              page: RestaurantMenuScreen(
                restaurantId: state.pathParameters['id']!,
                restaurantName: extra['name'] as String? ?? 'Restaurant',
                commissionPercent: (extra['commissionPercent'] as num?)?.toDouble() ?? 15.0,
              ),
            );
          },
        ),
        // Partner routes
        AppRouter.route('/partner/dashboard', AuthStateRedirector(allowedRoles: UserRole.partnerRoles, child: const PartnerGatekeeper()), name: 'partnerDashboard'),
        AppRouter.route('/partner/settings', const PartnerSettingsScreen(), name: 'partnerSettings'),
        AppRouter.route('/partner/dispatch-center', const PartnerDispatchCenterScreen(), name: 'partnerDispatchCenter'),
        AppRouter.route('/partner/analytics', const PartnerAnalyticsScreen(), name: 'partnerAnalytics'),
        AppRouter.route('/partner/payouts', const PartnerPayoutsScreen(), name: 'partnerPayouts'),
        AppRouter.route('/partner/orders', const PartnerOrdersScreen(), name: 'partnerOrders'),
        GoRoute(
          path: '/partner/menu/:id',
          name: 'partnerMenu',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: PartnerMenuManagementScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
        // Driver routes
        ShellRoute(
          builder: (context, state, child) => DriverShellScreen(child: child),
          routes: [
            AppRouter.route('/driver/dashboard', AuthStateRedirector(allowedRoles: UserRole.driverRoles, child: const DriverDashboardScreen()), name: 'driverDashboard'),
            AppRouter.route('/driver/available-requests', const AvailableRequestsScreen(), name: 'driverAvailableRequests'),
            AppRouter.route('/driver/earnings', const DriverEarningsScreen(), name: 'driverEarnings'),
            AppRouter.route('/driver/profile', const DriverProfileScreen(), name: 'driverProfile'),
          ],
        ),
        AppRouter.route('/driver/wallet', const DriverWalletScreen(), name: 'driverWallet'),
        AppRouter.route('/driver/safety', const DriverSafetyScreen(), name: 'driverSafety'),
        AppRouter.route('/driver/delivery-history', const DeliveryHistoryScreen(), name: 'driverDeliveryHistory'),
        GoRoute(
          path: '/driver/active-delivery/:id',
          name: 'driverActiveDelivery',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: ActiveDeliveryScreen(requestId: state.pathParameters['id']!),
          ),
        ),
        // Admin routes
        AppRouter.route('/admin/dashboard', AuthStateRedirector(allowedRoles: UserRole.adminRoles, child: const AdminDashboardScreen()), name: 'adminDashboard'),
      ],
      redirect: _redirect,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final auth = AuthProvider.instance;
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    final isLoggedIn = fbUser != null;

    // Always allow these routes
    if (location == '/login' || location == '/signup' || location == '/forgot-password') return null;
    if (location == '/privacy-policy' || location == '/terms-conditions' || location == '/help-support') return null;
    if (location == '/access-denied') return null;

    // Not logged in → login
    if (!isLoggedIn) return '/login';

    // Auth still loading
    if (auth == null || auth.isLoading) return null;

    // No user model yet
    if (auth.user == null) return null;

    // Account disabled
    if (!auth.user!.isActive) {
      return '/access-denied?reason=disabled&currentRole=${auth.user!.role.value}';
    }

    // Login/signup while logged in → role home
    if (location == '/login' || location == '/signup') {
      return _roleHomePath(auth.user!.role);
    }

    // Check role prefix
    final rolePrefix = _roleRoutePrefix(auth.user!.role);
    if (!location.startsWith(rolePrefix)) {
      return '$rolePrefix/dashboard';
    }

    return null;
  }

  String _roleHomePath(UserRole role) => switch (role) {
    UserRole.superAdmin => '/admin/dashboard',
    UserRole.restaurantOwner || UserRole.cashier => '/partner/dashboard',
    UserRole.driver => '/driver/dashboard',
    UserRole.customer => '/customer/home',
  };

  String _roleRoutePrefix(UserRole role) => switch (role) {
    UserRole.superAdmin => '/admin',
    UserRole.restaurantOwner || UserRole.cashier => '/partner',
    UserRole.driver => '/driver',
    UserRole.customer => '/customer',
  };

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider(create: (_) => CartProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AnythingProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AddressProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => CustomerHomeProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => OfflineQueueProvider()..load(), lazy: true),
        ChangeNotifierProvider(create: (ctx) => PartnerRoleController(ctx.read<AuthProvider>()), lazy: true),
        ChangeNotifierProvider(create: (_) => PartnerHomeProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DriverWalletProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DispatchProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AdminStatsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserProfileProvider(), lazy: true),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'TayyebGo Portal',
             theme: TayyebGoTheme.lightTheme(),
             darkTheme: TayyebGoTheme.darkTheme(),
            themeMode: theme.mode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
