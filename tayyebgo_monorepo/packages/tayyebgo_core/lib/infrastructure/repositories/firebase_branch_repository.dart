import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/branch.dart';
import '../../domain/value_objects/geohash.dart';
import '../../domain/repositories/i_branch_repository.dart';

class FirebaseBranchRepository implements IBranchRepository {
  static final FirebaseBranchRepository instance = FirebaseBranchRepository._();
  FirebaseBranchRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _branches => _firestore.collection('branches');

  @override
  Stream<List<Branch>> watchByBrand(String brandId) => _branches
      .where('brandId', isEqualTo: brandId)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Branch.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Stream<List<Branch>> watchNearby(double lat, double lon,
      {double radiusKm = 5.0}) {
    final hash = Geohash.encode(lat, lon);
    final precision = Geohash.precisionForRadius(radiusKm);
    final prefix = hash.substring(0, precision);
    final end = '${prefix.substring(0, prefix.length - 1)}'
        '${String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1)}';
    return _branches
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThan: end)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(
                (d) => Branch.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  @override
  Stream<Branch?> watchById(String id) => _branches
      .doc(id)
      .snapshots()
      .map((d) => d.exists
          ? Branch.fromMap(d.data() as Map<String, dynamic>, d.id)
          : null);

  @override
  Future<void> create(Branch branch) =>
      _branches.doc(branch.id).set(branch.toMap());

  @override
  Future<void> update(String id, Map<String, dynamic> updates) =>
      _branches.doc(id).update(updates);

  @override
  Future<void> deactivate(String id) =>
      _branches.doc(id).update({'isActive': false});
}