import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreCustomizationScreen extends StatefulWidget {
  final String restaurantId;
  const StoreCustomizationScreen({super.key, required this.restaurantId});
  @override
  State<StoreCustomizationScreen> createState() => _StoreCustomizationScreenState();
}

class _StoreCustomizationScreenState extends State<StoreCustomizationScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  Color _selectedColor = TayyebGoTheme.primaryColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurant() async {
    final doc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .get();
    if (doc.exists && mounted) {
      final d = doc.data()!;
      _nameCtrl.text = d['name'] as String? ?? '';
      _descCtrl.text = d['description'] as String? ?? '';
      _feeCtrl.text = (d['deliveryFee'] as num?)?.toString() ?? '0';
      _selectedColor = Color(int.tryParse(d['brandColor'] as String? ?? '') ?? 0xFFA98D6B);
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .update({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'deliveryFee': double.tryParse(_feeCtrl.text) ?? 0,
        'brandColor': _selectedColor.value.toRadixString(16).padLeft(8, '0'),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Store Customization',
      body: StreamScreenBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurantId)
            .snapshots(),
        onSuccess: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Store Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feeCtrl,
              decoration: InputDecoration(
                labelText: 'Delivery Fee (SYP)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Brand Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Colors.amber, Colors.blue, Colors.green, Colors.red,
                Colors.purple, Colors.orange, Colors.teal, Colors.pink,
                const Color(0xFFA98D6B), Colors.brown,
              ].map((c) => GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: _selectedColor == c
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: _selectedColor == c
                        ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: _selectedColor == c
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
