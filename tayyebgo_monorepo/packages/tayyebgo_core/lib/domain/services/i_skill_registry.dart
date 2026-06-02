import '../entities/skill.dart';
import '../entities/skill_execution.dart';

abstract class ISkillRegistry {
  void register(Skill skill);

  Skill? get(String name);

  List<Skill> list();

  void unregister(String name);

  List<Skill> listDestructive();

  bool contains(String name);

  int get count;

  Stream<SkillExecution> watchExecutions();

  SkillExecution? lastExecutionFor(String skillName);
}
