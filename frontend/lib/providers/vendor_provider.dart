import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor.dart';

class VendorProvider extends ChangeNotifier {
  List<Vendor> _allVendors = [];
  bool _isLoading = false;
  String? _error;

  List<Vendor> get allVendors => _allVendors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVendors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('isActive', isEqualTo: true)
          .get();
      _allVendors = snapshot.docs
          .map((doc) => Vendor.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      _allVendors = _demoVendors;
    }

    _isLoading = false;
    notifyListeners();
  }

  static const List<Vendor> _demoVendors = [
    Vendor(id: '1', name: 'Al Mandi Palace', typeDisplay: 'Yemeni', address: 'Main Street', rating: 4.5, isOpen: true),
    Vendor(id: '2', name: 'Pizza Roma', typeDisplay: 'Italian', address: 'King Road', rating: 4.2, isOpen: true),
    Vendor(id: '3', name: 'Sushi World', typeDisplay: 'Japanese', address: 'Prince St', rating: 4.8, isOpen: true),
    Vendor(id: '4', name: 'Grill House', typeDisplay: 'American', address: 'Market Ave', rating: 4.0, isOpen: false),
    Vendor(id: '5', name: 'Café Arabica', typeDisplay: 'Café', address: 'Park Lane', rating: 4.6, isOpen: true),
  ];
}
