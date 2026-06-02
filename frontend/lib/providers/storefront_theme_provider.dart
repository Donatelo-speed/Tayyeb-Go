import 'package:flutter/foundation.dart';
import '../models/storefront_theme.dart';
import '../services/api_service.dart';
import '../services/api_service_extensions.dart';

class StorefrontThemeProvider extends ChangeNotifier {
  final ApiService _api;

  StorefrontThemeProvider({ApiService? api}) : _api = api ?? ApiService();

  /// Cache: vendorId → theme.  Multiple store sheets can coexist.
  final Map<String, StorefrontTheme> _cache = {};

  /// The currently active storefront (the one the user is viewing).
  StorefrontTheme? _active;
  StorefrontTheme? get active => _active;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ─── Load ──────────────────────────────────────────────────────────────────

  /// Fetches theme for [vendorId].  If cached and [forceRefresh] is false,
  /// returns immediately from cache without a network call.
  Future<StorefrontTheme> loadThemeFor(
    String vendorId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(vendorId)) {
      _active = _cache[vendorId];
      notifyListeners();
      return _active!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getStorefrontTheme(vendorId);
      final theme = StorefrontTheme.fromJson(data as Map<String, dynamic>);
      _cache[vendorId] = theme;
      _active = theme;
    } catch (e) {
      // Fall back to defaults — never block the screen from loading.
      final fallback = StorefrontTheme.defaultFor(vendorId);
      _cache[vendorId] = fallback;
      _active = fallback;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _active!;
  }

  /// Activate a cached theme without a network call (e.g. when navigating
  /// back to a previously loaded store).
  void activateCached(String vendorId) {
    if (_cache.containsKey(vendorId)) {
      _active = _cache[vendorId];
      notifyListeners();
    }
  }

  // ─── Vendor-side theme editor ──────────────────────────────────────────────

  /// Persist vendor's theme changes to backend.
  Future<bool> saveTheme(StorefrontTheme theme) async {
    try {
      await _api.saveStorefrontTheme(theme.vendorId, theme.toJson());
      _cache[theme.vendorId] = theme;
      if (_active?.vendorId == theme.vendorId) {
        _active = theme;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Applies a preview update locally without persisting (for live-preview in
  /// the vendor theme editor — no network call).
  void previewTheme(StorefrontTheme theme) {
    _active = theme;
    notifyListeners();
  }

  void clearActive() {
    _active = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
