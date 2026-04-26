import 'package:flutter/material.dart';
import 'dart:async';
import '../config.dart';

class CurrencyShimmerService extends ChangeNotifier {
  static final CurrencyShimmerService _instance = CurrencyShimmerService._internal();
  factory CurrencyShimmerService() => _instance;
  CurrencyShimmerService._internal();

  double _exchangeRate = Config.exchangeRate;
  bool _isUpdating = false;
  Timer? _updateTimer;

  double get exchangeRate => _exchangeRate;
  bool get isUpdating => _isUpdating;

  // Live price conversion
  double convert(double usdAmount) => usdAmount * _exchangeRate;

  // Format with shimmer effect
  String format(double usdAmount, {bool showSymbol = true}) {
    final sy = convert(usdAmount);
    final formatted = sy >= 1000 
      ? '${(sy / 1000).toStringAsFixed(1)}K' 
      : sy.toStringAsFixed(0);
    return showSymbol ? '$formatted ل.س' : formatted;
  }

  // Format dual (USD + SYP)
  String formatDual(double usdAmount) {
    return '\$${usdAmount.toStringAsFixed(2)} • ${format(usdAmount)}';
  }

  // Admin updates rate - triggers shimmer across app
  void updateRate(double newRate) async {
    if (_isUpdating) return;
    _isUpdating = true;
    notifyListeners();

    // Simulate shimmer duration
    await Future.delayed(const Duration(milliseconds: 500));
    
    _exchangeRate = newRate;
    _isUpdating = false;
    notifyListeners();
  }

  // Start auto-update (admin feature)
  void startAutoUpdate({Duration interval = const Duration(hours: 1)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) async {
      // In production: fetch from API
      // For demo: subtle fluctuation
      final fluctuation = 1 + (DateTime.now().second % 3 - 1) * 0.001;
      _exchangeRate = (_exchangeRate * fluctuation).roundToDouble();
      notifyListeners();
    });
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

class PriceDisplay extends StatefulWidget {
  final double usdAmount;
  final TextStyle? style;
  final bool showDual;
  final bool enableShimmer;

  const PriceDisplay({
    super.key,
    required this.usdAmount,
    this.style,
    this.showDual = false,
    this.enableShimmer = true,
  });

  @override
  State<PriceDisplay> createState() => _PriceDisplayState();
}

class _PriceDisplayState extends State<PriceDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  final _currencyService = CurrencyShimmerService();

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enableShimmer && _currencyService.isUpdating) {
      _shimmerController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.titleMedium;
    
    if (widget.showDual) {
      return Text(
        _currencyService.formatDual(widget.usdAmount),
        style: style,
      );
    }

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableShimmer && _currencyService.isUpdating
            ? _shimmerAnimation.value 
            : 1.0,
          child: Text(
            _currencyService.format(widget.usdAmount),
            style: style?.copyWith(
              color: _currencyService.isUpdating 
                ? Colors.amber 
                : style.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

class PredictiveCartService {
  static final PredictiveCartService _instance = PredictiveCartService._internal();
  factory PredictiveCartService() => _instance;
  PredictiveCartService._internal();

  final Map<int, List<int>> _associations = {
    // Coffee → sugar, milk
    15: [16, 17],
    // Milk → cereal, bread  
    16: [18, 19],
    // Bread → butter, jam
    19: [20, 21],
    // Tea → sugar, milk
    22: [16, 17],
    // Batteries → flashlight
    35: [36],
  };

  List<Map<String, dynamic>> getSuggestions(
    Map<String, dynamic> currentProduct,
    List<Map<String, dynamic>> allProducts,
  ) {
    final productId = currentProduct['id'] as int?;
    if (productId == null) return [];

    final suggestedIds = _associations[productId] ?? [];
    return allProducts.where((p) => suggestedIds.contains(p['id'])).toList();
  }

  void addAssociation(int productId, List<int> suggestions) {
    _associations[productId] = suggestions;
  }
}