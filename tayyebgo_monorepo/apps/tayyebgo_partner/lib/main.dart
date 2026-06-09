import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'providers/offline_queue_provider.dart';
import 'providers/partner_role_controller.dart';
import 'screens/partner_gatekeeper.dart';
import 'screens/ai_menu_creation_screen.dart';
import 'screens/store_customization_screen.dart';
import 'screens/kitchen_mode_screen.dart';
import 'screens/partner_onboarding_screen.dart';
import 'screens/partner_dispatch_center_screen.dart';
import 'screens/partner_marketing_center_screen.dart';
import 'screens/partner_settings_screen.dart';
import 'screens/partner_menu_management_screen.dart';
import 'screens/partner_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
    SyncEngine.instance.start();
    AppLocator.instance.init();
    runApp(const PartnerApp());
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
                Text('Initialization Error',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PartnerApp extends StatefulWidget {
  const PartnerApp({super.key});
  @override
  State<PartnerApp> createState() => _PartnerAppState();
}

class _PartnerAppState extends State<PartnerApp> {
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
        AppRouter.route('/splash', const PartnerSplashScreen(), name: 'splash'),
        AppRouter.route('/login', const LoginScreen(), name: 'login'),
        AppRouter.route('/onboarding', const PartnerOnboardingScreen(), name: 'onboarding'),
        AppRouter.route('/dashboard', const AuthStateRedirector(child: PartnerGatekeeper()), name: 'dashboard'),
        AppRouter.route('/profile', const ProfileScreen(), name: 'profile'),
        AppRouter.route('/settings', const PartnerSettingsScreen(), name: 'settings'),
        AppRouter.route('/notifications', const NotificationsScreen(), name: 'notifications'),
        AppRouter.route('/dispatch-center', const PartnerDispatchCenterScreen(), name: 'dispatchCenter'),
        AppRouter.route('/marketing-center', const PartnerMarketingCenterScreen(), name: 'marketingCenter'),
        GoRoute(
          path: '/menu/:id',
          name: 'menu',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: PartnerMenuManagementScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/ai-menu/:id',
          name: 'aiMenu',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: AiMenuCreationScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/customize/:id',
          name: 'customize',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: StoreCustomizationScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/kitchen/:id',
          name: 'kitchen',
          pageBuilder: (_, state) => SlideTransitionPage(
            page: KitchenModeScreen(restaurantId: state.pathParameters['id']!),
          ),
        ),
      ],
      redirect: _redirect,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    return appRedirect(
      location: state.matchedLocation,
      allowedRoles: [UserRole.restaurantOwner, UserRole.cashier, UserRole.superAdmin],
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
        // Essential providers - initialized immediately
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
        // Lazy-loaded providers - only created when accessed
        ChangeNotifierProvider(create: (_) => LocaleProvider('en'), lazy: true),
        ChangeNotifierProvider(create: (_) => OfflineQueueProvider()..load(), lazy: true),
        ChangeNotifierProvider(create: (ctx) => PartnerRoleController(ctx.read<AuthProvider>()), lazy: true),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserProfileProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => PartnerHomeProvider(), lazy: true),
      ],
      child: ErrorBoundary(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'TayyebGo - Partner',
              theme: TayyebGoTheme.lightTheme(context),
              darkTheme: TayyebGoTheme.darkTheme(context),
              themeMode: themeProvider.mode,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
