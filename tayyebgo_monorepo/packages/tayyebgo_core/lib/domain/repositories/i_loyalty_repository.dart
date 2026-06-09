abstract class ILoyaltyRepository {
  Future<List<Map<String, dynamic>>> getTransactions(String userId);
  Future<int> getCurrentPoints(String userId);
  Future<bool> awardPoints({
    required String userId,
    required int points,
    required String type,
    required String description,
    String? orderId,
  });
  Future<bool> redeemPoints({
    required String userId,
    required int points,
    required String description,
  });
  Future<Map<String, dynamic>> getStreakData(String userId);
}
