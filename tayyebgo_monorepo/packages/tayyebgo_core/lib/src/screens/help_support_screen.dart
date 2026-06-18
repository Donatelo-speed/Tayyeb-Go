import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: context.backgroundColor,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: context.textPrimaryColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text('Help & Support',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor)),
                centerTitle: true,
              ),

              // Hero
              SliverToBoxAdapter(child: _buildHero(context)),

              // FAQ
              SliverToBoxAdapter(child: _buildSectionTitle(context, 'Frequently Asked Questions')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: _faqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return _buildFaqCard(context, faq['q']!, faq['a']!);
                  },
                ),
              ),

              // Contact
              SliverToBoxAdapter(child: const SizedBox(height: 32)),
              SliverToBoxAdapter(child: _buildSectionTitle(context, 'Contact Us')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: _contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = _contacts[index];
                    return _buildContactCard(
                      context,
                      icon: c['icon'] as IconData,
                      title: c['title'] as String,
                      subtitle: c['subtitle'] as String,
                      url: c['url'] as String,
                    );
                  },
                ),
              ),

              // Submit ticket
              SliverToBoxAdapter(child: _buildSubmitTicketButton(context)),

              // Hours
              SliverToBoxAdapter(child: _buildHoursCard(context)),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Semantics(
      label: 'Help and support center',
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryHover,
              AppColors.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: AppRadius.brXl,
          boxShadow: [
            BoxShadow(
              color: AppColors.glowPrimary,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we\nhelp you?',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Find answers or reach out to our support team.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.brFull,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryHover],
              ),
              borderRadius: AppRadius.brSm,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, String question, String answer) {
    return AnimatedPressScale(
      onTap: null,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            iconColor: AppColors.primary,
            collapsedIconColor: context.textMutedColor,
            children: [
              Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
            title: Text(
              question,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return AnimatedPressScale(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textMutedColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitTicketButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: AnimatedPressScale(
        onTap: () => context.push('/create-ticket'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryHover],
            ),
            borderRadius: AppRadius.brLg,
            boxShadow: [
              BoxShadow(
                color: AppColors.glowPrimary,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Submit a Ticket',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Operating Hours'),
            const SizedBox(height: 4),
            _hoursRow(context, 'Customer Support', '24/7', AppColors.success),
            const SizedBox(height: 10),
            _hoursRow(context, 'Phone Support', '9 AM — 11 PM (Damascus)', AppColors.info),
            const SizedBox(height: 10),
            _hoursRow(context, 'Email Response', 'Within 24 hours', AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _hoursRow(BuildContext context, String label, String hours, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: context.textPrimaryColor,
            ),
          ),
        ),
        Text(
          hours,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

const _faqs = [
  {
    'q': 'How do I track my order?',
    'a': 'Once your order is placed, go to the Orders tab and tap on the active order. You can see real-time status updates and driver location.',
  },
  {
    'q': 'How do I cancel an order?',
    'a': 'Open your active order and tap "Cancel Order". You can cancel before the restaurant accepts the order for a full refund.',
  },
  {
    'q': 'How do I request a refund?',
    'a': 'Go to Order History, select the order, and tap "Report Issue". Describe the problem and our team will review within 24 hours.',
  },
  {
    'q': 'How do I change my delivery address?',
    'a': 'Go to Profile > Addresses to add, edit, or remove delivery addresses.',
  },
  {
    'q': 'How do I apply a promo code?',
    'a': 'At checkout, tap "Apply Promo Code" and enter your code. The discount will be applied to your order total.',
  },
  {
    'q': 'How do I become a driver?',
    'a': 'Download the TayyebGo Driver app, create an account, and complete the onboarding process. You\'ll need a valid driver\'s license and vehicle registration.',
  },
];

const _contacts = [
  {
    'icon': Icons.email_rounded,
    'title': 'Email Support',
    'subtitle': 'support@tayyebgo.com',
    'url': 'mailto:support@tayyebgo.com',
  },
  {
    'icon': Icons.phone_rounded,
    'title': 'Phone Support',
    'subtitle': '+963 11 234 5678',
    'url': 'tel:+963112345678',
  },
  {
    'icon': Icons.chat_rounded,
    'title': 'WhatsApp',
    'subtitle': 'Chat with us',
    'url': 'https://wa.me/963112345678',
  },
];
