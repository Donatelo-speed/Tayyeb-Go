import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];
  List<String> _suggestions = [];
  List<String> _trendingSearches = [];
  bool _showSuggestions = false;

  final _smartSearch = SmartSearchService();

  final _categories = [
    ('All', Icons.grid_view_rounded),
    ('Restaurant', Icons.restaurant_rounded),
    ('Grocery', Icons.local_grocery_store_rounded),
    ('Pharmacy', Icons.local_pharmacy_rounded),
    ('Retail', Icons.store_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendingSearches();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _searchCtrl.text.length >= 2) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTrendingSearches() async {
    try {
      final trending = await _smartSearch.getTrendingSearches();
      if (mounted) setState(() => _trendingSearches = trending);
    } catch (_) {
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
          _showSuggestions = query.trim().length >= 2;
        });
        if (query.trim().length >= 2) {
          try {
            final suggestions = await _smartSearch.getSuggestions(query.trim());
            if (mounted) setState(() => _suggestions = suggestions);
          } catch (_) {
          }
        }
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });
    _focusNode.unfocus();

    final userId = AuthProvider.instance?.user?.id ?? '';
    if (userId.isNotEmpty) {
      _smartSearch.saveSearchQuery(userId, query);
    }

    try {
      final results = await _smartSearch.search(
        query: query,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _showSuggestions = false;
    });
  }

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
                    Expanded(
                      child: Text(
                        'Explore',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          color: context.textPrimaryColor,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AnimatedPressScale(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.08),
                          borderRadius: AppRadius.brMd,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: context.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nearby',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: context.primaryColor,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: AnimatedFadeSlide(
                delay: 100,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: AppRadius.brCard,
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
                        focusNode: _focusNode,
                        onChanged: _onSearchChanged,
                        onSubmitted: _performSearch,
                        style: GoogleFonts.inter(
                          color: context.textPrimaryColor,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search restaurants, food, stores...',
                          hintStyle: GoogleFonts.inter(
                            color: context.textMutedColor,
                            fontSize: 15,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.search_rounded,
                              color: context.textMutedColor,
                              size: 22,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? AnimatedFadeSlide(
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: context.textMutedColor,
                                    ),
                                    onPressed: _clearSearch,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.brCard,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    if (_showSuggestions && (_suggestions.isNotEmpty || _trendingSearches.isNotEmpty))
                      AnimatedFadeSlide(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: AppRadius.brCard,
                            border: Border.all(
                              color: context.borderColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_suggestions.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                                  child: Text(
                                    'Suggestions',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: context.textMutedColor,
                                    ),
                                  ),
                                ),
                                ..._suggestions.map((s) => ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: context.textMutedColor,
                                  ),
                                  title: Text(
                                    s,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  onTap: () {
                                    _searchCtrl.text = s;
                                    _performSearch(s);
                                  },
                                )),
                              ],
                              if (_trendingSearches.isNotEmpty && _searchQuery.isEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                                  child: Text(
                                    'Trending',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: context.textMutedColor,
                                    ),
                                  ),
                                ),
                                ..._trendingSearches.map((s) => ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 18,
                                    color: context.warningColor,
                                  ),
                                  title: Text(
                                    s,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  onTap: () {
                                    _searchCtrl.text = s;
                                    _performSearch(s);
                                  },
                                )),
                              ],
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: AnimatedFadeSlide(
                delay: 200,
                duration: const Duration(milliseconds: 500),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (label, icon) = _categories[i];
                    final selected = _selectedCategory == label;
                    return AnimatedPressScale(
                      onTap: () {
                        setState(() => _selectedCategory = label);
                        if (_searchQuery.isNotEmpty) _performSearch(_searchQuery);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? context.primaryColor
                              : context.surfaceColor,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(
                            color: selected
                                ? context.primaryColor
                                : context.borderColor.withValues(alpha: 0.4),
                            width: selected ? 1 : 0.5,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: context.primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : context.textMutedColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: selected
                                    ? Colors.white
                                    : context.textMutedColor,
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
            const SizedBox(height: 4),
            Expanded(
              child: _searchQuery.isNotEmpty || _isSearching
                  ? _buildSearchResults()
                  : _buildRestaurantStream(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: context.primaryColor,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results for "$_searchQuery"',
        subtitle: 'Try a different search term',
        actionText: 'Clear Search',
        onAction: _clearSearch,
        accentColor: context.primaryColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return AnimatedFadeSlide(
          delay: (index * 50).toDouble(),
          duration: const Duration(milliseconds: 400),
          child: _buildSearchResultCard(result),
        );
      },
    );
  }

  Widget _buildSearchResultCard(SearchResult result) {
    return AnimatedPressScale(
      onTap: () {
        if (result.type == 'restaurant') {
          context.push('/restaurant/${result.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brCard,
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.primaryColor.withValues(alpha: 0.15),
                    context.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: AppRadius.brMd,
              ),
              child: result.imageUrl != null && result.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: AppRadius.brMd,
                      child: Image.network(
                        result.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.restaurant_rounded,
                          color: context.primaryColor,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      result.type == 'restaurant'
                          ? Icons.restaurant_rounded
                          : Icons.fastfood_rounded,
                      color: context.primaryColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textPrimaryColor,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: result.type == 'restaurant'
                              ? context.primaryColor.withValues(alpha: 0.08)
                              : context.successColor.withValues(alpha: 0.08),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Text(
                          result.type == 'restaurant'
                              ? (result.category ?? 'Restaurant')
                              : (result.category ?? 'Menu Item'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: result.type == 'restaurant'
                                ? context.primaryColor
                                : context.successColor,
                          ),
                        ),
                      ),
                      if (result.rating != null && result.rating! > 0) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: context.warningColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${result.rating!.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ],
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

  Widget _buildRestaurantStream() {
    final provider = context.read<CustomerHomeProvider>();
    final verticalType = _selectedCategory == 'All' ? 'Restaurant' : _selectedCategory;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: provider.watchRestaurants(verticalType),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load restaurants',
            subtitle: 'Please try again',
            actionText: 'Retry',
            onAction: () => setState(() {}),
            accentColor: context.errorColor,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: context.primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final restaurants = snapshot.data ?? [];

        if (restaurants.isEmpty) {
          return EmptyState(
            icon: Icons.storefront_rounded,
            title: 'No restaurants available',
            subtitle: 'Check back later for new options',
            accentColor: context.primaryColor,
          );
        }

        return RefreshIndicator(
          color: context.primaryColor,
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _buildSection('Popular Near You', restaurants.take(4).toList()),
              const SizedBox(height: 28),
              _buildSection('All Restaurants', restaurants),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> restaurants) {
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
                borderRadius: AppRadius.brXs,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: context.textPrimaryColor,
                letterSpacing: 0,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: context.surfaceAltColor,
                borderRadius: AppRadius.brButton,
              ),
              child: Text(
                '${restaurants.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textMutedColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => AnimatedFadeSlide(
              delay: (i * 60).toDouble(),
              duration: const Duration(milliseconds: 400),
              child: _restaurantCard(restaurants[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _restaurantCard(Map<String, dynamic> r) {
    final name = r['name'] as String? ?? 'Unknown';
    final cuisine = r['cuisineType'] as String? ?? '';
    final imageUrl = r['imageUrl'] as String?;
    final restaurantId = r['id'] as String? ?? '';
    final rating = (r['rating'] as num?)?.toDouble() ?? 4.5;

    return AnimatedPressScale(
      onTap: () => context.push('/restaurant/$restaurantId'),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brCard,
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
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
            Expanded(
              child: Padding(
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
                        color: context.textMutedColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: context.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.surfaceAltColor,
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Text(
                            'Delivery',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: context.textMutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      height: 120,
      width: double.infinity,
      color: context.surfaceAltColor,
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_rounded,
            size: 24,
            color: context.primaryColor,
          ),
        ),
      ),
    );
  }
}
