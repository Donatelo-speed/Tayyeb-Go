import 'package:flutter/foundation.dart';
import '../models/smart_address.dart';
import '../di/app_locator.dart';

class AddressProvider extends ChangeNotifier {
  List<SmartAddress> _addresses = [];
  SmartAddress? _selectedAddress;
  bool _isLoading = false;
  String? _error;

  List<SmartAddress> get addresses => _addresses;
  SmartAddress? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAddresses(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await AppLocator.instance.addresses.getAddresses(userId);
      _addresses = data.map((d) => SmartAddress.fromMap(d['id'] as String, d)).toList();

      if (_selectedAddress != null) {
        _selectedAddress = _addresses.firstWhere(
          (a) => a.id == _selectedAddress!.id,
          orElse: () => _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.isNotEmpty ? _addresses.first : _selectedAddress!,
          ),
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addAddress({
    required String userId,
    required String label,
    required String fullAddress,
    String? city,
    String? street,
    String? building,
    String? floor,
    String? apartment,
    double? latitude,
    double? longitude,
    String? landmark,
    String? buildingPhotoUrl,
    String? voiceNoteUrl,
    String? voiceDirections,
    bool isDefault = false,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (isDefault) {
        await AppLocator.instance.addresses.clearDefaultAddress(userId);
      }

      final addressData = {
        'label': label,
        'fullAddress': fullAddress,
        if (city != null) 'city': city,
        if (street != null) 'street': street,
        if (building != null) 'building': building,
        if (floor != null) 'floor': floor,
        if (apartment != null) 'apartment': apartment,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (landmark != null) 'landmark': landmark,
        if (buildingPhotoUrl != null) 'buildingPhotoUrl': buildingPhotoUrl,
        if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
        if (voiceDirections != null) 'voiceDirections': voiceDirections,
        'isDefault': isDefault,
      };

      final docId = await AppLocator.instance.addresses.addAddress(userId, addressData);

      await loadAddresses(userId);
      return docId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAddress(String userId, SmartAddress address) async {
    try {
      if (address.isDefault) {
        await AppLocator.instance.addresses.clearDefaultAddress(userId);
      }

      await AppLocator.instance.addresses.updateAddress(
        userId,
        address.id,
        address.toFirestore(),
      );

      await loadAddresses(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      await AppLocator.instance.addresses.deleteAddress(userId, addressId);

      _addresses.removeWhere((a) => a.id == addressId);
      if (_selectedAddress?.id == addressId) {
        _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectAddress(SmartAddress address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void clear() {
    _addresses = [];
    _selectedAddress = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
