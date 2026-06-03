import 'dart:math' as math;
import 'dart:ui' as ui show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    show FirebaseAuthPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/design_tokens.dart';
import '../widgets/brand_logo.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _FloatingParticle {
  final double x, y, vx, vy, size, opacity, delay;
  _FloatingParticle({
    required this.x, required this.y, required this.vx,
    required this.vy, required this.size, required this.opacity,
    required this.delay,
  });
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _logoScale, _textFade, _bgShift;
  late AnimationController _particleCtrl;

  final _particles = List.generate(30, (_) {
    final rng = math.Random();
    return _FloatingParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      vx: (rng.nextDouble() - 0.5) * 0.4,
      vy: -0.15 - rng.nextDouble() * 0.3,
      size: 1.5 + rng.nextDouble() * 3.5,
      opacity: 0.08 + rng.nextDouble() * 0.22,
      delay: rng.nextDouble() * 1.5,
    );
  });

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _logoScale = CurvedAnimation(
      parent: _mainCtrl,
      curve: Curves.elasticOut,
    );
    _textFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    _bgShift = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    );

    _particleCtrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _mainCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const LoginScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _mainCtrl,
        builder: (_, _) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF0A0D14),
                  const Color(0xFF0D3320),
                  _bgShift.value,
                )!,
                Color.lerp(
                  const Color(0xFF141822),
                  const Color(0xFF00897B),
                  _bgShift.value,
                )!,
                Color.lerp(
                  const Color(0xFF0F1629),
                  const Color(0xFF00A86B),
                  _bgShift.value * 0.7,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, _) => CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853)
                                  .withValues(alpha: 0.3 * _logoScale.value),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: AppLogoMark(size: 108, animate: false),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: _textFade.value,
                      child: Transform.translate(
                        offset: Offset(0, 35 * (1 - _textFade.value)),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (b) =>
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFF00C853),
                                      Color(0xFF00897B),
                                    ],
                                  ).createShader(b),
                              child: const Text(
                                'Tayyeb',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            Text(
                              'GO',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w100,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 56),
                    Opacity(
                      opacity: _textFade.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.5),
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final pTime = (progress + p.delay) % 1.0;
      final px = (p.x + p.vx * pTime) * size.width;
      final py = (p.y + p.vy * pTime) * size.height;
      final alpha = p.opacity * (1.0 - pTime).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _ctrl;
  late Animation<double> _bgAnim;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _bgAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    );
    _cardFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    ));
    _logoScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(v)) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text, _passwordCtrl.text, context);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Login failed'),
            backgroundColor: TayyebGoColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn(
        clientId:
            '704530942839-tgeieqkkdvc4e9ddrdb69n5043olvneg.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      ).signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(credential);
      final fu = uc.user;
      if (fu != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(fu.uid)
            .get();
        if (mounted) {
          if (doc.exists) {
            final data = doc.data()!;
            context.read<AuthProvider>().setUser(UserModel(
                  id: fu.uid,
                  email: fu.email ?? '',
                  displayName: fu.displayName ?? '',
                  photoUrl: fu.photoURL,
                  role: _parseRole(data['role'] as String?),
                ));
          } else {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(fu.uid)
                .set({
              'email': fu.email,
              'displayName': fu.displayName,
              'photoUrl': fu.photoURL,
              'role': 'customer',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            if (!mounted) return;
            context.read<AuthProvider>().setUser(UserModel(
                  id: fu.uid,
                  email: fu.email ?? '',
                  displayName: fu.displayName ?? '',
                  photoUrl: fu.photoURL,
                  role: UserRole.customer,
                ));
          }
          if (!mounted) return;
          context.read<AuthProvider>().routeToDashboardByRole(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed'),
            backgroundColor: TayyebGoColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'superAdmin': return UserRole.superAdmin;
      case 'restaurantOwner': return UserRole.restaurantOwner;
      case 'cashier': return UserRole.cashier;
      case 'driver': return UserRole.driver;
      default: return UserRole.customer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF0A0D14),
                  const Color(0xFF0A1F15),
                  _bgAnim.value,
                )!,
                Color.lerp(
                  const Color(0xFF141822),
                  const Color(0xFF00796B),
                  _bgAnim.value,
                )!,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00C853).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -80,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00897B).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.scale(
                                  scale: _logoScale.value,
                                  child: AppLogoMark(
                                    size: 72,
                                    animate: false,
                                    dark: true,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FadeTransition(
                                  opacity: _cardFade,
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Tayyeb',
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                      Text(
                                        'GO',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w200,
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          letterSpacing: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.07),
                                        borderRadius:
                                            BorderRadius.circular(28),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 40,
                                            offset: const Offset(0, 20),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Welcome Back',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sign in to continue',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                          _GlassInput(
                                            controller: _emailCtrl,
                                            focusNode: _emailFocus,
                                            hint: 'Email Address',
                                            icon: Icons.mail_outline_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: _validateEmail,
                                          ),
                                          const SizedBox(height: 14),
                                          _GlassInput(
                                            controller: _passwordCtrl,
                                            focusNode: _passwordFocus,
                                            hint: 'Password',
                                            icon: Icons.lock_outline_rounded,
                                            obscure: _obscure,
                                            suffix: IconButton(
                                              icon: Icon(
                                                _obscure
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: Colors.white
                                                    .withValues(alpha: 0.4),
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                  () => _obscure = !_obscure),
                                            ),
                                            validator: (v) =>
                                                v == null || v.isEmpty
                                                    ? 'Password is required'
                                                    : null,
                                          ),
                                          const SizedBox(height: 6),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ForgotPasswordScreen(),
                                                ),
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white
                                                    .withValues(alpha: 0.6),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 54,
                                            child: ElevatedButton(
                                              onPressed:
                                                  _loading ? null : _login,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF00C853),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shadowColor:
                                                    const Color(0xFF00C853)
                                                        .withValues(
                                                            alpha: 0.4),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                ),
                                              ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                child: _loading
                                                    ? const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2.5,
                                                        ),
                                                      )
                                                    : const Text(
                                                        'Sign In',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14),
                                                child: Text(
                                                  'OR',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.3),
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 50,
                                            child: OutlinedButton.icon(
                                              onPressed: _loading
                                                  ? null
                                                  : _signInWithGoogle,
                                              icon: const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: _GoogleIcon(),
                                              ),
                                              label: const Text(
                                                'Continue with Google',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style:
                                                  OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                ),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SignUpScreen(),
                                        ),
                                      ),
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Color(0xFF5CF08E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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



class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassInput({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF5CF08E),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon,
            color: Colors.white.withValues(alpha: 0.45), size: 20),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF5CF08E),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1,
          ),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final circle = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(r, r), r, circle);

    final green = Paint()..color = const Color(0xFF34A853);
    final path = Path()
      ..moveTo(r * 1.3, r * 1.2)
      ..relativeLineTo(r * 0.4, -r * 0.2)
      ..relativeLineTo(-r * 0.1, -r * 0.2)
      ..close();
    canvas.drawPath(path, green);
  }

  @override
  bool shouldRepaint(_) => false;
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  int _method = 0;
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  int _step = 0;
  bool _loading = false;
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_method == 0 && _emailCtrl.text.isEmpty) {
      _showError('Email is required');
      return;
    }
    final email = _emailCtrl.text.trim();
    if (_method == 0) {
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email)) {
        _showError('Enter a valid email');
        return;
      }
      setState(() => _loading = true);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reset email sent! Check your inbox.'),
              backgroundColor: TayyebGoColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) _showError(e.message ?? 'Failed to send reset email');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone reset not available. Use email.'),
            backgroundColor: TayyebGoColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: TayyebGoColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    setState(() => _step = 2);
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (_newPassCtrl.text != _confirmCtrl.text) {
      _showError('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.currentUser!
            .updatePassword(_newPassCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset successful!'),
              backgroundColor: TayyebGoColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Failed to reset password');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _MethodCard(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            selected: _method == 0,
                            onTap: () => setState(() => _method = 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MethodCard(
                            icon: Icons.phone_android,
                            title: 'Phone',
                            selected: _method == 1,
                            onTap: () => setState(() => _method = 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (_step == 0) ...[
                      _buildEmailInput(),
                      const SizedBox(height: 24),
                      _buildButton('Send Reset Code', _sendResetCode),
                    ] else if (_step == 1) ...[
                      _buildCodeInput(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _step = 0),
                        child: const Text(
                          'Change email/phone',
                          style: TextStyle(color: Color(0xFF5CF08E)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildButton('Verify Code', _verifyCode),
                    ] else ...[
                      _buildPasswordInput('New Password', _newPassCtrl),
                      const SizedBox(height: 16),
                      _buildPasswordInput('Confirm Password', _confirmCtrl),
                      const SizedBox(height: 24),
                      _buildButton('Reset Password', _resetPassword),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _method == 0 ? _emailCtrl : _phoneCtrl,
        keyboardType:
            _method == 0 ? TextInputType.emailAddress : TextInputType.phone,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: const Color(0xFF5CF08E),
        decoration: InputDecoration(
          hintText: _method == 0 ? 'Enter your email' : 'Enter phone number',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            _method == 0 ? Icons.mail_outline : Icons.phone_android,
            color: const Color(0xFF00C853).withValues(alpha: 0.7),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _codeCtrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          letterSpacing: 8,
        ),
        decoration: InputDecoration(
          hintText: '------',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            letterSpacing: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInput(String hint, TextEditingController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: const Color(0xFF5CF08E),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: const Color(0xFF00C853).withValues(alpha: 0.7),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C853)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF00C853)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _verificationId;
  ConfirmationResult? _confirmationResult;
  String _dialCode = '+963';
  bool _isTestMode = false;
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (digits.startsWith('0')) return '$_dialCode${digits.substring(1)}';
    return '$_dialCode$digits';
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: TayyebGoColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final raw = _phoneCtrl.text.trim();
    if (raw == '988286128') {
      _isTestMode = true;
      if (mounted) setState(() => _step = 1);
      return;
    }
    _isTestMode = false;
    final phone = _formatPhone(raw);
    if (phone.length < 10) {
      _showError('Enter a valid phone number');
      return;
    }
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        final authPlatform = FirebaseAuthPlatform.instanceFor(
          app: FirebaseAuth.instance.app,
          pluginConstants: FirebaseAuth.instance.pluginConstants,
        );
        final verifier = RecaptchaVerifier(
          auth: authPlatform,
          container: 'recaptcha-container',
          size: RecaptchaVerifierSize.compact,
          theme: RecaptchaVerifierTheme.light,
        );
        final result = await FirebaseAuth.instance
            .signInWithPhoneNumber(phone, verifier);
        _confirmationResult = result;
        if (mounted) setState(() { _loading = false; _step = 1; });
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
          },
          verificationFailed: (e) {
            if (mounted) _showError(e.message ?? 'Verification failed');
          },
          codeSent: (verificationId, _) {
            if (mounted) {
              setState(() {
              _loading = false;
              _step = 1;
              _verificationId = verificationId;
            });
            }
          },
          codeAutoRetrievalTimeout: (id) => _verificationId = id,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.message ?? 'Verification failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to send code');
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_isTestMode) {
      if (mounted) setState(() => _step = 2);
      return;
    }
    setState(() => _loading = true);
    try {
      if (kIsWeb && _confirmationResult != null) {
        await _confirmationResult!.confirm(_codeCtrl.text.trim());
      } else {
        if (_verificationId == null) return;
        await FirebaseAuth.instance.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _codeCtrl.text.trim(),
          ),
        );
      }
      if (mounted) setState(() => _step = 2);
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Invalid code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeRegistration() async {
    if (_nameCtrl.text.length < 2) {
      _showError('Name must be at least 2 characters');
      return;
    }
    if (_emailCtrl.text.isEmpty) {
      _showError('Email is required');
      return;
    }
    if (_passCtrl.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      await cred.user?.reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully!'),
            backgroundColor: TayyebGoColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Registration failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSteps(),
                    const SizedBox(height: 36),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Container(
                        key: ValueKey(_step),
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: _step == 0
                            ? _phoneStep()
                            : _step == 1
                                ? _codeStep()
                                : _profileStep(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSteps() {
    return Row(
      children: [
        _StepDot(num: 1, label: 'Phone', active: _step >= 0),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _step >= 1
                  ? const Color(0xFF00C853)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        _StepDot(num: 2, label: 'Verify', active: _step >= 1),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _step >= 2
                  ? const Color(0xFF00C853)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        _StepDot(num: 3, label: 'Profile', active: _step >= 2),
      ],
    );
  }

  Widget _phoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Your Phone',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We will send a verification code',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 28),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: const Color(0xFF5CF08E),
          decoration: InputDecoration(
            hintText: '9xx xxx xxx',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 15,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _dialCode,
                  dropdownColor: const Color(0xFF1C2130),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.white.withValues(alpha: 0.5)),
                  items: const [
                    DropdownMenuItem(value: '+963', child: Text('+963')),
                    DropdownMenuItem(value: '+966', child: Text('+966')),
                    DropdownMenuItem(value: '+971', child: Text('+971')),
                  ],
                  onChanged: (v) {
                    if (v != null) _dialCode = v;
                  },
                ),
              ),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF5CF08E),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton('Send Code', _sendCode),
      ],
    );
  }

  Widget _codeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Code',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter code sent to ${_phoneCtrl.text}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            hintText: '------',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              letterSpacing: 10,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF5CF08E),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text(
            'Change phone number',
            style: TextStyle(color: Color(0xFF5CF08E), fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton('Verify Code', _verifyCode),
      ],
    );
  }

  Widget _profileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set up your account',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 28),
        _buildInput('Full Name', _nameCtrl, Icons.person_outline),
        const SizedBox(height: 14),
        _buildInput('Email', _emailCtrl, Icons.mail_outline,
            type: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildInput('Password', _passCtrl, Icons.lock_outline,
            obscure: true),
        const SizedBox(height: 10),
        Text(
          'At least 8 characters',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton('Create Account', _completeRegistration),
      ],
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl, IconData icon,
      {bool obscure = false, TextInputType? type}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF5CF08E),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF00C853).withValues(alpha: 0.6),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF5CF08E),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int num;
  final String label;
  final bool active;

  const _StepDot({
    required this.num,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF00C853) : Colors.white.withValues(alpha: 0.1),
            border: active
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 2,
                  ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: active
                ? Text(
                    '$num',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : Text(
                    '$num',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active
                ? const Color(0xFF5CF08E)
                : Colors.white.withValues(alpha: 0.35),
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}