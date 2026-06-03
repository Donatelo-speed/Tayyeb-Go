/// TayyebGo — Modifier System
/// Supports nested modifier groups with conditional pricing:
///   - Adding Mayo      => +$0.50
///   - Removing Ketchup => $0.00
///   - Extra Cheese     => +$1.00 (capped at maxSelections)
library;

enum ModifierSelectionType { single, multi }

/// A single option within a modifier group.
class ModifierOption {
  final String id;
  final String name;

  /// Price delta. Positive = surcharge, negative = reduction (e.g. removing ingredient).
  final double priceDelta;

  /// Whether this option is included in the base product by default.
  final bool isDefault;

  /// False means sold out for this option today.
  final bool isAvailable;

  /// Optional calorie contribution for dietary tracking.
  final int? caloriesDelta;

  const ModifierOption({
    required this.id,
    required this.name,
    this.priceDelta = 0.0,
    this.isDefault = false,
    this.isAvailable = true,
    this.caloriesDelta,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> j) => ModifierOption(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        priceDelta: double.tryParse(j['price_delta']?.toString() ?? '0') ?? 0.0,
        isDefault: j['is_default'] ?? false,
        isAvailable: j['is_available'] ?? true,
        caloriesDelta: j['calories_delta'] != null ? (j['calories_delta'] as num).toInt() : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price_delta': priceDelta,
        'is_default': isDefault,
        'is_available': isAvailable,
        'calories_delta': caloriesDelta,
      };

  /// Human-readable price label for UI ("+$0.50", "Free", "-$0.25").
  String get priceLabel {
    if (priceDelta == 0) return 'Free';
    final sign = priceDelta > 0 ? '+' : '';
    return '$sign\$${priceDelta.abs().toStringAsFixed(2)}';
  }

  ModifierOption copyWith({
    String? id,
    String? name,
    double? priceDelta,
    bool? isDefault,
    bool? isAvailable,
    int? caloriesDelta,
  }) =>
      ModifierOption(
        id: id ?? this.id,
        name: name ?? this.name,
        priceDelta: priceDelta ?? this.priceDelta,
        isDefault: isDefault ?? this.isDefault,
        isAvailable: isAvailable ?? this.isAvailable,
        caloriesDelta: caloriesDelta ?? this.caloriesDelta,
      );
}

/// A group of modifier options attached to a product.
/// e.g. "Protein" (single, required), "Extras" (multi, max 3), "Remove Ingredients" (multi, optional)
class ModifierGroup {
  final String id;
  final String name;
  final ModifierSelectionType selectionType;
  final bool isRequired;

  /// Minimum options customer must pick (0 = truly optional).
  final int minSelections;

  /// Maximum options customer can pick (1 for radio, >1 for checkbox).
  final int maxSelections;

  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.selectionType = ModifierSelectionType.single,
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections = 1,
    required this.options,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> j) => ModifierGroup(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        selectionType: j['selection_type'] == 'multi'
            ? ModifierSelectionType.multi
            : ModifierSelectionType.single,
        isRequired: j['is_required'] ?? false,
        minSelections: (j['min_selections'] as num?)?.toInt() ?? 0,
        maxSelections: (j['max_selections'] as num?)?.toInt() ?? 1,
        options: (j['options'] as List? ?? [])
            .map((o) => ModifierOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'selection_type': selectionType == ModifierSelectionType.multi ? 'multi' : 'single',
        'is_required': isRequired,
        'min_selections': minSelections,
        'max_selections': maxSelections,
        'options': options.map((o) => o.toJson()).toList(),
      };

  /// Returns default-selected option IDs for this group (pre-populate UI state).
  List<String> get defaultSelections => options
      .where((o) => o.isDefault && o.isAvailable)
      .map((o) => o.id)
      .toList();

  /// Returns available options only.
  List<ModifierOption> get availableOptions =>
      options.where((o) => o.isAvailable).toList();
}

/// Resolved selection state for one modifier group on a specific cart line item.
/// This is what lives in the cart — not the template above.
class SelectedModifierGroup {
  final String groupId;
  final String groupName;

  /// IDs of the options the customer selected.
  final List<String> selectedOptionIds;

  /// Reference to the group template for price calculations.
  final ModifierGroup group;

  const SelectedModifierGroup({
    required this.groupId,
    required this.groupName,
    required this.selectedOptionIds,
    required this.group,
  });

  /// Total price contribution of selected options in this group.
  double get priceDelta {
    double total = 0;
    for (final opt in group.options) {
      if (selectedOptionIds.contains(opt.id)) {
        total += opt.priceDelta;
      }
    }
    return total;
  }

  /// Human-readable summary: "Spicy, Extra Sauce (+$1.00)"
  String get summary {
    final selected =
        group.options.where((o) => selectedOptionIds.contains(o.id)).toList();
    if (selected.isEmpty) return 'None';
    return selected.map((o) => o.name).join(', ');
  }

  SelectedModifierGroup copyWith({List<String>? selectedOptionIds}) =>
      SelectedModifierGroup(
        groupId: groupId,
        groupName: groupName,
        selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
        group: group,
      );

  factory SelectedModifierGroup.fromDefaults(ModifierGroup group) =>
      SelectedModifierGroup(
        groupId: group.id,
        groupName: group.name,
        selectedOptionIds: group.defaultSelections,
        group: group,
      );

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'group_name': groupName,
        'selected_option_ids': selectedOptionIds,
      };
}

/// Upsell link: product A suggests product B (e.g. "Customers also ordered").
class UpsellLink {
  final String sourceProductId;
  final String targetProductId;
  final String targetProductName;
  final String? targetProductImageUrl;
  final double targetProductPrice;
  final String? prompt; // e.g. "Add a drink?"

  const UpsellLink({
    required this.sourceProductId,
    required this.targetProductId,
    required this.targetProductName,
    this.targetProductImageUrl,
    required this.targetProductPrice,
    this.prompt,
  });

  factory UpsellLink.fromJson(Map<String, dynamic> j) => UpsellLink(
        sourceProductId: j['source_product_id']?.toString() ?? '',
        targetProductId: j['target_product_id']?.toString() ?? '',
        targetProductName: j['target_product_name'] ?? '',
        targetProductImageUrl: j['target_product_image_url'],
        targetProductPrice:
            double.tryParse(j['target_product_price']?.toString() ?? '0') ?? 0,
        prompt: j['prompt'],
      );

  Map<String, dynamic> toJson() => {
        'source_product_id': sourceProductId,
        'target_product_id': targetProductId,
        'target_product_name': targetProductName,
        'target_product_image_url': targetProductImageUrl,
        'target_product_price': targetProductPrice,
        'prompt': prompt,
      };
}
