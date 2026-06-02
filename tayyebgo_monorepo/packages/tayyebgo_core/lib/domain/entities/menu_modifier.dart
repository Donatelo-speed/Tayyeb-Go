import '../value_objects/money.dart';

class MenuModifier {
  final String id;
  final String name;
  final Money extraPrice;
  final bool isDefault;

  const MenuModifier({
    required this.id,
    required this.name,
    this.extraPrice = const Money(0),
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'extraPrice': extraPrice.amountInCents,
        'isDefault': isDefault,
      };

  factory MenuModifier.fromMap(Map<String, dynamic> m) => MenuModifier(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        extraPrice: Money((m['extraPrice'] as num?)?.toInt() ?? 0),
        isDefault: m['isDefault'] as bool? ?? false,
      );
}

class MenuModifierGroup {
  final String id;
  final String name;
  final bool isRequired;
  final int minSelections;
  final int maxSelections;
  final List<MenuModifier> modifiers;

  const MenuModifierGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections = 1,
    this.modifiers = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isRequired': isRequired,
        'minSelections': minSelections,
        'maxSelections': maxSelections,
        'modifiers': modifiers.map((m) => m.toMap()).toList(),
      };

  factory MenuModifierGroup.fromMap(Map<String, dynamic> m) =>
      MenuModifierGroup(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        isRequired: m['isRequired'] as bool? ?? false,
        minSelections: (m['minSelections'] as num?)?.toInt() ?? 0,
        maxSelections: (m['maxSelections'] as num?)?.toInt() ?? 1,
        modifiers: (m['modifiers'] as List<dynamic>?)
                ?.map(
                    (e) => MenuModifier.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}