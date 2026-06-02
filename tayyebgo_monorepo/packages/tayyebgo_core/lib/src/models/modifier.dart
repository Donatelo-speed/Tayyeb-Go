class ModifierOption {
  final String id;
  final String name;
  final String? nameAr;
  final double priceAdjustment;
  final bool isDefault;
  final int maxQuantity;

  ModifierOption({
    required this.id,
    required this.name,
    this.nameAr,
    this.priceAdjustment = 0.0,
    this.isDefault = false,
    this.maxQuantity = 1,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) => ModifierOption(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        nameAr: json['nameAr'] as String?,
        priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ??
            json['priceAdjustment'] as double? ??
            0.0,
        isDefault: json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
        maxQuantity: (json['max_quantity'] as num?)?.toInt() ??
            json['maxQuantity'] as int? ??
            1,
      );
}

class ModifierGroup {
  final String id;
  final String name;
  final String? nameAr;
  final int minSelections;
  final int maxSelections;
  final List<ModifierOption> options;
  final bool required;

  ModifierGroup({
    required this.id,
    required this.name,
    this.nameAr,
    this.minSelections = 0,
    this.maxSelections = 1,
    this.options = const [],
    this.required = false,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        nameAr: json['nameAr'] as String?,
        minSelections: (json['min_selections'] as num?)?.toInt() ??
            json['minSelections'] as int? ??
            0,
        maxSelections: (json['max_selections'] as num?)?.toInt() ??
            json['maxSelections'] as int? ??
            1,
        options: (json['options'] as List<dynamic>?)
                ?.map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        required: json['required'] as bool? ?? false,
      );
}

class SelectedModifierGroup {
  final String groupId;
  final String groupName;
  final List<String> selectedOptionIds;
  final ModifierGroup group;

  SelectedModifierGroup({
    required this.groupId,
    required this.groupName,
    required this.selectedOptionIds,
    required this.group,
  });

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'group_name': groupName,
        'selected_option_ids': selectedOptionIds,
      };

  factory SelectedModifierGroup.fromJson(Map<String, dynamic> json, ModifierGroup group) {
    return SelectedModifierGroup(
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name'] as String? ?? '',
      selectedOptionIds: (json['selected_option_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      group: group,
    );
  }
}
