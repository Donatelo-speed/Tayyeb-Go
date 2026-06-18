import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  State<DriverApplicationScreen> createState() => _DriverApplicationScreenState();
}

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _vehicleTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 640;
    final isTablet = w >= 640 && w < 1024;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), AppColors.background],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _NavBar(isMobile: isMobile),
              SizedBox(height: isMobile ? 32 : 64),
              _submitted ? _SuccessView(isMobile: isMobile) : _FormView(isMobile: isMobile, isTablet: isTablet, formKey: _formKey, controllers: {
                'name': _nameController,
                'phone': _phoneController,
                'city': _cityController,
                'vehicleType': _vehicleTypeController,
                'notes': _notesController,
              }, onSubmit: _submit),
              SizedBox(height: isMobile ? 48 : 80),
              _Footer(isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NAV BAR ───────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final bool isMobile;
  const _NavBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 56, vertical: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.driverAccent, Color(0xFF0F9D58)]),
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('TayyebGo', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink('About', () => context.go('/about')),
              _NavLink('Partner App', () => context.go('/partner-application')),
              _NavLink('Support', () => context.go('/help-support')),
              const SizedBox(width: 12),
            ],
            PressScale(
              onTap: () => context.push('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.driverAccent, Color(0xFF0F9D58)]),
                  borderRadius: AppRadius.brButton,
                  boxShadow: [BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 2))],
                ),
                child: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ─── FORM VIEW ─────────────────────────────────────────

class _FormView extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onSubmit;

  const _FormView({required this.isMobile, required this.isTablet, required this.formKey, required this.controllers, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : isTablet ? 120 : 200),
      child: Column(
        children: [
          // Header
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.driverAccent, Color(0xFF0F9D58)]),
              borderRadius: AppRadius.brMd,
              boxShadow: [BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 24),
          Text('Become a Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: isMobile ? 28 : 36, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            'Earn money delivering with TayyebGo.\nFlexible hours, competitive earnings, and a supportive community.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 48),

          // Benefits
          _BenefitsRow(isMobile: isMobile),
          const SizedBox(height: 48),

          // Form card
          Container(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10)),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application Form', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Fill in your details to get started', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(height: 32),
                  _buildField('Full Name', controllers['name']!, Icons.person_outline_rounded, 'Enter your full name'),
                  const SizedBox(height: 20),
                  _buildField('Phone Number', controllers['phone']!, Icons.phone_outlined, '+963 XXX XXX XXX', keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildField('City', controllers['city']!, Icons.location_city_outlined, 'e.g. Homs, Damascus, Aleppo'),
                  const SizedBox(height: 20),
                  _buildField('Vehicle Type', controllers['vehicleType']!, Icons.two_wheeler_rounded, 'Motorcycle, Car, Bicycle, On Foot'),
                  const SizedBox(height: 20),
                  _buildField('Additional Notes', controllers['notes']!, Icons.notes_outlined, 'Any relevant experience or information', maxLines: 3),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: PressScale(
                      onTap: onSubmit,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.driverAccent, Color(0xFF0F9D58)]),
                          borderRadius: AppRadius.brButton,
                          boxShadow: [BoxShadow(color: AppColors.driverAccent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: Text('Submit Application', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'We\'ll review your application within 48 hours.',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: const BorderSide(color: AppColors.driverAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── BENEFITS ROW ──────────────────────────────────────

class _BenefitsRow extends StatelessWidget {
  final bool isMobile;
  const _BenefitsRow({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      _Benefit(Icons.access_time_rounded, 'Flexible Hours', 'Work when you want'),
      _Benefit(Icons.account_balance_wallet_rounded, 'Competitive Pay', 'Earn more per delivery'),
      _Benefit(Icons.shield_rounded, 'Safe & Supported', '24/7 driver support'),
      _Benefit(Icons.trending_up_rounded, 'Grow Fast', 'Promotions & bonuses'),
    ];

    return isMobile
        ? Column(children: benefits.map((b) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _BenefitCard(benefit: b))).toList())
        : Row(children: benefits.map((b) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: _BenefitCard(benefit: b)))).toList());
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Benefit(this.icon, this.title, this.subtitle);
}

class _BenefitCard extends StatelessWidget {
  final _Benefit benefit;
  const _BenefitCard({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.driverAccent.withValues(alpha: 0.1),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(benefit.icon, color: AppColors.driverAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                Text(benefit.subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SUCCESS VIEW ──────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final bool isMobile;
  const _SuccessView({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 480,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0),
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Application Submitted!', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            'Thank you for applying to become a TayyebGo driver.\nWe\'ll review your application and get back to you within 48 hours.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 32),
          PressScale(
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.driverAccent, Color(0xFF0F9D58)]),
                borderRadius: AppRadius.brButton,
              ),
              child: Text('Back to Home', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FOOTER ────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool isMobile;
  const _Footer({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 40),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.15)))),
      child: isMobile
          ? Column(children: [
              Text('2025 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ])
          : Row(children: [
              Text('2025 TayyebGo. All rights reserved.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              const Spacer(),
              GestureDetector(onTap: () => context.go('/privacy-policy'), child: Text('Privacy Policy', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))),
              const SizedBox(width: 20),
              GestureDetector(onTap: () => context.go('/terms-conditions'), child: Text('Terms', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))),
              const SizedBox(width: 20),
              GestureDetector(onTap: () => context.go('/help-support'), child: Text('Help', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))),
            ]),
    );
  }
}
