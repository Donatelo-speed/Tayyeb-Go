import '../entities/menu_item.dart';

abstract class IMenuRepository {
  Stream<List<MenuItem>> watchByRestaurant(String restaurantId);
  Future<void> save(MenuItem item);
  Future<void> update(String id, Map<String, dynamic> updates);
  Future<void> delete(String id);
}
