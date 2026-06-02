import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/i_promotion_repository.dart';

class FirebasePromotionRepository implements IPromotionRepository {
  static final FirebasePromotionRepository instance = FirebasePromotionRepository._();
  FirebasePromotionRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('Promos');

  @override
  Stream<List<Promotion>> watchActive() => _col
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Promotion.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Future<void> save(Promotion promotion) =>
      _col.doc(promotion.id).set(promotion.toMap());

  @override
  Future<void> toggleActive(String id, bool active) =>
      _col.doc(id).update({'isActive': active});

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
