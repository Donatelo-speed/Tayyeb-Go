import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

enum BusinessCategory {
  foodBeverage('food_beverage', 'Food & Beverage', 'restaurant'),
  retail('retail', 'Retail', 'shopping_bag'),
  health('health', 'Health', 'local_pharmacy'),
  services('services', 'Services', 'miscellaneous_services'),
  logistics('logistics', 'Logistics', 'local_shipping');

  final String value;
  final String displayName;
  final String iconKey;
  const BusinessCategory(this.value, this.displayName, this.iconKey);

  static BusinessCategory fromValue(String? value) {
    return BusinessCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => BusinessCategory.foodBeverage,
    );
  }
}

class BusinessType {
  final String id;
  final String name;
  final BusinessCategory category;
  final String iconKey;
  final List<String> suggestedSections;
  final String defaultTemplate;

  const BusinessType({
    required this.id,
    required this.name,
    required this.category,
    required this.iconKey,
    this.suggestedSections = const [],
    this.defaultTemplate = 'modern',
  });
}

class BusinessTypes {
  static const all = <BusinessType>[
    BusinessType(id: 'restaurant', name: 'Restaurant', category: BusinessCategory.foodBeverage, iconKey: 'restaurant', suggestedSections: ['banner', 'categories', 'popular', 'meals', 'deals', 'reviews'], defaultTemplate: 'restaurant'),
    BusinessType(id: 'fast_food', name: 'Fast Food', category: BusinessCategory.foodBeverage, iconKey: 'fastfood', suggestedSections: ['banner', 'combos', 'popular', 'deals'], defaultTemplate: 'fast_food'),
    BusinessType(id: 'pizza', name: 'Pizza', category: BusinessCategory.foodBeverage, iconKey: 'local_pizza', suggestedSections: ['banner', 'pizzas', 'combos', 'deals'], defaultTemplate: 'restaurant'),
    BusinessType(id: 'shawarma', name: 'Shawarma', category: BusinessCategory.foodBeverage, iconKey: 'lunch_dining', suggestedSections: ['banner', 'meals', 'combos', 'popular'], defaultTemplate: 'fast_food'),
    BusinessType(id: 'cafe', name: 'Cafe', category: BusinessCategory.foodBeverage, iconKey: 'local_cafe', suggestedSections: ['banner', 'drinks', 'desserts', 'reviews'], defaultTemplate: 'cafe'),
    BusinessType(id: 'bakery', name: 'Bakery', category: BusinessCategory.foodBeverage, iconKey: 'bakery_dining', suggestedSections: ['banner', 'breads', 'pastries', 'popular'], defaultTemplate: 'cafe'),
    BusinessType(id: 'sweets', name: 'Sweets', category: BusinessCategory.foodBeverage, iconKey: 'cake', suggestedSections: ['banner', 'sweets', 'combos', 'reviews'], defaultTemplate: 'cafe'),
    BusinessType(id: 'supermarket', name: 'Supermarket', category: BusinessCategory.retail, iconKey: 'shopping_cart', suggestedSections: ['banner', 'categories', 'weekly_offers', 'fruits', 'vegetables', 'beverages', 'household'], defaultTemplate: 'market'),
    BusinessType(id: 'mini_market', name: 'Mini Market', category: BusinessCategory.retail, iconKey: 'storefront', suggestedSections: ['banner', 'categories', 'offers', 'popular'], defaultTemplate: 'market'),
    BusinessType(id: 'electronics', name: 'Electronics', category: BusinessCategory.retail, iconKey: 'devices', suggestedSections: ['banner', 'categories', 'featured', 'new_arrivals', 'best_sellers'], defaultTemplate: 'electronics'),
    BusinessType(id: 'clothing', name: 'Clothing', category: BusinessCategory.retail, iconKey: 'checkroom', suggestedSections: ['banner', 'categories', 'new_arrivals', 'featured'], defaultTemplate: 'modern'),
    BusinessType(id: 'cosmetics', name: 'Cosmetics', category: BusinessCategory.retail, iconKey: 'spa', suggestedSections: ['banner', 'categories', 'featured', 'bestsellers'], defaultTemplate: 'modern'),
    BusinessType(id: 'home_supplies', name: 'Home Supplies', category: BusinessCategory.retail, iconKey: 'home', suggestedSections: ['banner', 'categories', 'featured'], defaultTemplate: 'modern'),
    BusinessType(id: 'pharmacy', name: 'Pharmacy', category: BusinessCategory.health, iconKey: 'local_pharmacy', suggestedSections: ['search_medicine', 'health_categories', 'featured', 'daily_needs', 'quick_delivery'], defaultTemplate: 'pharmacy'),
    BusinessType(id: 'medical_supplies', name: 'Medical Supplies', category: BusinessCategory.health, iconKey: 'medical_services', suggestedSections: ['search', 'categories', 'featured'], defaultTemplate: 'pharmacy'),
    BusinessType(id: 'optical_store', name: 'Optical Store', category: BusinessCategory.health, iconKey: 'visibility', suggestedSections: ['banner', 'frames', 'lenses', 'featured'], defaultTemplate: 'modern'),
    BusinessType(id: 'flower_shop', name: 'Flower Shop', category: BusinessCategory.services, iconKey: 'local_florist', suggestedSections: ['banner', 'occasions', 'featured'], defaultTemplate: 'modern'),
    BusinessType(id: 'printing_shop', name: 'Printing Shop', category: BusinessCategory.services, iconKey: 'print', suggestedSections: ['banner', 'services', 'pricing'], defaultTemplate: 'minimal'),
    BusinessType(id: 'pet_store', name: 'Pet Store', category: BusinessCategory.services, iconKey: 'pets', suggestedSections: ['banner', 'categories', 'featured'], defaultTemplate: 'modern'),
    BusinessType(id: 'parcel_service', name: 'Parcel Service', category: BusinessCategory.logistics, iconKey: 'inventory_2', suggestedSections: ['banner', 'rates', 'tracking'], defaultTemplate: 'minimal'),
    BusinessType(id: 'courier_partner', name: 'Courier Partner', category: BusinessCategory.logistics, iconKey: 'delivery_dining', suggestedSections: ['banner', 'services', 'rates'], defaultTemplate: 'minimal'),
  ];

