import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_modifier.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/services/i_menu_sync_service.dart';

class FirebaseMenuSyncService implements IMenuSyncService {
  static final FirebaseMenuSyncService instance = FirebaseMenuSyncService._();
  FirebaseMenuSyncService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _items => _firestore.collection('menu_items');
  CollectionReference get _branches => _firestore.collection('branches');

  @override
  Stream<List<MenuItem>> getBranchMenu(String branchId) {
    final controller = StreamController<List<MenuItem>>();
    List<MenuItem> shared = [];
    List<MenuItem> branchItems = [];

    void emit() {
      if (controller.isClosed) return;
      controller.add(_merge(shared, branchItems));
    }

    _branches.doc(branchId).get().then((snap) {
      if (!snap.exists) {
        controller.addError(Exception('Branch $branchId not found'));
        return;
      }
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) {
        controller.addError(Exception('Branch $branchId has no data'));
        return;
      }
      final brandId = data['brandId'] as String? ?? '';
      if (brandId.isEmpty) {
        controller.addError(Exception('Branch $branchId has no brandId'));
        return;
      }

      _items
          .where('brandId', isEqualTo: brandId)
          .where('branchId', isNull: true)
          .snapshots()
          .listen((s) {
        shared = s.docs
            .map((d) =>
                MenuItem.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
        emit();
      }, onError: controller.addError);

      _items
          .where('branchId', isEqualTo: branchId)
          .snapshots()
          .listen((s) {
        branchItems = s.docs
            .map((d) =>
                MenuItem.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
        emit();
      }, onError: controller.addError);
    }, onError: controller.addError);

    return controller.stream;
  }

  @override
  Stream<List<MenuItem>> getBrandSharedItems(String brandId) => _items
      .where('brandId', isEqualTo: brandId)
      .where('branchId', isNull: true)
      .orderBy('sortOrder')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => MenuItem.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  @override
  Future<MenuItem> createSharedItem({
    required String brandId,
    required String name,
    required String description,
    required Money price,
    required String category,
    List<String> tags = const [],
    String? imageUrl,
    int sortOrder = 0,
    List<MenuModifierGroup> modifierGroups = const [],
  }) async {
    final docRef = _items.doc();
    final item = MenuItem(
      id: docRef.id,
      brandId: brandId,
      name: name,
      description: description,
      price: price,
      category: category,
      tags: tags,
      imageUrl: imageUrl,
      sortOrder: sortOrder,
      modifierGroups: modifierGroups,
      createdAt: DateTime.now(),
    );
    await docRef.set(item.toMap());
    return item;
  }

  @override
  Future<MenuItem> createBranchOverride({
    required String brandId,
    required String branchId,
    required String sharedItemId,
    Money? price,
    Money? originalPrice,
    bool? isAvailable,
    String? description,
    int? sortOrder,
  }) async {
    final sharedDoc = await _items.doc(sharedItemId).get();
    if (!sharedDoc.exists) {
      throw Exception('Shared item $sharedItemId not found');
    }
    final shared = sharedDoc.data() as Map<String, dynamic>;

    final docRef = _items.doc();
    final item = MenuItem(
      id: docRef.id,
      brandId: brandId,
      branchId: branchId,
      sharedItemId: sharedItemId,
      name: shared['name'] as String? ?? '',
      description: description ?? shared['description'] as String? ?? '',
      price: price ?? Money((shared['price'] as num?)?.toInt() ?? 0),
      originalPrice: originalPrice,
      category: shared['category'] as String? ?? 'Main Course',
      tags: (shared['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modifierGroups: (shared['modifierGroups'] as List<dynamic>?)
              ?.map((e) =>
                  MenuModifierGroup.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isAvailable: isAvailable ?? shared['isAvailable'] as bool? ?? true,
      imageUrl: shared['imageUrl'] as String?,
      sortOrder: sortOrder ?? (shared['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.now(),
    );
    await docRef.set(item.toMap());
    return item;
  }

  @override
  Future<void> propagateSharedUpdate(
      String sharedItemId, Map<String, dynamic> updatedFields) async {
    final allowed = <String>{
      'name', 'description', 'category', 'tags',
      'modifierGroups', 'sortOrder', 'imageUrl',
    };
    final safe = updatedFields.entries
        .where((e) => allowed.contains(e.key))
        .fold<Map<String, dynamic>>({}, (m, e) {
      m[e.key] = e.value;
      return m;
    });
    safe['updatedAt'] = FieldValue.serverTimestamp();

    await _items.doc(sharedItemId).update(safe);
  }

  @override
  Future<void> removeBranchOverride(String overrideId) async {
    await _items.doc(overrideId).delete();
  }

  @override
  Future<void> deleteSharedItem(String sharedItemId) async {
    final batch = _firestore.batch();
    batch.delete(_items.doc(sharedItemId));
    final overrides = await _items
        .where('sharedItemId', isEqualTo: sharedItemId)
        .get();
    for (final doc in overrides.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  List<MenuItem> _merge(List<MenuItem> shared, List<MenuItem> branchItems) {
    final overrideMap = <String, MenuItem>{};
    for (final item in branchItems) {
      final key = item.sharedItemId ?? item.id;
      overrideMap[key] = item;
    }

    final merged = <MenuItem>[];
    final seen = <String>{};

    for (final item in shared) {
      final key = item.sharedItemId ?? item.id;
      seen.add(key);
      final override = overrideMap[key];
      if (override != null) {
        merged.add(item.copyWith(
          price: override.price,
          originalPrice: override.originalPrice,
          isAvailable: override.isAvailable,
          description: override.description,
          sortOrder: override.sortOrder,
          branchId: override.branchId,
        ));
      } else {
        merged.add(item);
      }
    }

    for (final item in branchItems) {
      final key = item.sharedItemId ?? item.id;
      if (!seen.contains(key)) {
        merged.add(item);
        seen.add(key);
      }
    }

    merged.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return merged;
  }
}