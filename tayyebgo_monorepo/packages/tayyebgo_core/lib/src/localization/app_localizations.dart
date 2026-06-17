import 'package:flutter/widgets.dart';
import 'l10n_en.dart';
import 'l10n_ar.dart';

enum AppLocale {
  en,
  ar,
}

extension AppLocaleExtension on AppLocale {
  Locale get locale {
    switch (this) {
      case AppLocale.en:
        return const Locale('en', 'US');
      case AppLocale.ar:
        return const Locale('ar', 'SA');
    }
  }

  String get languageName {
    switch (this) {
      case AppLocale.en:
        return 'English';
      case AppLocale.ar:
        return 'العربية';
    }
  }

  bool get isRtl => this == AppLocale.ar;
}

class AppLocalizations {
  AppLocalizations._();

  static AppLocalizations? _current;
  static AppLocale _currentLocale = AppLocale.en;

  static AppLocalizations get current {
    _current ??= AppLocalizations._();
    return _current!;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? current;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static void setLocale(AppLocale locale) {
    _currentLocale = locale;
    _current = null;
  }

  static AppLocale get currentLocale => _currentLocale;

  Object get _strings {
    switch (_currentLocale) {
      case AppLocale.en:
        return L10nEn.instance;
      case AppLocale.ar:
        return L10nAr.instance;
    }
  }

  L10nEn get en => L10nEn.instance;
  L10nAr get ar => L10nAr.instance;

  String get appName => _strings.appName;
  String get ok => _strings.ok;
  String get cancel => _strings.cancel;
  String get save => _strings.save;
  String get delete => _strings.delete;
  String get edit => _strings.edit;
  String get close => _strings.close;
  String get done => _strings.done;
  String get yes => _strings.yes;
  String get no => _strings.no;
  String get back => _strings.back;
  String get next => _strings.next;
  String get continue_ => _strings.continue_;
  String get confirm => _strings.confirm;
  String get submit => _strings.submit;
  String get retry => _strings.retry;
  String get loading => _strings.loading;
  String get noResults => _strings.noResults;
  String get required_ => _strings.required_;
  String get optional => _strings.optional;
  String get search => _strings.search;
  String get filter => _strings.filter;
  String get sort => _strings.sort;
  String get apply => _strings.apply;
  String get reset => _strings.reset;
  String get selectAll => _strings.selectAll;
  String get deselectAll => _strings.deselectAll;
  String get share => _strings.share;
  String get copy => _strings.copy;
  String get copied => _strings.copied;
  String get viewAll => _strings.viewAll;
  String get seeMore => _strings.seeMore;
  String get seeLess => _strings.seeLess;
  String get showMap => _strings.showMap;
  String get hideMap => _strings.hideMap;

  // Auth
  String get login => _strings.login;
  String get loginTitle => _strings.loginTitle;
  String get loginSubtitle => _strings.loginSubtitle;
  String get signup => _strings.signup;
  String get signupTitle => _strings.signupTitle;
  String get signupSubtitle => _strings.signupSubtitle;
  String get logout => _strings.logout;
  String get logoutConfirm => _strings.logoutConfirm;
  String get email => _strings.email;
  String get emailHint => _strings.emailHint;
  String get password => _strings.password;
  String get passwordHint => _strings.passwordHint;
  String get confirmPassword => _strings.confirmPassword;
  String get confirmPasswordHint => _strings.confirmPasswordHint;
  String get forgotPassword => _strings.forgotPassword;
  String get resetPassword => _strings.resetPassword;
  String get resetPasswordSubtitle => _strings.resetPasswordSubtitle;
  String get resetPasswordSent => _strings.resetPasswordSent;
  String get orContinueWith => _strings.orContinueWith;
  String get continueWithGoogle => _strings.continueWithGoogle;
  String get continueWithApple => _strings.continueWithApple;
  String get continueWithFacebook => _strings.continueWithFacebook;
  String get dontHaveAccount => _strings.dontHaveAccount;
  String get alreadyHaveAccount => _strings.alreadyHaveAccount;
  String get createAccount => _strings.createAccount;
  String get signIn => _strings.signIn;
  String get phone => _strings.phone;
  String get phoneHint => _strings.phoneHint;
  String get phoneVerification => _strings.phoneVerification;
  String get enterOtp => _strings.enterOtp;
  String get resendCode => _strings.resendCode;
  String get verify => _strings.verify;
  String get invalidEmail => _strings.invalidEmail;
  String get invalidPassword => _strings.invalidPassword;
  String get passwordMismatch => _strings.passwordMismatch;
  String get fieldRequired => _strings.fieldRequired;
  String get invalidPhone => _strings.invalidPhone;
  String get invalidOtp => _strings.invalidOtp;
  String get accountCreated => _strings.accountCreated;
  String get welcomeBack => _strings.welcomeBack;

  // Navigation
  String get home => _strings.home;
  String get explore => _strings.explore;
  String get categories => _strings.categories;
  String get orders => _strings.orders;
  String get cart => _strings.cart;
  String get profile => _strings.profile;
  String get settings => _strings.settings;
  String get notifications => _strings.notifications;
  String get messages => _strings.messages;
  String get favorites => _strings.favorites;
  String get addresses => _strings.addresses;
  String get paymentMethods => _strings.paymentMethods;
  String get helpSupport => _strings.helpSupport;
  String get about => _strings.about;
  String get terms => _strings.terms;
  String get privacy => _strings.privacy;

  // Home
  String get homeTitle => _strings.homeTitle;
  String get homeSubtitle => _strings.homeSubtitle;
  String get nearbyRestaurants => _strings.nearbyRestaurants;
  String get popularNearYou => _strings.popularNearYou;
  String get trendingNow => _strings.trendingNow;
  String get recommendedForYou => _strings.recommendedForYou;
  String get recentlyOrdered => _strings.recentlyOrdered;
  String get newOnTayyebGo => _strings.newOnTayyebGo;
  String get featuredRestaurants => _strings.featuredRestaurants;
  String get topPicks => _strings.topPicks;
  String get deals => _strings.deals;
  String get offers => _strings.offers;
  String get coupons => _strings.coupons;
  String get viewDeals => _strings.viewDeals;
  String get promoCode => _strings.promoCode;
  String get promoHint => _strings.promoHint;
  String get applyPromo => _strings.applyPromo;
  String get promoApplied => _strings.promoApplied;
  String get promoInvalid => _strings.promoInvalid;
  String get promoExpired => _strings.promoExpired;
  String get whatsNew => _strings.whatsNew;
  String get goodMorning => _strings.goodMorning;
  String get goodAfternoon => _strings.goodAfternoon;
  String get goodEvening => _strings.goodEvening;

  // Categories
  String get allCategories => _strings.allCategories;
  String get food => _strings.food;
  String get groceries => _strings.groceries;
  String get drinks => _strings.drinks;
  String get desserts => _strings.desserts;
  String get snacks => _strings.snacks;
  String get pizza => _strings.pizza;
  String get burgers => _strings.burgers;
  String get sushi => _strings.sushi;
  String get chinese => _strings.chinese;
  String get japanese => _strings.japanese;
  String get korean => _strings.korean;
  String get thai => _strings.thai;
  String get indian => _strings.indian;
  String get mexican => _strings.mexican;
  String get italian => _strings.italian;
  String get arabic => _strings.arabic;
  String get american => _strings.american;
  String get seafood => _strings.seafood;
  String get chicken => _strings.chicken;
  String get vegan => _strings.vegan;
  String get vegetarian => _strings.vegetarian;
  String get healthy => _strings.healthy;
  String get fastfood => _strings.fastfood;
  String get coffee => _strings.coffee;
  String get breakfast => _strings.breakfast;
  String get lunch => _strings.lunch;
  String get dinner => _strings.dinner;
  String get lateNight => _strings.lateNight;

  // Restaurant
  String get restaurant => _strings.restaurant;
  String get restaurants => _strings.restaurants;
  String get viewMenu => _strings.viewMenu;
  String get rating => _strings.rating;
  String get ratings => _strings.ratings;
  String get reviews => _strings.reviews;
  String get deliveryFee => _strings.deliveryFee;
  String get freeDelivery => _strings.freeDelivery;
  String get deliveryTime => _strings.deliveryTime;
  String get minOrder => _strings.minOrder;
  String get openingHours => _strings.openingHours;
  String get closed => _strings.closed;
  String get openNow => _strings.openNow;
  String get opensAt => _strings.opensAt;
  String get closesAt => _strings.closesAt;
  String get isOpen => _strings.isOpen;
  String get isClosed => _strings.isClosed;
  String get currentlyClosed => _strings.currentlyClosed;
  String get openToday => _strings.openToday;
  String get openUntil => _strings.openUntil;
  String get viewAllReviews => _strings.viewAllReviews;
  String get writeReview => _strings.writeReview;
  String get noReviewsYet => _strings.noReviewsYet;
  String get restaurantInfo => _strings.restaurantInfo;
  String get description => _strings.description;
  String get featured => _strings.featured;
  String get popular => _strings.popular;
  String get nearby => _strings.nearby;
  String get topRated => _strings.topRated;
  String get sortByName => _strings.sortByName;
  String get sortByRating => _strings.sortByRating;
  String get sortByDistance => _strings.sortByDistance;
  String get sortByPrice => _strings.sortByPrice;

  // Menu
  String get menu => _strings.menu;
  String get allItems => _strings.allItems;
  String get popularItems => _strings.popularItems;
  String get specialOffers => _strings.specialOffers;
  String get bestSellers => _strings.bestSellers;
  String get newItems => _strings.newItems;
  String get seasonal => _strings.seasonal;
  String get comboMeals => _strings.comboMeals;
  String get addOns => _strings.addOns;
  String get sides => _strings.sides;
  String get beverages => _strings.beverages;
  String get viewDetails => _strings.viewDetails;
  String get price => _strings.price;
  String get perPerson => _strings.perPerson;
  String get calories => _strings.calories;
  String get prepTime => _strings.prepTime;
  String get spiceLevel => _strings.spiceLevel;
  String get mild => _strings.mild;
  String get medium => _strings.medium;
  String get spicy => _strings.spicy;
  String get verySpicy => _strings.verySpicy;
  String get ingredients => _strings.ingredients;
  String get nutritionInfo => _strings.nutritionInfo;
  String get allergens => _strings.allergens;
  String get suitableFor => _strings.suitableFor;
  String get glutenFree => _strings.glutenFree;
  String get dairyFree => _strings.dairyFree;
  String get halal => _strings.halal;
  String get kosher => _strings.kosher;
  String get noItemsAvailable => _strings.noItemsAvailable;

  // Cart
  String get myCart => _strings.myCart;
  String get emptyCart => _strings.emptyCart;
  String get emptyCartSubtitle => _strings.emptyCartSubtitle;
  String get browseMenu => _strings.browseMenu;
  String get addItem => _strings.addItem;
  String get removeItem => _strings.removeItem;
  String get updateQuantity => _strings.updateQuantity;
  String get quantity => _strings.quantity;
  String get increaseQuantity => _strings.increaseQuantity;
  String get decreaseQuantity => _strings.decreaseQuantity;
  String get itemAdded => _strings.itemAdded;
  String get itemRemoved => _strings.itemRemoved;
  String get cartCleared => _strings.cartCleared;
  String get clearCart => _strings.clearCart;
  String get clearCartConfirm => _strings.clearCartConfirm;
  String get specialInstructions => _strings.specialInstructions;
  String get specialInstructionsHint => _strings.specialInstructionsHint;
  String get addToCart => _strings.addToCart;
  String get goToCart => _strings.goToCart;
  String get continueBrowsing => _strings.continueBrowsing;

  // Checkout
  String get checkout => _strings.checkout;
  String get placeOrder => _strings.placeOrder;
  String get orderSummary => _strings.orderSummary;
  String get subtotal => _strings.subtotal;
  String get deliveryFeeLabel => _strings.deliveryFeeLabel;
  String get serviceFee => _strings.serviceFee;
  String get tax => _strings.tax;
  String get tip => _strings.tip;
  String get addTip => _strings.addTip;
  String get tipSuggested => _strings.tipSuggested;
  String get total => _strings.total;
  String get estimatedTotal => _strings.estimatedTotal;
  String get payNow => _strings.payNow;
  String get payOnDelivery => _strings.payOnDelivery;
  String get paymentMethod => _strings.paymentMethod;
  String get selectPaymentMethod => _strings.selectPaymentMethod;
  String get addPaymentMethod => _strings.addPaymentMethod;
  String get creditCard => _strings.creditCard;
  String get debitCard => _strings.debitCard;
  String get applePay => _strings.applePay;
  String get googlePay => _strings.googlePay;
  String get cashOnDelivery => _strings.cashOnDelivery;
  String get cardNumber => _strings.cardNumber;
  String get expiryDate => _strings.expiryDate;
  String get cvv => _strings.cvv;
  String get cardholderName => _strings.cardholderName;
  String get billingAddress => _strings.billingAddress;
  String get saveCard => _strings.saveCard;
  String get deliveryAddress => _strings.deliveryAddress;
  String get selectAddress => _strings.selectAddress;
  String get addAddress => _strings.addAddress;
  String get editAddress => _strings.editAddress;
  String get deleteAddress => _strings.deleteAddress;
  String get noAddresses => _strings.noAddresses;
  String get setAsDefault => _strings.setAsDefault;
  String get useCurrentLocation => _strings.useCurrentLocation;
  String get addressLine1 => _strings.addressLine1;
  String get addressLine2 => _strings.addressLine2;
  String get city => _strings.city;
  String get state => _strings.state;
  String get zipCode => _strings.zipCode;
  String get country => _strings.country;
  String get deliveryInstructions => _strings.deliveryInstructions;
  String get deliveryInstructionsHint => _strings.deliveryInstructionsHint;
  String get deliveryAsap => _strings.deliveryAsap;
  String get scheduleDelivery => _strings.scheduleDelivery;
  String get selectDate => _strings.selectDate;
  String get selectTime => _strings.selectTime;
  String get asap => _strings.asap;
  String get schedule => _strings.schedule;
  String get orderPlaced => _strings.orderPlaced;
  String get orderPlacedSubtitle => _strings.orderPlacedSubtitle;
  String get orderConfirmation => _strings.orderConfirmation;
  String get orderNumber => _strings.orderNumber;
  String get estimatedDelivery => _strings.estimatedDelivery;
  String get orderPreparing => _strings.orderPreparing;
  String get orderAccepted => _strings.orderAccepted;
  String get orderReady => _strings.orderReady;

  // Orders
  String get currentOrders => _strings.currentOrders;
  String get pastOrders => _strings.pastOrders;
  String get noOrders => _strings.noOrders;
  String get noOrdersSubtitle => _strings.noOrdersSubtitle;
  String get orderDetails => _strings.orderDetails;
  String get orderStatus => _strings.orderStatus;
  String get trackOrder => _strings.trackOrder;
  String get orderReceived => _strings.orderReceived;
  String get orderConfirmed => _strings.orderConfirmed;
  String get preparing => _strings.preparing;
  String get outForDelivery => _strings.outForDelivery;
  String get delivered => _strings.delivered;
  String get cancelled => _strings.cancelled;
  String get refunded => _strings.refunded;
  String get partiallyRefunded => _strings.partiallyRefunded;
  String get orderCancelled => _strings.orderCancelled;
  String get cancelOrder => _strings.cancelOrder;
  String get cancelOrderConfirm => _strings.cancelOrderConfirm;
  String get cancelReason => _strings.cancelReason;
  String get reorder => _strings.reorder;
  String get reorderConfirm => _strings.reorderConfirm;
  String get rateOrder => _strings.rateOrder;
  String get writeReviewHint => _strings.writeReviewHint;
  String get deliveryRating => _strings.deliveryRating;
  String get foodRating => _strings.foodRating;
  String get serviceRating => _strings.serviceRating;
  String get submitRating => _strings.submitRating;
  String get thankYouForRating => _strings.thankYouForRating;
  String get orderAgain => _strings.orderAgain;
  String get downloadInvoice => _strings.downloadInvoice;
  String get receipt => _strings.receipt;
  String get itemizedReceipt => _strings.itemizedReceipt;
  String get totalSaved => _strings.totalSaved;
  String get youSaved => _strings.youSaved;
  String get deliveryPartner => _strings.deliveryPartner;
  String get callDeliveryPartner => _strings.callDeliveryPartner;
  String get messageDeliveryPartner => _strings.messageDeliveryPartner;
  String get tipDeliveryPartner => _strings.tipDeliveryPartner;

  // Profile
  String get editProfile => _strings.editProfile;
  String get updateProfile => _strings.updateProfile;
  String get profileUpdated => _strings.profileUpdated;
  String get fullName => _strings.fullName;
  String get nameHint => _strings.nameHint;
  String get dateOfBirth => _strings.dateOfBirth;
  String get gender => _strings.gender;
  String get male => _strings.male;
  String get female => _strings.female;
  String get other => _strings.other;
  String get preferNotToSay => _strings.preferNotToSay;
  String get changePhoto => _strings.changePhoto;
  String get removePhoto => _strings.removePhoto;
  String get takePhoto => _strings.takePhoto;
  String get chooseFromGallery => _strings.chooseFromGallery;
  String get accountSettings => _strings.accountSettings;
  String get changePassword => _strings.changePassword;
  String get currentPassword => _strings.currentPassword;
  String get newPassword => _strings.newPassword;
  String get confirmNewPassword => _strings.confirmNewPassword;
  String get passwordChanged => _strings.passwordChanged;
  String get deleteAccount => _strings.deleteAccount;
  String get deleteAccountConfirm => _strings.deleteAccountConfirm;
  String get deactivateAccount => _strings.deactivateAccount;
  String get linkedAccounts => _strings.linkedAccounts;
  String get google => _strings.google;
  String get facebook => _strings.facebook;
  String get apple => _strings.apple;

  // Notifications
  String get notificationPreferences => _strings.notificationPreferences;
  String get pushNotifications => _strings.pushNotifications;
  String get emailNotifications => _strings.emailNotifications;
  String get smsNotifications => _strings.smsNotifications;
  String get orderUpdates => _strings.orderUpdates;
  String get promotions => _strings.promotions;
  String get newRestaurants => _strings.newRestaurants;
  String get dealsAndOffers => _strings.dealsAndOffers;
  String get noNotifications => _strings.noNotifications;
  String get markAllRead => _strings.markAllRead;
  String get clearAll => _strings.clearAll;
  String get deleteNotification => _strings.deleteNotification;
  String get notificationsCleared => _strings.notificationsCleared;

  // Addresses
  String get homeAddress => _strings.homeAddress;
  String get workAddress => _strings.workAddress;
  String get otherAddress => _strings.otherAddress;
  String get savedAddresses => _strings.savedAddresses;
  String get addressSaved => _strings.addressSaved;
  String get addressDeleted => _strings.addressDeleted;
  String get setDefaultAddress => _strings.setDefaultAddress;
  String get defaultAddress => _strings.defaultAddress;
  String get selectOnMap => _strings.selectOnMap;
  String get confirmLocation => _strings.confirmLocation;
  String get locationServicesDisabled => _strings.locationServicesDisabled;
  String get locationPermissionDenied => _strings.locationPermissionDenied;

  // Settings
  String get appSettings => _strings.appSettings;
  String get language => _strings.language;
  String get selectLanguage => _strings.selectLanguage;
  String get english => _strings.english;
  String get arabic => _strings.arabic;
  String get currency => _strings.currency;
  String get selectCurrency => _strings.selectCurrency;
  String get usd => _strings.usd;
  String get sar => _strings.sar;
  String get aed => _strings.aed;
  String get egp => _strings.egp;
  String get theme => _strings.theme;
  String get lightMode => _strings.lightMode;
  String get darkMode => _strings.darkMode;
  String get systemDefault => _strings.systemDefault;
  String get units => _strings.units;
  String get metric => _strings.metric;
  String get imperial => _strings.imperial;
  String get fontSize => _strings.fontSize;
  String get small => _strings.small;
  String get normal => _strings.normal;
  String get large => _strings.large;

  // Errors
  String get errorGeneric => _strings.errorGeneric;
  String get errorNetwork => _strings.errorNetwork;
  String get errorServer => _strings.errorServer;
  String get errorTimeout => _strings.errorTimeout;
  String get errorNotFound => _strings.errorNotFound;
  String get errorUnauthorized => _strings.errorUnauthorized;
  String get errorForbidden => _strings.errorForbidden;
  String get errorBadRequest => _strings.errorBadRequest;
  String get errorTooManyRequests => _strings.errorTooManyRequests;
  String get errorPaymentFailed => _strings.errorPaymentFailed;
  String get errorLocationFailed => _strings.errorLocationFailed;
  String get errorCamera => _strings.errorCamera;
  String get errorStorage => _strings.errorStorage;
  String get errorPhotoLibrary => _strings.errorPhotoLibrary;
  String get errorUploadFailed => _strings.errorUploadFailed;
  String get errorOrderFailed => _strings.errorOrderFailed;
  String get errorReorderFailed => _strings.errorReorderFailed;
  String get errorRatingFailed => _strings.errorRatingFailed;
  String get errorProfileUpdateFailed => _strings.errorProfileUpdateFailed;
  String get errorPasswordChangeFailed => _strings.errorPasswordChangeFailed;
  String get errorAddressFailed => _strings.errorAddressFailed;
  String get errorCouponInvalid => _strings.errorCouponInvalid;
  String get errorCouponExpired => _strings.errorCouponExpired;
  String get errorMinimumOrder => _strings.errorMinimumOrder;
  String get errorRestaurantClosed => _strings.errorRestaurantClosed;
  String get errorItemUnavailable => _strings.errorItemUnavailable;
  String get errorCartEmpty => _strings.errorCartEmpty;
  String get errorDeliveryArea => _strings.errorDeliveryArea;

  // Food specific
  String get popularDishes => _strings.popularDishes;
  String get dailySpecials => _strings.dailySpecials;
  String get weekendSpecials => _strings.weekendSpecials;
  String get kidsMenu => _strings.kidsMenu;
  String get familyDeals => _strings.familyDeals;
  String get groupOrders => _strings.groupOrders;
  String get catering => _strings.catering;
  String get mealPlans => _strings.mealPlans;
  String get subscription => _strings.subscription;
  String get subscribeNow => _strings.subscribeNow;
  String get manageSubscription => _strings.manageSubscription;
  String get cancelSubscription => _strings.cancelSubscription;
  String get subscriptionActive => _strings.subscriptionActive;
  String get subscriptionCancelled => _strings.subscriptionCancelled;
  String get pricePerWeek => _strings.pricePerWeek;
  String get pricePerMonth => _strings.pricePerMonth;

  // Delivery
  String get deliveryOptions => _strings.deliveryOptions;
  String get pickup => _strings.pickup;
  String get pickupTime => _strings.pickupTime;
  String get pickupReadyAt => _strings.pickupReadyAt;
  String get selectPickupTime => _strings.selectPickupTime;
  String get deliveryUnavailable => _strings.deliveryUnavailable;
  String get pickupAvailable => _strings.pickupAvailable;
  String get estimatedPickupTime => _strings.estimatedPickupTime;
  String get deliveryAvailable => _strings.deliveryAvailable;
  String get expressDelivery => _strings.expressDelivery;
  String get scheduledDelivery => _strings.scheduledDelivery;

  // Promotions
  String get referralProgram => _strings.referralProgram;
  String get referralCode => _strings.referralCode;
  String get shareReferralCode => _strings.shareReferralCode;
  String get referralBonus => _strings.referralBonus;
  String get earnBonus => _strings.earnBonus;
  String get loyaltyProgram => _strings.loyaltyProgram;
  String get loyaltyPoints => _strings.loyaltyPoints;
  String get earnPoints => _strings.earnPoints;
  String get redeemPoints => _strings.redeemPoints;
  String get pointsBalance => _strings.pointsBalance;
  String get pointsExpiring => _strings.pointsExpiring;
  String get memberSince => _strings.memberSince;

  // General UI
  String get comingSoon => _strings.comingSoon;
  String get underMaintenance => _strings.underMaintenance;
  String get maintenanceSubtitle => _strings.maintenanceSubtitle;
  String get updateAvailable => _strings.updateAvailable;
  String get updateNow => _strings.updateNow;
  String get skipForNow => _strings.skipForNow;
  String get givePermission => _strings.givePermission;
  String get enableLocation => _strings.enableLocation;
  String get selectLanguageTitle => _strings.selectLanguageTitle;
  String get onboardingTitle1 => _strings.onboardingTitle1;
  String get onboardingSubtitle1 => _strings.onboardingSubtitle1;
  String get onboardingTitle2 => _strings.onboardingTitle2;
  String get onboardingSubtitle2 => _strings.onboardingSubtitle2;
  String get onboardingTitle3 => _strings.onboardingTitle3;
  String get onboardingSubtitle3 => _strings.onboardingSubtitle3;
  String get getStarted => _strings.getStarted;
  String get swipeToSeeMore => _strings.swipeToSeeMore;
  String get pullToRefresh => _strings.pullToRefresh;
  String get tapToRetry => _strings.tapToRetry;
  String get noInternetConnection => _strings.noInternetConnection;
  String get tryAgain => _strings.tryAgain;
  String get connectionRestored => _strings.connectionRestored;
  String get offlineMode => _strings.offlineMode;
  String get online => _strings.online;
  String get offline => _strings.offline;
  String get version => _strings.version;
  String get developedBy => _strings.developedBy;
  String get allRightsReserved => _strings.allRightsReserved;

  // Date and Time
  String get today => _strings.today;
  String get yesterday => _strings.yesterday;
  String get tomorrow => _strings.tomorrow;
  String get thisWeek => _strings.thisWeek;
  String get lastWeek => _strings.lastWeek;
  String get thisMonth => _strings.thisMonth;
  String get lastMonth => _strings.lastMonth;
  String get justNow => _strings.justNow;
  String get minutesAgo => _strings.minutesAgo;
  String get hoursAgo => _strings.hoursAgo;
  String get daysAgo => _strings.daysAgo;
  String get weeksAgo => _strings.weeksAgo;
  String get monthsAgo => _strings.monthsAgo;

  // Misc
  String get noFavorites => _strings.noFavorites;
  String get noFavoritesSubtitle => _strings.noFavoritesSubtitle;
  String get addToFavorites => _strings.addToFavorites;
  String get removeFromFavorites => _strings.removeFromFavorites;
  String get itemSaved => _strings.itemSaved;
  String get itemRemovedFromFavorites => _strings.itemRemovedFromFavorites;
  String get contactUs => _strings.contactUs;
  String get faq => _strings.faq;
  String get reportIssue => _strings.reportIssue;
  String get feedback => _strings.feedback;
  String get rateApp => _strings.rateApp;
  String get shareApp => _strings.shareApp;
  String get inviteFriends => _strings.inviteFriends;
  String get legal => _strings.legal;
  String get licenses => _strings.licenses;
  String get openSourceLibraries => _strings.openSourceLibraries;
  String get accessibility => _strings.accessibility;
  String get darkModeToggle => _strings.darkModeToggle;
  String get logoutSuccess => _strings.logoutSuccess;
  String get accountDeleted => _strings.accountDeleted;
  String get sessionExpired => _strings.sessionExpired;
  String get welcomeBackMessage => _strings.welcomeBackMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations.setLocale(
      locale.languageCode == 'ar' ? AppLocale.ar : AppLocale.en,
    );
    return AppLocalizations.current;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
