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
  Timer? _debounce;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final _categories = [
    ('All', Icons.grid_view_rounded),
    ('Restaurant', Icons.restaurant_rounded),
    ('Grocery', Icons.local_grocery_store_rounded),
    ('Pharmacy', Icons.local_pharmacy_rounded),
    ('Retail', Icons.store_rounded),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = query.trim().toLowerCase());
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
                        Text('Homs', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.primaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search restaurants, food, stores...',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: context.textMutedColor, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: context.textMutedColor),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
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
                    onTap: () => setState(() => _selectedCategory = label),
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
              child: _buildRestaurantStream(),
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                  const SizedBox(height: 12),
                  Text('Failed to load restaurants', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 15)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: context.primaryColor));
        }

        var restaurants = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          restaurants = restaurants.where((r) {
            final name = (r['name'] as String? ?? '').toLowerCase();
            final cuisine = (r['cuisineType'] as String? ?? '').toLowerCase();
            return name.contains(_searchQuery) || cuisine.contains(_searchQuery);
          }).toList();
        }

        if (restaurants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Icon(Icons.search_off_rounded, size: 36, color: context.textMutedColor),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No restaurants available',
                  style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Text('Clear search', style: GoogleFonts.inter(color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
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

    return GestureDetector(
      onTap: () => context.push('/restaurant/$restaurantId'),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon(),
                      ),
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
                        Text('4.5', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 11, color: context.textMutedColor),
                        const SizedBox(width: 2),
                        Text('20-30 min', style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
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
