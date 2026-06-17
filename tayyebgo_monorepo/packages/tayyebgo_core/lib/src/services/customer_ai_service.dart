import 'package:cloud_firestore/cloud_firestore.dart';

class AISearchResult {
  final String id;
  final String name;
  final String type;
  final double? price;
  final String? imageUrl;
  final String? restaurantName;
  final String? restaurantId;
  final double? relevanceScore;
  final Map<String, dynamic>? metadata;

  AISearchResult({
    required this.id,
    required this.name,
    required this.type,
    this.price,
    this.imageUrl,
    this.restaurantName,
    this.restaurantId,
    this.relevanceScore,
    this.metadata,
  });

  factory AISearchResult.fromFirestore(DocumentSnapshot doc, {String? type}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AISearchResult(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: type ?? data['type'] as String? ?? 'unknown',
      price: (data['price'] as num?)?.toDouble(),
      imageUrl: data['imageUrl'] as String?,
      restaurantName: data['restaurantName'] as String?,
      restaurantId: data['restaurantId'] as String?,
      metadata: data,
    );
  }
}

class AIRecommendation {
  final String itemId;
  final String name;
  final String? imageUrl;
  final double price;
  final String restaurantId;
  final String restaurantName;
  final String reason;
  final double confidence;

  AIRecommendation({
    required this.itemId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.restaurantId,
    required this.restaurantName,
    required this.reason,
    required this.confidence,
  });
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    role: map['role'] as String? ?? 'user',
    content: map['content'] as String? ?? '',
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int? ?? 0),
  );
}

class UserPreferences {
  final List<String> favoriteCategories;
  final List<String> favoriteRestaurants;
  final double averageOrderValue;
  final List<String> dietaryRestrictions;
  final Map<String, int> categoryFrequency;
  final Map<String, int> restaurantFrequency;

  UserPreferences({
    required this.favoriteCategories,
    required this.favoriteRestaurants,
    required this.averageOrderValue,
    required this.dietaryRestrictions,
    required this.categoryFrequency,
    required this.restaurantFrequency,
  });

  factory UserPreferences.empty() => UserPreferences(
    favoriteCategories: [],
    favoriteRestaurants: [],
    averageOrderValue: 0,
    dietaryRestrictions: [],
    categoryFrequency: {},
    restaurantFrequency: {},
  );
}

class CustomerAIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AISearchResult>> smartSearch(String query) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();
      final results = <AISearchResult>[];

      final parsedQuery = _parseSearchQuery(normalizedQuery);

      if (parsedQuery.containsKey('restaurant')) {
        final restaurantResults = await _searchRestaurants(parsedQuery['restaurant']!);
        results.addAll(restaurantResults);
      }

      final menuResults = await _searchMenuItems(parsedQuery);
      results.addAll(menuResults);

      final scoredResults = _rankResults(results, parsedQuery);
      scoredResults.sort((a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));

      return scoredResults.take(20).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _parseSearchQuery(String query) {
    final parsed = <String, dynamic>{
      'keywords': <String>[],
      'maxPrice': null,
      'category': null,
      'restaurant': null,
      'nearby': false,
      'dietary': <String>[],
      'timeOfDay': null,
    };

    final priceMatch = RegExp(r'(?:under|below|max|less than)\s+(\d+)').firstMatch(query);
    if (priceMatch != null) {
      parsed['maxPrice'] = double.tryParse(priceMatch.group(1) ?? '');
    }

    final categoryKeywords = {
      'dinner': 'dinner',
      'lunch': 'lunch',
      'breakfast': 'breakfast',
      'snack': 'snack',
      'dessert': 'dessert',
      'pizza': 'pizza',
      'burger': 'burger',
      'sushi': 'sushi',
      'salad': 'salad',
      'pasta': 'pasta',
      'grill': 'grill',
      'seafood': 'seafood',
      'vegetarian': 'vegetarian',
      'vegan': 'vegan',
    };

    for (final entry in categoryKeywords.entries) {
      if (query.contains(entry.key)) {
        parsed['category'] = entry.value;
        break;
      }
    }

    final nearbyWords = ['nearby', 'near me', 'close', 'around', 'local'];
    for (final word in nearbyWords) {
      if (query.contains(word)) {
        parsed['nearby'] = true;
        break;
      }
    }

    final timeKeywords = {
      'morning': 'morning',
      'breakfast': 'morning',
      'noon': 'afternoon',
      'lunch': 'afternoon',
      'afternoon': 'afternoon',
      'evening': 'evening',
      'dinner': 'evening',
      'night': 'night',
      'late': 'night',
    };

    for (final entry in timeKeywords.entries) {
      if (query.contains(entry.key)) {
        parsed['timeOfDay'] = entry.value;
        break;
      }
    }

    final dietaryKeywords = ['vegetarian', 'vegan', 'halal', 'gluten-free', 'healthy'];
    for (final keyword in dietaryKeywords) {
      if (query.contains(keyword)) {
        (parsed['dietary'] as List<String>).add(keyword);
      }
    }

    final stopWords = ['find', 'get', 'show', 'me', 'i', 'want', 'need', 'looking', 'for', 'some', 'a', 'the', 'with', 'and', 'or'];
    final words = query.split(RegExp(r'\s+'));
    for (final word in words) {
      if (!stopWords.contains(word) && word.length > 2) {
        (parsed['keywords'] as List<String>).add(word);
      }
    }

    return parsed;
  }

  Future<List<AISearchResult>> _searchRestaurants(String query) async {
    try {
      final restaurants = await _firestore
          .collection('restaurants')
          .where('isOpen', isEqualTo: true)
          .limit(20)
          .get();

      return restaurants.docs.map((doc) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final cuisine = (data['cuisine'] as String? ?? '').toLowerCase();
        final tags = (data['tags'] as List<dynamic>? ?? []).map((t) => t.toString().toLowerCase()).join(' ');

        double score = 0;
        if (name.contains(query)) score += 10;
        if (cuisine.contains(query)) score += 5;
        if (tags.contains(query)) score += 3;

        return AISearchResult(
          id: doc.id,
          name: data['name'] as String? ?? '',
          type: 'restaurant',
          imageUrl: data['imageUrl'] as String?,
          relevanceScore: score,
          metadata: data,
        );
      }).where((r) => r.relevanceScore! > 0).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AISearchResult>> _searchMenuItems(Map<String, dynamic> parsedQuery) async {
    try {
      final results = <AISearchResult>[];

      final restaurants = await _firestore
          .collection('restaurants')
          .where('isOpen', isEqualTo: true)
          .limit(10)
          .get();

      for (final restaurant in restaurants.docs) {
        final menuItems = await _firestore
            .collection('restaurants')
            .doc(restaurant.id)
            .collection('menu')
            .where('isAvailable', isEqualTo: true)
            .get();

        for (final item in menuItems.docs) {
          final data = item.data();
          final name = (data['name'] as String? ?? '').toLowerCase();
          final description = (data['description'] as String? ?? '').toLowerCase();
          final category = (data['category'] as String? ?? '').toLowerCase();
          final price = (data['price'] as num?)?.toDouble() ?? 0;

          double score = 0;

          final keywords = parsedQuery['keywords'] as List<String>;
          for (final keyword in keywords) {
            if (name.contains(keyword)) score += 5;
            if (description.contains(keyword)) score += 3;
            if (category.contains(keyword)) score += 2;
          }

          final maxPrice = parsedQuery['maxPrice'] as double?;
          if (maxPrice != null && price > maxPrice) {
            score = 0;
          } else if (maxPrice != null && price <= maxPrice) {
            score += 3;
          }

          final queryCategory = parsedQuery['category'] as String?;
          if (queryCategory != null && category.contains(queryCategory)) {
            score += 4;
          }

          final dietary = parsedQuery['dietary'] as List<String>;
          final tags = (data['tags'] as List<dynamic>? ?? []).map((t) => t.toString().toLowerCase()).toList();
          for (final restriction in dietary) {
            if (tags.contains(restriction)) {
              score += 3;
            }
          }

          if (score > 0) {
            results.add(AISearchResult(
              id: item.id,
              name: data['name'] as String? ?? '',
              type: 'menu_item',
              price: price,
              imageUrl: data['imageUrl'] as String?,
              restaurantName: restaurant.data()['name'] as String?,
              restaurantId: restaurant.id,
              relevanceScore: score,
              metadata: {
                ...data,
                'restaurantName': restaurant.data()['name'],
                'restaurantId': restaurant.id,
              },
            ));
          }
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  List<AISearchResult> _rankResults(List<AISearchResult> results, Map<String, dynamic> parsedQuery) {
    return results.map((result) {
      double adjustedScore = result.relevanceScore ?? 0;

      if (result.type == 'restaurant') {
        adjustedScore *= 1.2;
      }

      return AISearchResult(
        id: result.id,
        name: result.name,
        type: result.type,
        price: result.price,
        imageUrl: result.imageUrl,
        restaurantName: result.restaurantName,
        restaurantId: result.restaurantId,
        relevanceScore: adjustedScore,
        metadata: result.metadata,
      );
    }).toList();
  }

  Future<List<AIRecommendation>> getRecommendations(
    String userId, {
    Map<String, dynamic>? context,
  }) async {
    try {
      final preferences = await analyzePreferences(userId);
      final recommendations = <AIRecommendation>[];

      final timeOfDay = _getCurrentTimeOfDay();

      final restaurants = await _firestore
          .collection('restaurants')
          .where('isOpen', isEqualTo: true)
          .limit(15)
          .get();

      for (final restaurant in restaurants.docs) {
        final restaurantData = restaurant.data();
        final menuItems = await _firestore
            .collection('restaurants')
            .doc(restaurant.id)
            .collection('menu')
            .where('isAvailable', isEqualTo: true)
            .get();

        for (final item in menuItems.docs) {
          final itemData = item.data();
          final category = itemData['category'] as String? ?? '';
          final tags = (itemData['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList();

          double confidence = 0.5;

          if (preferences.favoriteCategories.contains(category)) {
            confidence += 0.2;
          }

          if (preferences.favoriteRestaurants.contains(restaurant.id)) {
            confidence += 0.15;
          }

          final price = (itemData['price'] as num?)?.toDouble() ?? 0;
          if (price >= preferences.averageOrderValue * 0.5 && price <= preferences.averageOrderValue * 1.5) {
            confidence += 0.1;
          }

          if (timeOfDay == 'morning' && (category.contains('breakfast') || tags.contains('morning'))) {
            confidence += 0.15;
          } else if (timeOfDay == 'afternoon' && (category.contains('lunch') || tags.contains('lunch'))) {
            confidence += 0.15;
          } else if (timeOfDay == 'evening' && (category.contains('dinner') || tags.contains('dinner'))) {
            confidence += 0.15;
          }

          confidence = confidence.clamp(0.0, 1.0);

          if (confidence > 0.6) {
            final reason = _generateRecommendationReason(
              preferences: preferences,
              category: category,
              timeOfDay: timeOfDay,
              restaurantName: restaurantData['name'] as String? ?? '',
            );

            recommendations.add(AIRecommendation(
              itemId: item.id,
              name: itemData['name'] as String? ?? '',
              imageUrl: itemData['imageUrl'] as String?,
              price: price,
              restaurantId: restaurant.id,
              restaurantName: restaurantData['name'] as String? ?? '',
              reason: reason,
              confidence: confidence,
            ));
          }
        }
      }

      recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
      return recommendations.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ChatMessage>> chatWithAI(List<ChatMessage> messages) async {
    try {
      if (messages.isEmpty) return [];

      final lastMessage = messages.last.content.toLowerCase();

      String response;

      if (lastMessage.contains('recommend') || lastMessage.contains('suggest')) {
        response = _generateRecommendationResponse(lastMessage);
      } else if (lastMessage.contains('order') || lastMessage.contains('food')) {
        response = _generateOrderHelpResponse(lastMessage);
      } else if (lastMessage.contains('price') || lastMessage.contains('cost') || lastMessage.contains('cheap')) {
        response = _generatePriceResponse(lastMessage);
      } else if (lastMessage.contains('diet') || lastMessage.contains('vegetarian') || lastMessage.contains('vegan')) {
        response = _generateDietaryResponse(lastMessage);
      } else if (lastMessage.contains('hello') || lastMessage.contains('hi') || lastMessage.contains('hey')) {
        response = 'Hello! I\'m your TayyebGo assistant. I can help you find food, get recommendations, or answer questions about our restaurants. What would you like?';
      } else if (lastMessage.contains('help')) {
        response = 'I can help you with:\n• Finding restaurants and menu items\n• Getting personalized recommendations\n• Dietary preferences and restrictions\n• Price range searches\n• Order suggestions\n\nJust ask me anything about food!';
      } else {
        response = 'I\'m here to help you find the perfect meal! You can ask me for recommendations, search for specific dishes, or tell me about your dietary preferences. What are you in the mood for?';
      }

      return [
        ...messages,
        ChatMessage(role: 'assistant', content: response),
      ];
    } catch (e) {
      return [
        ...messages,
        ChatMessage(role: 'assistant', content: 'Sorry, I encountered an error. Please try again.'),
      ];
    }
  }

  String _generateRecommendationResponse(String query) {
    if (query.contains('dinner') || query.contains('evening')) {
      return 'For dinner, I recommend trying our grilled dishes or pasta options. Many restaurants offer special dinner menus with hearty portions. Would you like me to find specific restaurants near you?';
    }
    if (query.contains('lunch') || query.contains('afternoon')) {
      return 'For lunch, lighter options like salads, wraps, or sandwiches are popular. Many restaurants have lunch specials that offer great value. Want me to search for lunch deals?';
    }
    if (query.contains('breakfast') || query.contains('morning')) {
      return 'Great morning choices include breakfast platters, pastries, or healthy smoothie bowls. Some cafes open early for the best selection. Shall I find breakfast spots?';
    }
    return 'I\'d love to help you find something delicious! Could you tell me more about what you\'re in the mood for? Are you looking for something specific or open to suggestions?';
  }

  String _generateOrderHelpResponse(String query) {
    if (query.contains('order')) {
      return 'To place an order, simply:\n1. Browse restaurants or search for dishes\n2. Add items to your cart\n3. Choose delivery or pickup\n4. Complete payment\n\nWould you like me to help you find something specific?';
    }
    return 'I can help you find food! Tell me what type of cuisine you\'re craving, or I can suggest popular items from nearby restaurants.';
  }

  String _generatePriceResponse(String query) {
    if (query.contains('cheap') || query.contains('budget')) {
      return 'For budget-friendly options, look for:\n• Lunch specials (usually 11am-2pm)\n• Combo meals\n• Street food vendors\n\nI can search for restaurants with meals under a specific price. What\'s your budget?';
    }
    return 'I can help you find options in your price range. What\'s your budget? For example, "meals under 5000 SYP" or "cheap eats nearby".';
  }

  String _generateDietaryResponse(String query) {
    if (query.contains('vegetarian')) {
      return 'Many restaurants offer vegetarian options like:\n• Vegetable curries\n• Salads and grain bowls\n• Pasta with veggie sauces\n\nI can filter search results to show only vegetarian items.';
    }
    if (query.contains('vegan')) {
      return 'For vegan options, look for:\n• Vegetable-based dishes\n• Salads without cheese/dressing\n• Rice and bean combinations\n\nI\'ll highlight vegan-friendly restaurants for you.';
    }
    return 'I can help you find food that matches your dietary needs. Are you vegetarian, vegan, gluten-free, or have other preferences?';
  }

  String _getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  String _generateRecommendationReason({
    required UserPreferences preferences,
    required String category,
    required String timeOfDay,
    required String restaurantName,
  }) {
    final reasons = <String>[];

    if (preferences.favoriteCategories.contains(category)) {
      reasons.add('matches your favorite category');
    }

    if (preferences.favoriteRestaurants.contains(restaurantName)) {
      reasons.add('from a restaurant you love');
    }

    if (timeOfDay == 'morning' && category.contains('breakfast')) {
      reasons.add('perfect for breakfast time');
    } else if (timeOfDay == 'afternoon' && category.contains('lunch')) {
      reasons.add('great for lunch');
    } else if (timeOfDay == 'evening' && category.contains('dinner')) {
      reasons.add('ideal for dinner');
    }

    if (reasons.isEmpty) {
      reasons.add('popular choice');
    }

    return 'Recommended because ${reasons.join(', and ')}.';
  }

  Future<UserPreferences> analyzePreferences(String userId) async {
    try {
      final orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .limit(50)
          .get();

      if (orders.docs.isEmpty) {
        return UserPreferences.empty();
      }

      final categoryFrequency = <String, int>{};
      final restaurantFrequency = <String, int>{};
      double totalOrderValue = 0;
      final dietaryTags = <String>{};

      for (final order in orders.docs) {
        final orderData = order.data();
        final restaurantId = orderData['restaurantId'] as String? ?? '';
        final total = (orderData['total'] as num?)?.toDouble() ?? 0;

        totalOrderValue += total;

        if (restaurantId.isNotEmpty) {
          restaurantFrequency[restaurantId] = (restaurantFrequency[restaurantId] ?? 0) + 1;
        }

        final items = orderData['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final itemData = item as Map<String, dynamic>;
          final category = itemData['category'] as String? ?? '';
          if (category.isNotEmpty) {
            categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;
          }

          final tags = itemData['tags'] as List<dynamic>? ?? [];
          for (final tag in tags) {
            final tagStr = tag.toString().toLowerCase();
            if (['vegetarian', 'vegan', 'halal', 'gluten-free'].contains(tagStr)) {
              dietaryTags.add(tagStr);
            }
          }
        }
      }

      final sortedCategories = categoryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteCategories = sortedCategories.take(5).map((e) => e.key).toList();

      final sortedRestaurants = restaurantFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteRestaurants = sortedRestaurants.take(5).map((e) => e.key).toList();

      final averageOrderValue = orders.docs.isNotEmpty
          ? totalOrderValue / orders.docs.length
          : 0.0;

      await _firestore.collection('user_preferences').doc(userId).set({
        'favoriteCategories': favoriteCategories,
        'favoriteRestaurants': favoriteRestaurants,
        'averageOrderValue': averageOrderValue,
        'dietaryRestrictions': dietaryTags.toList(),
        'categoryFrequency': categoryFrequency,
        'restaurantFrequency': restaurantFrequency,
        'lastAnalyzed': FieldValue.serverTimestamp(),
      });

      return UserPreferences(
        favoriteCategories: favoriteCategories,
        favoriteRestaurants: favoriteRestaurants,
        averageOrderValue: averageOrderValue,
        dietaryRestrictions: dietaryTags.toList(),
        categoryFrequency: categoryFrequency,
        restaurantFrequency: restaurantFrequency,
      );
    } catch (e) {
      return UserPreferences.empty();
    }
  }
}
