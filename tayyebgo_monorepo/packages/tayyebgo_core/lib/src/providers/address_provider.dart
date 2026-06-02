import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/smart_address.dart';

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

      final snap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .get();

      _addresses = snap.docs
          .map((d) => SmartAddress.fromFirestore(d))
          .toList();

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
        await _clearDefaultAddress(userId);
      }

      final docRef = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('addresses')
          .add({
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadAddresses(userId);
      return docRef.id;
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
        await _clearDefaultAddress(userId);
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('addresses')
          .doc(address.id)
          .update(address.toFirestore());

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
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();

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

  Future<void> _clearDefaultAddress(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.update({'isDefault': false});
    }
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