  static BusinessType byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.first,
    );
  }

  static List<BusinessType> byCategory(BusinessCategory category) {
    return all.where((t) => t.category == category).toList();
  }
}

IconData businessIcon(String key) {
  switch (key) {
    case 'restaurant': return Icons.restaurant;
    case 'fastfood': return Icons.fastfood;
    case 'local_pizza': return Icons.local_pizza;
    case 'lunch_dining': return Icons.lunch_dining;
    case 'local_cafe': return Icons.local_cafe;
    case 'bakery_dining': return Icons.bakery_dining;
    case 'cake': return Icons.cake;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'shopping_cart': return Icons.shopping_cart;
    case 'storefront': return Icons.storefront;
    case 'devices': return Icons.devices;
    case 'checkroom': return Icons.checkroom;
    case 'spa': return Icons.spa;
    case 'home': return Icons.home;
    case 'local_pharmacy': return Icons.local_pharmacy;
    case 'medical_services': return Icons.medical_services;
    case 'visibility': return Icons.visibility;
    case 'local_florist': return Icons.local_florist;
    case 'print': return Icons.print;
    case 'pets': return Icons.pets;
    case 'inventory_2': return Icons.inventory_2;
    case 'delivery_dining': return Icons.delivery_dining;
    case 'miscellaneous_services': return Icons.miscellaneous_services;
    case 'local_shipping': return Icons.local_shipping;
    default: return Icons.store;
  }
}

enum BusinessPackage {
  starter('starter', 'Starter', 'Basic listing', 0),
  professional('professional', 'Professional', 'Analytics + promotions', 49),
  enterprise('enterprise', 'Enterprise', 'Everything unlocked', 199);

  final String value;
  final String displayName;
  final String description;
  final double priceUSD;
  const BusinessPackage(this.value, this.displayName, this.description, this.priceUSD);

  static BusinessPackage fromValue(String? value) {
    return BusinessPackage.values.firstWhere(
      (p) => p.value == value,
      orElse: () => BusinessPackage.starter,
    );
  }
}

enum BusinessStatus {
  open('open', 'Open', 'circle', 'success'),
  busy('busy', 'Busy', 'access_time', 'warning'),
  offline('offline', 'Offline', 'do_not_disturb_on', 'error'),
  suspended('suspended', 'Suspended', 'block', 'error'),
  pendingApproval('pending_approval', 'Pending Approval', 'hourglass_empty', 'warning');

  final String value;
  final String displayName;
  final String iconKey;
  final String colorKey;
  const BusinessStatus(this.value, this.displayName, this.iconKey, this.colorKey);

  static BusinessStatus fromValue(String? value) {
    return BusinessStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => BusinessStatus.open,
    );
  }
}

IconData statusIcon(String key) {
  switch (key) {
    case 'circle': return Icons.circle;
    case 'access_time': return Icons.access_time;
    case 'do_not_disturb_on': return Icons.do_not_disturb_on;
    case 'block': return Icons.block;
    case 'hourglass_empty': return Icons.hourglass_empty;
    default: return Icons.circle;
  }
}

Color statusColor(String key, BuildContext context) {
  switch (key) {
    case 'success': return AppColors.success;
    case 'warning': return AppColors.warning;
    case 'error': return AppColors.error;
    default: return context.textMutedColor;
  }
}

class DesignTemplate {
  final String id;
  final String name;
  final String description;
  final String iconKey;

  const DesignTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
  });

  static const all = <DesignTemplate>[
    DesignTemplate(id: 'modern', name: 'Modern', description: 'Clean, balanced layout', iconKey: 'dashboard'),
    DesignTemplate(id: 'premium', name: 'Premium', description: 'Hero banner, full-width', iconKey: 'star'),
    DesignTemplate(id: 'minimal', name: 'Minimal', description: 'Whitespace-focused', iconKey: 'crop_square'),
    DesignTemplate(id: 'market', name: 'Market Style', description: 'Category grid first', iconKey: 'shopping_basket'),
    DesignTemplate(id: 'pharmacy', name: 'Pharmacy Style', description: 'Search-first, no images', iconKey: 'search'),
    DesignTemplate(id: 'cafe', name: 'Cafe Style', description: 'Warm, photo-driven', iconKey: 'local_cafe'),
    DesignTemplate(id: 'fast_food', name: 'Fast Food Style', description: 'Combos and deals first', iconKey: 'fastfood'),
    DesignTemplate(id: 'restaurant', name: 'Restaurant Style', description: 'Full menu browsing', iconKey: 'restaurant_menu'),
    DesignTemplate(id: 'electronics', name: 'Electronics Style', description: 'Categories + featured', iconKey: 'devices'),
  ];

  static DesignTemplate byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.first,
    );
  }
}
