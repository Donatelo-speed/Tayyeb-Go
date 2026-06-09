import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../../domain/repositories/i_driver_repository.dart';
import '../../domain/repositories/i_restaurant_repository.dart';
import '../../domain/repositories/i_menu_repository.dart';
import '../../domain/repositories/i_promotion_repository.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../../domain/repositories/i_brand_repository.dart';
import '../../domain/repositories/i_branch_repository.dart';
import '../../domain/repositories/i_driver_wallet_repository.dart';
import '../../domain/repositories/i_address_repository.dart';
import '../../domain/repositories/i_loyalty_repository.dart';
import '../../domain/repositories/i_anything_repository.dart';
import '../../domain/repositories/i_dispatch_repository.dart';
import '../../domain/repositories/i_promotion_lookup_repository.dart';
import '../../infrastructure/repositories/firebase_auth_repository.dart';
import '../../infrastructure/repositories/firebase_order_repository.dart';
import '../../infrastructure/repositories/firebase_driver_repository.dart';
import '../../infrastructure/repositories/firebase_restaurant_repository.dart';
import '../../infrastructure/repositories/firebase_menu_repository.dart';
import '../../infrastructure/repositories/firebase_promotion_repository.dart';
import '../../infrastructure/repositories/firebase_payment_repository.dart';
import '../../infrastructure/repositories/firebase_brand_repository.dart';
import '../../infrastructure/repositories/firebase_branch_repository.dart';
import '../../infrastructure/repositories/firebase_driver_wallet_repository.dart';
import '../../infrastructure/repositories/firebase_address_repository.dart';
import '../../infrastructure/repositories/firebase_loyalty_repository.dart';
import '../../infrastructure/repositories/firebase_anything_repository.dart';
import '../../infrastructure/repositories/firebase_dispatch_repository.dart';
import '../../infrastructure/repositories/firebase_promotion_lookup_repository.dart';

class AppLocator {
  AppLocator._();

  static final AppLocator instance = AppLocator._();

  // Essential repository - initialized immediately
  late final IAuthRepository auth;

  // Lazy-loaded repositories - initialized on first access
  IOrderRepository? _orders;
  IOrderRepository get orders => _orders ??= FirebaseOrderRepository.instance;

  IDriverRepository? _drivers;
  IDriverRepository get drivers => _drivers ??= FirebaseDriverRepository.instance;

  IRestaurantRepository? _restaurants;
  IRestaurantRepository get restaurants => _restaurants ??= FirebaseRestaurantRepository.instance;

  IMenuRepository? _menus;
  IMenuRepository get menus => _menus ??= FirebaseMenuRepository.instance;

  IPromotionRepository? _promotions;
  IPromotionRepository get promotions => _promotions ??= FirebasePromotionRepository.instance;

  IPaymentRepository? _payments;
  IPaymentRepository get payments => _payments ??= FirebasePaymentRepository.instance;

  IBrandRepository? _brands;
  IBrandRepository get brands => _brands ??= FirebaseBrandRepository.instance;

  IBranchRepository? _branches;
  IBranchRepository get branches => _branches ??= FirebaseBranchRepository.instance;

  IDriverWalletRepository? _driverWallet;
  IDriverWalletRepository get driverWallet => _driverWallet ??= FirebaseDriverWalletRepository.instance;

  IAddressRepository? _addresses;
  IAddressRepository get addresses => _addresses ??= FirebaseAddressRepository.instance;

  ILoyaltyRepository? _loyalty;
  ILoyaltyRepository get loyalty => _loyalty ??= FirebaseLoyaltyRepository.instance;

  IAnythingRepository? _anything;
  IAnythingRepository get anything => _anything ??= FirebaseAnythingRepository.instance;

  IDispatchRepository? _dispatch;
  IDispatchRepository get dispatch => _dispatch ??= FirebaseDispatchRepository.instance;

  IPromotionLookupRepository? _promotionLookup;
  IPromotionLookupRepository get promotionLookup => _promotionLookup ??= FirebasePromotionLookupRepository.instance;

  void init() {
    // Only initialize essential repository immediately
    auth = FirebaseAuthRepository.instance;
    // All other repositories are lazy-loaded on first access
  }
}
