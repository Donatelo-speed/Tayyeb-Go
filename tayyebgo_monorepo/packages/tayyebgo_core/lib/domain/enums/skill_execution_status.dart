enum SkillExecutionStatus {
  pending,
  running,
  success,
  failed;

  String get value => name;

  bool get isTerminal => this == success || this == failed;
  bool get isActive => !isTerminal;
}

extension SkillExecutionStatusX on SkillExecutionStatus {
  static SkillExecutionStatus fromValue(String v) =>
      SkillExecutionStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => SkillExecutionStatus.pending,
      );
}
