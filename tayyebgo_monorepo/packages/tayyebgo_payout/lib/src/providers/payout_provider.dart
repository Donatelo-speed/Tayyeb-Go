import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/payout.dart';

class PayoutProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  Stream<List<Payout>>? _payoutsStream;
  List<Payout> _payouts = [];
  bool _loading = false;
  String? _error;

  PayoutProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  List<Payout> get payouts => _payouts;
  bool get loading => _loading;
  String? get error => _error;

  void listenToVendorPayouts(String vendorId) {
    _payoutsStream = _firestore
        .collection('payouts')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payout.fromMap(doc.data(), doc.id))
            .toList());

    _payoutsStream!.listen(
      (payouts) {
        _payouts = payouts;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _loading = false;
        notifyListeners();
      },
    );
    _loading = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _payoutsStream = null;
    super.dispose();
  }
}
