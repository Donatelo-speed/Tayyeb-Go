abstract class IAddressRepository {
  Future<List<Map<String, dynamic>>> getAddresses(String userId);
  Future<String?> addAddress(String userId, Map<String, dynamic> addressData);
  Future<bool> updateAddress(String userId, String addressId, Map<String, dynamic> data);
  Future<bool> deleteAddress(String userId, String addressId);
  Future<void> clearDefaultAddress(String userId);
}
