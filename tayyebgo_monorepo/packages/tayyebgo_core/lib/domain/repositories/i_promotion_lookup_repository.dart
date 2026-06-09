abstract class IPromotionLookupRepository {
  Future<Map<String, dynamic>?> validateCoupon(String code);
}
