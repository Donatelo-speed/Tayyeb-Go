import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'screens/anything_request_screen.dart';
import 'screens/anything_tracking_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/menu/restaurant_menu_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/tracking/order_tracking_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/customer_wallet_screen.dart';
import 'screens/customer_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
    AppLocator.instance.init();
    runApp(const CustomerApp());
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

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});
  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
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
      initialLocation: '/splash',
      routes: [
        AppRouter.route('/splash', const CustomerSplashScreen(), name: 'splash'),
        AppRouter.route('/login', const LoginScreen(), name: 'login'),
        AppRouter.route('/home', const AuthStateRedirector(child: CustomerHomeScreen()), name: 'home'),
        AppRouter.route('/checkout', const CheckoutScreen(), name: 'checkout'),
        AppRouter.route('/cart', const CartScreen(), name: 'cart'),
        AppRouter.route('/order-history', const OrderHistoryScreen(), name: 'orderHistory'),
        AppRouter.route('/profile', const ProfileScreen(), name: 'profile'),
        AppRouter.route('/explore', const ExploreScreen(), name: 'explore'),
        AppRouter.route('/wallet', const CustomerWalletScreen(), name: 'wallet'),
        AppRouter.route('/settings', const SettingsScreen(), name: 'settings'),
        AppRouter.route('/notifications', const NotificationsScreen(), name: 'notifications'),
        AppRouter.route('/anything-request', const AnythingRequestScreen(), name: 'anythingRequest'),
        GoRoute(
          path: '/anything-tracking/:id',
          name: 'anythingTracking',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: AnythingTrackingScreen(requestId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/restaurant/:id',
          name: 'restaurant',
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
          path: '/tracking/:orderId',
          name: 'tracking',
          pageBuilder: (_, state) {
            return SlideTransitionPage(
              page: OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
            );
          },
        ),
      ],
      redirect: _redirect,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    return appRedirect(
      location: state.matchedLocation,
      allowedRoles: [UserRole.customer, UserRole.superAdmin],
      auth: AuthProvider.instance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Essential providers - initialized immediately
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
        // Lazy-loaded providers - only created when accessed
        ChangeNotifierProvider(create: (_) => CartProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => LocaleProvider('en'), lazy: true),
        ChangeNotifierProvider(create: (_) => AnythingProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => AddressProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserProfileProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => CustomerHomeProvider(), lazy: true),
      ],
      child: ErrorBoundary(
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'TayyebGo',
              theme: TayyebGoTheme.lightTheme(context),
              darkTheme: TayyebGoTheme.darkTheme(context),
              themeMode: theme.mode,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
