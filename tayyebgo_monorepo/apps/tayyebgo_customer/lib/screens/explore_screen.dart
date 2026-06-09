import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  final _categories = [
    ('All', Icons.grid_view_rounded),
    ('Restaurants', Icons.restaurant_rounded),
    ('Grocery', Icons.local_grocery_store_rounded),
    ('Pharmacy', Icons.local_pharmacy_rounded),
    ('Retail', Icons.store_rounded),
  ];

  final _popularRestaurants = [
    {'name': 'Al Baik', 'cuisine': 'Fried Chicken', 'rating': 4.8, 'deliveryTime': '25-35', 'image': '🍗'},
    {'name': 'Shawarma Waseem', 'cuisine': 'Shawarma', 'rating': 4.6, 'deliveryTime': '15-25', 'image': '🌯'},
    {'name': 'Baklawa Al-Halabi', 'cuisine': 'Desserts', 'rating': 4.9, 'deliveryTime': '20-30', 'image': '🍩'},
    {'name': 'Pizza Palace', 'cuisine': 'Italian', 'rating': 4.5, 'deliveryTime': '30-40', 'image': '🍕'},
  ];

  final _nearbyStores = [
    {'name': 'Al-Wahr Market', 'type': 'Grocery', 'distance': '0.8 km', 'icon': '🛒'},
    {'name': 'City Pharmacy', 'type': 'Pharmacy', 'distance': '1.2 km', 'icon': '💊'},
    {'name': 'Fresh Mart', 'type': 'Grocery', 'distance': '1.5 km', 'icon': '🥬'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Explore', style: GoogleFonts.inter(fontWeight: FontWeight.w200, fontSize: 28, color: context.textPrimaryColor)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Search restaurants, stores, food...',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                prefixIcon: Icon(Icons.search_rounded, color: context.textMutedColor, size: 22),
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.primaryColor)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, icon) = _categories[i];
                  final selected = _selectedCategory == label;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? context.primaryColor : context.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? context.primaryColor : context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: selected ? context.textPrimaryColor : context.textMutedColor),
                          const SizedBox(width: 6),
                          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: selected ? context.textPrimaryColor : context.textMutedColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Popular Near You', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text('See All', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.primaryColor, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _popularRestaurants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _popularCard(context, _popularRestaurants[i]),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Nearby Stores', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text('See All', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.primaryColor, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._nearbyStores.map((s) => _nearbyCard(context, s)),
          ],
        ),
      ),
    );
  }

  Widget _popularCard(BuildContext context, Map<String, dynamic> r) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/explore-${r['name']}'),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.surfaceAltColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Text(r['image'] as String, style: const TextStyle(fontSize: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r['cuisine'] as String, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: context.warningColor),
                      Text('${r['rating']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded, size: 12, color: context.textMutedColor),
                      Text('${r['deliveryTime']} min', style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nearbyCard(BuildContext context, Map<String, dynamic> s) {
    return Container(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(s['icon'] as String, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                Text(s['type'] as String, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Text(s['distance'] as String, style: GoogleFonts.inter(color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
