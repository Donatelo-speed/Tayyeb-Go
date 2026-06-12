import 'package:cloud_firestore/cloud_firestore.dart';

class SearchResult {
  final String id;
  final String name;
  final String type;
  final String? imageUrl;
  final double? rating;
  final String? category;
  final double? distance;
  final int relevanceScore;

  const SearchResult({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl,
    this.rating,
    this.category,
    this.distance,
    required this.relevanceScore,
  });
}

class SmartSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search with fuzzy matching, typo tolerance, and relevance ranking.
  Future<List<SearchResult>> search({
    required String query,
    String? category,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();
    final terms = normalizedQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    final results = <SearchResult>[];

    final restaurantResults = await _searchRestaurants(terms, category);
    results.addAll(restaurantResults);

    final menuResults = await _searchMenuItems(terms, category);
    results.addAll(menuResults);

    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results.take(limit).toList();
  }

  /// Get search suggestions (autocomplete).
  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.trim().length < 2) return [];

    final normalized = partialQuery.toLowerCase().trim();

    final snap = await _firestore.collection('restaurants')
        .where('isActive', isEqualTo: true)
        .limit(30)
        .get();

    final suggestions = <String>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toLowerCase();
      if (name.contains(normalized)) {
        suggestions.add(data['name'] as String? ?? '');
      }

      final cuisine = (data['cuisine'] as String? ?? '').toLowerCase();
      if (cuisine.contains(normalized) && !suggestions.contains(data['cuisine'])) {
        suggestions.add(data['cuisine'] as String? ?? '');
      }
    }

    final menuSnap = await _firestore.collectionGroup('menu')
        .where('isAvailable', isEqualTo: true)
        .limit(50)
        .get();

    for (final doc in menuSnap.docs) {
      final data = doc.data();
      final itemName = (data['name'] as String? ?? '').toLowerCase();
      if (itemName.contains(normalized) && !suggestions.contains(data['name'])) {
        suggestions.add(data['name'] as String? ?? '');
      }
    }

    final historySuggestions = await _getSearchHistory(normalized);
    for (final h in historySuggestions) {
      if (!suggestions.contains(h)) suggestions.insert(0, h);
    }

    return suggestions.take(8).toList();
  }

  /// Save a search query to history.
  Future<void> saveSearchQuery(String userId, String query) async {
    if (query.trim().isEmpty) return;
    try {
      await _firestore.collection('search_history').add({
        'userId': userId,
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Get trending searches.
  Future<List<String>> getTrendingSearches({int limit = 5}) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final snap = await _firestore.collection('search_history')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .limit(200)
          .get();

      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final q = (data['query'] as String? ?? '').toLowerCase().trim();
        if (q.length >= 2) {
          counts[q] = (counts[q] ?? 0) + 1;
        }
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(limit).map((e) => e.key).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchRestaurants(List<String> terms, String? category) async {
    Query query = _firestore.collection('restaurants')
        .where('isActive', isEqualTo: true)
        .limit(50);

    if (category != null && category != 'All') {
      query = query.where('vertical', isEqualTo: category.toLowerCase());
    }

    final snap = await query.get();
    final results = <SearchResult>[];

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      final cuisine = (data['cuisine'] as String? ?? '').toLowerCase();
      final description = (data['description'] as String? ?? '').toLowerCase();

      int score = 0;
      for (final term in terms) {
        if (name == term) score += 100;
        else if (name.startsWith(term)) score += 80;
        else if (name.contains(term)) score += 60;
        else if (_fuzzyMatch(name, term)) score += 40;

        if (cuisine.contains(term)) score += 30;
        if (description.contains(term)) score += 10;
      }

      if (score > 0) {
        final rating = (data['rating'] as num?)?.toDouble() ?? 0;
        score += (rating * 5).toInt();

        results.add(SearchResult(
          id: doc.id,
          name: data['name'] as String? ?? '',
          type: 'restaurant',
          imageUrl: data['imageUrl'] as String?,
          rating: rating,
          category: data['cuisine'] as String?,
          relevanceScore: score,
        ));
      }
    }

    return results;
  }

  Future<List<SearchResult>> _searchMenuItems(List<String> terms, String? category) async {
    final snap = await _firestore.collectionGroup('menu')
        .where('isAvailable', isEqualTo: true)
        .limit(100)
        .get();

    final results = <SearchResult>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toLowerCase();
      final description = (data['description'] as String? ?? '').toLowerCase();
      final itemCategory = (data['category'] as String? ?? '').toLowerCase();

      int score = 0;
      for (final term in terms) {
        if (name == term) score += 90;
        else if (name.startsWith(term)) score += 70;
        else if (name.contains(term)) score += 50;
        else if (_fuzzyMatch(name, term)) score += 30;

        if (description.contains(term)) score += 10;
        if (itemCategory.contains(term)) score += 15;
      }

      if (score > 0) {
        results.add(SearchResult(
          id: doc.id,
          name: data['name'] as String? ?? '',
          type: 'menu_item',
          category: data['category'] as String?,
          relevanceScore: score,
        ));
      }
    }

    return results;
  }

  /// Simple fuzzy matching: allows one character substitution.
  bool _fuzzyMatch(String text, String pattern) {
    if (pattern.length < 3) return false;
    if (text.contains(pattern)) return true;

    final words = text.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length < pattern.length) continue;
      int diff = 0;
      for (int i = 0; i < pattern.length && i < word.length; i++) {
        if (word[i] != pattern[i]) diff++;
      }
      if (diff <= 1) return true;
    }
    return false;
  }

  Future<List<String>> _getSearchHistory(String normalized) async {
    try {
      final snap = await _firestore.collection('search_history')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snap.docs
          .map((d) => (d.data()['query'] as String? ?? '').toLowerCase())
          .where((q) => q.contains(normalized) && q.isNotEmpty)
          .toSet()
          .toList()
          .take(3)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
