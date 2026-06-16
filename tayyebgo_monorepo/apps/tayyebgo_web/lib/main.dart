import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
// Customer screens
import 'package:tayyebgo_customer/screens/customer_main_screen.dart';
import 'package:tayyebgo_customer/screens/cart/cart_screen.dart';
import 'package:tayyebgo_customer/screens/checkout/checkout_screen.dart';
import 'package:tayyebgo_customer/screens/menu/restaurant_menu_screen.dart';
import 'package:tayyebgo_customer/screens/order_history_screen.dart';
import 'package:tayyebgo_customer/screens/address_management_screen.dart';
import 'package:tayyebgo_customer/screens/reorder_screen.dart';
import 'package:tayyebgo_customer/screens/tracking/order_tracking_screen.dart';
import 'package:tayyebgo_customer/screens/explore_screen.dart';
import 'package:tayyebgo_customer/screens/customer_wallet_screen.dart';
import 'package:tayyebgo_customer/screens/membership_screen.dart';
import 'package:tayyebgo_customer/screens/referral_screen.dart';
import 'package:tayyebgo_customer/screens/gift_cards_screen.dart';
import 'package:tayyebgo_customer/screens/points_rewards_screen.dart';
import 'package:tayyebgo_customer/screens/tayyebgo_picks_screen.dart';
import 'package:tayyebgo_customer/screens/subscription/subscription_plans_screen.dart';
import 'package:tayyebgo_customer/screens/subscription/subscription_dashboard_screen.dart';
import 'package:tayyebgo_customer/screens/anything_request_screen.dart';
import 'package:tayyebgo_customer/screens/anything_tracking_screen.dart';
import 'package:tayyebgo_customer/providers/subscription_provider.dart';
// Partner screens
import 'package:tayyebgo_partner/screens/partner_gatekeeper.dart';
import 'package:tayyebgo_partner/screens/partner_settings_screen.dart';
import 'package:tayyebgo_partner/screens/partner_menu_management_screen.dart';
import 'package:tayyebgo_partner/screens/partner_dispatch_center_screen.dart';
import 'package:tayyebgo_partner/screens/partner_marketing_center_screen.dart';
import 'package:tayyebgo_partner/screens/partner_analytics_screen.dart';
import 'package:tayyebgo_partner/screens/partner_payouts_screen.dart';
import 'package:tayyebgo_partner/screens/partner_contracts_screen.dart';
import 'package:tayyebgo_partner/screens/partner_onboarding_screen.dart';
import 'package:tayyebgo_partner/screens/ai_menu_creation_screen.dart';
import 'package:tayyebgo_partner/screens/store_customization_screen.dart';
import 'package:tayyebgo_partner/screens/kitchen_mode_screen.dart';
import 'package:tayyebgo_partner/screens/store_theme_screen.dart';
import 'package:tayyebgo_partner/screens/modifier_builder_screen.dart';
import 'package:tayyebgo_partner/providers/offline_queue_provider.dart';
import 'package:tayyebgo_partner/providers/partner_role_controller.dart';
// Driver screens
import 'package:tayyebgo_driver/screens/driver_dashboard_screen.dart';
import 'package:tayyebgo_driver/screens/driver_shell_screen.dart';
import 'package:tayyebgo_driver/screens/available_requests_screen.dart';
import 'package:tayyebgo_driver/screens/driver_earnings_screen.dart';
import 'package:tayyebgo_driver/screens/driver_wallet_screen.dart';
import 'package:tayyebgo_driver/screens/driver_safety_screen.dart';
import 'package:tayyebgo_driver/screens/driver_profile_screen.dart';
import 'package:tayyebgo_driver/screens/driver_edit_profile_screen.dart';
import 'package:tayyebgo_driver/screens/driver_documents_screen.dart';
import 'package:tayyebgo_driver/screens/delivery_history_screen.dart';
import 'package:tayyebgo_driver/screens/driver_heatmap_screen.dart';
import 'package:tayyebgo_driver/screens/active_delivery_screen.dart';
import 'package:tayyebgo_driver/screens/driver_onboarding_screen.dart';
// Admin screens
import 'package:tayyebgo_admin/features/dashboard/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Do NOT set AuthProvider.defaultExpectedRole — let Firestore role drive routing
    AuthGateService.instance.init();
    SyncEngine.instance.start();
    AppLocator.instance.init();
    runApp(const TayyebGoWebApp());
  } catch (e, s) {
    if (kDebugMode) {
      print('[FIREBASE INIT ERROR] $e');
      print(s);
    }
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0x1AF87171),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 40, color: Color(0xFFF87171)),
                ),
                const SizedBox(height: 20),
                Text('Initialization Error',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: const Color(0xFFF8FAFC))),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TayyebGoWebApp extends StatefulWidget {
  const TayyebGoWebApp({super.key});
  @override
  State<TayyebGoWebApp> createState() => _TayyebGoWebAppState();
}

