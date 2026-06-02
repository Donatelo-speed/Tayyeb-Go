import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoyaltyProvider extends ChangeNotifier {
  int _coinsBalance = 0;
  int _totalEarned = 0;
  int _totalSpent = 0;
  int _tierLevel = 1;
  String _tierName = 'Bronze';
  bool _isLoading = false;
  
  int get coinsBalance => _coinsBalance;
  int get totalEarned => _totalEarned;
  int get totalSpent => _totalSpent;
  int get tierLevel => _tierLevel;
  String get tierName => _tierName;
  bool get isLoading => _isLoading;
  
  // Tier benefits
  List<String> get tierBenefits {
    switch (_tierLevel) {
      case 1: return ['1% coins back on orders'];
      case 2: return ['2% coins back', 'Free delivery'];
      case 3: return ['3% coins back', 'Free delivery', 'Priority support'];
      case 4: return ['5% coins back', 'Free delivery', 'Priority support', 'Exclusive offers'];
      default: return [];
    }
  }
  
  // Calculate coins earned from order
  int calculateCoinsEarned(double orderAmount) {
    final percentage = _getTierPercentage();
    return (orderAmount * percentage / 100).round();
  }
  
  int _getTierPercentage() {
    switch (_tierLevel) {
      case 1: return 1;
      case 2: return 2;
      case 3: return 3;
      case 4: return 5;
      default: return 1;
    }
  }
  
  Future<void> loadWallet(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock data for demo
      _coinsBalance = 150;
      _totalEarned = 250;
      _totalSpent = 100;
      _tierLevel = 2;
      _tierName = 'Silver';
    } catch (e) {
      debugPrint('Failed to load wallet: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> spendCoins(int amount) async {
    if (amount > _coinsBalance) {
      return false;
    }
    
    try {
      _coinsBalance -= amount;
      _totalSpent += amount;
      
      // Check for tier downgrade
      _updateTier();
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  void earnCoins(int amount) {
    _coinsBalance += amount;
    _totalEarned += amount;
    _updateTier();
    notifyListeners();
  }
  
  void _updateTier() {
    final totalValue = _totalEarned - _totalSpent;
    
    if (totalValue >= 200000) {
      _tierLevel = 4;
      _tierName = 'Platinum';
    } else if (totalValue >= 50000) {
      _tierLevel = 3;
      _tierName = 'Gold';
    } else if (totalValue >= 10000) {
      _tierLevel = 2;
      _tierName = 'Silver';
    } else {
      _tierLevel = 1;
      _tierName = 'Bronze';
    }
  }
  
  // Get discount from coins
  double applyCoinsDiscount(double orderTotal, int coinsToUse) {
    // 1 coin = 10 SYP discount
    final discount = coinsToUse * 10.0;
    return (orderTotal - discount).clamp(0, orderTotal);
  }
}

// =====================================================
// LOYALTY WIDGETS
// =====================================================

class LoyaltyCoinsDisplay extends StatelessWidget {
  final LoyaltyProvider loyalty;
  final bool showDetails;
  
  const LoyaltyCoinsDisplay({
    super.key,
    required this.loyalty,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTierColor().withValues(alpha: 0.8),
            _getTierColor(),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Coin Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.white,
              size: 32,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Balance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loyalty.coinsBalance} Coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showDetails)
                  Text(
                    '${loyalty.tierName} Tier • ${loyalty.tierBenefits.first}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Tier Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              loyalty.tierName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getTierColor() {
    switch (loyalty.tierLevel) {
      case 1: return Colors.orange; // Bronze
      case 2: return Colors.grey; // Silver
      case 3: return Colors.amber; // Gold
      case 4: return Colors.purple; // Platinum
      default: return Colors.orange;
    }
  }
}

class CoinDiscountDialog extends StatefulWidget {
  final LoyaltyProvider loyalty;
  final double orderTotal;
  
  const CoinDiscountDialog({
    super.key,
    required this.loyalty,
    required this.orderTotal,
  });

  @override
  State<CoinDiscountDialog> createState() => _CoinDiscountDialogState();
}

class _CoinDiscountDialogState extends State<CoinDiscountDialog> {
  late int _selectedCoins;
  
  @override
  void initState() {
    super.initState();
    _selectedCoins = 0;
  }
  
  @override
  Widget build(BuildContext context) {
    final maxCoins = widget.loyalty.coinsBalance;
    final discount = _selectedCoins * 10.0;
    final newTotal = widget.orderTotal - discount;
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.monetization_on, color: Colors.amber),
          SizedBox(width: 8),
          Text('Use Coins'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You have ${maxCoins} coins',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Slider
          Slider(
            value: _selectedCoins.toDouble(),
            min: 0,
            max: maxCoins.toDouble(),
            divisions: (maxCoins / 10).floor(),
            label: '$_selectedCoins coins',
            onChanged: (v) => setState(() => _selectedCoins = v.round()),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '-${discount.toStringAsFixed(0)} SYP',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'New Total: ${newTotal.toStringAsFixed(0)} SYP',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedCoins),
          child: Text('Use $_selectedCoins Coins'),
        ),
      ],
    );
  }
}