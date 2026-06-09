import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_address_repository.dart';

class FirebaseAddressRepository implements IAddressRepository {
  static final FirebaseAddressRepository instance = FirebaseAddressRepository._();
  FirebaseAddressRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _addrRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('addresses');

  @override
  Future<List<Map<String, dynamic>>> getAddresses(String userId) async {
    final snap = await _addrRef(userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;
      return data;
    }).toList();
  }

  @override
  Future<String?> addAddress(String userId, Map<String, dynamic> addressData) async {
    final docRef = await _addrRef(userId).add({
      ...addressData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<bool> updateAddress(String userId, String addressId, Map<String, dynamic> data) async {
    await _addrRef(userId).doc(addressId).update(data);
    return true;
  }

  @override
  Future<bool> deleteAddress(String userId, String addressId) async {
    await _addrRef(userId).doc(addressId).delete();
    return true;
  }

  @override
  Future<void> clearDefaultAddress(String userId) async {
    final snap = await _addrRef(userId)
        .where('isDefault', isEqualTo: true)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }
}
