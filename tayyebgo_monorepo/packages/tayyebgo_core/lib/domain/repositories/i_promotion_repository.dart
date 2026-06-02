import '../entities/promotion.dart';

abstract class IPromotionRepository {
  Stream<List<Promotion>> watchActive();
  Future<void> save(Promotion promotion);
  Future<void> toggleActive(String id, bool active);
  Future<void> delete(String id);
}
