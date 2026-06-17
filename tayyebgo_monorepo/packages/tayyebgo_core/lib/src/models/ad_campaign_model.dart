import 'package:cloud_firestore/cloud_firestore.dart';

enum AdType {
  sponsoredListing,
  bannerAd,
  pushAd,
}

enum AdStatus {
  draft,
  active,
  paused,
  completed,
  expired,
}

class AdCampaign {
  final String id;
  final String restaurantId;
  final AdType type;
  final AdStatus status;
  final double budget;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetZones;
  final int impressions;
  final int clicks;

  AdCampaign({
    required this.id,
    required this.restaurantId,
    required this.type,
    required this.status,
    required this.budget,
    this.spent = 0,
    required this.startDate,
    required this.endDate,
    this.targetZones = const [],
    this.impressions = 0,
    this.clicks = 0,
  });

  bool get isRunning => status == AdStatus.active;

  double get budgetRemaining => (budget - spent).clamp(0, budget);

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;

  Map<String, dynamic> toJSON() => {
        'id': id,
        'restaurantId': restaurantId,
        'type': type.name,
        'status': status.name,
        'budget': budget,
        'spent': spent,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'targetZones': targetZones,
        'impressions': impressions,
        'clicks': clicks,
      };

  factory AdCampaign.fromJSON(Map<String, dynamic> json) {
    return AdCampaign(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      type: AdType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AdType.sponsoredListing,
      ),
      status: AdStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AdStatus.draft,
      ),
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.fromMillisecondsSinceEpoch(
          json['startDate'] as int? ?? 0),
      endDate:
          DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int? ?? 0),
      targetZones: (json['targetZones'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      impressions: json['impressions'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
    );
  }

  factory AdCampaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdCampaign.fromJSON({...data, 'id': doc.id});
  }

  AdCampaign copyWith({
    String? id,
    String? restaurantId,
    AdType? type,
    AdStatus? status,
    double? budget,
    double? spent,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetZones,
    int? impressions,
    int? clicks,
  }) {
    return AdCampaign(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      type: type ?? this.type,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetZones: targetZones ?? this.targetZones,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
    );
  }
}
