import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/landing_screen.dart';
import 'screens/driver_application_screen.dart';
import 'screens/partner_application_screen.dart';
import 'screens/about_screen.dart';
import 'screens/download_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AuthGateService.instance.init();
    AppLocator.instance.init();
    runApp(const TayyebGoPortal());
  } catch (e, s) {
    if (kDebugMode) debugPrint('[PORTAL ERROR] $e\n$s');
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
        backgroundColor: const Color(0xFF090B10),
        body: Center(
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const TayyebGoPortal()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
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
        AppRouter.route('/driver-application', const DriverApplicationScreen(), name: 'driverApplication'),
        AppRouter.route('/partner-application', const PartnerApplicationScreen(), name: 'partnerApplication'),
        AppRouter.route('/about', const AboutScreen(), name: 'about'),
        AppRouter.route('/download', const DownloadScreen(), name: 'download'),
        AppRouter.route('/dashboard', const DashboardRedirectScreen(), name: 'dashboard'),
      ],
      redirect: _redirect,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final auth = AuthProvider.instance;
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    final isLoggedIn = fbUser != null;

    // Always allow these routes (but only when NOT logged in)
    if (!isLoggedIn) {
      if (location == '/login' || location == '/signup' || location == '/forgot-password') return null;
      if (location == '/privacy-policy' || location == '/terms-conditions' || location == '/help-support') return null;
      if (location == '/access-denied') return null;
      if (location == '/') return null;
      if (location == '/driver-application' || location == '/partner-application') return null;
      if (location == '/about' || location == '/download') return null;
      return '/login';
    }

    // Logged in but auth still loading
    if (auth == null || auth.isLoading) return null;

    // Logged in but no user model yet
    if (auth.user == null) return null;

    // Account disabled
    if (!auth.user!.isActive) {
      return '/access-denied?reason=disabled';
    }

    // Logged in → redirect to appropriate app
    // Since this is a portal, we'll show a role-based redirect page
    return '/dashboard';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
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

// Dashboard redirect screen
class DashboardRedirectScreen extends StatelessWidget {
  const DashboardRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get the app URL based on role
    String appUrl;
    String appName;
    IconData appIcon;
    Color appColor;

    switch (user.role) {
      case UserRole.superAdmin:
        appUrl = 'https://tayyebgo-app.web.app/admin/dashboard';
        appName = 'Admin Dashboard';
        appIcon = Icons.admin_panel_settings_rounded;
        appColor = const Color(0xFF8B5CF6);
        break;
      case UserRole.restaurantOwner:
      case UserRole.cashier:
        appUrl = 'https://tayyebgo-app.web.app/partner/dashboard';
        appName = 'Partner Dashboard';
        appIcon = Icons.store_rounded;
        appColor = const Color(0xFFF97316);
        break;
      case UserRole.driver:
        appUrl = 'https://tayyebgo-app.web.app/driver/dashboard';
        appName = 'Driver Dashboard';
        appIcon = Icons.local_shipping_rounded;
        appColor = const Color(0xFF22C55E);
        break;
      case UserRole.customer:
        appUrl = 'https://tayyebgo-app.web.app/customer/home';
        appName = 'Customer App';
        appIcon = Icons.shopping_bag_rounded;
        appColor = const Color(0xFF0050CB);
        break;
      default:
        appUrl = 'https://tayyebgo-app.web.app';
        appName = 'TayyebGo';
        appIcon = Icons.apps_rounded;
        appColor = const Color(0xFFFF5A2C);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090B10),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [appColor, appColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(appIcon, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              // Welcome text
              Text(
                'Welcome, ${user.displayName.isNotEmpty ? user.displayName : user.email}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Redirecting to $appName...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),
              // Loading indicator
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(appColor),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 32),
              // Open in new tab button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(appUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    'Open $appName',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sign out button
              TextButton(
                onPressed: () async {
                  final auth = AuthProvider.instance;
                  if (auth != null) {
                    await auth.logout();
                  }
                  if (context.mounted) context.go('/login');
                },
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
