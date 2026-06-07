import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/i_restaurant_repository.dart';

class FirebaseRestaurantRepository implements IRestaurantRepository {
  static final FirebaseRestaurantRepository instance = FirebaseRestaurantRepository._();
  FirebaseRestaurantRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('restaurants');

  @override
  Stream<List<Restaurant>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Restaurant.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Stream<Restaurant> watchById(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => Restaurant.fromMap(d.data() as Map<String, dynamic>, d.id));

  @override
  Stream<List<Restaurant>> watchByOwner(String ownerId) => _col
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Restaurant.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Future<void> save(Restaurant restaurant) =>
      _col.doc(restaurant.id).set(restaurant.toMap());

  @override
  Future<void> update(String id, Map<String, dynamic> updates) =>
      _col.doc(id).update(updates);

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
