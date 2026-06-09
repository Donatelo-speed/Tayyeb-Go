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
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_greeting(), style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                user?.displayName.isNotEmpty == true ? user!.displayName : 'Guest',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w200, fontSize: 28, color: context.textPrimaryColor),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.borderColor)),
                            child: Icon(Icons.notifications_outlined, color: context.textMutedColor, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text('What are you craving?', style: GoogleFonts.inter(fontWeight: FontWeight.w200, fontSize: 24, color: context.textPrimaryColor)),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                        return _ScaleOnTap(
                          onTap: () => setState(() => _selectedVertical = vt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: 88,
                            decoration: BoxDecoration(
                              color: active ? color.withValues(alpha: 0.15) : context.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: active ? color.withValues(alpha: 0.4) : context.borderColor, width: active ? 1.5 : 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: active ? color.withValues(alpha: 0.2) : context.surfaceAltColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_iconForVertical(vt), color: active ? color : context.textMutedColor, size: 24),
                                ),
                                const SizedBox(height: 8),
                                Text(vt.displayName, style: TextStyle(color: active ? color : context.textMutedColor, fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.borderColor)),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      style: GoogleFonts.inter(color: context.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'Search restaurants, cuisines...',
                        hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                        prefixIcon: Icon(Icons.search_rounded, color: context.textMutedColor, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: 20, color: context.textMutedColor),
                                onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
              ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _LoyaltyCard(customerId: customerId),
                  ),
                ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Row(
                      children: [
                        Text('Active Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go('/order-history'),
                          child: Text('History', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.primaryColor)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _ActiveOrdersSection(customerId: customerId),
                  ),
                ),

              if (customerId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: _FavoritesSection(customerId: customerId),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Text('Nearby', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
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
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [context.primaryColor, const Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: context.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.redeem_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loyalty Coins', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    const SizedBox(height: 4),
                    AnimatedCounter(
                      value: coins, prefix: '', suffix: ' coins',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Redeem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)),
        child: Column(
          children: [
            Icon(Icons.shopping_bag_outlined, color: context.textMutedColor, size: 40),
            const SizedBox(height: 12),
            Text('No active orders', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Your orders will appear here', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      children: docs.map((d) {
        final status = d['status'] as String? ?? '';
        return GestureDetector(
          onTap: () => context.go('/tracking/${d['id']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.receipt_long_rounded, size: 20, color: context.primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['restaurantName'] as String? ?? 'Order', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                      const SizedBox(height: 4),
                      OrderStatusBadge(status: status),
                    ],
                  ),
                ),
                Text('\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: context.textMutedColor, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
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
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final d = docs[i];
          final name = d['name'] as String? ?? '';
          final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
          final imageUrl = d['imageUrl'] as String?;
          return GestureDetector(
            onTap: () => context.go('/restaurant/${d['id']}', extra: {'name': name, 'commissionPercent': commission}),
            child: Container(
              width: 120,
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TGAvatar(
                    initials: name, imageUrl: imageUrl, size: TGAvatarSize.sm,
                    backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)),
        child: Column(
          children: [
            Icon(widget.searchQuery.isNotEmpty ? Icons.search_off_rounded : widget.iconForVertical(widget.verticalType), color: context.textMutedColor, size: 40),
            const SizedBox(height: 12),
            Text(widget.searchQuery.isNotEmpty ? 'No results found' : 'No ${widget.verticalType.displayName.toLowerCase()}s available', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor, fontSize: 15)),
            const SizedBox(height: 4),
            Text(widget.searchQuery.isNotEmpty ? 'Try a different search term' : 'Check back later', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      children: docs.map((d) {
        final name = d['name'] as String? ?? '';
        final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
        final isFav = widget.customerId != null ? (d['favoritedBy'] as List<dynamic>?)?.contains(widget.customerId) ?? false : false;
        final cuisine = d['cuisine'] as String? ?? widget.verticalType.displayName;
        final rating = (d['rating'] as num?)?.toDouble();
        final imageUrl = d['imageUrl'] as String?;
        return _ScaleOnTap(
          onTap: () => context.go('/restaurant/${d['id']}', extra: {'name': name, 'commissionPercent': commission}),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null
                      ? Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Container(
                          height: 160, width: double.infinity,
                          color: context.surfaceAltColor,
                          child: Icon(widget.iconForVertical(widget.verticalType), color: context.textMutedColor, size: 48),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: context.textPrimaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                if (rating != null) ...[
                                  Icon(Icons.star_rounded, size: 16, color: context.warningColor),
                                  const SizedBox(width: 2),
                                  Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(cuisine, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _infoChip(context, Icons.access_time_rounded, '20-30 min'),
                                const SizedBox(width: 12),
                                _infoChip(context, Icons.delivery_dining_rounded, 'Free delivery'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorite(d['id'] as String, isFav),
                        child: _ScaleOnTap(
                          onTap: () => _toggleFavorite(d['id'] as String, isFav),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: isFav ? Colors.red.withValues(alpha: 0.1) : context.surfaceAltColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : context.textMutedColor, size: 20),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textMutedColor),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
      ],
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
