import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_execution.dart';
import '../../domain/enums/skill_execution_status.dart';
import '../../infrastructure/services/skill_execution_engine.dart';

class SkillRegistryProvider extends ChangeNotifier {
  static SkillRegistryProvider? _instance;
  static SkillRegistryProvider? get instance => _instance;

  final SkillExecutionEngine _engine = SkillExecutionEngine.instance;
  StreamSubscription<SkillExecution>? _executionSub;

  List<SkillExecution> _executions = [];
  SkillExecution? _activeExecution;
  String? _error;

  List<SkillExecution> get executions => _executions;
  SkillExecution? get activeExecution => _activeExecution;
  String? get error => _error;
  List<Skill> get skills => _engine.list();
  List<Skill> get destructiveSkills => _engine.listDestructive();
  bool get hasActiveExecution => _activeExecution != null;
  int get successCount =>
      _executions.where((e) => e.status == SkillExecutionStatus.success).length;
  int get failedCount =>
      _executions.where((e) => e.status == SkillExecutionStatus.failed).length;

  SkillRegistryProvider() {
    _instance = this;
    _executionSub = _engine.watchExecutions().listen(_onExecutionUpdate);
  }

  void registerSkill(Skill skill) {
    _engine.register(skill);
    notifyListeners();
  }

  void registerSkills(List<Skill> skills) {
    for (final s in skills) {
      _engine.register(s);
    }
    notifyListeners();
  }

  void unregisterSkill(String name) {
    _engine.unregister(name);
    notifyListeners();
  }

  bool contains(String name) => _engine.contains(name);

  Future<SkillExecution> executeSkill(
    String skillName,
    Map<String, dynamic> input, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _error = null;
    notifyListeners();

    final result = await _engine.execute(
      skillName: skillName,
      input: input,
      timeout: timeout,
    );

    if (result.status == SkillExecutionStatus.failed) {
      _error = result.error;
    }
    notifyListeners();
    return result;
  }

  void _onExecutionUpdate(SkillExecution execution) {
    _executions = _engine.history();
    if (execution.status.isActive) {
      _activeExecution = execution;
    } else {
      _activeExecution = null;
    }
    notifyListeners();
  }

  void clearHistory() {
    _engine.clearHistory();
    _executions = [];
    _activeExecution = null;
    _error = null;
    notifyListeners();
  }

  Skill? getSkill(String name) => _engine.get(name);
  List<SkillExecution> history({String? skillName}) =>
      _engine.history(skillName: skillName);

  @override
  void dispose() {
    _executionSub?.cancel();
    super.dispose();
  }
}
