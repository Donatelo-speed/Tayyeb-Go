import '../value_objects/skill_input_schema.dart';

typedef SkillExecutor = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> input);

class Skill {
  final String name;
  final String description;
  final SkillInputSchema inputSchema;
  final bool destructive;
  final SkillExecutor execute;

  const Skill({
    required this.name,
    required this.description,
    required this.inputSchema,
    this.destructive = false,
    required this.execute,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema.toJson(),
        'destructive': destructive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Skill && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
