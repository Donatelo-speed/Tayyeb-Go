import '../../domain/entities/branch.dart';

abstract class IBranchRepository {
  Stream<List<Branch>> watchByBrand(String brandId);
  Stream<List<Branch>> watchNearby(double lat, double lon, {double radiusKm});
  Stream<Branch?> watchById(String id);
  Future<void> create(Branch branch);
  Future<void> update(String id, Map<String, dynamic> updates);
  Future<void> deactivate(String id);
}
