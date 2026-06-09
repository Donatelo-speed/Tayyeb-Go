abstract class IDispatchRepository {
  Stream<List<Map<String, dynamic>>> watchDispatchesForDriver(String driverId);
  Future<bool> acceptDispatch(String dispatchId, String driverId);
  Future<bool> rejectDispatch(String dispatchId, String driverId);
  Future<bool> markPickedUp(String dispatchId, String orderId, String driverId);
  Future<bool> completeDelivery(String dispatchId, String orderId, String driverId);
}
