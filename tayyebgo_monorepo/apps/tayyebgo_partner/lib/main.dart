import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'providers/offline_queue_provider.dart';
import 'providers/partner_role_controller.dart';
import 'screens/partner_gatekeeper.dart';
import 'screens/ai_menu_creation_screen.dart';
import 'screens/store_customization_screen.dart';
import 'screens/kitchen_mode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
    SyncEngine.instance.start();
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

class PartnerApp extends StatefulWidget {
  const PartnerApp({super.key});
  @override
  State<PartnerApp> createState() => _PartnerAppState();
}

class _PartnerAppState extends State<PartnerApp> {
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
        AppRouter.route('/dashboard', const AuthStateRedirector(child: PartnerGatekeeper()), name: 'dashboard'),
        AppRouter.route('/profile', const ProfileScreen(), name: 'profile'),
        AppRouter.route('/settings', const SettingsScreen(), name: 'settings'),
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider('en')),
        ChangeNotifierProvider(create: (_) => OfflineQueueProvider()..load()),
        ChangeNotifierProvider(create: (ctx) => PartnerRoleController(ctx.read<AuthProvider>())),
      ],
      child: ErrorBoundary(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'TayyebGo - Partner',
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
