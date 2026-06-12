import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_promotion_lookup_repository.dart';

class FirebasePromotionLookupRepository implements IPromotionLookupRepository {
  static final FirebasePromotionLookupRepository instance = FirebasePromotionLookupRepository._();
  FirebasePromotionLookupRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> validateCoupon(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    final snapshot = await _firestore
        .collection('promos')
        .where('code', isEqualTo: normalizedCode)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    final isActive = data['isActive'] as bool? ?? data['active'] as bool? ?? false;
    if (!isActive) return null;

    return data;
  }
}
