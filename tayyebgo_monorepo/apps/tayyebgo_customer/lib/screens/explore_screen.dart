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
    } catch (e) {
      debugPrint('Failed to load trending searches: $e');
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
          } catch (e) {
            debugPrint('Failed to get suggestions: $e');
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
    } catch (e) {
      debugPrint('Search failed: $e');
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Explore', style: GoogleFonts.inter(fontWeight: FontWeight.w200, fontSize: 28, color: context.textPrimaryColor)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: context.primaryColor),
                        const SizedBox(width: 4),
                        Text('Nearby', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.primaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _performSearch,
                    style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search restaurants, food, stores...',
                      hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: context.textMutedColor, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: context.textMutedColor),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: context.surfaceColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.primaryColor)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  if (_showSuggestions && (_suggestions.isNotEmpty || _trendingSearches.isNotEmpty))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderColor),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_suggestions.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text('Suggestions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: context.textMutedColor)),
                            ),
                            ..._suggestions.map((s) => ListTile(
                              dense: true,
                              leading: Icon(Icons.search_rounded, size: 18, color: context.textMutedColor),
                              title: Text(s, style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor)),
                              onTap: () {
                                _searchCtrl.text = s;
                                _performSearch(s);
                              },
                            )),
                          ],
                          if (_trendingSearches.isNotEmpty && _searchQuery.isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text('Trending', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: context.textMutedColor)),
                            ),
                            ..._trendingSearches.map((s) => ListTile(
                              dense: true,
                              leading: Icon(Icons.local_fire_department_rounded, size: 18, color: context.warningColor),
                              title: Text(s, style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor)),
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
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, icon) = _categories[i];
                  final selected = _selectedCategory == label;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = label);
                      if (_searchQuery.isNotEmpty) _performSearch(_searchQuery);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? context.primaryColor : context.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? context.primaryColor : context.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15, color: selected ? Colors.white : context.textMutedColor),
                          const SizedBox(width: 6),
                          Text(label, style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: selected ? Colors.white : context.textMutedColor,
                          )),
                        ],
                      ),
                    ),
                  );
                },
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
      return Center(child: CircularProgressIndicator(color: context.primaryColor));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: context.textMutedColor),
            const SizedBox(height: 12),
            Text('No results for "$_searchQuery"', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 15)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _clearSearch,
              child: Text('Clear search', style: GoogleFonts.inter(color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(result);
      },
    );
  }

  Widget _buildSearchResultCard(SearchResult result) {
    return GestureDetector(
      onTap: () {
        if (result.type == 'restaurant') {
          context.push('/restaurant/${result.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: result.imageUrl != null && result.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(result.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant_rounded, color: context.primaryColor, size: 24),
                      ),
                    )
                  : Icon(
                      result.type == 'restaurant' ? Icons.restaurant_rounded : Icons.fastfood_rounded,
                      color: context.primaryColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: result.type == 'restaurant'
                              ? context.primaryColor.withValues(alpha: 0.1)
                              : context.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          result.type == 'restaurant' ? (result.category ?? 'Restaurant') : (result.category ?? 'Menu Item'),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                            color: result.type == 'restaurant' ? context.primaryColor : context.successColor),
                        ),
                      ),
                      if (result.rating != null && result.rating! > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star_rounded, size: 14, color: context.warningColor),
                        const SizedBox(width: 2),
                        Text('${result.rating!.toStringAsFixed(1)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMutedColor),
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                const SizedBox(height: 12),
                Text('Failed to load restaurants', style: GoogleFonts.inter(color: context.textMutedColor)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white),
                  child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: context.primaryColor));
        }

        final restaurants = snapshot.data ?? [];

        if (restaurants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_rounded, size: 48, color: context.textMutedColor),
                const SizedBox(height: 12),
                Text('No restaurants available', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 15)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: context.primaryColor,
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSection('Popular Near You', restaurants.take(4).toList()),
              const SizedBox(height: 24),
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
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: context.textPrimaryColor)),
            const SizedBox(width: 8),
            Text('${restaurants.length}', style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _restaurantCard(restaurants[i]),
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

    return GestureDetector(
      onTap: () => context.push('/restaurant/$restaurantId'),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.surfaceAltColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon()),
                    )
                  : _placeholderIcon(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(cuisine, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 13, color: context.warningColor),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                        const SizedBox(width: 8),
                        Icon(Icons.delivery_dining_rounded, size: 11, color: context.textMutedColor),
                        const SizedBox(width: 2),
                        Text('Delivery', style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
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
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.restaurant_rounded, size: 22, color: context.primaryColor),
      ),
    );
  }
}
