import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

      final fn = FirebaseFunctions.instance.httpsCallable('processAiMenuImage');
      final result = await fn({
        'base64Image': base64Image,
      });

      final data = result.data as Map<String, dynamic>;
      final content = data['result']['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content);
      final items = parsed['items'] as List<dynamic>? ?? [parsed];
      if (!mounted) return;
      setState(() {
        _detectedItems = items.map((i) => {
          'name': i['name'] as String? ?? 'Unknown',
          'price': (i['price'] as num?)?.toDouble() ?? 0,
          'category': i['category'] as String? ?? 'General',
          'description': i['description'] as String? ?? '',
        }).toList();
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
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menu_items')
          .add({
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
    return AppScaffold(
      title: 'AI Menu Creation',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, size: 48, color: Colors.amber),
                  const SizedBox(height: 8),
                  const Text('Upload a menu photo or PDF',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('AI will detect items, prices, and categories'),
                  const SizedBox(height: 16),
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Take Photo'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processImage,
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isProcessing ? 'Processing...' : 'Extract Menu with AI'),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_detectedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detected Items (${_detectedItems.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _saveToFirestore,
                  icon: const Icon(Icons.save),
                  label: const Text('Save All'),
                ),
              ],
            ),
            const Divider(),
            ..._detectedItems.map((item) => ListTile(
              title: Text(item['name'] as String),
              subtitle: Text('${item['category']} — SYP ${(item['price'] as num).toStringAsFixed(0)}'),
              trailing: Text('SYP ${(item['price'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ],
      ),
    );
  }
}
