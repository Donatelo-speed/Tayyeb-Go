import '../entities/menu_item.dart';
import '../entities/menu_modifier.dart';
import '../value_objects/money.dart';

abstract class IMenuSyncService {
  Stream<List<MenuItem>> getBranchMenu(String branchId);

  Stream<List<MenuItem>> getBrandSharedItems(String brandId);

  Future<MenuItem> createSharedItem({
    required String brandId,
    required String name,
    required String description,
    required Money price,
    required String category,
    List<String> tags,
    String? imageUrl,
    int sortOrder,
    List<MenuModifierGroup> modifierGroups,
  });

  Future<MenuItem> createBranchOverride({
    required String brandId,
    required String branchId,
    required String sharedItemId,
    Money? price,
    Money? originalPrice,
    bool? isAvailable,
    String? description,
    int? sortOrder,
  });

  Future<void> propagateSharedUpdate(
    String sharedItemId,
    Map<String, dynamic> updatedFields,
  );

  Future<void> removeBranchOverride(String overrideId);

  Future<void> deleteSharedItem(String sharedItemId);
}