class CommissionRate {
  final String id;
  final String name;
  final double percent;
  final double? minOrderAmount;
  final double? maxOrderAmount;
  final String? verticalType;

  const CommissionRate({
    required this.id,
    required this.name,
    required this.percent,
    this.minOrderAmount,
    this.maxOrderAmount,
    this.verticalType,
  });

  bool appliesTo(double orderAmount, String vertical) {
    if (verticalType != null && verticalType != vertical) return false;
    if (minOrderAmount != null && orderAmount < minOrderAmount!) return false;
    if (maxOrderAmount != null && orderAmount > maxOrderAmount!) return false;
    return true;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'percent': percent,
        if (minOrderAmount != null) 'minOrderAmount': minOrderAmount,
        if (maxOrderAmount != null) 'maxOrderAmount': maxOrderAmount,
        'verticalType': verticalType,
      };

  factory CommissionRate.fromMap(String id, Map<String, dynamic> map) => CommissionRate(
        id: id,
        name: map['name'] as String? ?? '',
        percent: (map['percent'] as num?)?.toDouble() ?? 15.0,
        minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble(),
        maxOrderAmount: (map['maxOrderAmount'] as num?)?.toDouble(),
        verticalType: map['verticalType'] as String?,
      );
}
