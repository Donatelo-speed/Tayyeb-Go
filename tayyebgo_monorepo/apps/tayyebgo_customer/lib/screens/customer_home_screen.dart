import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
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

  Color _bgForVertical(VerticalType v) {
    switch (v) {
      case VerticalType.restaurant: return const Color(0xFFFFF7ED);
      case VerticalType.grocery: return const Color(0xFFF0FDF4);
      case VerticalType.pharmacy: return const Color(0xFFFEF2F2);
      case VerticalType.retail: return const Color(0xFFF5F3FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final customerId = user?.id;
    final greeting = _greeting();

    return AppScaffold(
      title: '',
      showCart: true,
      showNotifications: true,
      body: FadeTransition(
        opacity: _fade,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _buildHeroBanner(greeting, user),
            const SizedBox(height: 20),
            _buildSearchBar(),
            if (customerId != null) ...[
              const SizedBox(height: 20),
              _LoyaltyCard(customerId: customerId),
            ],
            const SizedBox(height: 24),
            _buildSectionHeader('Active Orders', Icons.receipt_long_rounded,
                onAction: customerId != null ? () => context.go('/order-history') : null,
                actionLabel: 'History'),
            const SizedBox(height: 8),
            if (customerId != null)
              _ActiveOrdersSection(
                customerId: customerId,
                iconForVertical: _iconForVertical,
                colorForVertical: _colorForVertical,
              ),
            if (customerId != null)
              _FavoritesSection(
                customerId: customerId,
                iconForVertical: _iconForVertical,
                colorForVertical: _colorForVertical,
              ),
            const SizedBox(height: 24),
            _VerticalFilterRow(
              selected: _selectedVertical,
              onChanged: (v) => setState(() => _selectedVertical = v),
              iconForVertical: _iconForVertical,
              colorForVertical: _colorForVertical,
              bgForVertical: _bgForVertical,
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Nearby', Icons.near_me_rounded),
            const SizedBox(height: 12),
            _NearbyRestaurantsSection(
              customerId: customerId,
              verticalType: _selectedVertical,
              searchQuery: _searchQuery,
              iconForVertical: _iconForVertical,
              colorForVertical: _colorForVertical,
            ),
          ],
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

  Widget _buildHeroBanner(String greeting, UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: user?.displayName.isNotEmpty == true
                      ? Text(user!.displayName[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20))
                      : const Icon(Icons.person_rounded,
                          color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    user?.displayName.isNotEmpty == true
                        ? user!.displayName
                        : 'Guest',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('What are you craving today?',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search restaurants, cuisines...',
          hintStyle: TextStyle(
              color: TayyebGoTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: TayyebGoTheme.textMuted.withValues(alpha: 0.5)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: TayyebGoTheme.primaryColor),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        const Spacer(),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
      ],
    );
  }
}

class _VerticalFilterRow extends StatelessWidget {
  final VerticalType selected;
  final ValueChanged<VerticalType> onChanged;
  final IconData Function(VerticalType) iconForVertical;
  final Color Function(VerticalType) colorForVertical;
  final Color Function(VerticalType) bgForVertical;

  const _VerticalFilterRow({
    required this.selected,
    required this.onChanged,
    required this.iconForVertical,
    required this.colorForVertical,
    required this.bgForVertical,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: VerticalType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final vt = VerticalType.values[i];
          final active = vt == selected;
          final color = colorForVertical(vt);
          return GestureDetector(
            onTap: () => onChanged(vt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? color : bgForVertical(vt),
                borderRadius: BorderRadius.circular(14),
                border: active
                    ? null
                    : Border.all(
                        color: color.withValues(alpha: 0.2),
                      ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconForVertical(vt),
                      size: 18,
                      color: active ? Colors.white : color),
                  const SizedBox(width: 6),
                  Text(vt.displayName,
                      style: TextStyle(
                        color: active ? Colors.white : color,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  final String customerId;
  const _LoyaltyCard({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final coins = (data?['loyaltyCoins'] as num?)?.toInt() ?? 0;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.redeem_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loyalty Coins',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$coins coins',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Redeem',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
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
  final IconData Function(VerticalType) iconForVertical;
  final Color Function(VerticalType) colorForVertical;

  const _ActiveOrdersSection({
    required this.customerId,
    required this.iconForVertical,
    required this.colorForVertical,
  });

  @override
  State<_ActiveOrdersSection> createState() => _ActiveOrdersSectionState();
}

class _ActiveOrdersSectionState extends State<_ActiveOrdersSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('active_$_retryKey'),
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: widget.customerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        return TripleStateWidget(
          state: snap.hasError
              ? TripleState.error
              : !snap.hasData
                  ? TripleState.loading
                  : TripleState.success,
          errorMessage: snap.hasError
              ? 'Unable to load orders right now.'
              : null,
          onRetry: () => setState(() => _retryKey++),
          shimmerItemCount: 2,
          child: snap.hasData
              ? _buildContent(snap.data!)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(QuerySnapshot snap) {
    final activeDocs = snap.docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return !['delivered', 'cancelled'].contains(d['status']);
    }).toList();
    if (activeDocs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'No active orders',
          subtitle: 'Your orders will appear here once you place one',
        ),
      );
    }
    return Column(
      children: activeDocs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final status = d['status'] as String? ?? '';
        final vt = VerticalType.fromValue(
            d['verticalType'] as String? ?? '');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: InkWell(
            onTap: () => context.go('/tracking/${doc.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.colorForVertical(vt)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.iconForVertical(vt),
                      size: 20,
                      color: widget.colorForVertical(vt)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                          d['restaurantName']
                                  as String? ??
                              'Order',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      OrderStatusBadge(status: status),
                    ],
                  ),
                ),
                Text(
                    '\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: TayyebGoTheme.textMuted),
              ],
            ),
          ),
        );
      }).toList(),
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
  State<_NearbyRestaurantsSection> createState() =>
      _NearbyRestaurantsSectionState();
}

class _NearbyRestaurantsSectionState
    extends State<_NearbyRestaurantsSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('restaurants_${widget.verticalType.value}_$_retryKey'),
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .where('isActive', isEqualTo: true)
          .where('verticalType',
              isEqualTo: widget.verticalType.value)
          .snapshots(),
      builder: (context, snap) {
        return TripleStateWidget(
          state: snap.hasError
              ? TripleState.error
              : !snap.hasData
                  ? TripleState.loading
                  : TripleState.success,
          errorMessage: snap.hasError
              ? 'Unable to load restaurants right now.'
              : null,
          onRetry: () => setState(() => _retryKey++),
          shimmerItemCount: 3,
          child: snap.hasData
              ? _buildContent(snap.data!)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(QuerySnapshot snap) {
    var docs = snap.docs;
    if (widget.searchQuery.isNotEmpty) {
      docs = docs.where((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final name =
            (d['name'] as String? ?? '').toLowerCase();
        final cuisine =
            (d['cuisine'] as String? ?? '').toLowerCase();
        return name.contains(widget.searchQuery) ||
            cuisine.contains(widget.searchQuery);
      }).toList();
    }
    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: EmptyState(
          icon: widget.searchQuery.isNotEmpty
              ? Icons.search_off_rounded
              : widget.iconForVertical(
                  widget.verticalType),
          title: widget.searchQuery.isNotEmpty
              ? 'No results found'
              : 'No ${widget.verticalType.displayName.toLowerCase()}s available',
          subtitle: widget.searchQuery.isNotEmpty
              ? 'Try a different search term'
              : 'Check back later',
        ),
      );
    }
    return Column(
      children: docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? '';
        final commission =
            (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
        final isFav = widget.customerId != null
            ? (d['favoritedBy'] as List<dynamic>?)
                    ?.contains(widget.customerId) ??
                false
            : false;
        final vt = VerticalType.fromValue(
            d['verticalType'] as String? ?? '');
        final rating =
            (d['rating'] as num?)?.toDouble();
        final imageUrl =
            d['imageUrl'] as String?;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.go(
                '/restaurant/${doc.id}',
                extra: {
                  'name': name,
                  'commissionPercent': commission,
                }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(16),
                    color: widget
                        .colorForVertical(vt)
                        .withValues(alpha: 0.1),
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(
                                imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl == null
                      ? Icon(
                          widget.iconForVertical(vt),
                          color:
                              widget.colorForVertical(vt),
                          size: 26,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(vt.displayName,
                              style: const TextStyle(
                                  color: Color(
                                      0xFF94A3B8),
                                  fontSize: 12)),
                          if (rating != null) ...[
                            const SizedBox(width: 10),
                            const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color:
                                    Color(0xFFFBBF24)),
                            const SizedBox(width: 2),
                            Text(
                                rating
                                    .toStringAsFixed(
                                        1),
                                style: const TextStyle(
                                    color: Color(
                                        0xFF94A3B8),
                                    fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _toggleFavorite(doc.id, isFav),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isFav
                          ? Colors.red
                              .withValues(alpha: 0.1)
                          : const Color(0xFFF8FAFC),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isFav
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFav
                          ? Colors.red
                          : const Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _toggleFavorite(
      String id, bool currentlyFav) async {
    if (widget.customerId == null) return;
    if (currentlyFav) {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(id)
          .update({
        'favoritedBy':
            FieldValue.arrayRemove([widget.customerId])
      });
    } else {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(id)
          .update({
        'favoritedBy':
            FieldValue.arrayUnion([widget.customerId])
      });
    }
  }
}

class _FavoritesSection extends StatefulWidget {
  final String customerId;
  final IconData Function(VerticalType) iconForVertical;
  final Color Function(VerticalType) colorForVertical;

  const _FavoritesSection({
    required this.customerId,
    required this.iconForVertical,
    required this.colorForVertical,
  });

  @override
  State<_FavoritesSection> createState() =>
      _FavoritesSectionState();
}

class _FavoritesSectionState extends State<_FavoritesSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('fav_$_retryKey'),
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .where('isActive', isEqualTo: true)
          .where('favoritedBy',
              arrayContains: widget.customerId)
          .snapshots(),
      builder: (context, snap) {
        return TripleStateWidget(
          state: snap.hasError
              ? TripleState.error
              : !snap.hasData
                  ? TripleState.loading
                  : TripleState.success,
          errorMessage: snap.hasError
              ? 'Unable to load favorites.'
              : null,
          onRetry: () => setState(() => _retryKey++),
          shimmerItemCount: 1,
          child: snap.hasData
              ? _buildContent(snap.data!)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(QuerySnapshot snap) {
    if (snap.docs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded,
                size: 16, color: Colors.red),
          ),
          const SizedBox(width: 10),
          const Text('Favorites',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: snap.docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final d = snap.docs[i].data()
                  as Map<String, dynamic>;
              final name =
                  d['name'] as String? ?? '';
              final commission =
                  (d['commissionPercent'] as num?)
                          ?.toDouble() ??
                      15.0;
              final vt = VerticalType.fromValue(
                  d['verticalType'] as String? ?? '');
              final imageUrl =
                  d['imageUrl'] as String?;
              return InkWell(
                onTap: () => context.go(
                    '/restaurant/${snap.docs[i].id}',
                    extra: {
                      'name': name,
                      'commissionPercent':
                          commission,
                    }),
                borderRadius:
                    BorderRadius.circular(16),
                child: Container(
                  width: 130,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(
                            0xFFF1F5F9)),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget
                              .colorForVertical(vt)
                              .withValues(
                                  alpha: 0.1),
                          borderRadius:
                              BorderRadius
                                  .circular(12),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                      imageUrl),
                                  fit: BoxFit
                                      .cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? Icon(
                                widget.iconForVertical(
                                    vt),
                                color: widget
                                    .colorForVertical(
                                        vt),
                                size: 22,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(name,
                          style: const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              fontSize: 12),
                          textAlign:
                              TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow
                              .ellipsis),
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