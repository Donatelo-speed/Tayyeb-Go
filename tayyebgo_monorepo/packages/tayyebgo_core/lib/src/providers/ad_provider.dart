import 'package:flutter/foundation.dart';
import '../models/ad_campaign_model.dart';
import '../services/ad_service.dart';

enum AdProviderState {
  initial,
  loading,
  success,
  error,
}

class AdProvider extends ChangeNotifier {
  final AdService _adService = AdService();

  AdProviderState _campaignsState = AdProviderState.initial;
  AdProviderState _sponsoredState = AdProviderState.initial;
  AdProviderState _analyticsState = AdProviderState.initial;

  List<AdCampaign> _campaigns = [];
  List<AdCampaign> _sponsoredStores = [];
  CampaignAnalytics? _analytics;

  String? _campaignsError;
  String? _sponsoredError;
  String? _analyticsError;

  AdProviderState get campaignsState => _campaignsState;
  AdProviderState get sponsoredState => _sponsoredState;
  AdProviderState get analyticsState => _analyticsState;

  List<AdCampaign> get campaigns => _campaigns;
  List<AdCampaign> get sponsoredStores => _sponsoredStores;
  CampaignAnalytics? get analytics => _analytics;

  String? get campaignsError => _campaignsError;
  String? get sponsoredError => _sponsoredError;
  String? get analyticsError => _analyticsError;

  bool get isLoadingCampaigns => _campaignsState == AdProviderState.loading;
  bool get isLoadingSponsored => _sponsoredState == AdProviderState.loading;
  bool get isLoadingAnalytics => _analyticsState == AdProviderState.loading;

  Future<void> createCampaign(
      String restaurantId, Map<String, dynamic> campaignData) async {
    _campaignsState = AdProviderState.loading;
    _campaignsError = null;
    notifyListeners();

    try {
      final campaign =
          await _adService.createCampaign(restaurantId, campaignData);
      _campaigns.insert(0, campaign);
      _campaignsState = AdProviderState.success;
    } catch (e) {
      _campaignsState = AdProviderState.error;
      _campaignsError = 'Failed to create campaign: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> getCampaigns(String restaurantId) async {
    _campaignsState = AdProviderState.loading;
    _campaignsError = null;
    notifyListeners();

    try {
      _campaigns = await _adService.getCampaigns(restaurantId);
      _campaignsState = AdProviderState.success;
    } catch (e) {
      _campaignsState = AdProviderState.error;
      _campaignsError = 'Failed to load campaigns: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> pauseCampaign(String campaignId) async {
    try {
      await _adService.pauseCampaign(campaignId);
      _campaigns = _campaigns.map((c) {
        if (c.id == campaignId) {
          return c.copyWith(status: AdStatus.paused);
        }
        return c;
      }).toList();
      notifyListeners();
    } catch (e) {
      _campaignsError = 'Failed to pause campaign: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> resumeCampaign(String campaignId) async {
    try {
      await _adService.resumeCampaign(campaignId);
      _campaigns = _campaigns.map((c) {
        if (c.id == campaignId) {
          return c.copyWith(status: AdStatus.active);
        }
        return c;
      }).toList();
      notifyListeners();
    } catch (e) {
      _campaignsError = 'Failed to resume campaign: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> getSponsoredStores(String zone) async {
    _sponsoredState = AdProviderState.loading;
    _sponsoredError = null;
    notifyListeners();

    try {
      _sponsoredStores = await _adService.getSponsoredStores(zone);
      _sponsoredState = AdProviderState.success;
    } catch (e) {
      _sponsoredState = AdProviderState.error;
      _sponsoredError = 'Failed to load sponsored stores: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> getCampaignAnalytics(String campaignId) async {
    _analyticsState = AdProviderState.loading;
    _analyticsError = null;
    notifyListeners();

    try {
      _analytics = await _adService.getCampaignAnalytics(campaignId);
      _analyticsState = AdProviderState.success;
    } catch (e) {
      _analyticsState = AdProviderState.error;
      _analyticsError = 'Failed to load analytics: ${e.toString()}';
    }

    notifyListeners();
  }

  void clearError() {
    _campaignsError = null;
    _sponsoredError = null;
    _analyticsError = null;
    notifyListeners();
  }

  void reset() {
    _campaignsState = AdProviderState.initial;
    _sponsoredState = AdProviderState.initial;
    _analyticsState = AdProviderState.initial;
    _campaigns = [];
    _sponsoredStores = [];
    _analytics = null;
    _campaignsError = null;
    _sponsoredError = null;
    _analyticsError = null;
    notifyListeners();
  }
}
