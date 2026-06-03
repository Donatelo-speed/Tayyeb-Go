import 'package:flutter/material.dart';

class CommissionData {
  final String restaurantId;
  final String restaurantName;
  final double currentDebt;
  final double debtCeiling;
  final double totalEarned;
  final double totalSettled;
  final List<CommissionTransaction> pendingTransactions;
  final bool isSuspended;
  final String? suspensionReason;

  CommissionData({
    required this.restaurantId,
    required this.restaurantName,
    required this.currentDebt,
    required this.debtCeiling,
    required this.totalEarned,
    required this.totalSettled,
    required this.pendingTransactions,
    required this.isSuspended,
    this.suspensionReason,
  });

  double get debtPercentage => (currentDebt / debtCeiling) * 100;
  bool get isNearLimit => debtPercentage > 80;
}

class CommissionTransaction {
  final String id;
  final DateTime date;
  final String orderNumber;
  final double orderAmount;
  final double commissionAmount;
  final String status;

  CommissionTransaction({
    required this.id,
    required this.date,
    required this.orderNumber,
    required this.orderAmount,
    required this.commissionAmount,
    required this.status,
  });
}

class CommissionProvider extends ChangeNotifier {
  List<CommissionData> _restaurants = [];
  bool _isLoading = false;
  double _totalPlatformCommission = 0;
  
  List<CommissionData> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  double get totalPlatformCommission => _totalPlatformCommission;

  Future<void> loadCommissionData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Mock data
      _restaurants = [
        CommissionData(
          restaurantId: 'rest_1',
          restaurantName: 'Al Mandi House',
          currentDebt: 45000,
          debtCeiling: 50000,
          totalEarned: 150000,
          totalSettled: 105000,
          pendingTransactions: [
            CommissionTransaction(
              id: '1',
              date: DateTime.now().subtract(const Duration(days: 1)),
              orderNumber: 'TG20260001',
              orderAmount: 25000,
              commissionAmount: 3750,
              status: 'pending',
            ),
            CommissionTransaction(
              id: '2',
              date: DateTime.now().subtract(const Duration(days: 2)),
              orderNumber: 'TG20260002',
              orderAmount: 18000,
              commissionAmount: 2700,
              status: 'pending',
            ),
          ],
          isSuspended: false,
        ),
        CommissionData(
          restaurantId: 'rest_2',
          restaurantName: 'Pizza Al Sheikh',
          currentDebt: 55000,
          debtCeiling: 50000, // OVER LIMIT!
          totalEarned: 200000,
          totalSettled: 145000,
          pendingTransactions: [
            CommissionTransaction(
              id: '3',
              date: DateTime.now(),
              orderNumber: 'TG20260003',
              orderAmount: 30000,
              commissionAmount: 4500,
              status: 'overdue',
            ),
          ],
          isSuspended: true,
          suspensionReason: 'Commission debt exceeded ceiling',
        ),
      ];
      
      _totalPlatformCommission = _restaurants.fold(
        0.0, (sum, r) => sum + r.currentDebt,
      );
    } catch (e) {
      debugPrint('Failed to load commission data: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> settleDebt(String restaurantId, double amount) async {
    // In production: Call API to record settlement
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _restaurants.indexWhere((r) => r.restaurantId == restaurantId);
    if (index >= 0) {
      final updated = _restaurants[index];
      _restaurants[index] = CommissionData(
        restaurantId: updated.restaurantId,
        restaurantName: updated.restaurantName,
        currentDebt: (updated.currentDebt - amount).clamp(0, double.infinity),
        debtCeiling: updated.debtCeiling,
        totalEarned: updated.totalEarned,
        totalSettled: updated.totalSettled + amount,
        pendingTransactions: updated.pendingTransactions,
        isSuspended: false,
      );
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<bool> updateDebtCeiling(String restaurantId, double newCeiling) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _restaurants.indexWhere((r) => r.restaurantId == restaurantId);
    if (index >= 0) {
      final updated = _restaurants[index];
      _restaurants[index] = CommissionData(
        restaurantId: updated.restaurantId,
        restaurantName: updated.restaurantName,
        currentDebt: updated.currentDebt,
        debtCeiling: newCeiling,
        totalEarned: updated.totalEarned,
        totalSettled: updated.totalSettled,
        pendingTransactions: updated.pendingTransactions,
        isSuspended: updated.currentDebt > newCeiling,
      );
      notifyListeners();
      return true;
    }
    return false;
  }
}

// =====================================================
// ADMIN SETTLEMENTS DASHBOARD WIDGET
// =====================================================

class SettlementsDashboard extends StatelessWidget {
  final CommissionProvider provider;
  
  const SettlementsDashboard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Commission Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A085), Color(0xFF2ECC71)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Platform Commission',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.totalPlatformCommission.toStringAsFixed(0)} SYP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Restaurant Debts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...provider.restaurants.map((restaurant) => 
            _RestaurantDebtCard(
              restaurant: restaurant,
              onSettle: () => _showSettleDialog(context, restaurant),
              onUpdateCeiling: () => _showCeilingDialog(context, restaurant),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSettleDialog(BuildContext context, CommissionData restaurant) {
    final controller = TextEditingController(
      text: restaurant.currentDebt.toStringAsFixed(0),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle ${restaurant.restaurantName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Settlement Amount',
            prefixText: 'SYP ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              provider.settleDebt(restaurant.restaurantId, amount);
              Navigator.pop(context);
            },
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }
  
  void _showCeilingDialog(BuildContext context, CommissionData restaurant) {
    final controller = TextEditingController(
      text: restaurant.debtCeiling.toStringAsFixed(0),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${restaurant.restaurantName} Ceiling'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Debt Ceiling',
            prefixText: 'SYP ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final ceiling = double.tryParse(controller.text) ?? 50000;
              provider.updateDebtCeiling(restaurant.restaurantId, ceiling);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _RestaurantDebtCard extends StatelessWidget {
  final CommissionData restaurant;
  final VoidCallback onSettle;
  final VoidCallback onUpdateCeiling;
  
  const _RestaurantDebtCard({
    required this.restaurant,
    required this.onSettle,
    required this.onUpdateCeiling,
  });

  @override
  Widget build(BuildContext context) {
    final isOverLimit = restaurant.currentDebt > restaurant.debtCeiling;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOverLimit ? Border.all(color: Colors.red, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.restaurantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (restaurant.isSuspended)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SUSPENDED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: onUpdateCeiling,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Debt Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Debt: ${restaurant.currentDebt.toStringAsFixed(0)} SYP',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Ceiling: ${restaurant.debtCeiling.toStringAsFixed(0)} SYP',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (restaurant.currentDebt / restaurant.debtCeiling).clamp(0, 1),
                backgroundColor: Colors.grey.shade200,
                color: isOverLimit 
                    ? Colors.red 
                    : restaurant.isNearLimit 
                        ? Colors.orange 
                        : const Color(0xFF16A085),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earned',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${restaurant.totalEarned.toStringAsFixed(0)} SYP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Settled',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${restaurant.totalSettled.toStringAsFixed(0)} SYP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: restaurant.currentDebt > 0 ? onSettle : null,
              icon: const Icon(Icons.paid),
              label: const Text('Settle Balance'),
            ),
          ),
        ],
      ),
    );
  }
}