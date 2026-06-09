import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'screens/active_delivery_screen.dart';
import 'screens/available_requests_screen.dart';
import 'screens/driver_earnings_screen.dart';
import 'screens/driver_wallet_screen.dart';
import 'screens/driver_safety_screen.dart';
import 'screens/driver_onboarding_screen.dart';
import 'screens/driver_profile_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/driver_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
    AppLocator.instance.init();
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
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Initialization Error', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
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
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _authListenable = AuthListenable();
    _router = _buildRouter();
    _themeProvider = ThemeProvider();
  }

  GoRouter _buildRouter() {
    return AppRouter.create(
      refreshListenable: _authListenable,
      initialLocation: '/splash',
      routes: [
        AppRouter.route('/splash', const DriverSplashScreen(), name: 'splash'),
        AppRouter.route('/login', const LoginScreen(), name: 'login'),
        AppRouter.route('/signup', const SignUpScreen(), name: 'signup'),
        AppRouter.route('/onboarding', const DriverOnboardingScreen(), name: 'onboarding'),
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
        AppRouter.route('/profile', const DriverProfileScreen(), name: 'profile'),
        AppRouter.route('/settings', const SettingsScreen(), name: 'settings'),
        AppRouter.route('/notifications', const NotificationsScreen(), name: 'notifications'),
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
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Essential providers - initialized immediately
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
        // Lazy-loaded providers - only created when accessed
        ChangeNotifierProvider(create: (_) => LocaleProvider('en'), lazy: true),
        ChangeNotifierProvider(create: (_) => AnythingProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DriverWalletProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DispatchProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserProfileProvider(), lazy: true),
      ],
      child: _DispatchLifecycle(
        child: ErrorBoundary(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'TayyebGo - Driver',
            theme: TayyebGoTheme.lightTheme(context),
            darkTheme: TayyebGoTheme.darkTheme(context),
            themeMode: _themeProvider.mode,
            routerConfig: _router,
          ),
        ),
      ),
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
