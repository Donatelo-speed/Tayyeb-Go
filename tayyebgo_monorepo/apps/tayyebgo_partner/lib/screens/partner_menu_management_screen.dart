import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _selectedCategory = 'All';
  final List<String> _categories = ['All'];

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
            onPressed: () => _showAddEditDialog(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add Item', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: context.warningColor),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menu_items')
            .where('restaurantId', isEqualTo: widget.restaurantId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.primaryColor));
          }

          final docs = snap.data?.docs ?? [];

          final Set<String> cats = {'All'};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = data['category'] as String? ?? '';
            if (cat.isNotEmpty) cats.add(cat);
          }
          if (cats.length > _categories.length) {
            _categories.clear();
            _categories.addAll(cats);
          }

          final filtered = _selectedCategory == 'All'
              ? docs
              : docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['category'] == _selectedCategory;
                }).toList();

          return Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final selected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? context.warningColor : context.surfaceColor,
                          borderRadius: AppRadius.brXl,
                          border: Border.all(color: selected ? context.warningColor : context.borderColor),
                        ),
                        child: Text(cat, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: selected ? context.backgroundColor : context.textMutedColor)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 64, color: context.textMutedColor),
                        const SizedBox(height: 16),
                        Text('No menu items yet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor)),
                        const SizedBox(height: 4),
                        Text('Tap "Add Item" to create your first menu item', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final doc = filtered[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] as String? ?? '';
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      final category = data['category'] as String? ?? '';
                      final isAvailable = data['isAvailable'] as bool? ?? true;
                      final imageUrl = data['imageUrl'] as String?;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _menuItemCard(context, doc.id, name, price, category, isAvailable, imageUrl),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuItemCard(BuildContext context, String docId, String name, double price, String category, bool available, String? imageUrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: AppRadius.brMd,
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: AppRadius.brMd,
                    child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.restaurant_rounded, color: context.textMutedColor, size: 24)),
                  )
                : Icon(Icons.restaurant_rounded, color: context.textMutedColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(category.isNotEmpty ? category : 'Uncategorized', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('SYP ${price.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.warningColor)),
              const SizedBox(height: 4),
              Switch(
                value: available,
                onChanged: (v) async {
                  try {
                    await FirebaseFirestore.instance.collection('menu_items').doc(docId).update({'isAvailable': v});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                    }
                  }
                },
                activeColor: context.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {String? existingId, Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final priceCtrl = TextEditingController(text: existing?['price']?.toString() ?? '');
    final categoryCtrl = TextEditingController(text: existing?['category'] as String? ?? '');
    String category = existing?['category'] as String? ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brCard),
        title: Text(existingId != null ? 'Edit Item' : 'Add Item', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Item name',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                  filled: true,
                  fillColor: context.backgroundColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Price (SYP)',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                  filled: true,
                  fillColor: context.backgroundColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Category (e.g. Mains, Drinks)',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                  filled: true,
                  fillColor: context.backgroundColor,
                ),
                onChanged: (v) => category = v.trim(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor)),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and price are required')));
                return;
              }
              final price = double.tryParse(priceCtrl.text.trim());
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price')));
                return;
              }
              try {
                final data = {
                  'name': nameCtrl.text.trim(),
                  'price': price,
                  'category': category.isNotEmpty ? category : 'Uncategorized',
                  'restaurantId': widget.restaurantId,
                  'isAvailable': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (existingId != null) {
                  await FirebaseFirestore.instance.collection('menu_items').doc(existingId).update(data);
                } else {
                  data['createdAt'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance.collection('menu_items').add(data);
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                }
              }
            },
            child: Text(existingId != null ? 'Update' : 'Add', style: GoogleFonts.inter(color: context.warningColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
