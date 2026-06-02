class Money {
  final int amountInCents;

  const Money(this.amountInCents);

  factory Money.fromDollars(double dollars) => Money((dollars * 100).round());

  double get inDollars => amountInCents / 100;

  String format({String symbol = '\$'}) =>
      '${symbol}${(amountInCents / 100).toStringAsFixed(2)}';

  Money operator +(Money other) => Money(amountInCents + other.amountInCents);
  Money operator -(Money other) => Money(amountInCents - other.amountInCents);
  Money operator *(num factor) => Money((amountInCents * factor).round());

  Map<String, dynamic> toMap() => {'amountInCents': amountInCents};

  factory Money.fromMap(Map<String, dynamic> m) =>
      Money((m['amountInCents'] as num?)?.toInt() ?? 0);

  @override
  bool operator ==(Object other) =>
      other is Money && amountInCents == other.amountInCents;

  @override
  int get hashCode => amountInCents.hashCode;
}
