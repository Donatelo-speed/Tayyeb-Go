import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/api_service_extensions.dart';

// ─── Driver availability states ────────────────────────────────────────────────

enum DriverAvailability {
  /// Driver has toggled offline — not discoverable by dispatch.
  offline,

  /// Driver is online and waiting for an order.
  available,

  /// Driver accepted an order and is en route to the restaurant.
  enRouteToRestaurant,

  /// Driver picked up the order and is heading to the customer.
  enRouteToCustomer,
}

// ─── Incoming order notification ──────────────────────────────────────────────

/// Represents an inbound order pushed to this driver by the dispatch engine.
/// The driver has [windowSeconds] to accept or reject before it times out.
class IncomingOrderNotification {
  final OrderModel order;
  final double distanceKm;
  final double estimatedEarnings;

  /// How many seconds the driver has to respond (default 30).
  final int windowSeconds;
  final DateTime receivedAt;

  IncomingOrderNotification({
    required this.order,
    required this.distanceKm,
    required this.estimatedEarnings,
    this.windowSeconds = 30,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  /// Seconds remaining in the accept/reject window.
  int get secondsRemaining {
    final elapsed = DateTime.now().difference(receivedAt).inSeconds;
    return math.max(0, windowSeconds - elapsed);
  }

  bool get isExpired => secondsRemaining == 0;

  double get progressFraction =>
      (windowSeconds - secondsRemaining) / windowSeconds;
}

// ─── GPS position ─────────────────────────────────────────────────────────────

class DriverPosition {
  final double lat;
  final double lng;
  final double? accuracy; // metres
  final double? heading; // degrees
  final DateTime timestamp;

  const DriverPosition({
    required this.lat,
    required this.lng,
    this.accuracy,
    this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
      };
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class DriverStatusProvider extends ChangeNotifier {
  final ApiService _api;

  DriverStatusProvider({ApiService? api}) : _api = api ?? ApiService();

  // ── Availability ────────────────────────────────────────────────────────────
  DriverAvailability _availability = DriverAvailability.offline;
  DriverAvailability get availability => _availability;
  bool get isOnline => _availability != DriverAvailability.offline;

  // ── Current order ────────────────────────────────────────────────────────────
  OrderModel? _activeOrder;
  OrderModel? get activeOrder => _activeOrder;

  // ── Incoming order window ────────────────────────────────────────────────────
  IncomingOrderNotification? _incomingOrder;
  IncomingOrderNotification? get incomingOrder => _incomingOrder;
  Timer? _acceptWindowTimer;
  Timer? _acceptWindowCountdown;
  int _countdownSeconds = 30;
  int get countdownSeconds => _countdownSeconds;

  // ── GPS ──────────────────────────────────────────────────────────────────────
  DriverPosition? _currentPosition;
  DriverPosition? get currentPosition => _currentPosition;

  Timer? _locationTimer;

  /// Simulated position drift for demo / emulator. Replace body with
  /// geolocator.getPositionStream() when the plugin is available.
  static const double _baseLat = 33.5138; // Damascus
  static const double _baseLng = 36.2765;
  int _locationTick = 0;

  // ── Earnings ─────────────────────────────────────────────────────────────────
  double _earningsToday = 0.0;
  double _earningsWeek = 0.0;
  double _earningsMonth = 0.0;
  int _completedToday = 0;

  double get earningsToday => _earningsToday;
  double get earningsWeek => _earningsWeek;
  double get earningsMonth => _earningsMonth;
  int get completedToday => _completedToday;

  // ── Polling for new orders ────────────────────────────────────────────────────
  Timer? _orderPollTimer;

  // ─── Public API ───────────────────────────────────────────────────────────────

  /// Call once after the user is authenticated as a driver.
  Future<void> initialize() async {
    await loadEarnings();
    // If previously online, restore state from server.
    try {
      final status = await _api.getDriverStatus();
      final serverOnline = status['is_online'] == true;
      if (serverOnline) {
        await _goOnline(restoring: true);
      }
    } catch (_) {
      // Server unreachable; start offline.
    }
  }

  /// Toggle between online and offline. Propagates to backend.
  Future<void> setOnline(bool online) async {
    if (online && !isOnline) {
      await _goOnline();
    } else if (!online && isOnline) {
      await _goOffline();
    }
  }

  Future<void> _goOnline({bool restoring = false}) async {
    _availability = DriverAvailability.available;
    notifyListeners();

    _startLocationBroadcast();
    _startOrderPolling();

    if (!restoring) {
      try {
        await _api.setDriverOnline(true, position: _currentPosition);
      } catch (_) {
        // State already set locally.
      }
    }
  }

  Future<void> _goOffline() async {
    _availability = DriverAvailability.offline;
    _dismissIncomingOrder();
    _locationTimer?.cancel();
    _locationTimer = null;
    _orderPollTimer?.cancel();
    _orderPollTimer = null;
    notifyListeners();

    try {
      await _api.setDriverOnline(false, position: _currentPosition);
    } catch (_) {}
  }

  // ─── Incoming order handling ───────────────────────────────────────────────

  void _presentIncomingOrder(IncomingOrderNotification notification) {
    if (_activeOrder != null) return; // already busy

    _incomingOrder = notification;
    _countdownSeconds = notification.windowSeconds;
    notifyListeners();

    // Countdown tick every second to update the progress ring.
    _acceptWindowCountdown?.cancel();
    _acceptWindowCountdown =
        Timer.periodic(const Duration(seconds: 1), (t) {
      _countdownSeconds = _incomingOrder?.secondsRemaining ?? 0;
      if (_countdownSeconds <= 0) {
        t.cancel();
        _dismissIncomingOrder();
      }
      notifyListeners();
    });

    // Auto-dismiss at window expiry.
    _acceptWindowTimer?.cancel();
    _acceptWindowTimer = Timer(
      Duration(seconds: notification.windowSeconds),
      _dismissIncomingOrder,
    );
  }

  /// Driver taps Accept.
  Future<bool> acceptOrder() async {
    final incoming = _incomingOrder;
    if (incoming == null || incoming.isExpired) return false;

    _acceptWindowTimer?.cancel();
    _acceptWindowCountdown?.cancel();

    try {
      await _api.acceptDriverOrder(incoming.order.id);
      _activeOrder = incoming.order;
      _availability = DriverAvailability.enRouteToRestaurant;
      _incomingOrder = null;
      notifyListeners();
      return true;
    } catch (e) {
      _dismissIncomingOrder();
      return false;
    }
  }

  /// Driver taps Reject.
  Future<void> rejectOrder() async {
    final incoming = _incomingOrder;
    if (incoming == null) return;

    _acceptWindowTimer?.cancel();
    _acceptWindowCountdown?.cancel();

    try {
      await _api.rejectDriverOrder(incoming.order.id);
    } catch (_) {}
    _dismissIncomingOrder();
  }

  void _dismissIncomingOrder() {
    _acceptWindowTimer?.cancel();
    _acceptWindowCountdown?.cancel();
    _incomingOrder = null;
    notifyListeners();
  }

  // ─── Order lifecycle progressions ─────────────────────────────────────────

  Future<bool> markPickedUp() async {
    if (_activeOrder == null) return false;
    try {
      await _api.updateOrderStatus(_activeOrder!.id, 'picked_up');
      _activeOrder = _activeOrder!.copyWith(status: OrderStatus.pickedUp);
      _availability = DriverAvailability.enRouteToCustomer;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markDelivered({String? proofUrl, String? signature}) async {
    if (_activeOrder == null) return false;
    try {
      await _api.completeDelivery(
        _activeOrder!.id,
        proofUrl: proofUrl,
        signature: signature,
        position: _currentPosition,
      );
      _earningsToday += _activeOrder!.deliveryFee;
      _earningsWeek += _activeOrder!.deliveryFee;
      _earningsMonth += _activeOrder!.deliveryFee;
      _completedToday++;
      _activeOrder = null;
      _availability = DriverAvailability.available;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── GPS broadcast ─────────────────────────────────────────────────────────

  void _startLocationBroadcast() {
    _locationTimer?.cancel();

    // Emit a position immediately, then every 5 seconds.
    _emitPosition();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _emitPosition();
    });
  }

  void _emitPosition() {
    // Production: replace with geolocator position stream.
    // For now we simulate gentle drift so the map marker moves.
    _locationTick++;
    final offset = _locationTick * 0.0001;
    final lat = _baseLat + offset * math.sin(_locationTick.toDouble());
    final lng = _baseLng + offset * math.cos(_locationTick.toDouble());

    _currentPosition = DriverPosition(
      lat: lat,
      lng: lng,
      accuracy: 5.0,
      heading: (_locationTick * 15.0) % 360,
      timestamp: DateTime.now(),
    );
    notifyListeners();

    // Fire-and-forget to backend.
    if (_currentPosition != null) {
      _api
          .broadcastDriverLocation(_currentPosition!)
          .catchError((_) {/* non-fatal */});
    }
  }

  // ─── Order polling ─────────────────────────────────────────────────────────

  void _startOrderPolling() {
    _orderPollTimer?.cancel();
    _orderPollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (_availability != DriverAvailability.available) return;
      try {
        final data = await _api.pollIncomingOrder();
        if (data != null && data['order'] != null) {
          final order = OrderModel.fromJson(data['order'] as Map<String, dynamic>);
          final notification = IncomingOrderNotification(
            order: order,
            distanceKm: double.tryParse(
                    data['distance_km']?.toString() ?? '1') ?? 1.0,
            estimatedEarnings: double.tryParse(
                    data['estimated_earnings']?.toString() ?? '5') ?? 5.0,
            windowSeconds: (data['window_seconds'] as num?)?.toInt() ?? 30,
          );
          _presentIncomingOrder(notification);
        }
      } catch (_) {/* non-fatal — keep polling */}
    });
  }

  // ─── Earnings ──────────────────────────────────────────────────────────────

  Future<void> loadEarnings() async {
    try {
      final data = await _api.getDriverEarnings();
      _earningsToday = double.tryParse(data['today']?.toString() ?? '0') ?? 0;
      _earningsWeek = double.tryParse(data['week']?.toString() ?? '0') ?? 0;
      _earningsMonth = double.tryParse(data['month']?.toString() ?? '0') ?? 0;
      _completedToday = (data['completed_today'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _locationTimer?.cancel();
    _orderPollTimer?.cancel();
    _acceptWindowTimer?.cancel();
    _acceptWindowCountdown?.cancel();
    super.dispose();
  }
}
