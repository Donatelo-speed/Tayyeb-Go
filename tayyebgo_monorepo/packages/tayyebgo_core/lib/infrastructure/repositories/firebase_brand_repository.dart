import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/brand.dart';
import '../../domain/repositories/i_brand_repository.dart';

class FirebaseBrandRepository implements IBrandRepository {
  static final FirebaseBrandRepository instance = FirebaseBrandRepository._();
  FirebaseBrandRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _brands => _firestore.collection('brands');

  @override
  Stream<List<Brand>> watchAll() => _brands
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Brand.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Stream<Brand?> watchById(String id) => _brands
      .doc(id)
      .snapshots()
      .map((d) =>
          d.exists ? Brand.fromMap(d.data() as Map<String, dynamic>, d.id) : null);

  @override
  Future<void> create(Brand brand) =>
      _brands.doc(brand.id).set(brand.toMap());

  @override
  Future<void> update(String id, Map<String, dynamic> updates) =>
      _brands.doc(id).update(updates);

  @override
  Future<void> deactivate(String id) =>
      _brands.doc(id).update({'isActive': false});
}