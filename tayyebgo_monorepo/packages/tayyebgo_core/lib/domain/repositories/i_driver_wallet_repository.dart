abstract class IDriverWalletRepository {
  Future<Map<String, dynamic>?> getWallet(String driverId);
  Stream<List<Map<String, dynamic>>> watchTransactions(String driverId);
  Future<bool> creditEarnings({
    required String driverId,
    required String orderId,
    required double amount,
    required String description,
  });
  Future<bool> requestPayout({
    required String driverId,
    required double amount,
  });
  Future<void> updateLevel(String driverId, String level);
}
