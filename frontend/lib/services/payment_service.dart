import 'package:flutter/material.dart';

enum PaymentMethod { cash, shamCash, paymera, visa }
enum PaymentStatus { pending, processing, completed, failed, refunded }

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final PaymentStatus status;
  final Map<String, dynamic>? providerData;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    required this.status,
    this.providerData,
  });
}

class PaymentService {
  // =====================================================
  // SHAM CASH INTEGRATION
  // =====================================================
  
  static Future<PaymentResult> payWithShamCash({
    required String orderId,
    required double amount,
    required String customerPhone,
    required String merchantAccount,
  }) async {
    try {
      // In production: Call Sham Cash API
      // final response = await http.post(
      //   Uri.parse('https://shamcash.api/pay'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'amount': amount,
      //     'from': customerPhone,
      //     'to': merchantAccount,
      //     'reference': orderId,
      //   }),
      // );
      
      // Demo: Simulate successful payment
      await Future.delayed(const Duration(seconds: 2));
      
      return PaymentResult(
        success: true,
        transactionId: 'SC_${DateTime.now().millisecondsSinceEpoch}',
        status: PaymentStatus.completed,
        providerData: {
          'provider': 'sham_cash',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: 'Sham Cash payment failed: $e',
      );
    }
  }
  
  // =====================================================
  // PAYMERA INTEGRATION
  // =====================================================
  
  static Future<PaymentResult> payWithPaymera({
    required String orderId,
    required double amount,
    required String walletId,
  }) async {
    try {
      // In production: Redirect to PAYMERA webview
      // Then wait for callback
      
      // Demo: Simulate
      await Future.delayed(const Duration(seconds: 2));
      
      return PaymentResult(
        success: true,
        transactionId: 'PM_${DateTime.now().millisecondsSinceEpoch}',
        status: PaymentStatus.completed,
        providerData: {
          'provider': 'paymera',
          'wallet_id': walletId,
          'qr_generated': true,
        },
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: 'PAYMERA payment failed: $e',
      );
    }
  }
  
  // =====================================================
  // VISA (Coming Soon Placeholder)
  // =====================================================
  
  static PaymentResult getVisaPlaceholder() {
    return PaymentResult(
      success: false,
      status: PaymentStatus.pending,
      errorMessage: 'Visa/MasterCard integration coming soon!',
    );
  }
  
  // =====================================================
  // PROCESS CHECKOUT
  // =====================================================
  
  static Future<PaymentResult> processCheckout({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? customerPhone,
    String? merchantAccount,
    String? walletId,
  }) async {
    switch (method) {
      case PaymentMethod.cash:
        return PaymentResult(
          success: true,
          transactionId: 'COD_${DateTime.now().millisecondsSinceEpoch}',
          status: PaymentStatus.pending, // Cash collected on delivery
          providerData: {'method': 'cash_on_delivery'},
        );
        
      case PaymentMethod.shamCash:
        return await payWithShamCash(
          orderId: orderId,
          amount: amount,
          customerPhone: customerPhone ?? '',
          merchantAccount: merchantAccount ?? '',
        );
        
      case PaymentMethod.paymera:
        return await payWithPaymera(
          orderId: orderId,
          amount: amount,
          walletId: walletId ?? '',
        );
        
      case PaymentMethod.visa:
        return getVisaPlaceholder();
    }
  }
}

// =====================================================
// CHECKOUT PAYMENT SELECTION WIDGET
// =====================================================

class PaymentSelectionSheet extends StatelessWidget {
  final double orderTotal;
  final Function(PaymentMethod) onSelect;
  final bool shamCashEnabled;
  final bool paymeraEnabled;
  
  const PaymentSelectionSheet({
    super.key,
    required this.orderTotal,
    required this.onSelect,
    this.shamCashEnabled = true,
    this.paymeraEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${orderTotal.toStringAsFixed(0)} SYP',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Cash on Delivery
          _PaymentOption(
            icon: Icons.money,
            title: 'Cash on Delivery',
            subtitle: 'Pay when you receive your order',
            onTap: () => onSelect(PaymentMethod.cash),
          ),
          
          // Sham Cash
          if (shamCashEnabled)
            _PaymentOption(
              icon: Icons.account_balance_wallet,
              title: 'Sham Cash',
              subtitle: 'Pay using your Sham Cash wallet',
              onTap: () => onSelect(PaymentMethod.shamCash),
              badge: 'Popular',
              badgeColor: Colors.green,
            ),
          
          // PAYMERA
          if (paymeraEnabled)
            _PaymentOption(
              icon: Icons.qr_code,
              title: 'PAYMERA',
              subtitle: 'Scan QR or pay with wallet',
              onTap: () => onSelect(PaymentMethod.paymera),
            ),
          
          // Visa (Coming Soon)
          _PaymentOption(
            icon: Icons.credit_card,
            title: 'Visa / Mastercard',
            subtitle: 'Coming Soon',
            onTap: null, // Disabled
            isDisabled: true,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? badge;
  final Color? badgeColor;
  final bool isDisabled;
  
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDisabled ? Colors.grey.shade300 : Colors.transparent,
          ),
        ),
        tileColor: isDisabled ? Colors.grey.shade100 : null,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDisabled 
                ? Colors.grey.shade300 
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDisabled ? Colors.grey : Theme.of(context).primaryColor,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.grey : null,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor?.withValues(alpha: 0.2) ?? Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    color: badgeColor ?? Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDisabled ? Colors.grey : Colors.grey.shade600,
          ),
        ),
        trailing: isDisabled 
            ? const Icon(Icons.lock, color: Colors.grey)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}