abstract class IAnythingRepository {
  Future<String?> createRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String storeName,
    required List<Map<String, dynamic>> items,
    required double budget,
    String? photoUrl,
    required String instructions,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String dropoffAddress,
    required String paymentMethod,
  });
  Future<List<Map<String, dynamic>>> getRequestsForCustomer(String userId);
  Future<List<Map<String, dynamic>>> getAvailableRequests();
  Future<bool> acceptRequest(String requestId, String driverId, String driverName);
  Future<bool> updateStatus(String requestId, String status);
  Future<bool> updateDriverLocation(String requestId, double lat, double lng);
  Future<bool> cancelRequest(String requestId);
  Stream<Map<String, dynamic>> watchRequest(String requestId);
}
