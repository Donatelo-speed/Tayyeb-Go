import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  VerticalType _selectedVertical = VerticalType.restaurant;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late final ScrollController _scrollController;
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  IconData _iconForVertical(VerticalType v) {
    switch (v) {
      case VerticalType.restaurant: return Icons.restaurant_rounded;
      case VerticalType.grocery: return Icons.local_grocery_store_rounded;
      case VerticalType.pharmacy: return Icons.local_pharmacy_rounded;
      case VerticalType.retail: return Icons.store_rounded;
    }
  }

  Color _colorForVertical(VerticalType v) {
    switch (v) {
      case VerticalType.restaurant: return const Color(0xFFF97316);
      case VerticalType.grocery: return const Color(0xFF22C55E);
      case VerticalType.pharmacy: return const Color(0xFFEF4444);
      case VerticalType.retail: return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final customerId = user?.id;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: AnimatedFadeSlide(
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      children: [
                        // Location selector
                        GestureDetector(
                          onTap: () => context.push('/addresses'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryHover]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Deliver to', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                    Text('Al Hamra, Homs', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Notification bell
                        AnimatedPressScale(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: Stack(
                              children: [
                                Center(child: Icon(Icons.notifications_outlined, color: context.textMutedColor, size: 22)),
                                Positioned(
                                  right: 10, top: 10,
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: AppColors.error, blurRadius: 4, spreadRadius: 1)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 100,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(), style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryHover],
                        ).createShader(bounds),
                        child: Text(
                          user?.displayName.isNotEmpty == true ? user!.displayName : 'Guest',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 32, color: Colors.white, letterSpacing: 0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 200,
                  duration: const Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: () => context.push('/explore'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                          const SizedBox(width: 12),
                          Text('Search restaurants, cuisines...', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quick categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AnimatedFadeSlide(
                  delay: 250,
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    children: [
                      _categoryChip(context, Icons.restaurant_rounded, 'Food', AppColors.primary),
                      const SizedBox(width: 10),
                      _categoryChip(context, Icons.local_grocery_store_rounded, 'Grocery', AppColors.driverAccent),
                      const SizedBox(width: 10),
                      _categoryChip(context, Icons.local_pharmacy_rounded, 'Pharmacy', AppColors.error),
                      const SizedBox(width: 10),
                      _categoryChip(context, Icons.store_rounded, 'Retail', AppColors.adminAccent),
                    ],
                  ),
                ),
              ),
            ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: AnimatedFadeSlide(
                    delay: 150,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'What are you craving?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: context.textPrimaryColor,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: AnimatedFadeSlide(
                    delay: 200,
                    duration: const Duration(milliseconds: 500),
                    child: SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: VerticalType.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final vt = VerticalType.values[i];
                          final active = vt == _selectedVertical;
                          final color = _colorForVertical(vt);
                          return AnimatedPressScale(
                            onTap: () => setState(() => _selectedVertical = vt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: 88,
                              decoration: BoxDecoration(
                                color: active
                                    ? color.withValues(alpha: 0.12)
                                    : context.surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: active
                                      ? color.withValues(alpha: 0.3)
                                      : context.borderColor.withValues(alpha: 0.4),
                                  width: active ? 1.5 : 0.5,
                                ),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? color.withValues(alpha: 0.18)
                                          : context.surfaceAltColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _iconForVertical(vt),
                                      color: active ? color : context.textMutedColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vt.displayName,
                                    style: TextStyle(
                                      color: active ? color : context.textMutedColor,
                                      fontSize: 12,
                                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: AnimatedFadeSlide(
                    delay: 250,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(18),
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
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                        style: GoogleFonts.inter(
                          color: context.textPrimaryColor,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search restaurants, cuisines...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? AnimatedFadeSlide(
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: AnimatedFadeSlide(
                      delay: 300,
                      duration: const Duration(milliseconds: 500),
                      child: _LoyaltyCard(customerId: customerId),
                    ),
                  ),
                ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: AnimatedFadeSlide(
                      delay: 325,
                      duration: const Duration(milliseconds: 500),
                      child: _LoyaltyPointsBanner(),
                    ),
                  ),
                ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: AnimatedFadeSlide(
                      delay: 345,
                      duration: const Duration(milliseconds: 500),
                      child: _QuickActionsGrid(),
                    ),
                  ),
                ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: AnimatedFadeSlide(
                      delay: 350,
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.primary, AppColors.primaryHover],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Active Orders',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: context.textPrimaryColor,
                              letterSpacing: 0,
                            ),
                          ),
                          const Spacer(),
                          AnimatedPressScale(
                            onTap: () => context.push('/order-history'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'History',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: AnimatedFadeSlide(
                      delay: 400,
                      duration: const Duration(milliseconds: 500),
                      child: _ActiveOrdersSection(customerId: customerId),
                    ),
                  ),
                ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: AnimatedFadeSlide(
                      delay: 450,
                      duration: const Duration(milliseconds: 500),
                      child: _RecommendationsSection(customerId: customerId),
                    ),
                  ),
                ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: AnimatedFadeSlide(
                      delay: 500,
                      duration: const Duration(milliseconds: 500),
                      child: _FavoritesSection(customerId: customerId),
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: AnimatedFadeSlide(
                    delay: 550,
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.customerAccent, Color(0xFFFFB703)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nearby',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: context.textPrimaryColor,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: _NearbyRestaurantsSection(
                    customerId: customerId,
                    verticalType: _selectedVertical,
                    searchQuery: _searchQuery,
                    iconForVertical: _iconForVertical,
                    colorForVertical: _colorForVertical,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _categoryChip(BuildContext context, IconData icon, String label, Color color) {
    return Expanded(
      child: AnimatedPressScale(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  final String customerId;
  const _LoyaltyCard({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<CustomerHomeProvider>().watchLoyalty(customerId),
      builder: (_, snap) {
        final data = snap.data?.isNotEmpty == true ? snap.data!.first : null;
        final coins = (data?['loyaltyCoins'] as num?)?.toInt() ?? 0;
        return TGCGradient(
          gradient: const [AppColors.primary, Color(0xFF8B5CF6)],
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.redeem_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loyalty Coins',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedCounter(
                      value: coins,
                      prefix: '',
                      suffix: ' coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPressScale(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Redeem',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveOrdersSection extends StatefulWidget {
  final String customerId;
  const _ActiveOrdersSection({required this.customerId});
  @override
  State<_ActiveOrdersSection> createState() => _ActiveOrdersSectionState();
}

class _ActiveOrdersSectionState extends State<_ActiveOrdersSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('active_$_retryKey'),
      stream: context.read<CustomerHomeProvider>().watchActiveOrders(widget.customerId),
      builder: (context, snap) {
        return TripleStateWidget(
          state: snap.hasError ? TripleState.error : !snap.hasData ? TripleState.loading : TripleState.success,
          errorMessage: snap.hasError ? 'Unable to load orders right now.' : null,
          onRetry: () => setState(() => _retryKey++),
          shimmerItemCount: 2,
          child: snap.hasData ? _buildContent(context, snap.data!) : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No active orders',
        subtitle: 'Your orders will appear here',
        accentColor: AppColors.primary,
      );
    }
    return Column(
      children: docs.map((d) {
        final status = d['status'] as String? ?? '';
        return AnimatedPressScale(
          onTap: () => context.push('/tracking/${d['id']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.borderColor.withValues(alpha: 0.4),
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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.primaryColor.withValues(alpha: 0.15),
                        context.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 22,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['restaurantName'] as String? ?? 'Order',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: context.textPrimaryColor,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      OrderStatusBadge(status: status),
                    ],
                  ),
                ),
                Text(
                  '\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: context.textPrimaryColor,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: context.textMutedColor,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationsSection extends StatefulWidget {
  final String customerId;
  const _RecommendationsSection({required this.customerId});
  @override
  State<_RecommendationsSection> createState() => _RecommendationsSectionState();
}

class _RecommendationsSectionState extends State<_RecommendationsSection> {
  final _recEngine = RecommendationEngine();
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final recs = await _recEngine.getRecommendedRestaurants(userId: widget.customerId, limit: 6);
      if (mounted) setState(() { _restaurants = recs; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const HorizontalSkeleton();
    if (_restaurants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryHover],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'For You',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: context.textPrimaryColor,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final r = _restaurants[i];
              final name = r['name'] as String? ?? '';
              final cuisine = r['cuisine'] as String? ?? r['cuisineType'] as String? ?? '';
              final imageUrl = r['imageUrl'] as String?;
              final rating = (r['rating'] as num?)?.toDouble() ?? 0;
              final id = r['id'] as String? ?? '';

              return AnimatedPressScale(
                onTap: () => context.push('/restaurant/$id'),
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: context.borderColor.withValues(alpha: 0.4),
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: context.surfaceAltColor,
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Container(
                                height: 100,
                                width: double.infinity,
                                color: context.surfaceAltColor,
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: context.textPrimaryColor,
                                letterSpacing: 0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cuisine,
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating > 0 ? rating.toStringAsFixed(1) : 'New',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FavoritesSection extends StatefulWidget {
  final String customerId;
  const _FavoritesSection({required this.customerId});
  @override
  State<_FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<_FavoritesSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('fav_$_retryKey'),
      stream: context.read<CustomerHomeProvider>().watchFavorites(widget.customerId),
      builder: (context, snap) {
        return TripleStateWidget(
          state: snap.hasError ? TripleState.error : !snap.hasData ? TripleState.loading : TripleState.success,
          errorMessage: snap.hasError ? 'Unable to load favorites.' : null,
          onRetry: () => setState(() => _retryKey++),
          shimmerItemCount: 1,
          child: snap.hasData ? _buildContent(context, snap.data!) : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final d = docs[i];
          final name = d['name'] as String? ?? '';
          final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
          final imageUrl = d['imageUrl'] as String?;
          return AnimatedPressScale(
            onTap: () => context.push('/restaurant/${d['id']}', extra: {'name': name, 'commissionPercent': commission}),
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TGAvatar(
                    initials: name,
                    imageUrl: imageUrl,
                    size: TGAvatarSize.sm,
                    backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: context.textPrimaryColor,
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NearbyRestaurantsSection extends StatefulWidget {
  final String? customerId;
  final VerticalType verticalType;
  final String searchQuery;
  final IconData Function(VerticalType) iconForVertical;
  final Color Function(VerticalType) colorForVertical;

  const _NearbyRestaurantsSection({
    this.customerId,
    required this.verticalType,
    required this.searchQuery,
    required this.iconForVertical,
    required this.colorForVertical,
  });

  @override
  State<_NearbyRestaurantsSection> createState() => _NearbyRestaurantsSectionState();
}

class _NearbyRestaurantsSectionState extends State<_NearbyRestaurantsSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('restaurants_${widget.verticalType.value}_$_retryKey'),
      stream: context.read<CustomerHomeProvider>().watchRestaurants(widget.verticalType.value),
      builder: (context, snap) {
        return TripleStateWidget(
          state: snap.hasError ? TripleState.error : !snap.hasData ? TripleState.loading : TripleState.success,
          errorMessage: snap.hasError ? 'Unable to load restaurants right now.' : null,
          onRetry: () => setState(() => _retryKey++),
          shimmerItemCount: 3,
          child: snap.hasData ? _buildContent(context, snap.data!) : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Map<String, dynamic>> docs) {
    if (widget.searchQuery.isNotEmpty) {
      docs = docs.where((d) {
        final name = (d['name'] as String? ?? '').toLowerCase();
        final cuisine = (d['cuisine'] as String? ?? '').toLowerCase();
        return name.contains(widget.searchQuery) || cuisine.contains(widget.searchQuery);
      }).toList();
    }
    if (docs.isEmpty) {
      return EmptyState(
        icon: widget.searchQuery.isNotEmpty
            ? Icons.search_off_rounded
            : widget.iconForVertical(widget.verticalType),
        title: widget.searchQuery.isNotEmpty
            ? 'No results found'
            : 'No ${widget.verticalType.displayName.toLowerCase()}s available',
        subtitle: widget.searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Check back later',
        accentColor: widget.colorForVertical(widget.verticalType),
      );
    }
    return Column(
      children: docs.map((d) {
        final name = d['name'] as String? ?? '';
        final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
        final isFav = widget.customerId != null
            ? (d['favoritedBy'] as List<dynamic>?)?.contains(widget.customerId) ?? false
            : false;
        final cuisine = d['cuisine'] as String? ?? widget.verticalType.displayName;
        final rating = (d['rating'] as num?)?.toDouble();
        final imageUrl = d['imageUrl'] as String?;
        return AnimatedPressScale(
          onTap: () => context.push('/restaurant/${d['id']}', extra: {'name': name, 'commissionPercent': commission}),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.borderColor.withValues(alpha: 0.4),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 170,
                          width: double.infinity,
                          color: context.surfaceAltColor,
                          child: Icon(
                            widget.iconForVertical(widget.verticalType),
                            color: context.textMutedColor,
                            size: 52,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: context.textPrimaryColor,
                                      letterSpacing: 0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (rating != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cuisine,
                              style: GoogleFonts.inter(
                                color: context.textMutedColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _infoChip(context, Icons.delivery_dining_rounded, 'Delivery'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedPressScale(
                        onTap: () => _toggleFavorite(d['id'] as String, isFav),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isFav
                                ? Colors.red.withValues(alpha: 0.1)
                                : context.surfaceAltColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : context.textMutedColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceAltColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.textMutedColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: context.textMutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(String id, bool currentlyFav) async {
    if (widget.customerId == null) return;
    await context.read<CustomerHomeProvider>().toggleFavorite(id, widget.customerId!, currentlyFav);
  }
}

class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleOnTap({required this.child, required this.onTap});

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class _LoyaltyPointsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final points = data?['loyaltyPoints'] ?? 0;
        return AnimatedPressScale(
          onTap: () => context.push('/points-rewards'),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loyalty Points', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white, letterSpacing: 0)),
                      const SizedBox(height: 4),
                      Text('Earn points on every order', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('$points pts', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedPressScale(
            onTap: () => context.push('/wallet'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(height: 8),
                  Text('Wallet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: context.textPrimaryColor)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedPressScale(
            onTap: () => context.push('/points-rewards'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.15), width: 0.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 24),
                  const SizedBox(height: 8),
                  Text('Rewards', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: context.textPrimaryColor)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedPressScale(
            onTap: () => context.push('/order-history'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.driverAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.driverAccent.withValues(alpha: 0.15), width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.driverAccent, size: 24),
                  const SizedBox(height: 8),
                  Text('Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: context.textPrimaryColor)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedPressScale(
            onTap: () => context.push('/addresses'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.15), width: 0.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF22C55E), size: 24),
                  const SizedBox(height: 8),
                  Text('Address', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: context.textPrimaryColor)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
