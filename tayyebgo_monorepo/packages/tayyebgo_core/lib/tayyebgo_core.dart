export 'domain/enums/driver_type.dart';
export 'domain/enums/fulfillment_type.dart';
export 'domain/enums/order_status.dart';
export 'domain/enums/pending_operation_type.dart';
export 'domain/enums/payment_method_type.dart';
export 'domain/enums/user_role.dart';
export 'domain/enums/skill_execution_status.dart';

export 'domain/value_objects/address.dart';
export 'domain/value_objects/geo_location.dart';
export 'domain/value_objects/geohash.dart';
export 'domain/value_objects/money.dart';
export 'domain/value_objects/operating_hours.dart';
export 'domain/value_objects/pending_operation.dart';
export 'domain/value_objects/skill_input_schema.dart';

export 'domain/entities/brand.dart';
export 'domain/entities/branch.dart';
export 'domain/entities/dispatch_request.dart';
export 'domain/entities/payout.dart';
export 'domain/entities/dispatch_zone.dart';
export 'domain/entities/driver.dart';
export 'domain/entities/menu_item.dart';
export 'domain/entities/menu_modifier.dart';
export 'domain/entities/order.dart';
export 'domain/entities/payment_method.dart';
export 'domain/entities/promotion.dart';
export 'domain/entities/restaurant.dart';
export 'domain/entities/user.dart';
export 'domain/entities/skill.dart';
export 'domain/entities/skill_execution.dart';

export 'src/providers/auth_provider.dart';
export 'src/providers/cart_provider.dart';
export 'src/providers/locale_provider.dart';
export 'src/providers/skill_registry_provider.dart';
export 'src/providers/anything_provider.dart';
export 'src/providers/address_provider.dart';
export 'src/providers/loyalty_provider.dart';
export 'src/providers/driver_wallet_provider.dart';
export 'src/models/product.dart';
export 'src/models/cart_line_item.dart';
export 'src/models/modifier.dart';
export 'src/models/user_model.dart';
export 'src/models/order_model.dart'
    show
        OrderModelEx,
        OrderStatusEx,
        OrderItemEx,
        SelectedModifierEx,
        DeliveryAddressEx,
        OrderStatusEventEx,
        OrderPaymentMethodEx;
export 'src/models/vendor.dart' show Vendor, DayHours, DeliveryMode;
export 'src/models/driver_model.dart' show DriverModel, VehicleType;
export 'src/models/promo_model.dart' show PromoModel, PromoType;
export 'src/models/saved_address.dart' show SavedAddress;
export 'src/models/loyalty_transaction.dart'
    show LoyaltyTransaction, LoyaltyTransactionType;
export 'src/models/anything_request_model.dart'
    show AnythingRequestModel, AnythingRequestStatus, AnythingRequestItem;
