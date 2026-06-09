import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerMenuManagementScreen extends StatefulWidget {
  final String restaurantId;
  const PartnerMenuManagementScreen({super.key, required this.restaurantId});

  @override
  State<PartnerMenuManagementScreen> createState() => _PartnerMenuManagementScreenState();
}

class _PartnerMenuManagementScreenState extends State<PartnerMenuManagementScreen> {
  int _selectedCategory = 0;
  final _categories = ['All Items', 'Popular', 'Starters', 'Mains', 'Drinks', 'Desserts'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Menu Management', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add Item', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: context.warningColor),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final selected = _selectedCategory == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? context.warningColor : context.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? context.warningColor : context.borderColor),
                    ),
                    child: Text(_categories[i], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: selected ? context.backgroundColor : context.textMutedColor)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _menuItemCard(context, 'Shawarma Plate', 'SYP 2,500', 'Popular', true, 4),
                const SizedBox(height: 10),
                _menuItemCard(context, 'Falafel Wrap', 'SYP 1,200', 'Starters', true, 3),
                const SizedBox(height: 10),
                _menuItemCard(context, 'Grilled Chicken', 'SYP 4,500', 'Mains', false, 5),
                const SizedBox(height: 10),
                _menuItemCard(context, 'Fresh Juice', 'SYP 800', 'Drinks', true, 4),
                const SizedBox(height: 10),
                _menuItemCard(context, 'Baklava', 'SYP 600', 'Desserts', true, 5),
                const SizedBox(height: 10),
                _menuItemCard(context, 'Hummus', 'SYP 900', 'Starters', false, 3),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItemCard(BuildContext context, String name, String price, String category, bool available, int photos) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_rounded, color: context.textMutedColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(category, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(Icons.photo_library_rounded, size: 12, color: context.textMutedColor),
                    const SizedBox(width: 2),
                    Text('$photos', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.warningColor)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: available ? context.successColor.withValues(alpha: 0.1) : context.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(available ? 'Available' : 'Hidden', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10, color: available ? context.successColor : context.errorColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
