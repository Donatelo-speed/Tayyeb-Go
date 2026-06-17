import 'package:cloud_firestore/cloud_firestore.dart';

class PriceChange {
  final String itemName;
  final double oldPrice;
  final double newPrice;

  PriceChange({
    required this.itemName,
    required this.oldPrice,
    required this.newPrice,
  });

  double get difference => newPrice - oldPrice;
  bool get increased => newPrice > oldPrice;
  bool get decreased => newPrice < oldPrice;
  double get percentageChange =>
      oldPrice > 0 ? ((newPrice - oldPrice) / oldPrice) * 100 : 0;
}

class ReorderResult {
  final bool canReorder;
  final List<String> reasons;
  final double? updatedTotal;
  final List<PriceChange> priceChanges;

  ReorderResult({
    required this.canReorder,
    required this.reasons,
    this.updatedTotal,
    this.priceChanges = const [],
  });

  bool get hasPriceChanges => priceChanges.isNotEmpty;
  bool get hasPriceIncrease =>
      priceChanges.any((change) => change.increased);
  bool get hasPriceDecrease =>
      priceChanges.any((change) => change.decreased);
}

class ReorderItem {
  final String itemId;
  final String name;
  final String? imageUrl;
  final double price;
  final int quantity;
  final List<ReorderModifier> modifiers;
  final String? specialInstructions;

  ReorderItem({
    required this.itemId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.quantity,
    this.modifiers = const [],
    this.specialInstructions,
  });

  double get subtotal => (price + modifiers.fold(0.0, (sum, m) => sum + m.price)) * quantity;
}

class ReorderModifier {
  final String modifierId;
  final String name;
  final double price;
  final String? groupId;

  ReorderModifier({
    required this.modifierId,
    required this.name,
    required this.price,
    this.groupId,
  });
}

class ReorderData {
  final String orderId;
  final String restaurantId;
  final String restaurantName;
  final List<ReorderItem> items;
  final double originalTotal;
  final double? updatedTotal;
  final Timestamp orderDate;
  final String? deliveryAddress;
  final String? specialInstructions;
  final List<PriceChange> priceChanges;

  ReorderData({
    required this.orderId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.originalTotal,
    this.updatedTotal,
    required this.orderDate,
    this.deliveryAddress,
    this.specialInstructions,
    this.priceChanges = const [],
  });

  bool get hasPriceChanges => priceChanges.isNotEmpty;
}

class ReorderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ReorderResult> canReorder(String orderId) async {
    try {
      final reasons = <String>[];
      final priceChanges = <PriceChange>[];

      final orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        return ReorderResult(
          canReorder: false,
          reasons: ['Order not found'],
        );
      }

      final orderData = orderDoc.data()!;
      final restaurantId = orderData['restaurantId'] as String?;
      
      if (restaurantId == null) {
        return ReorderResult(
          canReorder: false,
          reasons: ['Restaurant information not found'],
        );
      }

      final restaurantOpen = await _isRestaurantOpen(restaurantId);
      if (!restaurantOpen) {
        reasons.add('Restaurant is currently closed');
      }

      final items = orderData['items'] as List<dynamic>? ?? [];
      double updatedTotal = 0;

      for (final item in items) {
        final itemData = item as Map<String, dynamic>;
        final itemId = itemData['itemId'] as String?;
        final itemName = itemData['name'] as String?;
        final oldPrice = (itemData['price'] as num?)?.toDouble() ?? 0;
        final quantity = itemData['quantity'] as int? ?? 1;

        if (itemId == null || itemName == null) continue;

        final menuItem = await _getMenuItem(restaurantId, itemId);
        
        if (menuItem == null) {
          reasons.add('$itemName is no longer available');
          continue;
        }

        if (menuItem['isAvailable'] == false) {
          reasons.add('$itemName is currently unavailable');
          continue;
        }

        final newPrice = (menuItem['price'] as num?)?.toDouble() ?? 0;
        
        final modifiers = itemData['modifiers'] as List<dynamic>? ?? [];
        double modifierTotal = 0;
        
        for (final modifier in modifiers) {
          final modifierData = modifier as Map<String, dynamic>;
          final modifierId = modifierData['modifierId'] as String?;
          
          if (modifierId != null) {
            final modifierInfo = await _getModifierInfo(restaurantId, itemId, modifierId);
            if (modifierInfo != null && modifierInfo['isAvailable'] == false) {
              reasons.add('${modifierData['name']} modifier is no longer available');
              continue;
            }
            modifierTotal += (modifierInfo?['price'] as num?)?.toDouble() ?? 0;
          }
        }

        final itemTotal = (newPrice + modifierTotal) * quantity;
        updatedTotal += itemTotal;

        if ((newPrice - oldPrice).abs() > 0.01) {
          priceChanges.add(PriceChange(
            itemName: itemName,
            oldPrice: oldPrice * quantity,
            newPrice: newPrice * quantity,
          ));
        }
      }

