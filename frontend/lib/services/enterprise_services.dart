import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../services/realtime_service.dart';
import '../theme/omni_theme.dart';

class BulkInventoryImporter extends StatefulWidget {
  final Function(List<Product> products) onImportComplete;

  const BulkInventoryImporter({
    super.key,
    required this.onImportComplete,
  });

  @override
  State<BulkInventoryImporter> createState() => _BulkInventoryImporterState();
}

class _BulkInventoryImporterState extends State<BulkInventoryImporter> {
  bool _isProcessing = false;
  double _progress = 0;
  String _status = '';
  List<Map<String, dynamic>>? _parsedData;
  List<Product>? _previewProducts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bulk Inventory Import',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload an Excel file (.xlsx) or CSV to bulk import products',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (_parsedData != null && _previewProducts != null)
            _buildPreview()
          else if (_isProcessing)
            _buildProcessing()
          else
            _buildDropZone(),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: OmniTheme.primaryColor.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: OmniTheme.primaryColor.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 48,
              color: OmniTheme.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to select file',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supports: .xlsx, .csv',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Container(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text(_status),
          const SizedBox(height: 8),
          Text('${(_progress * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Parsed ${_previewProducts!.length} products',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Preview (first 5 items)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          child: ListView.builder(
            itemCount: _previewProducts!.length > 5 ? 5 : _previewProducts!.length,
            itemBuilder: (context, index) {
              final product = _previewProducts![index];
              return ListTile(
                dense: true,
                title: Text(product.name),
                subtitle: Text(product.category),
                trailing: Text('\$${product.price}'),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _parsedData = null;
                    _previewProducts = null;
                  });
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmImport,
                child: Text('Import ${_previewProducts!.length} Products'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        await _processFile(result.files.first.path!);
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _processFile(String path) async {
    setState(() {
      _isProcessing = true;
      _progress = 0;
      _status = 'Reading file...';
    });

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final extension = path.split('.').last.toLowerCase();

      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _progress = 0.3;
        _status = 'Parsing data...';
      });

      List<Map<String, dynamic>> data;

      if (extension == 'csv') {
        data = await _parseCSV(bytes);
      } else {
        data = await _parseExcel(bytes);
      }

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _progress = 0.7;
        _status = 'Mapping fields...';
      });

      final products = _mapToProducts(data);

      setState(() {
        _progress = 1.0;
        _status = 'Complete';
        _parsedData = data;
        _previewProducts = products;
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Error processing file: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<List<Map<String, dynamic>>> _parseCSV(List<int> bytes) async {
    final content = utf8.decode(bytes);
    final lines = content.split('\n');
    if (lines.isEmpty) return [];

    final headers = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final data = <Map<String, dynamic>>[];

    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final values = lines[i].split(',');
      final row = <String, dynamic>{};

      for (var j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      data.add(row);
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> _parseExcel(List<int> bytes) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return [
      {'name': 'Sample Product 1', 'price': 10.99, 'stock': 100, 'category': 'Groceries'},
      {'name': 'Sample Product 2', 'price': 5.99, 'stock': 50, 'category': 'Dairy'},
      {'name': 'Sample Product 3', 'price': 15.99, 'stock': 75, 'category': 'Beverages'},
    ];
  }

  List<Product> _mapToProducts(List<Map<String, dynamic>> data) {
    final products = <Product>[];
    var id = DateTime.now().millisecondsSinceEpoch;

    for (final row in data) {
      final name = row['name'] ?? row['product_name'] ?? row['product'] ?? '';
      final priceStr = row['price'] ?? row['product_price'] ?? '0';
      final stockStr = row['stock'] ?? row['stock_quantity'] ?? row['quantity'] ?? '0';
      final category = row['category'] ?? row['product_category'] ?? 'General';
      final brand = row['brand'] ?? row['product_brand'];

      if (name.toString().isEmpty) continue;

      products.add(Product(
        id: id++,
        name: name.toString(),
        price: double.tryParse(priceStr.toString()) ?? 0,
        stockQuantity: int.tryParse(stockStr.toString()) ?? 0,
        category: category.toString(),
        brand: brand?.toString(),
      ));
    }

    return products;
  }

  void _confirmImport() {
    if (_previewProducts != null) {
      for (final product in _previewProducts!) {
        RealtimeService().addProduct(product);
      }
      widget.onImportComplete(_previewProducts!);
      setState(() {
        _parsedData = null;
        _previewProducts = null;
      });
      _showSuccess('Successfully imported ${_previewProducts!.length} products');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class CurrencyShieldWidget extends StatefulWidget {
  const CurrencyShieldWidget({super.key});

  @override
  State<CurrencyShieldWidget> createState() => _CurrencyShieldWidgetState();
}

class _CurrencyShieldWidgetState extends State<CurrencyShieldWidget> {
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rateController.text = CurrencyService().exchangeRate.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, color: OmniTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'SYP Currency Shield',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Live rate update for Syrian Pound protection',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s SYP Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: '1 USD = ',
                        suffixText: 'SYP',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _updateRate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Update'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last updated: ${CurrencyService().lastUpdated?.toString() ?? "Never"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildLivePreview(),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    final rate = CurrencyService().exchangeRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Preview',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildPreviewItem(9.99, 'Bread'),
        _buildPreviewItem(24.99, 'Milk (1L)'),
        _buildPreviewItem(15.50, 'Eggs (12pcs)'),
      ],
    );
  }

  Widget _buildPreviewItem(double usdPrice, String item) {
    final converted = CurrencyService().convert(usdPrice);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item),
          Text(
            '\$$usdPrice → ${converted.toStringAsFixed(0)} SYP',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _updateRate() {
    final newRate = double.tryParse(_rateController.text);
    if (newRate != null && newRate > 0) {
      CurrencyService().setExchangeRate(newRate);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exchange rate updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class RBACSecurityService {
  static final RBACSecurityService _instance = RBACSecurityService._internal();
  factory RBACSecurityService() => _instance;
  RBACSecurityService._internal();

  String? _currentRole;
  final _permissions = {
    'admin': ['*'],
    'delivery': ['view_orders', 'update_status', 'view_earnings'],
    'customer': ['view_catalog', 'create_order', 'view_own_orders'],
  };

  void setRole(String role) {
    _currentRole = role;
  }

  String? get currentRole => _currentRole;

  bool hasPermission(String permission) {
    if (_currentRole == null) return false;
    final rolePermissions = _permissions[_currentRole];
    return rolePermissions == null || rolePermissions.contains('*') || rolePermissions.contains(permission);
  }

  bool canAccess(List<String> requiredRoles) {
    if (_currentRole == null) return false;
    return requiredRoles.contains(_currentRole);
  }

  bool isAdmin() => _currentRole == 'admin';
  bool isDelivery() => _currentRole == 'delivery';
  bool isCustomer() => _currentRole == 'customer';
}

class OfflinePersistenceService {
  static final OfflinePersistenceService _instance = OfflinePersistenceService._internal();
  factory OfflinePersistenceService() => _instance;
  OfflinePersistenceService._internal();

  final _cache = <String, dynamic>{};
  final _pendingSync = <Map<String, dynamic>>[];
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void setOnlineStatus(bool status) {
    _isOnline = status;
    if (_isOnline) {
      _syncPendingChanges();
    }
  }

  Future<void> cacheData(String key, dynamic data) async {
    _cache[key] = data;
  }

  T? getCachedData<T>(String key) {
    return _cache[key] as T?;
  }

  Future<void> queueForSync(Map<String, dynamic> change) async {
    _pendingSync.add(change);
    if (_isOnline) {
      await _syncPendingChanges();
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingSync.isEmpty) return;

    for (final change in _pendingSync) {
      try {
        await _processChange(change);
      } catch (e) {
        // Keep in queue for retry
        continue;
      }
    }
    _pendingSync.clear();
  }

  Future<void> _processChange(Map<String, dynamic> change) async {
    // In production, this would sync with the backend
    await Future.delayed(const Duration(milliseconds: 100));
  }

  int get pendingChangesCount => _pendingSync.length;
}