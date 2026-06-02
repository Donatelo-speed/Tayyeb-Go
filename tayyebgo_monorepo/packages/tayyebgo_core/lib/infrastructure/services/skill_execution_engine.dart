import 'dart:async';
import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_execution.dart';
import '../../domain/enums/skill_execution_status.dart';
import '../../domain/services/i_skill_registry.dart';

class SkillExecutionEngine implements ISkillRegistry {
  static final SkillExecutionEngine instance = SkillExecutionEngine._();
  SkillExecutionEngine._();

  final _skills = <String, Skill>{};
  final _executionHistory = <SkillExecution>[];
  final _executionController = StreamController<SkillExecution>.broadcast();

  static const _defaultTimeout = Duration(seconds: 30);

  @override
  void register(Skill skill) {
    _skills[skill.name] = skill;
  }

  @override
  Skill? get(String name) => _skills[name];

  @override
  List<Skill> list() => _skills.values.toList();

  @override
  void unregister(String name) {
    _skills.remove(name);
  }

  @override
  List<Skill> listDestructive() =>
      _skills.values.where((s) => s.destructive).toList();

  @override
  bool contains(String name) => _skills.containsKey(name);

  @override
  int get count => _skills.length;

  @override
  Stream<SkillExecution> watchExecutions() => _executionController.stream;

  @override
  SkillExecution? lastExecutionFor(String skillName) {
    return _executionHistory.lastWhere(
      (e) => e.skillName == skillName,
      orElse: () => throw StateError('No execution found for $skillName'),
    );
  }

  bool get hasDestructiveSkills => _skills.values.any((s) => s.destructive);

  Future<SkillExecution> execute({
    required String skillName,
    required Map<String, dynamic> input,
    Duration timeout = _defaultTimeout,
  }) async {
    final skill = _skills[skillName];
    if (skill == null) {
      throw ArgumentError('Skill "$skillName" is not registered');
    }

    final validationErrors = skill.inputSchema.validate(input);
    if (validationErrors.isNotEmpty) {
      final execution = SkillExecution.create(
        skillName: skillName,
        payload: input,
      ).copyWith(
        status: SkillExecutionStatus.failed,
        error: 'Validation failed: ${validationErrors.join('; ')}',
        completedAt: DateTime.now(),
        duration: Duration.zero,
      );
      _executionHistory.add(execution);
      _executionController.add(execution);
      return execution;
    }

    var execution = SkillExecution.create(
      skillName: skillName,
      payload: input,
    );

    execution = execution.copyWith(
      status: SkillExecutionStatus.running,
      startedAt: DateTime.now(),
    );
    _executionHistory.add(execution);
    _executionController.add(execution);

    try {
      final result = await skill
          .execute(input)
          .timeout(timeout);

      final completed = execution.copyWith(
        status: SkillExecutionStatus.success,
        output: result,
        completedAt: DateTime.now(),
        duration: DateTime.now().difference(execution.startedAt ?? DateTime.now()),
      );

      _executionHistory[_executionHistory.length - 1] = completed;
      _executionController.add(completed);
      return completed;
    } on TimeoutException {
      final failed = execution.copyWith(
        status: SkillExecutionStatus.failed,
        error: 'Skill "$skillName" timed out after ${timeout.inSeconds}s',
        completedAt: DateTime.now(),
        duration: timeout,
      );
      _executionHistory[_executionHistory.length - 1] = failed;
      _executionController.add(failed);
      return failed;
    } catch (e) {
      final failed = execution.copyWith(
        status: SkillExecutionStatus.failed,
        error: _formatError(e),
        completedAt: DateTime.now(),
        duration: DateTime.now().difference(execution.startedAt ?? DateTime.now()),
      );
      _executionHistory[_executionHistory.length - 1] = failed;
      _executionController.add(failed);
      return failed;
    }
  }

  String _formatError(Object e) {
    if (e is ArgumentError) return e.message;
    return e.toString();
  }

  List<SkillExecution> history({String? skillName}) {
    if (skillName != null) {
      return _executionHistory
          .where((e) => e.skillName == skillName)
          .toList();
    }
    return List.unmodifiable(_executionHistory);
  }

  void clearHistory() {
    _executionHistory.clear();
  }

  void dispose() {
    _executionController.close();
  }
}
