/// Lightweight intent classification. The agent uses pattern matching + a
/// keyword graph to decide which tools to invoke. We keep it local so the
/// agent is fully offline / private.
class Intent {
  final String id;
  final String label;
  final List<String> keywords;
  final List<String> toolNames;
  final String? clarifyingQuestion;
  final IntentKind kind;

  const Intent({
    required this.id,
    required this.label,
    required this.keywords,
    required this.toolNames,
    this.clarifyingQuestion,
    this.kind = IntentKind.read,
  });
}

enum IntentKind { read, create, edit, analyze, recommend, build, redesign, navigate, help }

class IntentClassifier {
  static final List<Intent> _intents = [
    // Reads
    const Intent(
      id: 'list_stores',
      label: 'List stores',
      keywords: ['list stores', 'show stores', 'all stores', 'stores list', 'show me stores'],
      toolNames: ['list_stores'],
      kind: IntentKind.read,
    ),
    const Intent(
      id: 'list_orders',
      label: 'List orders',
      keywords: ['list orders', 'show orders', 'recent orders', 'pending orders', 'all orders'],
      toolNames: ['list_orders'],
      kind: IntentKind.read,
    ),
    const Intent(
      id: 'list_drivers',
      label: 'List drivers',
      keywords: ['list drivers', 'show drivers', 'all drivers', 'driver list'],
      toolNames: ['list_drivers'],
      kind: IntentKind.read,
    ),
    const Intent(
      id: 'list_customers',
      label: 'List customers',
      keywords: ['list customers', 'show customers', 'top customers', 'user list'],
      toolNames: ['list_customers'],
      kind: IntentKind.read,
    ),
    const Intent(
      id: 'find_store',
      label: 'Find store',
      keywords: ['find store', 'look up store', 'search store', 'info on', 'tell me about'],
      toolNames: ['read_store'],
      kind: IntentKind.read,
    ),

    // Analyze
    const Intent(
      id: 'analyze_revenue',
      label: 'Analyze revenue',
      keywords: ['revenue', 'earnings', 'sales', 'how much money', 'gmv', 'income'],
      toolNames: ['analyze_revenue', 'read_revenue'],
      kind: IntentKind.analyze,
    ),
    const Intent(
      id: 'analyze_drivers',
      label: 'Analyze driver performance',
      keywords: ['driver performance', 'driver analysis', 'driver stats', 'driver metrics', 'driver leaderboard', 'best driver', 'top driver'],
      toolNames: ['analyze_driver_performance'],
      kind: IntentKind.analyze,
    ),
    const Intent(
      id: 'analyze_store',
      label: 'Analyze store performance',
      keywords: ['store performance', 'store analysis', 'top store', 'best store', 'worst store', 'store metrics'],
      toolNames: ['analyze_store_performance'],
      kind: IntentKind.analyze,
    ),
    const Intent(
      id: 'analyze_retention',
      label: 'Analyze customer retention',
      keywords: ['retention', 'churn', 'repeat customers', 'loyal', 'returning customers'],
      toolNames: ['analyze_customer_retention'],
      kind: IntentKind.analyze,
    ),
    const Intent(
      id: 'analyze_trends',
      label: 'Analyze order trends',
      keywords: ['order trend', 'peak hour', 'busy time', 'order pattern', 'trends'],
      toolNames: ['analyze_order_trends'],
      kind: IntentKind.analyze,
    ),

    // Recommend
    const Intent(
      id: 'recommend_ops',
      label: 'Operational improvements',
      keywords: ['what should i do', 'improve', 'issues', 'problems', 'priority', 'urgent', 'attention'],
      toolNames: ['recommend_operations'],
      kind: IntentKind.recommend,
    ),
    const Intent(
      id: 'recommend_drivers',
      label: 'Driver allocation',
      keywords: ['driver allocation', 'where to send drivers', 'driver coverage', 'rebalance drivers'],
      toolNames: ['recommend_driver_allocation'],
      kind: IntentKind.recommend,
    ),
    const Intent(
      id: 'recommend_marketing',
      label: 'Marketing ideas',
      keywords: ['marketing', 'campaign idea', 'promote', 're-engage', 'win back'],
      toolNames: ['recommend_marketing'],
      kind: IntentKind.recommend,
    ),
    const Intent(
      id: 'recommend_revenue',
      label: 'Revenue opportunities',
      keywords: ['revenue opportunity', 'grow revenue', 'increase sales', 'make more money'],
      toolNames: ['recommend_revenue'],
      kind: IntentKind.recommend,
    ),

    // Create — store builder
    const Intent(
      id: 'create_store',
      label: 'Create a new store',
      keywords: ['create store', 'new store', 'onboard store', 'add store', 'open a', 'launch a'],
      toolNames: [],
      kind: IntentKind.build,
    ),
    const Intent(
      id: 'redesign_store',
      label: 'Redesign a store',
      keywords: ['redesign', 'rebrand', 'refresh store', 'store makeover', 'new design', 'modernize'],
      toolNames: [],
      kind: IntentKind.redesign,
    ),

    // Create — direct
    const Intent(
      id: 'create_coupon',
      label: 'Create coupon',
      keywords: ['create coupon', 'new coupon', 'add coupon', 'make coupon', 'discount code'],
      toolNames: ['create_coupon'],
      kind: IntentKind.create,
    ),
    const Intent(
      id: 'create_campaign',
      label: 'Create campaign',
      keywords: ['create campaign', 'new campaign', 'launch campaign', 'send campaign'],
      toolNames: ['create_campaign'],
      kind: IntentKind.create,
    ),
    const Intent(
      id: 'create_notification',
      label: 'Send notification',
      keywords: ['send notification', 'broadcast', 'notify users', 'announce'],
      toolNames: ['create_notification'],
      kind: IntentKind.create,
    ),
    const Intent(
      id: 'create_promotion',
      label: 'Create promotion',
      keywords: ['create promotion', 'add promotion', 'new promo', 'store promotion'],
      toolNames: ['create_promotion'],
      kind: IntentKind.create,
    ),
    const Intent(
      id: 'generate_report',
      label: 'Generate report',
      keywords: ['generate report', 'run report', 'export report', 'create report'],
      toolNames: ['generate_report'],
      kind: IntentKind.create,
    ),
  ];

  static Intent? classify(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // Sort by specificity (longer match first).
    final ranked = [..._intents]..sort((a, b) {
        final aMax = a.keywords.fold<int>(0, (m, k) => k.length > m ? k.length : m);
        final bMax = b.keywords.fold<int>(0, (m, k) => k.length > m ? k.length : m);
        return bMax.compareTo(aMax);
      });
    for (final intent in ranked) {
      for (final kw in intent.keywords) {
        if (lower.contains(kw)) return intent;
      }
    }
    return null;
  }

  static List<Intent> suggest(String input, {int limit = 5}) {
    final lower = input.toLowerCase();
    final scored = <MapEntry<Intent, int>>[];
    for (final intent in _intents) {
      int score = 0;
      for (final kw in intent.keywords) {
        if (lower.contains(kw)) score += kw.length;
      }
      if (score > 0) scored.add(MapEntry(intent, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }
}
