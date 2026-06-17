import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/deep_link_service.dart';

class DeepLinkProvider extends ChangeNotifier {
  final DeepLinkService _service = DeepLinkService();
  StreamSubscription<DeepLinkRoute>? _routeSubscription;

  DeepLinkRoute? _pendingRoute;
  bool _initialized = false;

  DeepLinkRoute? get pendingRoute => _pendingRoute;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    await _service.initialize();
    _initialized = true;

    _routeSubscription = _service.onRoute.listen((route) {
      _pendingRoute = route;
      notifyListeners();
    });

    notifyListeners();
  }

  DeepLinkRoute? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  @override
  void dispose() {
    _routeSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