class _TayyebGoWebAppState extends State<TayyebGoWebApp> {
  late final AuthListenable _authListenable;
  late final GoRouter _router;
  late final ThemeProvider _themeProvider;
  LocaleProvider? _localeProvider;

  @override
  void initState() {
    super.initState();
    _authListenable = AuthListenable();
    _router = _buildRouter();
    _themeProvider = ThemeProvider();
    _initLocale();
  }

  Future<void> _initLocale() async {
    final lp = await LocaleProvider.create();
    if (mounted) setState(() => _localeProvider = lp);
  }

  @override
  void dispose() {
    _authListenable.dispose();
    _router.dispose();
    _themeProvider.dispose();
    _localeProvider?.dispose();
    super.dispose();
  }

  GoRouter _buildRouter() {
    return AppRouter.create(
      refreshListenable: _authListenable,
      initialLocation: '/splash',
      routes: [
        // ── Splash ──────────────────────────────────────────────
        AppRouter.route('/splash', const _UnifiedSplashScreen(), name: 'splash'),

        // ── Auth routes (shared) ────────────────────────────────
        AppRouter.route('/login', const LoginScreen(), name: 'login'),
        AppRouter.route('/signup', const SignUpScreen(), name: 'signup'),
        AppRouter.route('/forgot-password', const ForgotPasswordScreen(), name: 'forgotPassword'),
        AppRouter.route('/privacy-policy', const PrivacyPolicyScreen(), name: 'privacyPolicy'),
        AppRouter.route('/terms-conditions', const TermsConditionsScreen(), name: 'termsConditions'),
        AppRouter.route('/help-support', const HelpSupportScreen(), name: 'helpSupport'),

        // ── Customer routes ─────────────────────────────────────
        AppRouter.route('/customer/home', const CustomerMainScreen(), name: 'customerHome'),
        AppRouter.route('/customer/checkout', const CheckoutScreen(), name: 'customerCheckout'),
        AppRouter.route('/customer/cart', const CartScreen(), name: 'customerCart'),
        AppRouter.route('/customer/order-history', const OrderHistoryScreen(), name: 'customerOrderHistory'),
        AppRouter.route('/customer/addresses', const AddressManagementScreen(), name: 'customerAddresses'),
        GoRoute(
          path: '/customer/reorder/:id',
          name: 'customerReorder',
          builder: (_, state) => ReorderScreen(orderId: state.pathParameters['id']!),
        ),
        AppRouter.route('/customer/profile', const ProfileScreen(), name: 'customerProfile'),
        AppRouter.route('/customer/explore', const ExploreScreen(), name: 'customerExplore'),
        AppRouter.route('/customer/wallet', const CustomerWalletScreen(), name: 'customerWallet'),
        AppRouter.route('/customer/settings', const SettingsScreen(), name: 'customerSettings'),
        AppRouter.route('/customer/notifications', const NotificationsScreen(), name: 'customerNotifications'),
        AppRouter.route('/customer/membership', const MembershipScreen(), name: 'customerMembership'),
        AppRouter.route('/customer/subscription', const SubscriptionPlansScreen(), name: 'customerSubscription'),
        AppRouter.route('/customer/subscription/dashboard', const SubscriptionDashboardScreen(), name: 'customerSubscriptionDashboard'),
        AppRouter.route('/customer/referral', const ReferralScreen(), name: 'customerReferral'),
        AppRouter.route('/customer/gift-cards', const GiftCardsScreen(), name: 'customerGiftCards'),
        AppRouter.route('/customer/points-rewards', const PointsRewardsScreen(), name: 'customerPointsRewards'),
        AppRouter.route('/customer/picks', const TayyebGoPicksScreen(), name: 'customerPicks'),
        AppRouter.route('/customer/anything-request', const AnythingRequestScreen(), name: 'customerAnythingRequest'),
        GoRoute(
          path: '/customer/anything-tracking/:id',
          name: 'customerAnythingTracking',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: AnythingTrackingScreen(requestId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/customer/restaurant/:id',
          name: 'customerRestaurant',
          pageBuilder: (_, state) {
            final id = state.pathParameters['id']!;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return SlideTransitionPage(
              page: RestaurantMenuScreen(
                restaurantId: id,
                restaurantName: extra['name'] as String? ?? 'Restaurant',
                commissionPercent: (extra['commissionPercent'] as num?)?.toDouble() ?? 15.0,
              ),
            );
          },
        ),
        GoRoute(
          path: '/customer/tracking/:orderId',
          name: 'customerTracking',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
          ),
        ),

        // ── Partner routes ──────────────────────────────────────
        AppRouter.route('/partner/dashboard', const PartnerGatekeeper(), name: 'partnerDashboard'),
        AppRouter.route('/partner/profile', const ProfileScreen(), name: 'partnerProfile'),
        AppRouter.route('/partner/settings', const PartnerSettingsScreen(), name: 'partnerSettings'),
        AppRouter.route('/partner/notifications', const NotificationsScreen(), name: 'partnerNotifications'),
        AppRouter.route('/partner/dispatch-center', const PartnerDispatchCenterScreen(), name: 'partnerDispatchCenter'),
        AppRouter.route('/partner/marketing-center', const PartnerMarketingCenterScreen(), name: 'partnerMarketingCenter'),
        AppRouter.route('/partner/contracts', const PartnerContractsScreen(), name: 'partnerContracts'),
        AppRouter.route('/partner/payouts', const PartnerPayoutsScreen(), name: 'partnerPayouts'),
        AppRouter.route('/partner/analytics', const PartnerAnalyticsScreen(), name: 'partnerAnalytics'),
        AppRouter.route('/partner/store-theme', const StoreThemeScreen(), name: 'partnerStoreTheme'),
        AppRouter.route('/partner/onboarding', const PartnerOnboardingScreen(), name: 'partnerOnboarding'),
        GoRoute(
          path: '/partner/menu/:id',
          name: 'partnerMenu',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: PartnerMenuManagementScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/partner/modifiers/:itemId',
          name: 'partnerModifiers',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: ModifierBuilderScreen(menuItemId: state.pathParameters['itemId']!),
          ),
        ),
        GoRoute(
          path: '/partner/ai-menu/:id',
          name: 'partnerAiMenu',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: AiMenuCreationScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/partner/customize/:id',
          name: 'partnerCustomize',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: StoreCustomizationScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/partner/kitchen/:id',
          name: 'partnerKitchen',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: KitchenModeScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),

        // ── Driver routes ───────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => DriverShellScreen(child: child),
          routes: [
            AppRouter.route('/driver/dashboard', const DriverDashboardScreen(), name: 'driverDashboard'),
            AppRouter.route('/driver/available-requests', const AvailableRequestsScreen(), name: 'driverAvailableRequests'),
            AppRouter.route('/driver/earnings', const DriverEarningsScreen(), name: 'driverEarnings'),
            AppRouter.route('/driver/profile', const DriverProfileScreen(), name: 'driverProfile'),
          ],
        ),
        AppRouter.route('/driver/wallet', const DriverWalletScreen(), name: 'driverWallet'),
        AppRouter.route('/driver/safety', const DriverSafetyScreen(), name: 'driverSafety'),
        AppRouter.route('/driver/heatmap', const DriverHeatMapScreen(), name: 'driverHeatmap'),
        AppRouter.route('/driver/delivery-history', const DeliveryHistoryScreen(), name: 'driverDeliveryHistory'),
        AppRouter.route('/driver/edit-profile', const DriverEditProfileScreen(), name: 'driverEditProfile'),
        AppRouter.route('/driver/documents', const DriverDocumentsScreen(), name: 'driverDocuments'),
        AppRouter.route('/driver/settings', const SettingsScreen(), name: 'driverSettings'),
        AppRouter.route('/driver/notifications', const NotificationsScreen(), name: 'driverNotifications'),
        AppRouter.route('/driver/onboarding', const DriverOnboardingScreen(), name: 'driverOnboarding'),
        GoRoute(
          path: '/driver/active-delivery/:id',
          name: 'driverActiveDelivery',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: ActiveDeliveryScreen(requestId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/driver/active-delivery-food/:id',
          name: 'driverActiveDeliveryFood',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: ActiveDeliveryScreen(
              requestId: state.pathParameters['id']!,
              deliveryType: 'food',
            ),
          ),
        ),

        // ── Admin routes ────────────────────────────────────────
        AppRouter.route('/admin/dashboard', const AdminDashboardScreen(), name: 'adminDashboard'),
        AppRouter.route('/admin/profile', const AdminDashboardScreen(), name: 'adminProfile'),
        AppRouter.route('/admin/settings', const AdminDashboardScreen(), name: 'adminSettings'),
        AppRouter.route('/admin/notifications', const NotificationsScreen(), name: 'adminNotifications'),
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

    // Not logged in → login page (including splash)
    if (!isLoggedIn) {
      if (location == '/splash') return null; // let splash show briefly
      return '/login';
    }

    // Auth still loading → stay on current page
    if (auth == null || auth.isLoading) return null;

    // Logged in but no user model yet → wait
    if (auth.user == null) return null;

    // Account disabled → access denied
    if (!auth.user!.isActive) {
      return '/access-denied?reason=disabled&currentRole=${auth.user!.role.value}';
    }

    // Splash → redirect to role home
    if (location == '/splash') {
      return _roleHomePath(auth.user!.role);
    }

    // Login/signup while logged in → role home
    if (location == '/login' || location == '/signup') {
      return _roleHomePath(auth.user!.role);
    }

    // Check if the route prefix matches the user's role
    final rolePrefix = _roleRoutePrefix(auth.user!.role);
    if (!location.startsWith(rolePrefix)) {
      return '$rolePrefix/dashboard';
    }

    return null;
  }

