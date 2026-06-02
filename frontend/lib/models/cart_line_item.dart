import 'modifier.dart';
import 'product.dart';

/// A single line in the cart: one product at one quantity with a specific
/// modifier configuration.  Two "Burger" entries with different modifiers are
/// distinct CartLineItems (different [lineId]).
class CartLineItem {
  /// UUID generated at add-to-cart time so the same product with different
  /// modifiers can coexist as separate lines.
  final String lineId;

  final Product product;
  int quantity;

  /// One entry per ModifierGroup that has at least one option selected.
  final List<SelectedModifierGroup> selectedModifiers;

  /// Free-text note from the customer ("no onions please").
  final String? customerNote;

  CartLineItem({
    required this.lineId,
    required this.product,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.customerNote,
  });

  // ─── Price resolution ───────────────────────────────────────────────────────

  /// Sum of all modifier price deltas for a single unit.
  double get modifierDeltaPerUnit =>
      selectedModifiers.fold(0.0, (sum, s) => sum + s.priceDelta);

  /// Unit price after modifiers.
  double get unitPrice => product.price + modifierDeltaPerUnit;

  /// Total line price.
  double get lineTotal => unitPrice * quantity;

  // ─── Display helpers ─────────────────────────────────────────────────────────

  /// e.g. "Spicy, Extra Cheese (+$1.50) • Remove Ketchup"
  String get modifierSummary {
    if (selectedModifiers.isEmpty) return '';
    return selectedModifiers
        .where((s) => s.selectedOptionIds.isNotEmpty)
        .map((s) {
          final delta = s.priceDelta;
          final deltaStr =
              delta == 0 ? '' : ' (${delta > 0 ? '+' : ''}\$${delta.abs().toStringAsFixed(2)})';
          return '${s.summary}$deltaStr';
        })
        .join(' • ');
  }

  /// Checks whether this line item matches exactly the same product + modifiers
  /// as another (used before creating a new line vs. incrementing existing).
  bool hasSameConfigAs(Product p, List<SelectedModifierGroup> mods) {
    if (p.id != product.id) return false;
    if (mods.length != selectedModifiers.length) return false;
    for (int i = 0; i < mods.length; i++) {
      final a = mods[i];
      final b = selectedModifiers[i];
      if (a.groupId != b.groupId) return false;
      final aIds = List<String>.from(a.selectedOptionIds)..sort();
      final bIds = List<String>.from(b.selectedOptionIds)..sort();
      if (aIds.join(',') != bIds.join(',')) return false;
    }
    return true;
  }

  // ─── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'product_id': product.id,
        'product_name': product.displayName,
        'product_price': product.price,
        'quantity': quantity,
        'selected_modifiers':
            selectedModifiers.map((m) => m.toJson()).toList(),
        'customer_note': customerNote,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      };

  CartLineItem copyWith({
    int? quantity,
    List<SelectedModifierGroup>? selectedModifiers,
    String? customerNote,
  }) =>
      CartLineItem(
        lineId: lineId,
        product: product,
        quantity: quantity ?? this.quantity,
        selectedModifiers: selectedModifiers ?? this.selectedModifiers,
        customerNote: customerNote ?? this.customerNote,
      );
}

// ─── Modifier validation ──────────────────────────────────────────────────────

class ModifierValidationResult {
  final bool isValid;
  final List<String> errors; // one error message per failing group

  const ModifierValidationResult._(this.isValid, this.errors);

  factory ModifierValidationResult.valid() =>
      const ModifierValidationResult._(true, []);

  factory ModifierValidationResult.invalid(List<String> errors) =>
      ModifierValidationResult._(false, errors);
}

/// Validates that all required modifier groups have been satisfied.
ModifierValidationResult validateModifiers(
  List<ModifierGroup> groups,
  List<SelectedModifierGroup> selections,
) {
  final errors = <String>[];

  for (final group in groups) {
    final sel =
        selections.firstWhere((s) => s.groupId == group.id, orElse: () {
      return SelectedModifierGroup(
        groupId: group.id,
        groupName: group.name,
        selectedOptionIds: [],
        group: group,
      );
    });

    final count = sel.selectedOptionIds.length;

    if (group.isRequired && count < group.minSelections) {
      errors.add(
        '"${group.name}" requires at least ${group.minSelections} selection(s).',
      );
    }

    if (count > group.maxSelections) {
      errors.add(
        '"${group.name}" allows at most ${group.maxSelections} selection(s).',
      );
    }
  }

  return errors.isEmpty
      ? ModifierValidationResult.valid()
      : ModifierValidationResult.invalid(errors);
}
