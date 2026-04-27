import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/omni_theme.dart';
import '../../main.dart';
import '../../utils/currency_helper.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    _products = List.generate(12, (i) => {
      'id': i + 1,
      'name': 'Product ${i + 1}',
      'price': (i + 1) * 10.0 + 5,
      'stock': (i * 7) % 50,
      'category': ['Electronics', 'Clothing', 'Food', 'Books'][i % 4],
      'image': 'https://via.placeholder.com/300?text=Product${i + 1}',
    });
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 400;

    String t(String en, String ar) => isArabic ? ar : en;

    final filtered = _search.isEmpty ? _products : _products.where((p) => p['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: OmniTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('Products', 'المنتجات')),
        backgroundColor: OmniTheme.surfaceColor,
        foregroundColor: OmniTheme.textPrimary,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showDialog(context, null, isArabic))],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: OmniTheme.surfaceColor,
          child: Row(children: [
            Expanded(child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: t('Search...', 'بحث...'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                fillColor: OmniTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: OmniTheme.backgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.filter_list, color: OmniTheme.textMuted),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            _Chip(label: t('Total', 'الإجمالي'), value: '${_products.length}', color: Colors.blue),
            const SizedBox(width: 8),
            _Chip(label: t('In Stock', 'متوفر'), value: '${_products.where((p) => p['stock'] > 0).length}', color: Colors.green),
            const SizedBox(width: 8),
            _Chip(label: t('Out', 'نفد'), value: '${_products.where((p) => p['stock'] == 0).length}', color: Colors.red),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingWidget()
              : filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2, size: 64, color: OmniTheme.textMuted), const SizedBox(height: 12), Text(t('No products', 'لا توجد منتجات'), style: TextStyle(color: OmniTheme.textSecondary))]))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isSmall ? 2 : 3, childAspectRatio: 0.75, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _Card(product: product, isArabic: isArabic, onEdit: () => _showDialog(context, product, isArabic), onDelete: () => setState(() => _products.remove(product)));
                      },
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: OmniTheme.primaryColor,
        onPressed: () => _showDialog(context, null, isArabic),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDialog(BuildContext context, Map<String, dynamic>? product, bool isArabic) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final priceCtrl = TextEditingController(text: product?['price']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?['stock']?.toString() ?? '');
    String category = product?['category'] ?? 'Electronics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product == null ? (isArabic ? 'إضافة منتج' : 'Add Product') : (isArabic ? 'تعديل منتج' : 'Edit Product'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isArabic ? 'الاسم' : 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Price (USD)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isArabic ? 'الكمية' : 'Stock', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                Text(isArabic ? 'الفئة' : 'Category', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: ['Electronics', 'Clothing', 'Food', 'Books', 'Home', 'Sports'].map((c) => ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setModal(() => category = c),
                )).toList()),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isArabic ? 'تم الحفظ!' : 'Saved!'), backgroundColor: OmniTheme.successColor));
                    },
                    child: Text(isArabic ? 'حفظ' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: color))]),
    );
  }
}

class _Card extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isArabic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Card({required this.product, required this.isArabic, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product['stock'] == 0;
    return Container(
      decoration: BoxDecoration(color: OmniTheme.surfaceColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Stack(children: [
          Container(width: double.infinity, decoration: BoxDecoration(color: OmniTheme.backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))), child: Icon(Icons.image, size: 40, color: OmniTheme.textMuted)),
          if (outOfStock) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('OUT', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)))),
          Positioned(top: 8, right: 8, child: PopupMenuButton(
            icon: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: OmniTheme.surfaceColor, shape: BoxShape.circle), child: const Icon(Icons.more_vert, size: 16)),
            itemBuilder: (context) => [
              PopupMenuItem(onTap: onEdit, child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(isArabic ? 'تعديل' : 'Edit')])),
              PopupMenuItem(onTap: onDelete, child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red))])),
            ],
          )),
        ])),
        Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${product['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text('\$${(product['price'] as double).toStringAsFixed(2)}', style: TextStyle(color: OmniTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
          Text('${CurrencyHelper.formatSYP(CurrencyHelper.usdToSyp((product['price'] as double)))} ₤', style: TextStyle(fontSize: 10, color: OmniTheme.textMuted)),
          const SizedBox(height: 4),
          Row(children: [Icon(Icons.inventory_2, size: 12, color: outOfStock ? Colors.red : OmniTheme.textMuted), const SizedBox(width: 4), Text('${product['stock']}', style: TextStyle(fontSize: 11, color: outOfStock ? Colors.red : OmniTheme.textMuted))]),
        ])),
      ]),
    );
  }
}