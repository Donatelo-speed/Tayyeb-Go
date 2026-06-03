import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums/user_role.dart';
import '../models/loyalty_transaction.dart';
import '../models/saved_address.dart';
import '../models/user_model.dart';
import '../utils/result.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('Users');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _users.doc(uid);

  CollectionReference<Map<String, dynamic>> _addressesRef(String uid) =>
      _userRef(uid).collection('saved_addresses');

  CollectionReference<Map<String, dynamic>> _loyaltyRef(String uid) =>
      _userRef(uid).collection('loyalty_transactions');

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _userRef(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Stream<UserModel?> watchUser(String uid) =>
      _userRef(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });

  Future<Result<UserModel>> updateProfile(String uid, {
    String? displayName,
    String? phone,
    String? photoUrl,
    String? address,
    String? preferredLocale,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (address != null) updates['address'] = address;
      if (preferredLocale != null) updates['preferredLocale'] = preferredLocale;

      if (updates.length == 1) {
        return Failure('No fields provided to update.');
      }

      await _userRef(uid).update(updates);
      final doc = await _userRef(uid).get();
      return Success(UserModel.fromFirestore(doc));
    } catch (e) {
      return Failure('Could not update profile. Please try again.', error: e);
    }
  }

  Future<Result<void>> updateRole(String uid, UserRole role, {String? vendorId}) async {
    try {
      final fn = FirebaseFunctions.instance.httpsCallable('setUserRole');
      await fn({
        'uid': uid,
        'role': role.value,
        if (vendorId != null) 'restaurantId': vendorId,
      });
      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      return Failure(e.message ?? 'Could not update role.', error: e);
    } catch (e) {
      return Failure('Could not update role.', error: e);
    }
  }

  Future<Result<void>> setActiveStatus(String uid, {required bool isActive}) async {
    try {
      await _userRef(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(isActive ? 'Could not activate user.' : 'Could not deactivate user.', error: e);
    }
  }

  Stream<List<UserModel>> watchAllUsers({UserRole? role}) {
    Query<Map<String, dynamic>> query = _users.orderBy('createdAt', descending: true);
    if (role != null) {
      query = query.where('role', isEqualTo: role.value);
    }
    return query.snapshots().map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final q = query.trim();
      final snap = await _users
          .orderBy('displayName')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(20)
          .get();
      return snap.docs.map(UserModel.fromFirestore).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<SavedAddress>> watchSavedAddresses(String uid) =>
      _addressesRef(uid)
          .orderBy('isDefault', descending: true)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs.map(SavedAddress.fromFirestore).toList());

  Future<Result<SavedAddress>> addSavedAddress(String uid, SavedAddress address) async {
    try {
      final id = _uuid.v4();
      final ref = _addressesRef(uid).doc(id);
      if (address.isDefault) {
        await _clearDefaultFlag(uid);
      }
      await ref.set(address.copyWith(id: id).toFirestore());
      return Success(address.copyWith(id: id));
    } catch (e) {
      return Failure('Could not save address.', error: e);
    }
  }

  Future<Result<void>> updateSavedAddress(String uid, SavedAddress address) async {
    try {
      if (address.isDefault) {
        await _clearDefaultFlag(uid, excludeId: address.id);
      }
      await _addressesRef(uid).doc(address.id).update(address.toFirestore()..remove('createdAt'));
      return const Success(null);
    } catch (e) {
      return Failure('Could not update address.', error: e);
    }
  }

  Future<Result<void>> removeSavedAddress(String uid, String addressId) async {
    try {
      final wasDefault = await _addressesRef(uid)
          .doc(addressId)
          .get()
          .then((d) => (d.data()?['isDefault'] as bool?) ?? false);
      await _addressesRef(uid).doc(addressId).delete();
      if (wasDefault) {
        final remaining = await _addressesRef(uid)
            .orderBy('createdAt')
            .limit(1)
            .get();
        if (remaining.docs.isNotEmpty) {
          await remaining.docs.first.reference.update({'isDefault': true});
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure('Could not remove address.', error: e);
    }
  }

  Future<Result<void>> setDefaultAddress(String uid, String addressId) async {
    try {
      await _clearDefaultFlag(uid);
      await _addressesRef(uid).doc(addressId).update({'isDefault': true});
      return const Success(null);
    } catch (e) {
      return Failure('Could not set default address.', error: e);
    }
  }

  Future<void> _clearDefaultFlag(String uid, {String? excludeId}) async {
    final snap = await _addressesRef(uid)
        .where('isDefault', isEqualTo: true)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      if (doc.id == excludeId) continue;
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }

  Stream<int> watchLoyaltyBalance(String uid) =>
      _userRef(uid).snapshots()
          .map((doc) => (doc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0);

  Future<List<LoyaltyTransaction>> getLoyaltyTransactions(String uid, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _loyaltyRef(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snap = await query.get();
      return snap.docs.map(LoyaltyTransaction.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Stream<List<LoyaltyTransaction>> watchLoyaltyTransactions(String uid, {int limit = 20}) =>
      _loyaltyRef(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map(LoyaltyTransaction.fromFirestore).toList());

  Future<Result<void>> awardLoyaltyCoins(String uid, {
    required int coins,
    required String reason,
    String? orderId,
  }) async {
    if (coins <= 0) return const Failure('Coin amount must be positive.');
    try {
      final userSnap = await _userRef(uid).get();
      final currentBalance = (userSnap.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
      final newBalance = currentBalance + coins;
      final txnRef = _loyaltyRef(uid).doc(_uuid.v4());
      final batch = _firestore.batch();
      batch.update(_userRef(uid), {
        'loyaltyPoints': FieldValue.increment(coins),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(txnRef, {
        'type': LoyaltyTransactionType.earned.firestoreValue,
        'coins': coins,
        'reason': reason,
        if (orderId != null) 'orderId': orderId,
        'balanceAfter': newBalance,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure('Could not award loyalty coins.', error: e);
    }
  }

  Future<Result<void>> redeemLoyaltyCoins(String uid, {
    required int coins,
    required String orderId,
  }) async {
    if (coins <= 0) return const Failure('Coin amount must be positive.');
    try {
      await _firestore.runTransaction((txn) async {
        final userDoc = await txn.get(_userRef(uid));
        final currentBalance = (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
        if (currentBalance < coins) {
          throw _InsufficientCoinsException('Insufficient coins. Balance: $currentBalance, requested: $coins.');
        }
        final newBalance = currentBalance - coins;
        final txnRef = _loyaltyRef(uid).doc(_uuid.v4());
        txn.update(_userRef(uid), {
          'loyaltyPoints': FieldValue.increment(-coins),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        txn.set(txnRef, {
          'type': LoyaltyTransactionType.redeemed.firestoreValue,
          'coins': coins,
          'reason': 'Redeemed on order #$orderId',
          'orderId': orderId,
          'balanceAfter': newBalance,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return const Success(null);
    } on _InsufficientCoinsException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Could not redeem loyalty coins.', error: e);
    }
  }
}

class _InsufficientCoinsException implements Exception {
  final String message;
  const _InsufficientCoinsException(this.message);
}
