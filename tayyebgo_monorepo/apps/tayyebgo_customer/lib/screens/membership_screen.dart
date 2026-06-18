import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

enum BillingCycle { monthly, twoMonths, threeMonths }

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  BillingCycle _selectedCycle = BillingCycle.monthly;
  String _selectedPlan = 'plus';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AnimatedFadeSlide(
                duration: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    AnimatedPressScale(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(
                            color: context.borderColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: context.textPrimaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Membership',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: context.textPrimaryColor,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  AnimatedFadeSlide(
                    delay: 100,
                    duration: const Duration(milliseconds: 500),
                    child: _buildBillingToggle(),
                  ),
                  const SizedBox(height: 24),
                  AnimatedFadeSlide(
                    delay: 200,
                    duration: const Duration(milliseconds: 500),
                    child: _buildPlanCard(
                      id: 'basic',
                      name: 'Basic',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF22C55E),
                      monthlyPrice: 10,
                      features: [
                        'Free delivery on first 10 orders/month',
                        '5% discount on orders',
                        'Priority order processing',
                        'Member-only offers',
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFadeSlide(
                    delay: 300,
                    duration: const Duration(milliseconds: 500),
                    child: _buildPlanCard(
                      id: 'plus',
                      name: 'Plus',
                      icon: Icons.star_rounded,
                      color: AppColors.primary,
                      monthlyPrice: 20,
                      isPopular: true,
                      features: [
                        'Free delivery on first 25 orders/month',
                        '10% discount on orders',
                        'Bigger promotions',
                        'Faster support',
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFadeSlide(
                    delay: 400,
                    duration: const Duration(milliseconds: 500),
                    child: _buildPlanCard(
                      id: 'pro',
                      name: 'Pro',
                      icon: Icons.diamond_rounded,
                      color: const Color(0xFF8B5CF6),
                      monthlyPrice: 30,
                      features: [
                        'Free delivery on first 40 orders/month',
                        '15% discount on orders',
                        'Exclusive deals',
                        'Priority drivers',
                        'Cashback rewards',
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Family Plan
                  AnimatedFadeSlide(
                    delay: 425,
                    duration: const Duration(milliseconds: 500),
                    child: _buildPlanCard(
                      id: 'family',
                      name: 'Family',
                      icon: Icons.family_restroom_rounded,
                      color: const Color(0xFFEC4899),
                      monthlyPrice: 35,
                      features: [
                        '3 accounts included',
                        'Free delivery on all orders',
                        'Shared discounts',
                        'Family order tracking',
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weekend Plan
                  AnimatedFadeSlide(
                    delay: 450,
                    duration: const Duration(milliseconds: 500),
                    child: _buildPlanCard(
                      id: 'weekend',
                      name: 'Weekend',
                      icon: Icons.weekend_rounded,
                      color: const Color(0xFF3B82F6),
                      monthlyPrice: 5,
                      features: [
                        'Friday & Saturday free delivery',
                        'Weekend-only discounts',
                        'Perfect for casual users',
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedFadeSlide(
                    delay: 500,
                    duration: const Duration(milliseconds: 500),
                    child: _buildSavingsBanner(),
                  ),
                  const SizedBox(height: 24),
                  AnimatedFadeSlide(
                    delay: 600,
                    duration: const Duration(milliseconds: 500),
                    child: AnimatedPressScale(
                      onTap: () => _subscribe(),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getSelectedPlanColor(),
                              _getSelectedPlanColor().withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: AppRadius.brLg,
                          boxShadow: [
                            BoxShadow(
                              color: _getSelectedPlanColor().withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Subscribe Now',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSelectedPlanColor() {
    switch (_selectedPlan) {
      case 'basic':
        return const Color(0xFF22C55E);
      case 'plus':
        return AppColors.primary;
      case 'pro':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: BillingCycle.values.map((cycle) {
          final isSelected = _selectedCycle == cycle;
          final label = cycle == BillingCycle.monthly
              ? 'Monthly'
              : cycle == BillingCycle.twoMonths
                  ? '2 Months'
                  : '3 Months';
          final savings = cycle == BillingCycle.monthly
              ? null
              : cycle == BillingCycle.twoMonths
                  ? '10% off'
                  : '17% off';
          return Expanded(
            child: AnimatedPressScale(
              onTap: () => setState(() => _selectedCycle = cycle),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? context.primaryColor : Colors.transparent,
                  borderRadius: AppRadius.brMd,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: context.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? Colors.white : context.textMutedColor,
                      ),
                    ),
                    if (savings != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        savings,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : context.successColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
    required int monthlyPrice,
    bool isPopular = false,
    required List<String> features,
  }) {
    final isSelected = _selectedPlan == id;
    final price = _getPrice(monthlyPrice);
    final perMonth = _getPerMonth(monthlyPrice);

    return AnimatedPressScale(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : context.surfaceColor,
          borderRadius: AppRadius.brXl,
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : context.borderColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'TayyebGo $name',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: context.textPrimaryColor,
                              letterSpacing: 0,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: AppRadius.brSm,
                              ),
                              child: Text(
                                'MOST POPULAR',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$$perMonth/mo',
                        style: GoogleFonts.inter(
                          color: context.textMutedColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(
                      color: isSelected ? color : context.borderColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.06)
                    : context.surfaceAltColor.withValues(alpha: 0.5),
                borderRadius: AppRadius.brMd,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$$price',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 36,
                          color: color,
                          letterSpacing: 0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          _getCycleLabel(),
                          style: GoogleFonts.inter(
                            color: context.textMutedColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCycle != BillingCycle.monthly) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.savings_rounded, size: 16, color: context.successColor),
                        const SizedBox(width: 6),
                        Text(
                          'Save \$${_getSavings(monthlyPrice)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: context.successColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: color, size: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.inter(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsBanner() {
    final savings = _getSavings(_getMonthlyPrice());
    if (savings == '0') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.successColor.withValues(alpha: 0.1),
            context.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: context.successColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.successColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: context.successColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You save \$${_getSavings(_getMonthlyPrice())} with ${_getCycleLabel()} billing!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get guaranteed savings when you commit.',
                  style: GoogleFonts.inter(
                    color: context.textMutedColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getMonthlyPrice() {
    switch (_selectedPlan) {
      case 'basic':
        return 10;
      case 'plus':
        return 20;
      case 'pro':
        return 30;
      default:
        return 20;
    }
  }

  String _getPrice(int monthlyPrice) {
    switch (_selectedCycle) {
      case BillingCycle.monthly:
        return monthlyPrice.toString();
      case BillingCycle.twoMonths:
        return (monthlyPrice * 2 * 0.9).round().toString();
      case BillingCycle.threeMonths:
        return (monthlyPrice * 3 * 0.83).round().toString();
    }
  }

  String _getPerMonth(int monthlyPrice) {
    final total = int.parse(_getPrice(monthlyPrice));
    switch (_selectedCycle) {
      case BillingCycle.monthly:
        return monthlyPrice.toString();
      case BillingCycle.twoMonths:
        return (total / 2).round().toString();
      case BillingCycle.threeMonths:
        return (total / 3).round().toString();
    }
  }

  String _getSavings(int monthlyPrice) {
    switch (_selectedCycle) {
      case BillingCycle.monthly:
        return '0';
      case BillingCycle.twoMonths:
        return (monthlyPrice * 2 * 0.1).round().toString();
      case BillingCycle.threeMonths:
        return (monthlyPrice * 3 * 0.17).round().toString();
    }
  }

  String _getCycleLabel() {
    switch (_selectedCycle) {
      case BillingCycle.monthly:
        return 'billed monthly';
      case BillingCycle.twoMonths:
        return 'billed every 2 months';
      case BillingCycle.threeMonths:
        return 'billed every 3 months';
    }
  }

  void _subscribe() async {
    final price = _getMonthlyPrice();
    final months = _selectedCycle == BillingCycle.monthly
        ? 1
        : _selectedCycle == BillingCycle.twoMonths
            ? 2
            : 3;
    final totalCents = (price * months * 100).round();
    final orderId = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final result = await FirebasePaymentRepository.instance.processPayment(
        orderId: orderId,
        amountInCents: totalCents,
        currency: 'usd',
        paymentMethodId: '',
      );

      final clientSecret = result['clientSecret'] as String?;
      if (clientSecret == null || !context.mounted) return;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'TayyebGo',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'plan': _selectedPlan,
        'billingCycle': _selectedCycle.name,
        'amountInCents': totalCents,
        'currency': 'usd',
        'orderId': orderId,
        'status': 'active',
        'startDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome to TayyebGo ${_selectedPlan[0].toUpperCase()}${_selectedPlan.substring(1)}!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.brMd,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().contains('cancelled')
          ? 'Payment was cancelled'
          : 'Subscription failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.inter()),
          backgroundColor: context.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brMd,
          ),
        ),
      );
    }
  }
}
