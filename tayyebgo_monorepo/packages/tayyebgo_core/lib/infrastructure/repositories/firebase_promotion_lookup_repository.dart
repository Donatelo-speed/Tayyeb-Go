import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_promotion_lookup_repository.dart';

class FirebasePromotionLookupRepository implements IPromotionLookupRepository {
  static final FirebasePromotionLookupRepository instance = FirebasePromotionLookupRepository._();
  FirebasePromotionLookupRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> validateCoupon(String code) async {
    final snapshot = await _firestore
        .collection('promos')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .where('active', isEqualTo: true)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }
}
