import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'screens/active_delivery_screen.dart';
import 'screens/available_requests_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/driver_earnings_screen.dart';
import 'screens/driver_safety_screen.dart';
import 'screens/driver_wallet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
    runApp(const DriverApp());
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

class DriverApp extends StatefulWidget {
  const DriverApp({super.key});
  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
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
        AppRouter.route('/dashboard', const AuthStateRedirector(child: DriverDashboardScreen()), name: 'dashboard'),
        AppRouter.route('/available-requests', const AvailableRequestsScreen(), name: 'availableRequests'),
        AppRouter.route('/earnings', const DriverEarningsScreen(), name: 'earnings'),
        AppRouter.route('/wallet', const DriverWalletScreen(), name: 'wallet'),
        AppRouter.route('/safety', const DriverSafetyScreen(), name: 'safety'),
        GoRoute(
          path: '/active-delivery/:id',
          name: 'activeDelivery',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: ActiveDeliveryScreen(requestId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/active-delivery-food/:id',
          name: 'activeDeliveryFood',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: ActiveDeliveryScreen(
              requestId: state.pathParameters['id']!,
              deliveryType: 'food',
            ),
          ),
        ),
        AppRouter.route('/profile', const ProfileScreen(), name: 'profile'),
        AppRouter.route('/settings', const SettingsScreen(), name: 'settings'),
      ],
      redirect: _redirect,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    return appRedirect(
      location: state.matchedLocation,
      allowedRoles: [UserRole.driver, UserRole.superAdmin],
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
        ChangeNotifierProvider(create: (_) => LocaleProvider('en')),
        ChangeNotifierProvider(create: (_) => AnythingProvider()),
        ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
        ChangeNotifierProvider(create: (_) => DispatchProvider()),
      ],
      child: _DispatchLifecycle(
        child: ErrorBoundary(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'TayyebGo - Driver',
            theme: _buildTheme(),
            routerConfig: _router,
          ),
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

class _DispatchLifecycle extends StatefulWidget {
  final Widget child;
  const _DispatchLifecycle({required this.child});

  @override
  State<_DispatchLifecycle> createState() => _DispatchLifecycleState();
}

class _DispatchLifecycleState extends State<_DispatchLifecycle> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<DispatchProvider>().startListening(user.id);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