export 'src/models/smart_address.dart' show SmartAddress;
export 'src/models/driver_wallet_model.dart' show DriverWalletModel, DriverLevel;
export 'infrastructure/services/order_state_machine.dart';
export 'infrastructure/services/skill_execution_engine.dart';
export 'src/services/auth_gate.dart';
export 'src/services/auth_listenable.dart';
export 'src/widgets/order_status_badge.dart';
export 'src/widgets/shimmer_loading.dart';
export 'src/widgets/empty_state.dart';
export 'src/widgets/driver_live_map.dart';
export 'src/widgets/auto_dispatch_listener.dart';
export 'src/widgets/async_screen_builder.dart';
export 'src/widgets/error_boundary.dart';
export 'src/widgets/error_retry_widget.dart';
export 'src/widgets/order_rating.dart';
export 'src/widgets/triple_state_widget.dart';
export 'src/screens/access_denied_screen.dart';
export 'src/screens/login_screen.dart';
export 'src/screens/onboarding_screen.dart';
export 'src/screens/app_scaffold.dart';
export 'src/screens/profile_screen.dart';
export 'src/screens/settings_screen.dart';
export 'src/screens/auth_state_redirector.dart';
export 'src/screens/payment_selection_sheet.dart';
export 'src/screens/notifications_screen.dart';
export 'src/screens/register_screen.dart' show RegisterScreen;
export 'src/screens/cashier_terminal_screen.dart' show CashierTerminalView;
export 'presentation/theme/app_colors.dart';
export 'presentation/theme/app_gradients.dart';
export 'presentation/theme/app_typography.dart';
export 'presentation/theme/app_spacing.dart';
export 'presentation/theme/theme_provider.dart';
export 'presentation/shared_widgets/animated_button.dart';
export 'presentation/shared_widgets/glass_card.dart';
export 'presentation/shared_widgets/otp_field.dart';
export 'presentation/shared_widgets/press_scale.dart';
export 'presentation/shared_widgets/ui_feedback.dart';
export 'presentation/shared_widgets/slide_transition.dart';
export 'presentation/shared_widgets/skill_card.dart';
export 'presentation/shared_widgets/skill_execution_view.dart';
export 'presentation/shared_widgets/destructive_action_overlay.dart';
export 'src/theme/tayyebgo_theme.dart';
export 'src/firebase/firebase_options.dart';

export 'src/constants/route_names.dart' show Routes;
export 'src/utils/result.dart' show Result, Success, Failure, VoidResult;

export 'src/repositories/auth_repository.dart' show AuthRepository;
export 'src/repositories/user_repository.dart' show UserRepository;
export 'src/repositories/order_repository.dart' show OrderRepository;

export 'domain/repositories/i_auth_repository.dart';
export 'domain/repositories/i_brand_repository.dart';
export 'domain/repositories/i_branch_repository.dart';
export 'domain/repositories/i_order_repository.dart';
export 'domain/repositories/i_restaurant_repository.dart';
export 'domain/repositories/i_menu_repository.dart';
export 'domain/repositories/i_driver_repository.dart';
export 'domain/repositories/i_promotion_repository.dart';
export 'domain/repositories/i_payment_repository.dart';

export 'domain/services/i_auto_dispatcher.dart';
export 'domain/services/i_menu_sync_service.dart';
export 'domain/services/i_payment_service.dart';
export 'domain/services/i_skill_registry.dart';

export 'infrastructure/repositories/firebase_auth_repository.dart';
export 'infrastructure/repositories/firebase_brand_repository.dart';
export 'infrastructure/repositories/firebase_branch_repository.dart';
export 'infrastructure/repositories/firebase_order_repository.dart';
export 'infrastructure/repositories/firebase_restaurant_repository.dart';
export 'infrastructure/repositories/firebase_menu_repository.dart';
export 'infrastructure/repositories/firebase_driver_repository.dart';
export 'infrastructure/repositories/firebase_promotion_repository.dart';
export 'infrastructure/repositories/firebase_payment_repository.dart';
export 'infrastructure/repositories/offline_order_repository.dart';

export 'infrastructure/services/auto_dispatcher.dart';
export 'infrastructure/services/connectivity_service.dart';
export 'infrastructure/services/driver_scorer.dart';
export 'infrastructure/services/driver_location_service.dart';
export 'infrastructure/services/geolocation_service.dart';
export 'infrastructure/services/menu_sync_service.dart';
export 'infrastructure/services/offline_queue.dart';
export 'infrastructure/services/payment_gateway.dart';
export 'infrastructure/services/commission_calculator.dart';
export 'infrastructure/services/stripe_checkout_service.dart';
export 'infrastructure/services/sham_cash_service.dart';
export 'infrastructure/services/eta_service.dart';
export 'infrastructure/services/notification_templates.dart';
export 'infrastructure/services/revenue_service.dart';
export 'infrastructure/services/order_placement_service.dart';
export 'infrastructure/services/push_notification_service.dart';
export 'infrastructure/services/sync_engine.dart';

export 'presentation/router/app_router.dart';
export 'presentation/router/route_guards.dart';
