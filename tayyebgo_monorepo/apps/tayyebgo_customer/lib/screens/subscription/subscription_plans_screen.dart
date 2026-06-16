import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../providers/subscription_provider.dart';
import 'subscription_payment_sheet.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  SubscriptionPlanType _selectedPlan = SubscriptionPlanType.plus;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      context.read<SubscriptionProvider>().loadSubscription(userId);
    }
  }

  Color _planColor(SubscriptionPlanType plan) {
    switch (plan) {
      case SubscriptionPlanType.basic:
        return const Color(0xFF22C55E);
      case SubscriptionPlanType.plus:
        return AppColors.primary;
      case SubscriptionPlanType.premium:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _planIcon(SubscriptionPlanType plan) {
    switch (plan) {
      case SubscriptionPlanType.basic:
        return Icons.bolt_rounded;
      case SubscriptionPlanType.plus:
        return Icons.star_rounded;
      case SubscriptionPlanType.premium:
        return Icons.diamond_rounded;
    }
  }

  String _benefitLabel(String benefit) {
    switch (benefit) {
      case 'free_delivery':
        return 'Free delivery on all orders';
      case '5_percent_discount':
        return '5% discount on every order';
      case '10_percent_discount':
        return '10% discount on every order';
      case '15_percent_discount':
        return '15% discount on every order';
      case 'priority_offers':
        return 'Priority access to offers';
      case 'monthly_offers':
        return 'Exclusive monthly offers';
      case 'exclusive_deals':
        return 'Exclusive VIP deals';
      case 'early_access':
        return 'Early access to new features';
      case 'priority_support':
        return 'Priority customer support';
      default:
        return benefit.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final subProvider = context.watch<SubscriptionProvider>();

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
                          borderRadius: BorderRadius.circular(12),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TayyebGo Plus',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              color: context.textPrimaryColor,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose your perfect plan',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (subProvider.isSubscribed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedFadeSlide(
                  delay: 50,
                  duration: const Duration(milliseconds: 500),
                  child: _buildActiveBanner(subProvider),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  AnimatedFadeSlide(
                    delay: 100,
                    duration: const Duration(milliseconds: 500),
                    child: _buildComparisonTable(),
                  ),
                  const SizedBox(height: 20),
                  ...SubscriptionPlanType.values.asMap().entries.map(
                    (entry) {
                      final idx = entry.key;
                      final plan = entry.value;
                      return AnimatedFadeSlide(
                        delay: 200 + (idx * 100).toDouble(),
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPlanCard(plan),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedFadeSlide(
                    delay: 550,
                    duration: const Duration(milliseconds: 500),
                    child: AnimatedPressScale(
                      onTap: () => _onSubscribe(user),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _planColor(_selectedPlan),
                              _planColor(_selectedPlan).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _planColor(_selectedPlan).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Subscribe to ${_selectedPlan.displayName} — ${_selectedPlan.priceDisplay}',
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

  Widget _buildActiveBanner(SubscriptionProvider subProvider) {
    final sub = subProvider.activeSubscription!;
    final color = _planColor(sub.plan);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _planIcon(sub.plan),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active: TayyebGo ${sub.plan.displayName}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sub.daysRemaining} days remaining',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AnimatedPressScale(
            onTap: () => context.push('/subscription/dashboard'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Manage',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
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
          Text(
            'Why TayyebGo Plus?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: context.textPrimaryColor,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          _comparisonRow('Delivery Fee', '\$3.00', 'FREE', AppColors.success),
          _comparisonRow('Order Discount', 'None', '${_selectedPlan.discountPercent.toInt()}%', AppColors.success),
          _comparisonRow('Priority Support', '', '✓', AppColors.success),
          _comparisonRow('Monthly Savings', '~\$0', '~\$${(_selectedPlan.discountPercent * 2).toInt() * 5}', AppColors.success),
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, String without, String withPlus, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              without,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                withPlus,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanType plan) {
    final isSelected = _selectedPlan == plan;
    final color = _planColor(plan);

    return AnimatedPressScale(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_planIcon(plan), color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'TayyebGo ${plan.displayName}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: context.textPrimaryColor,
                              letterSpacing: 0,
                            ),
                          ),
                          if (plan == SubscriptionPlanType.plus) ...[
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
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'POPULAR',
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
                        '${plan.durationMonths} months',
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
                    borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceDisplay,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                      color: color,
                      letterSpacing: 0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      '/ ${plan.durationMonths} months',
                      style: GoogleFonts.inter(
                        color: context.textMutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (plan == SubscriptionPlanType.premium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Best Value',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...plan.benefits.map((b) => Padding(
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
                      _benefitLabel(b),
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

  void _onSubscribe(dynamic user) {
    if (user == null) {
      context.showError('Please log in first');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionPaymentSheet(
        plan: _selectedPlan,
        userId: user.id,
      ),
    );
  }
}
