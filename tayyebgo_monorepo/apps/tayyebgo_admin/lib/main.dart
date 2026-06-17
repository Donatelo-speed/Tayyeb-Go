import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart' hide ForgotPasswordScreen;
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/admin_splash_screen.dart';
import 'features/dashboard/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthProvider.defaultExpectedRole = UserRole.superAdmin;
    AuthGateService.instance.init();
    TestAccountSeeder.instance.seedIfNeeded();
    AppLocator.instance.init();
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
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
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
  LocaleProvider? _localeProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authListenable = AuthListenable();
    _router = _buildRouter();
    _initLocale();
  }

  Future<void> _initLocale() async {
    final lp = await LocaleProvider.create();
    if (mounted) setState(() => _localeProvider = lp);
  }

  GoRouter _buildRouter() {
    return AppRouter.create(
      refreshListenable: _authListenable,
      initialLocation: '/splash',
      routes: [
        AppRouter.route('/splash', const AdminSplashScreen(), name: 'splash'),
        AppRouter.route('/login', const LoginScreen(
          showSignUpLink: false,
          subtitle: 'Monitor and manage the entire platform.',
        ), name: 'login'),
        AppRouter.route(
          '/forgot-password',
          const ForgotPasswordScreen(),
          name: 'forgot-password',
        ),
        AppRouter.route('/privacy-policy', const PrivacyPolicyScreen(), name: 'privacyPolicy'),
        AppRouter.route('/terms-conditions', const TermsConditionsScreen(), name: 'termsConditions'),
        AppRouter.route('/help-support', const HelpSupportScreen(), name: 'helpSupport'),
        AppRouter.route(
          '/dashboard',
          AuthStateRedirector(allowedRoles: UserRole.adminRoles, child: const AdminDashboardScreen()),
          name: 'dashboard',
        ),
        AppRouter.route('/notifications', const NotificationsScreen(), name: 'notifications'),
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
    _localeProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Essential providers - initialized immediately
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Lazy-loaded providers - only created when accessed
        ChangeNotifierProvider.value(value: _localeProvider ?? LocaleProvider(const Locale('en'))),
        ChangeNotifierProvider(create: (_) => AdminStatsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserProfileProvider(), lazy: true),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Consumer<LocaleProvider>(
            builder: (context, localeProv, _) {
              final locale = _localeProvider?.locale ?? const Locale('en');
              return ErrorBoundary(
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'TayyebGo - Admin',
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: TayyebGoTheme.lightTheme(context),
                  darkTheme: TayyebGoTheme.darkTheme(context),
                  themeMode: themeProvider.mode,
                  routerConfig: _router,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
