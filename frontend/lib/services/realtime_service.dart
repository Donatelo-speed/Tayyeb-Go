import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'order.dart';
import 'product.dart';
import 'user.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final _orderStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _driverStreamController = StreamController<DriverEvent>>.broadcast();
  final _analyticsStreamController = StreamController<AnalyticsEvent>>.broadcast();
  final _inventoryStreamController = StreamController<InventoryEvent>>.broadcast();

  Stream<Map<String, dynamic>> get orderStream => _orderStreamController.stream;
  Stream<DriverEvent> get driverStream => _driverStreamController.stream;
  Stream<AnalyticsEvent> get analyticsStream => _analyticsStreamController.stream;
  Stream<InventoryEvent> get inventoryStream => _inventoryStreamController.stream;

  final _orders = <String, Order>{};
  final _drivers = <String, Driver>{};
  final _products = <int, Product>{};
  final _listeners = <String, Set<Function>>{};

  Timer? _simulationTimer;
  bool _isSimulating = false;

  void startSimulation() {
    if (_isSimulating) return;
    _isSimulating = true;

    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateRealtimeUpdates();
    });
  }

  void stopSimulation() {
    _isSimulating = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _simulateRealtimeUpdates() {
    final random = Random();
    final events = ['order_created', 'driver_location', 'order_status', 'inventory_update'];
    final eventType = events[random.nextInt(events.length)];

    switch (eventType) {
      case 'order_created':
        _analyticsStreamController.add(AnalyticsEvent(
          type: 'order_created',
          data: {'count': random.nextInt(5) + 1},
          timestamp: DateTime.now(),
        ));
        break;
      case 'driver_location':
        final driverIds = _drivers.keys.toList();
        if (driverIds.isNotEmpty) {
          final driverId = driverIds[random.nextInt(driverIds.length)];
          final driver = _drivers[driverId];
          if (driver != null) {
            _drivers[driverId] = driver.copyWith(
              lat: driver.lat + (random.nextDouble() - 0.5) * 0.01,
              lng: driver.lng + (random.nextDouble() - 0.5) * 0.01,
            );
            _driverStreamController.add(DriverEvent(
              type: DriverEventType.locationUpdate,
              driver: _drivers[driverId]!,
              timestamp: DateTime.now(),
            ));
          }
        }
        break;
      case 'order_status':
        final orderIds = _orders.keys.toList();
        if (orderIds.isNotEmpty) {
          final orderId = orderIds[random.nextInt(orderIds.length)];
          final order = _orders[orderId];
          if (order != null && order.status == OrderStatus.pending) {
            _orders[orderId] = order.copyWith(status: OrderStatus.accepted);
            _orderStreamController.add({
              'type': 'order_status_changed',
              'order': _orders[orderId]!.toJson(),
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        }
        break;
      case 'inventory_update':
        final productIds = _products.keys.toList();
        if (productIds.isNotEmpty) {
          final productId = productIds[random.nextInt(productIds.length)];
          final product = _products[productId];
          if (product != null) {
            _inventoryStreamController.add(InventoryEvent(
              type: InventoryEventType.stockUpdated,
              productId: productId,
              newStock: product.stockQuantity + random.nextInt(10) - 5,
              timestamp: DateTime.now(),
            ));
          }
        }
        break;
    }
  }

  void addOrder(Order order) {
    _orders[order.id] = order;
    _orderStreamController.add({
      'type': 'order_created',
      'order': order.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    _notifyListeners('order:${order.id}');
  }

  void updateOrderStatus(String orderId, OrderStatus status, {String? note}) {
    if (_orders.containsKey(orderId)) {
      final order = _orders[orderId]!;
      final history = [
        ...order.statusHistory,
        OrderStatusChange(
          status: status,
          changedBy: 'system',
          note: note,
          timestamp: DateTime.now(),
        ),
      ];
      _orders[orderId] = order.copyWith(status: status, statusHistory: history);
      _orderStreamController.add({
        'type': 'order_status_changed',
        'order': _orders[orderId]!.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      _notifyListeners('order:$orderId');
    }
  }

  void assignDriver(String orderId, Driver driver) {
    if (_orders.containsKey(orderId)) {
      _orders[orderId] = _orders[orderId]!.copyWith(
        driverId: driver.id,
        assignedDriver: driver,
        status: OrderStatus.accepted,
      );
      _orderStreamController.add({
        'type': 'driver_assigned',
        'order': _orders[orderId]!.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      _notifyListeners('order:$orderId');
    }
  }

  Order? getOrder(String orderId) => _orders[orderId];

  List<Order> get orders => _orders.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Order> get pendingOrders => _orders.values
      .where((o) => o.status == OrderStatus.pending)
      .toList();

  void addDriver(Driver driver) {
    _drivers[driver.id] = driver;
    _driverStreamController.add(DriverEvent(
      type: DriverEventType.statusChanged,
      driver: driver,
      timestamp: DateTime.now(),
    ));
  }

  void updateDriverLocation(String driverId, double lat, double lng) {
    if (_drivers.containsKey(driverId)) {
      _drivers[driverId] = _drivers[driverId]!.copyWith(lat: lat, lng: lng);
      _driverStreamController.add(DriverEvent(
        type: DriverEventType.locationUpdate,
        driver: _drivers[driverId]!,
        timestamp: DateTime.now(),
      ));
    }
  }

  Driver? getDriver(String driverId) => _drivers[driverId];

  List<Driver> get availableDrivers => _drivers.values
      .where((d) => d.isAvailable)
      .toList();

  List<Driver> get drivers => _drivers.values.toList();

  void addProduct(Product product) {
    _products[product.id] = product;
    _inventoryStreamController.add(InventoryEvent(
      type: InventoryEventType.productAdded,
      productId: product.id,
      newStock: product.stockQuantity,
      timestamp: DateTime.now(),
    ));
  }

  void updateProductStock(int productId, int newStock) {
    if (_products.containsKey(productId)) {
      final product = _products[productId]!;
      _products[productId] = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        stockQuantity: newStock,
        category: product.category,
        subCategory: product.subCategory,
        brand: product.brand,
        imageUrls: product.imageUrls,
        specifications: product.specifications,
        createdAt: product.createdAt,
      );
      _inventoryStreamController.add(InventoryEvent(
        type: InventoryEventType.stockUpdated,
        productId: productId,
        newStock: newStock,
        timestamp: DateTime.now(),
      ));
    }
  }

  Product? getProduct(int productId) => _products[productId];

  List<Product> get products => _products.values.toList();

  List<Product> get lowStockProducts => _products.values
      .where((p) => p.stockQuantity < 10)
      .toList();

  void subscribe(String channel, Function callback) {
    if (!_listeners.containsKey(channel)) {
      _listeners[channel] = {};
    }
    _listeners[channel]!.add(callback);
  }

  void unsubscribe(String channel, Function callback) {
    _listeners[channel]?.remove(callback);
  }

  void _notifyListeners(String channel) {
    for (final callback in _listeners[channel] ?? []) {
      callback();
    }
  }

  Map<String, dynamic> getAnalytics() {
    final now = DateTime.now();
    final todayOrders = _orders.values
        .where((o) => o.createdAt.day == now.day)
        .toList();
    final todayRevenue = todayOrders.fold<double>(
      0,
      (sum, o) => sum + o.total,
    );
    final activeDeliveries = _orders.values
        .where((o) => o.status == OrderStatus.inTransit || o.status == OrderStatus.pickedUp)
        .length;
    final pendingCount = pendingOrders.length;
    final lowStockCount = lowStockProducts.length;

    return {
      'today_revenue': todayRevenue,
      'today_orders': todayOrders.length,
      'active_deliveries': activeDeliveries,
      'pending_orders': pendingCount,
      'low_stock_count': lowStockCount,
      'total_drivers': _drivers.length,
      'online_drivers': _drivers.values.where((d) => d.isOnline).length,
      'available_drivers': _drivers.values.where((d) => d.isAvailable).length,
    };
  }

  void dispose() {
    stopSimulation();
    _orderStreamController.close();
    _driverStreamController.close();
    _analyticsStreamController.close();
    _inventoryStreamController.close();
  }
}

enum DriverEventType {
  statusChanged,
  locationUpdate,
  orderAssigned,
  orderCompleted,
}

class DriverEvent {
  final DriverEventType type;
  final Driver driver;
  final DateTime timestamp;

  DriverEvent({
    required this.type,
    required this.driver,
    required this.timestamp,
  });
}

enum AnalyticsEventType {
  orderCreated,
  orderCompleted,
  revenueUpdated,
  driverStatusChanged,
}

class AnalyticsEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

enum InventoryEventType {
  productAdded,
  stockUpdated,
  stockDepleted,
  priceChanged,
}

class InventoryEvent {
  final InventoryEventType type;
  final int productId;
  final int newStock;
  final DateTime timestamp;

  InventoryEvent({
    required this.type,
    required this.productId,
    required this.newStock,
    required this.timestamp,
  });
}

class SmartDispatcher {
  static final SmartDispatcher _instance = SmartDispatcher._internal();
  factory SmartDispatcher() => _instance;
  SmartDispatcher._internal();

  final RealtimeService _realtime = RealtimeService();
  final _broadcastController = StreamController<OrderBroadcast>>.broadcast();
  Timer? _dispatchTimer;
  final _pendingBroadcasts = <String, OrderBroadcast>{};

  Stream<OrderBroadcast> get broadcastStream => _broadcastController.stream;

  static const double defaultRadiusKm = 5.0;
  static const int defaultTimeoutSeconds = 30;

  void startDispatching() {
    _dispatchTimer?.cancel();
    _dispatchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkForPendingOrders();
    });
  }

  void stopDispatching() {
    _dispatchTimer?.cancel();
    _dispatchTimer = null;
  }

  void _checkForPendingOrders() {
    final pendingOrders = _realtime.pendingOrders;
    for (final order in pendingOrders) {
      if (!_pendingBroadcasts.containsKey(order.id)) {
        _broadcastOrder(order);
      }
    }
  }

  void _broadcastOrder(Order order) {
    final storeLocation = {'lat': 36.2014, 'lng': 37.1593};
    final availableDrivers = _realtime.availableDrivers;

    final nearbyDrivers = availableDrivers.where((driver) {
      final distance = _calculateDistance(
        storeLocation['lat']!,
        storeLocation['lng']!,
        driver.lat,
        driver.lng,
      );
      return distance <= defaultRadiusKm;
    }).toList()
      ..sort((a, b) {
        final distA = _calculateDistance(
          storeLocation['lat']!,
          storeLocation['lng']!,
          a.lat,
          a.lng,
        );
        final distB = _calculateDistance(
          storeLocation['lat']!,
          storeLocation['lng']!,
          b.lat,
          b.lng,
        );
        return distA.compareTo(distB);
      });

    if (nearbyDrivers.isEmpty) return;

    final broadcast = OrderBroadcast(
      order: order,
      availableDrivers: nearbyDrivers,
      storeLocation: GeoPoint(storeLocation['lat']!, storeLocation['lng']!),
      expiresAt: DateTime.now().add(Duration(seconds: defaultTimeoutSeconds)),
    );

    _pendingBroadcasts[order.id] = broadcast;
    _broadcastController.add(broadcast);

    _scheduleAutoFailover(broadcast);
  }

  void _scheduleAutoFailover(OrderBroadcast broadcast) {
    Future.delayed(Duration(seconds: defaultTimeoutSeconds), () {
      if (_pendingBroadcasts.containsKey(broadcast.order.id)) {
        final currentIndex = broadcast.currentDriverIndex;
        final nextIndex = currentIndex + 1;

        if (nextIndex < broadcast.availableDrivers.length) {
          final updatedBroadcast = OrderBroadcast(
            order: broadcast.order,
            availableDrivers: broadcast.availableDrivers,
            storeLocation: broadcast.storeLocation,
            expiresAt: DateTime.now().add(Duration(seconds: defaultTimeoutSeconds)),
            currentDriverIndex: nextIndex,
          );
          _pendingBroadcasts[broadcast.order.id] = updatedBroadcast;
          _broadcastController.add(updatedBroadcast);
        } else {
          _pendingBroadcasts.remove(broadcast.order.id);
        }
      }
    });
  }

  Future<bool> acceptOrder(String orderId, Driver driver) async {
    if (!_pendingBroadcasts.containsKey(orderId)) return false;

    final broadcast = _pendingBroadcasts[orderId]!;
    final targetDriver = broadcast.availableDrivers[broadcast.currentDriverIndex];

    if (targetDriver.id != driver.id) {
      return false;
    }

    _realtime.assignDriver(orderId, targetDriver);
    _pendingBroadcasts.remove(orderId);
    return true;
  }

  void declineOrder(String orderId, Driver driver) {
    if (!_pendingBroadcasts.containsKey(orderId)) return;

    final broadcast = _pendingBroadcasts[orderId]!;
    final currentIndex = broadcast.currentDriverIndex;
    final nextIndex = currentIndex + 1;

    if (nextIndex < broadcast.availableDrivers.length) {
      final updatedBroadcast = OrderBroadcast(
        order: broadcast.order,
        availableDrivers: broadcast.availableDrivers,
        storeLocation: broadcast.storeLocation,
        expiresAt: DateTime.now().add(Duration(seconds: defaultTimeoutSeconds)),
        currentDriverIndex: nextIndex,
      );
      _pendingBroadcasts[orderId] = updatedBroadcast;
      _broadcastController.add(updatedBroadcast);
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) {
    x = x % (2 * 3.141592653589793);
    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }
  double _cos(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  double _atan2(double y, double x) {
    if (x == 0) return y > 0 ? 1.5707963267948966 : -1.5707963267948966;
    double atan = _taylorAtan(y / x);
    if (x < 0) {
      return y >= 0 ? atan + 3.141592653589793 : atan - 3.141592653589793;
    }
    return atan;
  }
  double _taylorAtan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5707963267948966 - _taylorAtan(1 / x);
    }
    double result = x;
    double term = x;
    for (int n = 1; n <= 20; n++) {
      term *= -x * x;
      result += term / (2 * n + 1);
    }
    return result;
  }

  void dispose() {
    stopDispatching();
    _broadcastController.close();
  }
}

class OrderBroadcast {
  final Order order;
  final List<Driver> availableDrivers;
  final GeoPoint storeLocation;
  final DateTime expiresAt;
  final int currentDriverIndex;

  OrderBroadcast({
    required this.order,
    required this.availableDrivers,
    required this.storeLocation,
    required this.expiresAt,
    this.currentDriverIndex = 0,
  });

  Driver get currentDriver => availableDrivers[currentDriverIndex];

  int get remainingSeconds => expiresAt.difference(DateTime.now()).inSeconds;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  double get estimatedPayout => order.total * 0.15;

  double get distanceKm {
    const double earthRadius = 6371;
    final double dLat = _toRadians(storeLocation.lat - order.deliveryAddress.lat);
    final double dLng = _toRadians(storeLocation.lng - order.deliveryAddress.lng);
    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(storeLocation.lat)) *
            _cos(_toRadians(order.deliveryAddress.lat)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) {
    x = x % (2 * 3.141592653589793);
    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }
  double _cos(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  double _atan2(double y, double x) {
    if (x == 0) return y > 0 ? 1.5707963267948966 : -1.5707963267948966;
    double atan = _taylorAtan(y / x);
    if (x < 0) {
      return y >= 0 ? atan + 3.141592653589793 : atan - 3.141592653589793;
    }
    return atan;
  }
  double _taylorAtan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5707963267948966 - _taylorAtan(1 / x);
    }
    double result = x;
    double term = x;
    for (int n = 1; n <= 20; n++) {
      term *= -x * x;
      result += term / (2 * n + 1);
    }
    return result;
  }
}

class GeoPoint {
  final double lat;
  final double lng;

  GeoPoint(this.lat, this.lng);
}

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  double _exchangeRate = 13000.0;
  String _currency = 'SYP';
  DateTime? _lastUpdated;
  Timer? _updateTimer;

  double get exchangeRate => _exchangeRate;
  String get currency => _currency;
  DateTime? get lastUpdated => _lastUpdated;

  double convert(double amountUSD) => amountUSD * _exchangeRate;
  double convertToUSD(double amountSYP) => amountSYP / _exchangeRate;

  String formatSYP(double amountUSD) {
    final converted = convert(amountUSD);
    return '${converted.toStringAsFixed(0)} $_currency';
  }

  String formatDual(double amountUSD) {
    return '\$${amountUSD.toStringAsFixed(2)} / ${formatSYP(amountUSD)}';
  }

  void setExchangeRate(double rate) {
    _exchangeRate = rate;
    _lastUpdated = DateTime.now();
  }

  void startAutoUpdate({Duration interval = const Duration(hours: 1)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) async {
      await _fetchExchangeRate();
    });
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _fetchExchangeRate() async {
    try {
      // In production, this would call an actual API
      // For demo, we simulate a daily fluctuation
      final random = Random();
      final fluctuation = 1 + (random.nextDouble() - 0.5) * 0.02;
      _exchangeRate = (_exchangeRate * fluctuation).roundToDouble();
      _lastUpdated = DateTime.now();
    } catch (e) {
      // Keep last known rate on error
    }
  }

  void dispose() {
    stopAutoUpdate();
  }
}