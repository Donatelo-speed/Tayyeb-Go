import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_campaign_model.dart';

class CampaignAnalytics {
  final String campaignId;
  final int totalImpressions;
  final int totalClicks;
  final double ctr;
  final double totalSpent;
  final double budgetRemaining;
  final Map<String, int> dailyImpressions;
  final Map<String, int> dailyClicks;

  CampaignAnalytics({
    required this.campaignId,
    required this.totalImpressions,
    required this.totalClicks,
    required this.ctr,
    required this.totalSpent,
    required this.budgetRemaining,
    this.dailyImpressions = const {},
    this.dailyClicks = const {},
  });
}

class AdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _campaigns => _firestore.collection('ad_campaigns');

  Future<AdCampaign> createCampaign(
      String restaurantId, Map<String, dynamic> campaignData) async {
    final now = DateTime.now();
    final doc = _campaigns.doc();

    final campaign = AdCampaign(
      id: doc.id,
      restaurantId: restaurantId,
      type: AdType.values.firstWhere(
        (e) => e.name == campaignData['type'],
        orElse: () => AdType.sponsoredListing,
      ),
      status: AdStatus.draft,
      budget: (campaignData['budget'] as num?)?.toDouble() ?? 0,
      startDate: campaignData['startDate'] is DateTime
          ? campaignData['startDate']
          : DateTime.fromMillisecondsSinceEpoch(
              campaignData['startDate'] as int? ?? now.millisecondsSinceEpoch),
      endDate: campaignData['endDate'] is DateTime
          ? campaignData['endDate']
          : DateTime.fromMillisecondsSinceEpoch(
              campaignData['endDate'] as int? ??
                  now.add(const Duration(days: 7)).millisecondsSinceEpoch),
      targetZones: (campaignData['targetZones'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );

    await doc.set(campaign.toJSON());
    return campaign;
  }

  Future<List<AdCampaign>> getCampaigns(String restaurantId) async {
    final snapshot = await _campaigns
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('startDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AdCampaign.fromFirestore(doc))
        .toList();
  }

  Future<void> pauseCampaign(String campaignId) async {
    await _campaigns.doc(campaignId).update({
      'status': AdStatus.paused.name,
    });
  }

  Future<void> resumeCampaign(String campaignId) async {
    await _campaigns.doc(campaignId).update({
      'status': AdStatus.active.name,
    });
  }

  Future<List<AdCampaign>> getSponsoredStores(String zone) async {
    final snapshot = await _campaigns
        .where('type', isEqualTo: AdType.sponsoredListing.name)
        .where('status', isEqualTo: AdStatus.active.name)
        .get();

    return snapshot.docs
        .map((doc) => AdCampaign.fromFirestore(doc))
        .where((campaign) => campaign.targetZones.contains(zone))
        .where((campaign) {
      final now = DateTime.now();
      return now.isAfter(campaign.startDate) &&
          now.isBefore(campaign.endDate) &&
          campaign.spent < campaign.budget;
    }).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));
  }

  Future<void> trackImpression(String campaignId) async {
    await _campaigns.doc(campaignId).update({
      'impressions': FieldValue.increment(1),
    });
  }

  Future<void> trackClick(String campaignId) async {
    await _campaigns.doc(campaignId).update({
      'clicks': FieldValue.increment(1),
    });
  }

  Future<CampaignAnalytics> getCampaignAnalytics(String campaignId) async {
    final doc = await _campaigns.doc(campaignId).get();
    if (!doc.exists) {
      return CampaignAnalytics(
        campaignId: campaignId,
        totalImpressions: 0,
        totalClicks: 0,
        ctr: 0,
        totalSpent: 0,
        budgetRemaining: 0,
      );
    }

    final campaign = AdCampaign.fromFirestore(doc);

    final impressionsSnap = await _campaigns
        .doc(campaignId)
        .collection('impression_log')
        .get();

    final clicksSnap = await _campaigns
        .doc(campaignId)
        .collection('click_log')
        .get();

    final dailyImpressions = <String, int>{};
    final dailyClicks = <String, int>{};

    for (final doc in impressionsSnap.docs) {
      final date = (doc.data()['date'] as String?) ?? '';
      dailyImpressions[date] = (dailyImpressions[date] ?? 0) + 1;
    }

    for (final doc in clicksSnap.docs) {
      final date = (doc.data()['date'] as String?) ?? '';
      dailyClicks[date] = (dailyClicks[date] ?? 0) + 1;
    }

    return CampaignAnalytics(
      campaignId: campaignId,
      totalImpressions: campaign.impressions,
      totalClicks: campaign.clicks,
      ctr: campaign.ctr,
      totalSpent: campaign.spent,
      budgetRemaining: campaign.budgetRemaining,
      dailyImpressions: dailyImpressions,
      dailyClicks: dailyClicks,
    );
  }
}
