import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/dashboard/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthGateService.instance.init();
    runApp(const AdminApp());
  } catch (e, s) {
    if (kDebugMode) {
      print('[FIREBASE INIT ERROR] $e');
      print(s);
    }
    runApp(
      _ErrorApp(message: 'Unable to start. Please check your connection.'),
    );
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
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});
  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final AuthProvider _authProvider;
  late final AuthListenable _authListenable;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authListenable = AuthListenable();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return AppRouter.create(
      refreshListenable: _authListenable,
      initialLocation: '/splash',
      routes: [
        AppRouter.route('/login', const LoginScreen(), name: 'login'),
        AppRouter.route(
          '/forgot-password',
          const ForgotPasswordScreen(),
          name: 'forgot-password',
        ),
        AppRouter.route(
          '/dashboard',
          const AuthStateRedirector(child: AdminDashboardScreen()),
          name: 'dashboard',
        ),
        AppRouter.route('/profile', const AuthStateRedirector(child: AdminDashboardScreen()), name: 'profile'),
        AppRouter.route('/settings', const AuthStateRedirector(child: AdminDashboardScreen()), name: 'settings'),
      ],
      redirect: _redirect,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    return appRedirect(
      location: state.matchedLocation,
      allowedRoles: [UserRole.superAdmin],
      auth: AuthProvider.instance,
    );
  }

  @override
  void dispose() {
    _authListenable.dispose();
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => LocaleProvider('en')),
        ChangeNotifierProvider(create: (_) => AdminStatsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ErrorBoundary(
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'TayyebGo - Admin',
              theme: TayyebGoTheme.lightTheme(context),
              darkTheme: TayyebGoTheme.darkTheme(context),
              themeMode: themeProvider.mode,
              routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}
