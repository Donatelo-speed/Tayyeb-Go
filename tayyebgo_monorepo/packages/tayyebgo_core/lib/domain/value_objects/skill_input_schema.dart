import 'dart:convert';

class SkillInputSchema {
  final Map<String, dynamic> schema;

  const SkillInputSchema(this.schema);

  List<String> get required =>
      List<String>.from((schema['required'] as List<dynamic>?) ?? []);

  Map<String, dynamic>? get properties =>
      schema['properties'] as Map<String, dynamic>?;

  String? get description => schema['description'] as String?;

  String? get type => schema['type'] as String?;

  List<String> validate(Map<String, dynamic> input) {
    final errors = <String>[];

    for (final field in required) {
      if (!input.containsKey(field) || input[field] == null) {
        errors.add('Missing required field: $field');
        continue;
      }
      final propSchema = properties?[field] as Map<String, dynamic>?;
      if (propSchema == null) continue;

      final expectedType = propSchema['type'] as String?;
      if (expectedType != null) {
        final value = input[field];
        final typeError = _checkType(field, value, expectedType);
        if (typeError != null) errors.add(typeError);
      }
    }

    return errors;
  }

  String? _checkType(String field, dynamic value, String expectedType) {
    switch (expectedType) {
      case 'string':
        if (value is! String) return '$field must be a string';
        final pattern = properties?[field]?['pattern'] as String?;
        if (pattern != null &&
            RegExp(pattern).matchAsPrefix(value) == null) {
          return '$field does not match pattern $pattern';
        }
      case 'number':
        if (value is! num) return '$field must be a number';
      case 'integer':
        if (value is! int) return '$field must be an integer';
      case 'boolean':
        if (value is! bool) return '$field must be a boolean';
      case 'array':
        if (value is! List) return '$field must be an array';
      case 'object':
        if (value is! Map) return '$field must be an object';
    }
    return null;
  }

  Map<String, dynamic> toJson() => schema;

  factory SkillInputSchema.fromJson(Map<String, dynamic> json) =>
      SkillInputSchema(json);

  factory SkillInputSchema.fromRawJson(String raw) =>
      SkillInputSchema(jsonDecode(raw) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SkillInputSchema && schema.toString() == other.schema.toString();

  @override
  int get hashCode => schema.toString().hashCode;
}
