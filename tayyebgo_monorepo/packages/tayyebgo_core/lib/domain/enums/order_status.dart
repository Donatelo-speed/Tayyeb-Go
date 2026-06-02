enum OrderStatus {
  placed('placed'),
  accepted('accepted'),
  preparing('preparing'),
  ready('ready'),
  readyForDriver('ready_for_driver'),
  dispatched('dispatched'),
  pickedUp('picked_up'),
  delivered('delivered'),
  cancelled('cancelled');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromValue(String v) =>
      OrderStatus.values.firstWhere((s) => s.value == v, orElse: () => placed);

  bool get isTerminal => this == delivered || this == cancelled;
  bool get isActive => !isTerminal;
}
