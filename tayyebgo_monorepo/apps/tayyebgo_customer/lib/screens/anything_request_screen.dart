import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() => _items.add(_RequestItem(
        controller: TextEditingController(),
        quantityCtrl: TextEditingController(text: '1'))));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].controller.dispose();
      _items[index].quantityCtrl.dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
      if (file != null && mounted) setState(() => _photoPath = file.path);
    } catch (e) {
      debugPrint('Failed to pick photo: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) { _showSnack('Add at least one item'); return; }

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      if (mounted) setState(() => _isSubmitting = false);
      _showSnack('Not logged in');
      return;
    }

    try {
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
    } catch (e) {
      debugPrint('Submit request failed: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Failed to submit request');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.inter()), backgroundColor: context.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Anything Delivery', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _darkField(
              controller: _storeCtrl,
              label: 'Store Name',
              hint: 'e.g. Abu Ahmad Market',
              icon: Icons.store_rounded,
            ),
            const SizedBox(height: 16),
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _darkField(
                        controller: item.controller,
                        label: 'Item ${i + 1}',
                        hint: 'e.g. Pepsi',
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 65,
                      child: _darkField(
                        controller: item.quantityCtrl,
                        label: 'Qty',
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_rounded, color: context.errorColor, size: 22),
                      onPressed: () => _removeItem(i),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addItem,
              icon: Icon(Icons.add_rounded, size: 18, color: context.primaryColor),
              label: Text('Add Item', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.primaryColor)),
            ),
            const SizedBox(height: 16),
            _darkField(
              controller: _budgetCtrl,
              label: 'Budget (SYP)',
              hint: 'e.g. 50000',
              icon: Icons.monetization_on_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            if (_photoPath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.brMd,
                    child: Image.file(File(_photoPath!), height: 130, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _photoPath = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: Icon(Icons.photo_camera_rounded, size: 18, color: context.primaryColor),
                  label: Text('Add Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.primaryColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            _darkField(
              controller: _instructionsCtrl,
              label: 'Instructions',
              hint: 'Any special notes for the driver...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('Delivery Address', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
            const SizedBox(height: 10),
            _darkField(
              controller: _addressCtrl,
              label: 'Address',
              hint: 'e.g. Near Al Ahram Bakery, second building',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 10),
            _darkField(
              controller: _landmarkCtrl,
              label: 'Landmark (optional)',
              hint: 'e.g. Behind the mosque',
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: context.textPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: context.textPrimaryColor, strokeWidth: 2))
                    : Text('Submit Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: context.textMutedColor),
            prefixIcon: icon != null ? Icon(icon, color: context.textMutedColor, size: 20) : null,
            filled: true,
            fillColor: context.surfaceColor,
            border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.primaryColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _RequestItem {
  final TextEditingController controller;
  final TextEditingController quantityCtrl;
  _RequestItem({required this.controller, required this.quantityCtrl});
}