      final canReorder = reasons.isEmpty;

      return ReorderResult(
        canReorder: canReorder,
        reasons: reasons,
        updatedTotal: canReorder ? updatedTotal : null,
        priceChanges: priceChanges,
      );
    } catch (e) {
      return ReorderResult(
        canReorder: false,
        reasons: ['Error checking reorder availability: ${e.toString()}'],
      );
    }
  }

  Future<ReorderData?> getReorderData(String orderId) async {
    try {
      final orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        return null;
      }

      final orderData = orderDoc.data()!;
      final restaurantId = orderData['restaurantId'] as String? ?? '';
      final restaurantName = orderData['restaurantName'] as String? ?? '';
      final originalTotal = (orderData['total'] as num?)?.toDouble() ?? 0;
      final orderDate = orderData['orderDate'] as Timestamp? ?? Timestamp.now();
      final deliveryAddress = orderData['deliveryAddress'] as String?;
      final specialInstructions = orderData['specialInstructions'] as String?;

      final items = <ReorderItem>[];
      final priceChanges = <PriceChange>[];

      final itemsData = orderData['items'] as List<dynamic>? ?? [];
      
      for (final item in itemsData) {
        final itemMap = item as Map<String, dynamic>;
        final itemId = itemMap['itemId'] as String? ?? '';
        final name = itemMap['name'] as String? ?? '';
        final imageUrl = itemMap['imageUrl'] as String?;
        final oldPrice = (itemMap['price'] as num?)?.toDouble() ?? 0;
        final quantity = itemMap['quantity'] as int? ?? 1;
        final specialInst = itemMap['specialInstructions'] as String?;

        final menuItem = await _getMenuItem(restaurantId, itemId);
        final newPrice = (menuItem?['price'] as num?)?.toDouble() ?? oldPrice;

        if ((newPrice - oldPrice).abs() > 0.01) {
          priceChanges.add(PriceChange(
            itemName: name,
            oldPrice: oldPrice * quantity,
            newPrice: newPrice * quantity,
          ));
        }

        final modifiers = <ReorderModifier>[];
        final modifiersData = itemMap['modifiers'] as List<dynamic>? ?? [];
        
        for (final mod in modifiersData) {
          final modMap = mod as Map<String, dynamic>;
          modifiers.add(ReorderModifier(
            modifierId: modMap['modifierId'] as String? ?? '',
            name: modMap['name'] as String? ?? '',
            price: (modMap['price'] as num?)?.toDouble() ?? 0,
            groupId: modMap['groupId'] as String?,
          ));
        }

        items.add(ReorderItem(
          itemId: itemId,
          name: name,
          imageUrl: imageUrl,
          price: newPrice,
          quantity: quantity,
          modifiers: modifiers,
          specialInstructions: specialInst,
        ));
      }

      double updatedTotal = items.fold(0.0, (sum, item) => sum + item.subtotal);

      return ReorderData(
        orderId: orderId,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: items,
        originalTotal: originalTotal,
        updatedTotal: updatedTotal,
        orderDate: orderDate,
        deliveryAddress: deliveryAddress,
        specialInstructions: specialInstructions,
        priceChanges: priceChanges,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> _isRestaurantOpen(String restaurantId) async {
    try {
      final restaurantDoc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (!restaurantDoc.exists) {
        return false;
      }

      final data = restaurantDoc.data()!;
      final isOpen = data['isOpen'] as bool? ?? false;
      
      if (!isOpen) return false;

      final operatingHours = data['operatingHours'] as Map<String, dynamic>?;
      if (operatingHours == null) return isOpen;

      final now = DateTime.now();
      final dayOfWeek = _getDayName(now.weekday);
      final todayHours = operatingHours[dayOfWeek] as Map<String, dynamic>?;
      
      if (todayHours == null) return false;

      final openTime = todayHours['open'] as String?;
      final closeTime = todayHours['close'] as String?;
      
      if (openTime == null || closeTime == null) return false;

      final openDateTime = _parseTime(openTime, now);
      final closeDateTime = _parseTime(closeTime, now);

      return now.isAfter(openDateTime) && now.isBefore(closeDateTime);
    } catch (e) {
      return false;
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 
      'friday', 'saturday', 'sunday'
    ];
    return days[weekday - 1];
  }

  DateTime _parseTime(String time, DateTime referenceDate) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    
    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      hour,
      minute,
    );
  }

  Future<Map<String, dynamic>?> _getMenuItem(String restaurantId, String itemId) async {
    try {
      final menuDoc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .get();

      if (!menuDoc.exists) return null;
      return menuDoc.data();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getModifierInfo(
    String restaurantId, 
    String itemId, 
    String modifierId,
  ) async {
    try {
      final modifierDoc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .collection('modifiers')
          .doc(modifierId)
          .get();

      if (!modifierDoc.exists) return null;
      return modifierDoc.data();
    } catch (e) {
      return null;
    }
  }
}
