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
import 'theme/design_tokens.dart';
import 'widgets/page_transitions.dart';
import 'widgets/shimmer_loading.dart';
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
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TayyebGoColors.primary,
          brightness: Brightness.light,
          primary: TayyebGoColors.primary,
          secondary: TayyebGoColors.secondary,
          surface: TayyebGoColors.surface,
          error: TayyebGoColors.error,
        ),
        fontFamily: locale.isArabic ? 'Cairo' : 'Poppins',
        scaffoldBackgroundColor: TayyebGoColors.background,
        textTheme: TayyebGoTokens.textTheme(
          locale.isArabic ? 'Cairo' : 'Poppins',
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: TayyebGoColors.surface,
          foregroundColor: TayyebGoColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: TayyebGoColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TayyebGoColors.surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TayyebGoTokens.radiusSm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TayyebGoTokens.radiusSm),
            borderSide:
                const BorderSide(color: TayyebGoColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TayyebGoTokens.radiusSm),
            borderSide: const BorderSide(
                color: TayyebGoColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TayyebGoTokens.radiusSm),
            borderSide:
                const BorderSide(color: TayyebGoColors.error),
          ),
          hintStyle: const TextStyle(
            color: TayyebGoColors.textMuted,
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: TayyebGoColors.textSecondary,
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TayyebGoColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(TayyebGoTokens.radiusSm),
            ),
            elevation: 0,
            shadowColor:
                TayyebGoColors.primary.withValues(alpha: 0.25),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: TayyebGoColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(TayyebGoTokens.radiusSm),
            ),
            side: const BorderSide(
                color: TayyebGoColors.primary, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          backgroundColor: TayyebGoColors.surface,
          indicatorColor:
              TayyebGoColors.primary.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TayyebGoColors.primary,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: TayyebGoColors.textMuted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                  color: TayyebGoColors.primary, size: 24);
            }
            return const IconThemeData(
                color: TayyebGoColors.textMuted, size: 24);
          }),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: TayyebGoColors.surface,
          indicatorColor:
              TayyebGoColors.primary.withValues(alpha: 0.1),
          labelType: NavigationRailLabelType.all,
          selectedLabelTextStyle: const TextStyle(
            color: TayyebGoColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: TayyebGoColors.textMuted,
            fontSize: 12,
          ),
          selectedIconTheme:
              const IconThemeData(color: TayyebGoColors.primary),
          unselectedIconTheme:
              const IconThemeData(color: TayyebGoColors.textMuted),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: TayyebGoColors.background,
          selectedColor:
              TayyebGoColors.primary.withValues(alpha: 0.1),
          labelStyle: const TextStyle(
            fontSize: 12,
            color: TayyebGoColors.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TayyebGoTokens.radiusFull),
            side: BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        pageTransitionsTheme: smoothPageTransitions,
        dividerTheme: const DividerThemeData(
          color: TayyebGoColors.divider,
          thickness: 1,
          space: 1,
        ),
        cardTheme: CardThemeData(
          color: TayyebGoColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TayyebGoTokens.radiusMd),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TayyebGoTokens.radiusSm),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(TayyebGoTokens.radiusXl),
              topRight: Radius.circular(TayyebGoTokens.radiusXl),
            ),
          ),
        ),
      ),
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      return const HomeScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashLoadingScreen(
            subtitle: 'Restoring session...',
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return _AuthGate(firebaseUser: snapshot.data!);
        }
        return const SplashScreen();
      },
    );
  }
}

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
    if (!_resolved) {
      return const SplashLoadingScreen(
        subtitle: 'Loading your profile...',
      );
    }
    return const HomeScreen();
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final String error;
  const _FirebaseErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TayyebGoColors.error.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: TayyebGoColors.error,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Configuration Error',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Run flutterfire configure and restart',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: SelectableText(
                  error,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthProvider>().signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TayyebGoColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}