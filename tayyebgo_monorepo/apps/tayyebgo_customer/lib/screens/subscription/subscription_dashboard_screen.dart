import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() => _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState extends State<SubscriptionDashboardScreen> {
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
      case SubscriptionPlanType.starter:
        return const Color(0xFF22C55E);
      case SubscriptionPlanType.plus:
        return AppColors.primary;
      case SubscriptionPlanType.pro:
        return const Color(0xFF8B5CF6);
      case SubscriptionPlanType.vip:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(CustomerSubscription sub) {
    if (sub.isExpired) return 'Expired';
    if (sub.daysRemaining <= 7) return 'Expiring Soon';
    if (sub.isActive) return 'Active';
    return sub.status.value;
  }

  Color _statusColor(CustomerSubscription sub) {
    if (sub.isExpired) return AppColors.error;
    if (sub.daysRemaining <= 7) return AppColors.warning;
    if (sub.isActive) return AppColors.success;
    return AppColors.textMuted;
  }

  String _benefitLabel(String benefit) {
    switch (benefit) {
      case 'free_delivery':
        return 'Free delivery on all orders';
      case 'free_delivery_first_3_orders':
        return 'Free delivery on first 3 orders';
      case '3_percent_discount':
        return '3% discount on every order';
      case '5_percent_discount':
        return '5% discount on every order';
      case '7_percent_discount':
        return '7% discount on every order';
      case '10_percent_discount':
        return '10% discount on every order';
      case '12_percent_discount':
        return '12% discount on every order';
      case '15_percent_discount':
        return '15% discount on every order';
      case 'priority_offers':
        return 'Priority access to offers';
      case 'monthly_offers':
        return 'Exclusive monthly offers';
      case 'monthly_exclusive_offers':
        return 'Monthly exclusive offers';
      case 'exclusive_deals':
        return 'Exclusive VIP deals';
      case 'early_access':
        return 'Early access to new features';
      case 'priority_support':
        return 'Priority customer support';
      case 'vip_badge':
        return 'VIP badge on your profile';
      case 'dedicated_support':
        return 'Dedicated account manager';
      case 'monthly_free_item':
        return 'One free premium item per month';
      case 'double_rewards':
        return 'Double rewards points';
      default:
        return benefit.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'My Subscription',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
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
              child: subProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : subProvider.activeSubscription == null
                      ? _buildNoSubscription()
                      : _buildDashboard(subProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscription() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScaleIn(
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(Icons.card_membership_rounded, size: 44, color: AppColors.primary.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Active Subscription',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Subscribe to TayyebGo Plus for free delivery, discounts, and exclusive perks.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textMutedColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            AnimatedPressScale(
              onTap: () => context.push('/subscription'),
              child: Container(
                width: 220,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'View Plans',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(SubscriptionProvider subProvider) {
    final sub = subProvider.activeSubscription!;
    final color = _planColor(sub.plan);
    final statusColor = _statusColor(sub);
    final totalDays = sub.plan.durationMonths * 30;
    final progress = totalDays > 0 ? (sub.daysRemaining / totalDays).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        AnimatedFadeSlide(
          delay: 100,
          duration: const Duration(milliseconds: 500),
          child: _buildPlanHeader(sub, color, statusColor),
        ),
        const SizedBox(height: 20),
        AnimatedFadeSlide(
          delay: 200,
          duration: const Duration(milliseconds: 500),
          child: _buildProgressSection(sub, color, progress),
        ),
        const SizedBox(height: 20),
        AnimatedFadeSlide(
          delay: 300,
          duration: const Duration(milliseconds: 500),
          child: _buildStatsRow(sub),
        ),
        const SizedBox(height: 20),
        AnimatedFadeSlide(
          delay: 400,
          duration: const Duration(milliseconds: 500),
          child: _buildBenefitsList(sub, color),
        ),
        const SizedBox(height: 20),
        AnimatedFadeSlide(
          delay: 500,
          duration: const Duration(milliseconds: 500),
          child: _buildActionButtons(sub, subProvider),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPlanHeader(CustomerSubscription sub, Color color, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.star_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TayyebGo ${sub.plan.displayName}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: context.textPrimaryColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(sub),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            sub.pricePaid.format(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(CustomerSubscription sub, Color color, double progress) {
    final totalDays = sub.plan.durationMonths * 30;
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Days Remaining',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: context.textPrimaryColor,
                ),
              ),
              Text(
                '${sub.daysRemaining} / $totalDays days',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.surfaceAltColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Expires: ${sub.expiryDate.day}/${sub.expiryDate.month}/${sub.expiryDate.year}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(CustomerSubscription sub) {
    return Row(
      children: [
        Expanded(
          child: TGCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withValues(alpha: 0.15),
                        AppColors.success.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.savings_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${sub.totalSavings.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: context.textPrimaryColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved this period',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TGCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.info.withValues(alpha: 0.15),
                        AppColors.info.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.info, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  '${sub.ordersUsed}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: context.textPrimaryColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Orders used',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsList(CustomerSubscription sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Benefits',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...sub.plan.benefits.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: sub.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : context.surfaceAltColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sub.isActive ? Icons.check : Icons.check,
                    color: sub.isActive ? AppColors.success : AppColors.textMuted,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _benefitLabel(b),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: sub.isActive
                          ? context.textPrimaryColor
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CustomerSubscription sub, SubscriptionProvider subProvider) {
    return Column(
      children: [
        if (!sub.isActive || sub.daysRemaining <= 7)
          AnimatedPressScale(
            onTap: () => context.push('/subscription'),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  sub.isExpired ? 'Renew Subscription' : 'Upgrade Plan',
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
        if (sub.isActive) ...[
          const SizedBox(height: 8),
          AnimatedPressScale(
            onTap: () => _showCancelDialog(subProvider),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Cancel Subscription',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(SubscriptionProvider subProvider) async {
    final confirmed = await context.confirmAction(
      title: 'Cancel Subscription',
      message: 'Are you sure you want to cancel your TayyebGo ${subProvider.activeSubscription?.plan.displayName} subscription? You will lose access to all benefits.',
      confirmLabel: 'Cancel Subscription',
      confirmColor: AppColors.error,
    );
    if (confirmed && mounted) {
      await subProvider.cancel('User cancelled');
      if (mounted) {
        context.showSuccess('Subscription cancelled');
      }
    }
  }
}
