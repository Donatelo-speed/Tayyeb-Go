enum OrderStatus {
  placed('placed'),
  pending('pending'),
  accepted('accepted'),
  preparing('preparing'),
  ready('ready'),
  readyForDriver('ready_for_driver'),
  dispatched('dispatched'),
  pickedUp('picked_up'),
  delivered('delivered'),
  cancelled('cancelled'),
  refunded('refunded');

  final String value;
  const OrderStatus(this.value);

  String get canonicalValue => this == OrderStatus.pending ? 'placed' : value;

  static OrderStatus fromValue(String v) {
    if (v == 'pending') return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (s) => s.value == v,
      orElse: () => OrderStatus.placed,
    );
  }

  bool get isTerminal => this == delivered || this == cancelled || this == refunded;
  bool get isActive => !isTerminal;
  bool get isCancellable =>
      this == placed || this == pending || this == accepted;
}
