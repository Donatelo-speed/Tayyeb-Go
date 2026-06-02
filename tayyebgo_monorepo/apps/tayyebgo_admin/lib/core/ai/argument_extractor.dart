/// Heuristic argument extractor. Pulls names, codes, percentages, and
/// keywords out of natural language to pre-fill tool arguments.
class ArgumentExtractor {
  static String? quotedString(String input) {
    final m = RegExp(r'"([^"]+)"').firstMatch(input);
    if (m != null) return m.group(1);
    final m2 = RegExp(r"'([^']+)'").firstMatch(input);
    if (m2 != null) return m2.group(1);
    return null;
  }

  /// Tries to find a quoted or "called X" / "named X" / "titled X" phrase.
  static String? entityName(String input) {
    final patterns = [
      RegExp('called\\s+([A-Z][\\w\\s&\'-]{1,40})', caseSensitive: false),
      RegExp('named\\s+([A-Z][\\w\\s&\'-]{1,40})', caseSensitive: false),
      RegExp('titled\\s+([A-Z][\\w\\s&\'-]{1,40})', caseSensitive: false),
      RegExp(r'"([^"]+)"'),
      RegExp(r"'([^']+)'"),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(input);
      if (m != null) return m.group(1)?.trim();
    }
    return null;
  }

  /// Maps free text → businessType key.
  static String? businessType(String input) {
    final lower = input.toLowerCase();
    const mapping = {
      'pharmacy': 'pharmacy',
      'drug': 'pharmacy',
      'medicine': 'pharmacy',
      'coffee': 'cafe',
      'cafe': 'cafe',
      'café': 'cafe',
      'restaurant': 'restaurant',
      'food': 'restaurant',
      'kitchen': 'restaurant',
      'pizza': 'restaurant',
      'burger': 'restaurant',
      'fast food': 'fast_food',
      'fastfood': 'fast_food',
      'market': 'market',
      'grocery': 'market',
      'shop': 'retail',
      'retail': 'retail',
      'clothing': 'retail',
      'fashion': 'retail',
      'electronics': 'electronics',
      'salon': 'service',
      'spa': 'service',
      'service': 'service',
    };
    for (final entry in mapping.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? template(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('modern')) return 'modern';
    if (lower.contains('minimal')) return 'minimal';
    if (lower.contains('premium')) return 'premium';
    if (lower.contains('pharmacy')) return 'pharmacy';
    if (lower.contains('market')) return 'market';
    if (lower.contains('cafe') || lower.contains('café') || lower.contains('coffee')) return 'cafe';
    if (lower.contains('fast') && lower.contains('food')) return 'fast_food';
    if (lower.contains('restaurant') || lower.contains('pizza')) return 'restaurant';
    if (lower.contains('electronics')) return 'electronics';
    return null;
  }

  /// "with 15% off" → 15
  static double? percentageOff(String input) {
    final m = RegExp(r'(\d{1,3})\s*%').firstMatch(input);
    if (m != null) return double.tryParse(m.group(1)!);
    final m2 = RegExp(r'(\d{1,3})\s*percent', caseSensitive: false).firstMatch(input);
    if (m2 != null) return double.tryParse(m2.group(1)!);
    return null;
  }

  static String? couponCode(String input) {
    final m = RegExp(r'\b([A-Z0-9]{4,12})\b').firstMatch(input.toUpperCase());
    if (m != null) return m.group(1);
    return null;
  }

  static String? hexColor(String input) {
    final m = RegExp(r'#([0-9A-Fa-f]{6})').firstMatch(input);
    if (m != null) return '#${m.group(1)}';
    return null;
  }
}
