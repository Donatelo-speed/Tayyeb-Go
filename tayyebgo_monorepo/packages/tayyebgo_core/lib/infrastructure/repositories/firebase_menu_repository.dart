import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/i_menu_repository.dart';

class FirebaseMenuRepository implements IMenuRepository {
  static final FirebaseMenuRepository instance = FirebaseMenuRepository._();
  FirebaseMenuRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('menu_items');

  @override
  Stream<List<MenuItem>> watchByRestaurant(String restaurantId) => _col
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => s.docs
          .map((d) => MenuItem.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Future<void> save(MenuItem item) => _col.doc(item.id).set(item.toMap());

  @override
  Future<void> update(String id, Map<String, dynamic> updates) =>
      _col.doc(id).update(updates);

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
