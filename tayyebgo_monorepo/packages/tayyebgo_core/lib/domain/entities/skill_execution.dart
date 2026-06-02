import 'package:uuid/uuid.dart';
import '../enums/skill_execution_status.dart';

class SkillExecution {
  final String id;
  final String skillName;
  final Map<String, dynamic> payload;
  final SkillExecutionStatus status;
  final Map<String, dynamic>? output;
  final String? error;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? duration;

  const SkillExecution({
    required this.id,
    required this.skillName,
    required this.payload,
    required this.status,
    this.output,
    this.error,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.duration,
  });

  factory SkillExecution.create({
    required String skillName,
    required Map<String, dynamic> payload,
  }) {
    return SkillExecution(
      id: const Uuid().v4(),
      skillName: skillName,
      payload: payload,
      status: SkillExecutionStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  SkillExecution copyWith({
    SkillExecutionStatus? status,
    Map<String, dynamic>? output,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? duration,
  }) =>
      SkillExecution(
        id: id,
        skillName: skillName,
        payload: payload,
        status: status ?? this.status,
        output: output ?? this.output,
        error: error ?? this.error,
        createdAt: createdAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        duration: duration ?? this.duration,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'skillName': skillName,
        'payload': payload,
        'status': status.value,
        if (output != null) 'output': output,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        if (duration != null) 'durationMs': duration!.inMilliseconds,
      };

  factory SkillExecution.fromJson(Map<String, dynamic> m) => SkillExecution(
        id: m['id'] as String? ?? '',
        skillName: m['skillName'] as String? ?? '',
        payload: Map<String, dynamic>.from(m['payload'] as Map? ?? {}),
        status: SkillExecutionStatusX.fromValue(m['status'] as String? ?? ''),
        output: m['output'] as Map<String, dynamic>?,
        error: m['error'] as String?,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
        startedAt: DateTime.tryParse(m['startedAt'] as String? ?? ''),
        completedAt: DateTime.tryParse(m['completedAt'] as String? ?? ''),
        duration: m['durationMs'] != null
            ? Duration(milliseconds: (m['durationMs'] as num).toInt())
            : null,
      );
}
