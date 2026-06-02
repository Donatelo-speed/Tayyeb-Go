import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AnythingRequestScreen extends StatefulWidget {
  const AnythingRequestScreen({super.key});
  @override
  State<AnythingRequestScreen> createState() => _AnythingRequestScreenState();
}

class _AnythingRequestScreenState extends State<AnythingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _items = <_RequestItem>[];
  String? _photoPath;
  double? _lat;
  double? _lng;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _storeCtrl.dispose();
    _budgetCtrl.dispose();
    _instructionsCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_RequestItem(controller: TextEditingController(), quantityCtrl: TextEditingController(text: '1'))));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].controller.dispose();
      _items[index].quantityCtrl.dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (file != null) {
      if (!mounted) return;
      setState(() => _photoPath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      _showSnack('Add at least one item');
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    if (auth.user == null) { _showSnack('Not logged in'); return; }

    final anything = context.read<AnythingProvider>();
    final requestId = await anything.createRequest(
      user: auth.user!,
      storeName: _storeCtrl.text.trim(),
      items: _items.map((i) => {
        'name': i.controller.text.trim(),
        'quantity': int.tryParse(i.quantityCtrl.text) ?? 1,
      }).toList(),
      budget: double.tryParse(_budgetCtrl.text) ?? 0,
      photoUrl: _photoPath,
      instructions: _instructionsCtrl.text.trim(),
      dropoffLatitude: _lat ?? 0,
      dropoffLongitude: _lng ?? 0,
      dropoffAddress: _addressCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (requestId != null) {
      context.go('/anything-tracking/$requestId');
    } else {
      _showSnack('Failed to submit request');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Anything Delivery',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _storeCtrl,
              decoration: InputDecoration(
                labelText: 'Store Name',
                hintText: 'e.g. Abu Ahmad Market',
                prefixIcon: const Icon(Icons.store),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Enter store name' : null,
            ),
            const SizedBox(height: 16),
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: item.controller,
                        decoration: InputDecoration(
                          labelText: 'Item ${i + 1}',
                          hintText: 'e.g. Pepsi',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: item.quantityCtrl,
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeItem(i),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetCtrl,
              decoration: InputDecoration(
                labelText: 'Budget (SYP)',
                hintText: 'e.g. 50000',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            if (_photoPath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_photoPath!), height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, shadows: [BoxShadow(blurRadius: 4)]),
                      onPressed: () => setState(() => _photoPath = null),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Add Photo'),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsCtrl,
              decoration: InputDecoration(
                labelText: 'Instructions',
                hintText: 'Any special notes for the driver...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Text('Delivery Address', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'e.g. Near Al Ahram Bakery, second building',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Enter delivery address' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _landmarkCtrl,
              decoration: InputDecoration(
                labelText: 'Landmark (optional)',
                hintText: 'e.g. Behind the mosque',
                prefixIcon: const Icon(Icons.flag),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RequestItem {
  final TextEditingController controller;
  final TextEditingController quantityCtrl;
  _RequestItem({required this.controller, required this.quantityCtrl});
}
