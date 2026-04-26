import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  static final CurrencyProvider _instance = CurrencyProvider._internal();
  factory CurrencyProvider() => _instance;
  CurrencyProvider._internal();

  double _exchangeRate = 13000.0;
  String _currency = 'SYP';
  String _baseCurrency = 'USD';
  bool _isAutoUpdate = true;
  DateTime? _lastUpdated;
  Timer? _updateTimer;
  List<VoidCallback>? _listeners;

  double get exchangeRate => _exchangeRate;
  String get currency => _currency;
  String get baseCurrency => _baseCurrency;
  DateTime? get lastUpdated => _lastUpdated;

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    _exchangeRate = prefs.getDouble('exchange_rate') ?? 13000.0;
    _currency = prefs.getString('currency') ?? 'SYP';
    if (_isAutoUpdate) {
      startAutoUpdate();
    }
    notifyListeners();
  }

  double convert(double amountUSD) => amountUSD * _exchangeRate;
  double convertToUSD(double amountSYP) => amountSYP / _exchangeRate;

  String format(double amountUSD, {bool showBoth = false}) {
    final converted = convert(amountUSD);
    if (showBoth) {
      return '\$${amountUSD.toStringAsFixed(2)} • ${converted.toStringAsFixed(0)} $_currency';
    }
    return '${converted.toStringAsFixed(0)} $_currency';
  }

  String formatCompact(double amountUSD) {
    final converted = convert(amountUSD);
    if (converted >= 1000000) {
      return '${(converted / 1000000).toStringAsFixed(1)}M $_currency';
    } else if (converted >= 1000) {
      return '${(converted / 1000).toStringAsFixed(1)}K $_currency';
    }
    return '${converted.toStringAsFixed(0)} $_currency';
  }

  void setExchangeRate(double rate, {bool persist = true}) async {
    _exchangeRate = rate;
    _lastUpdated = DateTime.now();
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('exchange_rate', rate);
    }
    notifyListeners();
  }

  void toggleAutoUpdate() {
    _isAutoUpdate = !_isAutoUpdate;
    if (_isAutoUpdate) {
      startAutoUpdate();
    } else {
      stopAutoUpdate();
    }
    notifyListeners();
  }

  void startAutoUpdate({Duration interval = const Duration(hours: 1)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) async {
      await _fetchLiveRate();
    });
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _fetchLiveRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fluctuation = 1 + (DateTime.now().second % 5 - 2) * 0.001;
      _exchangeRate = (_exchangeRate * fluctuation).roundToDouble();
      _lastUpdated = DateTime.now();
      await prefs.setDouble('exchange_rate', _exchangeRate);
      notifyListeners();
    } catch (e) {
      // Keep last known rate
    }
  }

  void dispose() {
    stopAutoUpdate();
    super.dispose();
  }
}

class GlobalCurrencyBanner extends StatelessWidget {
  final CurrencyProvider currency;

