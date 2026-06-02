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

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  VerticalType _selectedVertical = VerticalType.restaurant;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _iconForVertical(VerticalType v) {
    switch (v) {
      case VerticalType.restaurant:
        return Icons.restaurant;
      case VerticalType.grocery:
        return Icons.local_grocery_store;
      case VerticalType.pharmacy:
        return Icons.local_pharmacy;
      case VerticalType.retail:
        return Icons.store;
    }
  }

  Color _colorForVertical(VerticalType v) {
    switch (v) {
      case VerticalType.restaurant:
        return TayyebGoTheme.primaryColor;
      case VerticalType.grocery:
        return const Color(0xFF43A047);
      case VerticalType.pharmacy:
        return const Color(0xFFE53935);
      case VerticalType.retail:
        return const Color(0xFFFFA000);
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildGreeting(greeting, user),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 20),
          if (customerId != null) _LoyaltyCard(customerId: customerId),
          if (customerId != null) const SizedBox(height: 20),
          _buildSectionHeader('Your Orders', Icons.receipt_outlined, onAction: customerId != null ? () => context.go('/order-history') : null, actionLabel: 'History'),
          const SizedBox(height: 8),
          if (customerId != null)
            _ActiveOrdersSection(
              customerId: customerId,
              iconForVertical: _iconForVertical,
              colorForVertical: _colorForVertical,
            ),
          const SizedBox(height: 24),
          if (customerId != null)
            _FavoritesSection(
              customerId: customerId,
              iconForVertical: _iconForVertical,
              colorForVertical: _colorForVertical,
            ),
          if (customerId != null) const SizedBox(height: 24),
          _VerticalFilterRow(
            selected: _selectedVertical,
            onChanged: (v) => setState(() => _selectedVertical = v),
            iconForVertical: _iconForVertical,
            colorForVertical: _colorForVertical,
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Nearby ${_selectedVertical.displayName}s', Icons.location_on_outlined),
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
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildGreeting(String greeting, UserModel? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
          backgroundImage: user?.photoUrl != null
              ? NetworkImage(user!.photoUrl!) as ImageProvider
              : null,
          child: user?.photoUrl == null && user?.displayName.isNotEmpty == true
              ? Text(user!.displayName[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor))
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13)),
            Text(
              user?.displayName.isNotEmpty == true ? user!.displayName : 'Guest',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search restaurants, cuisines...',
        hintStyle: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: TayyebGoTheme.textMuted),
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
        fillColor: TayyebGoTheme.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: TayyebGoTheme.dividerColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: TayyebGoTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: TayyebGoTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: TayyebGoTheme.heading3),
        const Spacer(),
        if (onAction != null && actionLabel != null)
          TextButton.icon(
            icon: const Icon(Icons.arrow_forward_ios, size: 12),
            label: Text(actionLabel, style: const TextStyle(fontSize: 13)),
            onPressed: onAction,
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

  const _VerticalFilterRow({
    required this.selected,
    required this.onChanged,
    required this.iconForVertical,
    required this.colorForVertical,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: VerticalType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final vt = VerticalType.values[i];
          final isSelected = vt == selected;
          return ChoiceChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconForVertical(vt), size: 16, color: isSelected ? Colors.white : colorForVertical(vt)),
                const SizedBox(width: 6),
                Text(vt.displayName),
              ],
            ),
            selectedColor: colorForVertical(vt),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : TayyebGoTheme.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            backgroundColor: TayyebGoTheme.chipBackground,
            side: BorderSide.none,
            onSelected: (_) => onChanged(vt),
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
      stream: FirebaseFirestore.instance.collection('Users').doc(customerId).snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final coins = (data?['loyaltyCoins'] as num?)?.toInt() ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [TayyebGoTheme.primaryColor, TayyebGoTheme.primaryColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: TayyebGoTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loyalty Coins', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '$coins coins',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
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
      key: ValueKey('active_orders_$_retryKey'),
      stream: FirebaseFirestore.instance
          .collection('Orders')
          .where('customerId', isEqualTo: widget.customerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final friendlyError = snap.hasError
            ? 'Unable to load orders right now. Please try again.'
            : null;
        return TripleStateWidget(
          state: snap.hasError
              ? TripleState.error
              : !snap.hasData
                  ? TripleState.loading
                  : TripleState.success,
          errorMessage: friendlyError,
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
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No active orders',
        subtitle: 'Your orders will appear here once you place one',
      );
    }
    return Column(
      children: activeDocs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final status = d['status'] as String? ?? '';
        final vt = VerticalType.fromValue(d['verticalType'] as String? ?? '');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: TayyebGoTheme.cardDecoration,
          child: InkWell(
            onTap: () => context.go('/tracking/${doc.id}'),
            borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
            child: Row(
              children: [
                Icon(widget.iconForVertical(vt), size: 20, color: widget.colorForVertical(vt)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['restaurantName'] as String? ?? 'Order',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      OrderStatusBadge(status: status),
                    ],
                  ),
                ),
                Text('\$${(d['totalAmount'] as num?)?.toDouble() ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
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
  State<_NearbyRestaurantsSection> createState() => _NearbyRestaurantsSectionState();
}

class _NearbyRestaurantsSectionState extends State<_NearbyRestaurantsSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('restaurants_${widget.verticalType.value}_$_retryKey'),
      stream: FirebaseFirestore.instance
          .collection('Restaurants')
          .where('isActive', isEqualTo: true)
          .where('verticalType', isEqualTo: widget.verticalType.value)
          .snapshots(),
      builder: (context, snap) {
        final friendlyError = snap.hasError
            ? 'Unable to load restaurants right now. Please try again.'
            : null;
        return TripleStateWidget(
          state: snap.hasError
              ? TripleState.error
              : !snap.hasData
                  ? TripleState.loading
                  : TripleState.success,
          errorMessage: friendlyError,
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
        final name = (d['name'] as String? ?? '').toLowerCase();
        final cuisine = (d['cuisine'] as String? ?? '').toLowerCase();
        return name.contains(widget.searchQuery) || cuisine.contains(widget.searchQuery);
      }).toList();
    }
    if (docs.isEmpty) {
      return EmptyState(
        icon: widget.searchQuery.isNotEmpty ? Icons.search_off_rounded : widget.iconForVertical(widget.verticalType),
        title: widget.searchQuery.isNotEmpty
            ? 'No results found'
            : 'No ${widget.verticalType.displayName.toLowerCase()}s available',
        subtitle: widget.searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Check back later for new options in your area',
      );
    }
    return Column(
      children: docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
        final isFav = widget.customerId != null
            ? (d['favoritedBy'] as List<dynamic>?)?.contains(widget.customerId) ?? false
            : false;
        final vt = VerticalType.fromValue(d['verticalType'] as String? ?? '');
        final rating = (d['rating'] as num?)?.toDouble();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: TayyebGoTheme.cardDecoration,
          child: InkWell(
            borderRadius: BorderRadius.circular(TayyebGoTheme.radiusMd),
            onTap: () => context.go('/restaurant/${doc.id}', extra: {
              'name': d['name'] ?? '',
              'commissionPercent': commission,
            }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: widget.colorForVertical(vt).withValues(alpha: 0.1),
                  child: Icon(widget.iconForVertical(vt), color: widget.colorForVertical(vt)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['name'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(vt.displayName,
                              style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                          if (rating != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            Text(rating.toStringAsFixed(1),
                                style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : TayyebGoTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavorite(doc.id, isFav),
                ),
                Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _toggleFavorite(String restaurantId, bool currentlyFav) async {
    if (widget.customerId == null) return;
    if (currentlyFav) {
      await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .update({'favoritedBy': FieldValue.arrayRemove([widget.customerId])});
    } else {
      await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .update({'favoritedBy': FieldValue.arrayUnion([widget.customerId])});
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
  State<_FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<_FavoritesSection> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('favorites_$_retryKey'),
      stream: FirebaseFirestore.instance
          .collection('Restaurants')
          .where('isActive', isEqualTo: true)
          .where('favoritedBy', arrayContains: widget.customerId)
          .snapshots(),
      builder: (context, snap) {
        final friendlyError = snap.hasError
            ? 'Unable to load your favorites right now. Please try again.'
            : null;
        return TripleStateWidget(
          state: snap.hasError
              ? TripleState.error
              : !snap.hasData
                  ? TripleState.loading
                  : TripleState.success,
          errorMessage: friendlyError,
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
        Row(children: [
          const Icon(Icons.favorite, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Text('Favorites', style: TayyebGoTheme.heading3),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: snap.docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final d = snap.docs[i].data() as Map<String, dynamic>;
              final name = d['name'] as String? ?? '';
              final commission = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
              final vt = VerticalType.fromValue(d['verticalType'] as String? ?? '');
              return InkWell(
                onTap: () => context.go('/restaurant/${snap.docs[i].id}', extra: {
                  'name': name,
                  'commissionPercent': commission,
                }),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TayyebGoTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TayyebGoTheme.dividerColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.iconForVertical(vt), color: widget.colorForVertical(vt), size: 28),
                      const SizedBox(height: 6),
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
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