  String _roleHomePath(UserRole role) {
    return switch (role) {
      UserRole.superAdmin => '/admin/dashboard',
      UserRole.restaurantOwner || UserRole.cashier => '/partner/dashboard',
      UserRole.driver => '/driver/dashboard',
      UserRole.customer => '/customer/home',
    };
  }

  String _roleRoutePrefix(UserRole role) {
    return switch (role) {
      UserRole.superAdmin => '/admin',
      UserRole.restaurantOwner || UserRole.cashier => '/partner',
      UserRole.driver => '/driver',
      UserRole.customer => '/customer',
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _localeProvider ?? LocaleProvider(const Locale('en'))),
        // Customer providers
        ChangeNotifierProvider(create: (_) => CartProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AnythingProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AddressProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => CustomerHomeProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider(), lazy: true),
        // Partner providers
        ChangeNotifierProvider(create: (_) => OfflineQueueProvider()..load(), lazy: true),
        ChangeNotifierProvider(create: (ctx) => PartnerRoleController(ctx.read<AuthProvider>()), lazy: true),
        ChangeNotifierProvider(create: (_) => PartnerHomeProvider(), lazy: true),
        // Driver providers
        ChangeNotifierProvider(create: (_) => DriverWalletProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DispatchProvider(), lazy: true),
        // Admin providers
        ChangeNotifierProvider(create: (_) => AdminStatsProvider(), lazy: true),
        // Shared providers
        ChangeNotifierProvider(create: (_) => NotificationsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserProfileProvider(), lazy: true),
      ],
      child: ErrorBoundary(
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) {
            return Consumer<LocaleProvider>(
              builder: (context, localeProv, _) {
                final locale = _localeProvider?.locale ?? const Locale('en');
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'TayyebGo',
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  localeResolutionCallback: (locale, supportedLocales) {
                    for (final supported in supportedLocales) {
                      if (locale?.languageCode == supported.languageCode) {
                        return supported;
                      }
                    }
                    return supportedLocales.first;
                  },
                  theme: TayyebGoTheme.lightTheme(context),
                  darkTheme: TayyebGoTheme.darkTheme(context),
                  themeMode: theme.mode,
                  routerConfig: _router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UnifiedSplashScreen extends StatefulWidget {
  const _UnifiedSplashScreen();
  @override
  State<_UnifiedSplashScreen> createState() => _UnifiedSplashScreenState();
}

class _UnifiedSplashScreenState extends State<_UnifiedSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        final auth = AuthProvider.instance;
        final fbUser = fb.FirebaseAuth.instance.currentUser;
        if (fbUser != null && auth != null && auth.user != null && auth.user!.isActive) {
          final role = auth.user!.role;
          final home = switch (role) {
            UserRole.superAdmin => '/admin/dashboard',
            UserRole.restaurantOwner || UserRole.cashier => '/partner/dashboard',
            UserRole.driver => '/driver/dashboard',
            UserRole.customer => '/customer/home',
          };
          context.go(home);
        } else {
          context.go('/login');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.delivery_dining_rounded, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'TayyebGo',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 32,
                color: const Color(0xFFF97316),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your delivery, your way',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFF97316),
            ),
          ],
        ),
      ),
    );
  }
}
