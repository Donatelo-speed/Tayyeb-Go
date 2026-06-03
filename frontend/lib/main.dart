import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/vendor_dashboard_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/vendor_provider.dart';
import 'admin/providers/admin_provider.dart';
import 'services/auth_service.dart';
import 'services/auth_gate.dart';
import 'services/offline_sync_service.dart';
import 'theme/tayyebgo_theme.dart';
import 'widgets/page_transitions.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBwVf76nVKlxpVloPRklEax7EjlXivZck4",
        authDomain: "tayyebgo.firebaseapp.com",
        projectId: "tayyebgo",
        storageBucket: "tayyebgo.firebasestorage.app",
        messagingSenderId: "704530942839",
        appId: "1:704530942839:web:7e11271910bc913d6e2f72",
        measurementId: "G-R72V81JGFF",
      ),
    );
  } catch (e) {
    firebaseError = e.toString();
  }

  await OfflineSyncService.initialize();
  AuthGateService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('app_locale') ?? 'en';

  runApp(TayyebGoApp(
    savedLocale: savedLocale,
    firebaseError: firebaseError,
  ));
}

class TayyebGoApp extends StatelessWidget {
  final String savedLocale;
  final String? firebaseError;

  const TayyebGoApp({
    super.key,
    required this.savedLocale,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(savedLocale)),
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<DriverProvider>(create: (_) => DriverProvider()),
        ChangeNotifierProvider<VendorDashboardProvider>(
            create: (_) => VendorDashboardProvider()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<VendorProvider>(create: (_) => VendorProvider()),
        ChangeNotifierProvider<AdminProvider>(create: (_) => AdminProvider()),
      ],
      child: TayyebGoAppRoot(firebaseError: firebaseError),
    );
  }
}

class TayyebGoAppRoot extends StatelessWidget {
  final String? firebaseError;

  const TayyebGoAppRoot({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    // If Firebase failed, show a diagnostic screen instead of crashing silently
    if (firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _FirebaseErrorScreen(error: firebaseError!),
      );
    }

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Tayyeb-Go',
      debugShowCheckedModeBanner: false,
      locale: Locale(locale.locale),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection:
              locale.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TayyebGoTheme.primaryColor,
          primary: TayyebGoTheme.primaryColor,
          secondary: TayyebGoTheme.successColor,
          surface: TayyebGoTheme.surfaceColor,
        ),
        fontFamily: locale.isArabic ? 'Cairo' : 'Poppins',
        textTheme: TayyebGoTheme.textTheme,
        appBarTheme: TayyebGoTheme.appBarTheme,
        inputDecorationTheme: TayyebGoTheme.inputDecoration,
        elevatedButtonTheme: TayyebGoTheme.elevatedButton,
        outlinedButtonTheme: TayyebGoTheme.outlinedButton,
        navigationBarTheme: TayyebGoTheme.navigationBar,
        navigationRailTheme: TayyebGoTheme.navigationRail,
        chipTheme: TayyebGoTheme.chipTheme,
        pageTransitionsTheme: smoothPageTransitions,
        scaffoldBackgroundColor: TayyebGoTheme.backgroundColor,
        dividerTheme: DividerThemeData(
          color: TayyebGoTheme.dividerColor,
          thickness: 1,
          space: 1,
        ),
        cardTheme: CardThemeData(
          color: TayyebGoTheme.surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TayyebGoTheme.radiusSm),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(TayyebGoTheme.radiusXl),
              topRight: Radius.circular(TayyebGoTheme.radiusXl),
            ),
          ),
        ),
      ),
      home: const _SessionGate(),
    );
  }
}

/// Waits for Firebase Auth to restore the persisted session (IndexedDB on web)
/// before routing the user to either the dashboard or the login screen.
/// This prevents the "flash of login screen" on page refresh.
///
/// Architecture:
///   StreamBuilder--authStateChanges()
///     ├─ ConnectionState.waiting ──► _LoadingScreen
///     ├─ snapshot.hasData ──► _AuthGate (fetches Firestore profile, then HomeScreen)
///     └─ null / no-data ──► SplashScreen (login)
class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Phase 0: Demo / manually-set user — route directly to HomeScreen
    if (auth.isAuthenticated) {
      return const HomeScreen();
    }

    // Phase 1–3: Firebase Auth session (normal production path)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return _AuthGate(firebaseUser: snapshot.data!);
        }
        return const SplashScreen();
      },
    );
  }
}

/// Fetches the Firestore user document for the restored Firebase session,
/// then hands off to [HomeScreen] which reads role metadata from [AuthProvider].
/// This is a separate widget so the async Firestore call lives in initState,
/// never inside a build method.
class _AuthGate extends StatefulWidget {
  final User firebaseUser;
  const _AuthGate({required this.firebaseUser});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    await context.read<AuthProvider>().resolveUser(widget.firebaseUser);
    if (mounted) setState(() => _resolved = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) return const _LoadingScreen();
    return const HomeScreen();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Tayyeb-Go',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final String error;
  const _FirebaseErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Firebase Configuration Error',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Run `flutterfire configure` in your terminal to generate firebase_options.dart, '
                'then restart the app.',
                style: TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  error,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white54, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  auth.signOut();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
