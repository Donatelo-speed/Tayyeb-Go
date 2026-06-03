import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
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

  @override
  void initState() {
    super.initState();
    _authListenable = AuthListenable();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return AppRouter.create(
      refreshListenable: _authListenable,
      initialLocation: '/splash',
      routes: [
        AppRouter.route('/login', const LoginScreen(), name: 'login'),
        AppRouter.route('/home', const AuthStateRedirector(child: CustomerHomeScreen()), name: 'home'),
        AppRouter.route('/checkout', const CheckoutScreen(), name: 'checkout'),
        AppRouter.route('/cart', const CartScreen(), name: 'cart'),
        AppRouter.route('/order-history', const OrderHistoryScreen(), name: 'orderHistory'),
        AppRouter.route('/profile', const ProfileScreen(), name: 'profile'),
        AppRouter.route('/settings', const SettingsScreen(), name: 'settings'),
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
  void dispose() {
    _authListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider('en')),
        ChangeNotifierProvider(create: (_) => AnythingProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
      ],
      child: ErrorBoundary(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'TayyebGo - Customer',
          theme: _buildTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TayyebGoTheme.primaryColor,
        primary: TayyebGoTheme.primaryColor,
      ),
      scaffoldBackgroundColor: TayyebGoTheme.backgroundColor,
      appBarTheme: TayyebGoTheme.appBarTheme,
      inputDecorationTheme: TayyebGoTheme.inputDecoration,
      elevatedButtonTheme: TayyebGoTheme.elevatedButton,
    );
  }
}
