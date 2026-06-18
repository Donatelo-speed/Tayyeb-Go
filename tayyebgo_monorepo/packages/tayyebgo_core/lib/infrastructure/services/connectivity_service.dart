import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();
  Connectivity? _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void init() {
    if (kIsWeb) {
      _isOnline = true;
      return;
    }
    try {
      _connectivity = Connectivity();
      _connectivity!.checkConnectivity().then((result) {
        _isOnline = result != ConnectivityResult.none;
      });
      _sub = _connectivity!.onConnectivityChanged.listen((results) {
        _isOnline = results.any((r) => r != ConnectivityResult.none);
        _controller.add(_isOnline);
      });
    } catch (e) {
      debugPrint('[ConnectivityService] init error: $e');
      _isOnline = true;
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}