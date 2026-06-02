import '../value_objects/geo_location.dart';

class DispatchRequest {
  final String id;
  final String orderId;
  final String brandId;
  final String branchId;
  final GeoLocation pickupLocation;
  final GeoLocation dropoffLocation;
  final String? assignedDriverId;
  final DispatchStatus status;
  final List<DriverScore> candidateScores;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;

  const DispatchRequest({
    required this.id,
    required this.orderId,
    required this.brandId,
    required this.branchId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.assignedDriverId,
    this.status = DispatchStatus.pending,
    this.candidateScores = const [],
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
  });

  DispatchRequest copyWith({
    String? assignedDriverId,
    DispatchStatus? status,
    List<DriverScore>? candidateScores,
    DateTime? assignedAt,
    DateTime? completedAt,
  }) =>
      DispatchRequest(
        id: id,
        orderId: orderId,
        brandId: brandId,
        branchId: branchId,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        assignedDriverId: assignedDriverId ?? this.assignedDriverId,
        status: status ?? this.status,
        candidateScores: candidateScores ?? this.candidateScores,
        createdAt: createdAt,
        assignedAt: assignedAt ?? this.assignedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'brandId': brandId,
        'branchId': branchId,
        'pickupLat': pickupLocation.latitude,
        'pickupLon': pickupLocation.longitude,
        'dropoffLat': dropoffLocation.latitude,
        'dropoffLon': dropoffLocation.longitude,
        'assignedDriverId': assignedDriverId,
        'status': status.value,
        'candidateScores':
            candidateScores.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'assignedAt': assignedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DispatchRequest.fromMap(Map<String, dynamic> m, String docId) =>
      DispatchRequest(
        id: docId,
        orderId: m['orderId'] as String? ?? '',
        brandId: m['brandId'] as String? ?? '',
        branchId: m['branchId'] as String? ?? '',
        pickupLocation: GeoLocation(
          (m['pickupLat'] as num?)?.toDouble() ?? 0,
          (m['pickupLon'] as num?)?.toDouble() ?? 0,
        ),
        dropoffLocation: GeoLocation(
          (m['dropoffLat'] as num?)?.toDouble() ?? 0,
          (m['dropoffLon'] as num?)?.toDouble() ?? 0,
        ),
        assignedDriverId: m['assignedDriverId'] as String?,
        status: DispatchStatusX.fromValue(m['status'] as String? ?? ''),
        candidateScores: (m['candidateScores'] as List<dynamic>?)
                ?.map((e) =>
                    DriverScore.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt:
            DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime.now(),
        assignedAt:
            DateTime.tryParse(m['assignedAt'] as String? ?? ''),
        completedAt:
            DateTime.tryParse(m['completedAt'] as String? ?? ''),
      );
}

enum DispatchStatus {
  pending,
  scoring,
  assigned,
  accepted,
  enRoute,
  pickedUp,
  delivered,
  cancelled,
  fallbackWaiting,
  unassigned,
  overloaded;

  String get value => name;
}

extension DispatchStatusX on DispatchStatus {
  static DispatchStatus fromValue(String v) =>
      DispatchStatus.values.firstWhere(
        (e) => e.name == v || e.name.replaceAll('_', '') == v.replaceAll('_', ''),
        orElse: () => DispatchStatus.pending,
      );
}

class DriverScore {
  final String driverId;
  final String driverName;
  final String driverType;
  final double etaMinutes;
  final double distanceKm;
  final double rating;
  final int activeDeliveries;
  final double score;

  const DriverScore({
    required this.driverId,
    required this.driverName,
    this.driverType = 'platform',
    required this.etaMinutes,
    required this.distanceKm,
    required this.rating,
    required this.activeDeliveries,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'driverName': driverName,
        'driverType': driverType,
        'etaMinutes': etaMinutes,
        'distanceKm': distanceKm,
        'rating': rating,
        'activeDeliveries': activeDeliveries,
        'score': score,
      };

  factory DriverScore.fromJson(Map<String, dynamic> m) => DriverScore(
        driverId: m['driverId'] as String? ?? '',
        driverName: m['driverName'] as String? ?? '',
        driverType: m['driverType'] as String? ?? 'platform',
        etaMinutes: (m['etaMinutes'] as num?)?.toDouble() ?? 0,
        distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        activeDeliveries: (m['activeDeliveries'] as num?)?.toInt() ?? 0,
        score: (m['score'] as num?)?.toDouble() ?? 0,
      );
}