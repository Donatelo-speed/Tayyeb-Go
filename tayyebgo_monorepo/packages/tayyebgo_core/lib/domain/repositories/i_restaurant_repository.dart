import '../entities/restaurant.dart';

abstract class IRestaurantRepository {
  Stream<List<Restaurant>> watchAll();
  Stream<Restaurant> watchById(String id);
  Stream<List<Restaurant>> watchByOwner(String ownerId);
  Future<void> save(Restaurant restaurant);
  Future<void> update(String id, Map<String, dynamic> updates);
  Future<void> delete(String id);
}
