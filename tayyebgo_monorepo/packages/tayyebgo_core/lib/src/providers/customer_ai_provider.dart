import 'package:flutter/foundation.dart';
import '../services/customer_ai_service.dart';

enum CustomerAIState {
  initial,
  loading,
  success,
  error,
}

class CustomerAIProvider extends ChangeNotifier {
  final CustomerAIService _aiService = CustomerAIService();

  CustomerAIState _searchState = CustomerAIState.initial;
  CustomerAIState _recommendationState = CustomerAIState.initial;
  CustomerAIState _chatState = CustomerAIState.initial;
  CustomerAIState _preferencesState = CustomerAIState.initial;

  List<AISearchResult> _searchResults = [];
  List<AIRecommendation> _recommendations = [];
  List<ChatMessage> _chatMessages = [];
  UserPreferences? _userPreferences;

  String? _searchError;
  String? _recommendationError;
  String? _chatError;
  String? _preferencesError;

  CustomerAIState get searchState => _searchState;
  CustomerAIState get recommendationState => _recommendationState;
  CustomerAIState get chatState => _chatState;
  CustomerAIState get preferencesState => _preferencesState;

  List<AISearchResult> get searchResults => _searchResults;
  List<AIRecommendation> get recommendations => _recommendations;
  List<ChatMessage> get chatMessages => _chatMessages;
  UserPreferences? get userPreferences => _userPreferences;

  String? get searchError => _searchError;
  String? get recommendationError => _recommendationError;
  String? get chatError => _chatError;
  String? get preferencesError => _preferencesError;

  bool get isSearching => _searchState == CustomerAIState.loading;
  bool get isGettingRecommendations => _recommendationState == CustomerAIState.loading;
  bool get isChatting => _chatState == CustomerAIState.loading;
  bool get isAnalyzingPreferences => _preferencesState == CustomerAIState.loading;

  Future<void> smartSearch(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchState = CustomerAIState.loading;
    _searchError = null;
    notifyListeners();

    try {
      _searchResults = await _aiService.smartSearch(query);
      _searchState = CustomerAIState.success;
    } catch (e) {
      _searchState = CustomerAIState.error;
      _searchError = 'Search failed: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> getRecommendations(String userId, {Map<String, dynamic>? context}) async {
    _recommendationState = CustomerAIState.loading;
    _recommendationError = null;
    notifyListeners();

    try {
      _recommendations = await _aiService.getRecommendations(userId, context: context);
      _recommendationState = CustomerAIState.success;
    } catch (e) {
      _recommendationState = CustomerAIState.error;
      _recommendationError = 'Failed to get recommendations: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _chatState = CustomerAIState.loading;
    _chatError = null;

    _chatMessages.add(ChatMessage(role: 'user', content: message));
    notifyListeners();

    try {
      _chatMessages = await _aiService.chatWithAI(_chatMessages);
      _chatState = CustomerAIState.success;
    } catch (e) {
      _chatState = CustomerAIState.error;
      _chatError = 'Failed to get response: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> analyzePreferences(String userId) async {
    _preferencesState = CustomerAIState.loading;
    _preferencesError = null;
    notifyListeners();

    try {
      _userPreferences = await _aiService.analyzePreferences(userId);
      _preferencesState = CustomerAIState.success;
    } catch (e) {
      _preferencesState = CustomerAIState.error;
      _preferencesError = 'Failed to analyze preferences: ${e.toString()}';
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchState = CustomerAIState.initial;
    _searchError = null;
    notifyListeners();
  }

  void clearRecommendations() {
    _recommendations = [];
    _recommendationState = CustomerAIState.initial;
    _recommendationError = null;
    notifyListeners();
  }

  void clearChat() {
    _chatMessages = [];
    _chatState = CustomerAIState.initial;
    _chatError = null;
    notifyListeners();
  }

  void clearAllErrors() {
    _searchError = null;
    _recommendationError = null;
    _chatError = null;
    _preferencesError = null;
    notifyListeners();
  }

  void reset() {
    _searchState = CustomerAIState.initial;
    _recommendationState = CustomerAIState.initial;
    _chatState = CustomerAIState.initial;
    _preferencesState = CustomerAIState.initial;

    _searchResults = [];
    _recommendations = [];
    _chatMessages = [];
    _userPreferences = null;

    _searchError = null;
    _recommendationError = null;
    _chatError = null;
    _preferencesError = null;

    notifyListeners();
  }
}
