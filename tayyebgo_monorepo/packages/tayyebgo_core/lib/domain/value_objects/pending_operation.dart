import '../enums/pending_operation_type.dart';
import '../enums/order_status.dart';
import '../value_objects/geo_location.dart';

class PendingOperation {
  final String id;
  final PendingOperationType type;
  final String orderId;
  final OrderStatus? newStatus;
  final String? rejectionReason;
  final GeoLocation? location;
  final String actorId;
  final DateTime createdAt;
  final int retryCount;
  final String? dispatchId;
  final String? driverId;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.orderId,
    this.newStatus,
    this.rejectionReason,
    this.location,
    required this.actorId,
    required this.createdAt,
    this.retryCount = 0,
    this.dispatchId,
    this.driverId,
  });

  PendingOperation copyWith({int? retryCount, String? dispatchId, String? driverId}) => PendingOperation(
        id: id,
        type: type,
        orderId: orderId,
        newStatus: newStatus,
        rejectionReason: rejectionReason,
        location: location,
        actorId: actorId,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
        dispatchId: dispatchId ?? this.dispatchId,
        driverId: driverId ?? this.driverId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'orderId': orderId,
        if (newStatus != null) 'newStatus': newStatus!.value,
        'rejectionReason': rejectionReason,
        if (location != null)
          'latitude': location!.latitude,
        if (location != null)
          'longitude': location!.longitude,
        'actorId': actorId,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        if (dispatchId != null) 'dispatchId': dispatchId,
        if (driverId != null) 'driverId': driverId,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> m) =>
      PendingOperation(
        id: m['id'] as String? ?? '',
        type: PendingOperationTypeX.fromValue(m['type'] as String? ?? ''),
        orderId: m['orderId'] as String? ?? '',
        newStatus: m['newStatus'] != null
            ? OrderStatus.fromValue(m['newStatus'] as String)
            : null,
        rejectionReason: m['rejectionReason'] as String?,
        location: m['latitude'] != null
            ? GeoLocation(
                (m['latitude'] as num).toDouble(),
                (m['longitude'] as num).toDouble(),
              )
            : null,
        actorId: m['actorId'] as String? ?? '',
        createdAt:
            DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now(),
        retryCount: (m['retryCount'] as num?)?.toInt() ?? 0,
        dispatchId: m['dispatchId'] as String?,
        driverId: m['driverId'] as String?,
      );
}