import '../../domain/entities/brand.dart';

abstract class IBrandRepository {
  Stream<List<Brand>> watchAll();
  Stream<Brand?> watchById(String id);
  Future<void> create(Brand brand);
  Future<void> update(String id, Map<String, dynamic> updates);
  Future<void> deactivate(String id);
}