  const GlobalCurrencyBanner({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade700,
            Colors.green.shade500,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '1 USD = ${currency.exchangeRate.toStringAsFixed(0)} SYP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Live Rate',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SmartSearchService {
  static final SmartSearchService _instance = SmartSearchService._internal();
  factory SmartSearchService() => _instance;
  SmartSearchService._internal();

  final List<String> _recentSearches = [];
  final List<Map<String, dynamic>> _trending = [];
  final Map<String, List<Map<String, dynamic>> _suggestions = {};

  List<String> get recentSearches => _recentSearches;
  List<Map<String, dynamic>> get trending => _trending;

  void addSearch(String query) {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  List<Map<String, dynamic>> getSuggestions(String query) {
    if (query.isEmpty) return [];
    query = query.toLowerCase();

    final results = <Map<String, dynamic>>[];

    for (final term in _suggestions.keys) {
      if (term.toLowerCase().contains(query) || _levenshteinDistance(term.toLowerCase(), query) <= 2) {
        results.addAll(_suggestions[term]!);
      }
    }

    return results.take(5).toList();
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.length > s2.length) return _levenshteinDistance(s2, s1);
    final distances = List.generate(s1.length + 1, (i) => i);
    for (int i = 1; i <= s2.length; i++) {
      distances[0] = i;
      int newDist = i;
      for (int j = 1; j <= s1.length; j++) {
        final cost = s1[j - 1] == s2[i - 1] ? 0 : 1;
        newDist = [newDist, distances[j] + 1, distances[j - 1] + cost, newDist + 1]
            .reduce((a, b) => a < b ? a : b);
      }
      distances[s1.length] = newDist;
    }
    return distances[s1.length];
  }

  void setSuggestions(String query, List<Map<String, dynamic>> products) {
    _suggestions[query] = products;
  }
}

class PredictiveSearchDropdown extends StatefulWidget {
  final String query;
  final Function(Map<String, dynamic>) onSelect;
  final Function(String) onSearch;

  const PredictiveSearchDropdown({
    super.key,
    required this.query,
    required this.onSelect,
    required this.onSearch,
  });

  @override
  State<PredictiveSearchDropdown> createState() => _PredictiveSearchDropdownState();
}

class _PredictiveSearchDropdownState extends State<PredictiveSearchDropdown> {
  final _searchService = SmartSearchService();

  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty) {
      return _buildRecentSearches();
    }

    final suggestions = _searchService.getSuggestions(widget.query);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: suggestions.map((product) => ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag,
                    size: 20,
                    color: Colors.grey,
                  ),
          ),
          title: Text(product['name'] ?? ''),
          subtitle: Text(
            '\$${product['price']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.north_east, size: 16),
          onTap: () => widget.onSelect(product),
        )).toList(),
      ),
    );
  }

  Widget _buildRecentSearches() {
    final recent = _searchService.recentSearches;
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent.take(5).map((term) => ActionChip(
              avatar: const Icon(Icons.history, size: 16),
              label: Text(term),
              onPressed: () => widget.onSearch(term),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class MultiBasketService {
  static final MultiBasketService _instance = MultiBasketService._internal();
  factory MultiBasketService() => _instance;
  MultiBasketService._internal();

  final List<Basket> _baskets = [];
  String? _activeBasketId;

  List<Basket> get baskets => _baskets;
  String? get activeBasketId => _activeBasketId;

  Basket? get activeBasket {
    if (_activeBasketId == null) return null;
    return _baskets.firstWhere(
      (b) => b.id == _activeBasketId,
      orElse: () => _baskets.first,
    );
  }

  void createBasket(String name) {
    final basket = Basket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );
    _baskets.add(basket);
    if (_activeBasketId == null) {
      _activeBasketId = basket.id;
    }
  }

  void addToBasket(String basketId, Map<String, dynamic> product, {int quantity = 1}) {
    final basket = _baskets.firstWhere(
      (b) => b.id == basketId,
      orElse: () => throw Exception('Basket not found'),
    );
    final existingIndex = basket.items.indexWhere((i) => i['product_id'] == product['id']);
    if (existingIndex >= 0) {
      basket.items[existingIndex]['quantity'] =
          basket.items[existingIndex]['quantity'] + quantity;
    } else {
      basket.items.add({
        'product': product,
        'product_id': product['id'],
        'quantity': quantity,
      });
    }
  }

  void removeFromBasket(String basketId, int productId) {
    final basket = _baskets.firstWhere(
      (b) => b.id == basketId,
      orElse: () => throw Exception('Basket not found'),
    );
    basket.items.removeWhere((i) => i['product_id'] == productId);
  }

  void setActiveBasket(String basketId) {
    _activeBasketId = basketId;
  }

  void addAllToCart(List<Map<String, dynamic>> products) {
    final basket = activeBasket;
    if (basket == null) return;

    for (final item in products) {
      addToBasket(basket.id, item, quantity: 1);
    }
  }

  double getBasketTotal(String basketId) {
    final basket = _baskets.firstWhere(
      (b) => b.id == basketId,
      orElse: () => throw Exception('Basket not found'),
    );
    return basket.items.fold(0.0, (sum, item) {
      final price = item['product']['price'] ?? 0.0;
      final qty = item['quantity'] ?? 1;
      return sum + (price * qty);
    });
  }
}

class Basket {
  final String id;
  final String name;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;
  final bool isDefault;

  Basket({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.isDefault = false,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + (item['quantity'] ?? 1));

  double get total => items.fold(0.0, (sum, item) {
    final price = item['product']['price'] ?? 0.0;
    final qty = item['quantity'] ?? 1;
    return sum + (price * qty);
  });
}

class DriverStatusService {
  static final DriverStatusService _instance = DriverStatusService._internal();
  factory DriverStatusService() => _instance;
  DriverStatusService._internal();

  bool _isOnline = false;
  bool _isBusy = false;
  String? _currentOrderId;
  DateTime? _lastOnlineAt;
  bool _notificationsEnabled = true;
  String _pingSound = 'default';

  bool get isOnline => _isOnline;
  bool get isBusy => _isBusy;
  bool get isAvailable => _isOnline && !_isBusy && _currentOrderId == null;
  String? get currentOrderId => _currentOrderId;

  void goOnline() {
    _isOnline = true;
    _lastOnlineAt = DateTime.now();
  }

  void goOffline() {
    _isOnline = false;
    _isBusy = false;
    _currentOrderId = null;
  }

  void setBusy(bool busy) {
    _isBusy = busy;
  }

  void acceptOrder(String orderId) {
    _currentOrderId = orderId;
    _isBusy = true;
  }

  void completeOrder() {
    _currentOrderId = null;
    _isBusy = false;
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
  }

  void setPingSound(String sound) {
    _pingSound = sound;
  }

  Map<String, dynamic> getStatus() {
    return {
      'is_online': _isOnline,
      'is_busy': _isBusy,
      'is_available': isAvailable,
      'current_order_id': _currentOrderId,
      'last_online_at': _lastOnlineAt?.toIso8601String(),
    };
  }
}

class DriverStatusToggle extends StatelessWidget {
  final DriverStatusService status;
  final VoidCallback onToggle;

  const DriverStatusToggle({
    super.key,
    required this.status,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (status.isOnline) {
          status.goOffline();
        } else {
          status.goOnline();
        }
        onToggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: status.isOnline ? Colors.green : Colors.grey,
          borderRadius: BorderRadius.circular(30),
          boxShadow: status.isOnline
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.isOnline ? Icons.online_pin : Icons.offline_bolt,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              status.isOnline ? 'ONLINE' : 'OFFLINE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final List<Map<String, dynamic>> _pendingChanges = [];
  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get hasPendingChanges => _pendingChanges.isNotEmpty;
  int get pendingCount => _pendingChanges.length;

  void setOnlineStatus(bool status) {
    _isOnline = status;
    if (_isOnline && _pendingChanges.isNotEmpty) {
      syncPendingChanges();
    }
  }

  void queueChange(Map<String, dynamic> change) {
    _pendingChanges.add(change);
    if (_isOnline) {
      syncPendingChanges();
    }
  }

  Future<void> syncPendingChanges() async {
    if (_isSyncing || _pendingChanges.isEmpty) return;

    _isSyncing = true;
    final changes = List<Map<String, dynamic>>.from(_pendingChanges);

    for (final change in changes) {
      try {
        await _processChange(change);
        _pendingChanges.remove(change);
      } catch (e) {
        break;
      }
    }

    _isSyncing = false;
  }

  Future<void> _processChange(Map<String, dynamic> change) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Map<String, dynamic> getChangesSummary() {
    return {
      'pending_count': _pendingChanges.length,
      'is_online': _isOnline,
      'is_syncing': _isSyncing,
    };
  }
}

class WhatsAppBridge {
  static final WhatsAppBridge _instance = WhatsAppBridge._internal();
  factory WhatsAppBridge() => _instance;
  WhatsAppBridge._internal();

  String _adminNumber = '+963';

  void setAdminNumber(String number) {
    _adminNumber = number;
  }

  String getSupportLink({String? message}) {
    final encodedMessage = Uri.encodeComponent(message ?? 'Hello! I need help with my order.');
    return 'https://wa.me/$_adminNumber?text=$encodedMessage';
  }

  String getOrderSupportLink(String orderId, {String? issue}) {
    final message = issue ?? 'Order #$orderId - I need help';
    return getSupportLink(message: message);
  }

  String getDriverSupportLink(String driverId, {String? issue}) {
    final message = issue ?? 'Driver #$driverId - I need help';
    return getSupportLink(message: message);
  }
}

class SmartBundlingService {
  static final SmartBundlingService _instance = SmartBundlingService._internal();
  factory SmartBundlingService() => _instance;
  SmartBundlingService._internal();

  final Map<int, List<int>> _bundles = {
    1: [15, 17],
    15: [16, 17],
    16: [15],
    17: [1, 2],
    22: [23, 24],
    23: [22, 24],
    6: [7, 8, 9],
  };

  List<Map<String, dynamic>> getSuggestions(
    Map<String, dynamic> product,
    List<Map<String, dynamic>> allProducts,
  ) {
    final productId = product['id'] as int?;
    if (productId == null) return [];

    final suggestedIds = _bundles[productId] ?? [];
    return allProducts.where((p) => suggestedIds.contains(p['id'])).toList();
  }

  List<Map<String, dynamic>> getCategorySuggestions(
    String category,
    List<Map<String, dynamic>> allProducts,
  ) {
    return allProducts
        .where((p) => p['category'] == category)
        .take(5)
        .toList();
  }

  List<Map<String, dynamic>> getFrequentlyBoughtTogether(
    Map<String, dynamic> product,
    List<Map<String, dynamic>> allProducts,
  ) {
    final suggestions = getSuggestions(product, allProducts);
    if (suggestions.length < 3) {
      suggestions.addAll(getCategorySuggestions(product['category'] ?? '', allProducts));
    }
    return suggestions.take(4).toList();
  }
}

class SmartBundlingWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> allProducts;
  final Function(Map<String, dynamic>) onAdd;

  const SmartBundlingWidget({
    super.key,
    required this.product,
    required this.allProducts,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final service = SmartBundlingService();
    final suggestions = service.getFrequentlyBoughtTogether(
      product,
      allProducts,
    );

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Frequently Bought Together',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item['image_url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['image_url'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.shopping_bag),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      '\$${item['price']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TrustBadge extends StatelessWidget {
  final String type;

  const TrustBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'verified':
        icon = Icons.verified;
        color = Colors.blue;
        label = 'Verified';
        break;
      case 'premium':
        icon = Icons.star;
        color = Colors.amber;
        label = 'Premium';
        break;
      case 'top_driver':
        icon = Icons.emoji_events;
        color = Colors.orange;
        label = 'Top Driver';
        break;
      default:
        icon = Icons.verified;
        color = Colors.green;
        label = 'Trusted';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}