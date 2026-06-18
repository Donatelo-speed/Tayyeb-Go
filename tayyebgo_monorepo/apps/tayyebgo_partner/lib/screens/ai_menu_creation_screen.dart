import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AiMenuCreationScreen extends StatefulWidget {
  final String restaurantId;
  const AiMenuCreationScreen({super.key, required this.restaurantId});
  @override
  State<AiMenuCreationScreen> createState() => _AiMenuCreationScreenState();
}

class _AiMenuCreationScreenState extends State<AiMenuCreationScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _detectedItems = [];
  String? _error;

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      if (!mounted) return;
      setState(() => _selectedImage = File(file.path));
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final fn =
          FirebaseFunctions.instance.httpsCallable('processAiMenuImage');
      final result = await fn({
        'base64Image': base64Image,
      });

      final data = result.data as Map<String, dynamic>;
      final content =
          data['result']['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content);
      final items = parsed['items'] as List<dynamic>? ?? [parsed];
      if (!mounted) return;
      setState(() {
        _detectedItems = items
            .map((i) => {
                  'name': i['name'] as String? ?? 'Unknown',
                  'price': (i['price'] as num?)?.toDouble() ?? 0,
                  'category': i['category'] as String? ?? 'General',
                  'description': i['description'] as String? ?? '',
                })
            .toList();
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _error = 'AI processing failed: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToFirestore() async {
    for (final item in _detectedItems) {
      await FirebaseFirestore.instance.collection('menu_items').add({
        'restaurantId': widget.restaurantId,
        'name': item['name'],
        'nameAr': item['name'],
        'price': item['price'],
        'category': item['category'],
        'description': item['description'],
        'isAvailable': true,
        'isValid': true,
        'sortOrder': FieldValue.increment(1),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_detectedItems.length} items to menu')),
    );
    setState(() => _detectedItems = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('AI Menu Creation', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.brCard,
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.warningColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, size: 36, color: context.warningColor),
                ),
                const SizedBox(height: 12),
                Text('Upload a menu photo', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
                const SizedBox(height: 4),
                Text('AI will detect items, prices, and categories', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                const SizedBox(height: 16),
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: AppRadius.brMd,
                    child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _outlineButton(context, Icons.photo_camera_rounded, 'Take Photo', _pickImage),
                    const SizedBox(width: 12),
                    _outlineButton(context, Icons.photo_library_rounded, 'Gallery', _pickImage),
                  ],
                ),
              ],
            ),
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.warningColor,
                  foregroundColor: context.backgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.backgroundColor))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, size: 18),
                          const SizedBox(width: 8),
                          Text('Extract Menu with AI', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.errorColor.withValues(alpha: 0.1), borderRadius: AppRadius.brMd),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.errorColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: GoogleFonts.inter(color: context.errorColor, fontSize: 13))),
                ],
              ),
            ),
          ],
          if (_detectedItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detected Items (${_detectedItems.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                TextButton.icon(
                  onPressed: _saveToFirestore,
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: Text('Save All', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: context.successColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._detectedItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: context.warningColor.withValues(alpha: 0.1), borderRadius: AppRadius.brMd), child: Icon(Icons.restaurant_rounded, color: context.warningColor, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                          Text('${item['category']} · SYP ${(item['price'] as num).toStringAsFixed(0)}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('SYP ${(item['price'] as num).toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.warningColor)),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _outlineButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.warningColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
          ],
        ),
      ),
    );
  }
}
