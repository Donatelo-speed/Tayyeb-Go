enum PendingOperationType {
  transitionOrder,
  rejectOrder,
  createOrder,
  updateOrder,
}

extension PendingOperationTypeX on PendingOperationType {
  String get value => name;
  static PendingOperationType fromValue(String v) =>
      PendingOperationType.values.firstWhere(
        (e) => e.name == v,
        orElse: () => PendingOperationType.transitionOrder,
      );
}