import 'package:flutter/material.dart';
import '../../domain/enums/payment_method_type.dart';
import '../../domain/value_objects/money.dart';
import '../theme/tayyebgo_theme.dart';

class PaymentSelectionSheet extends StatefulWidget {
  final Money totalAmount;
  final Money? deliveryFee;
  final Money? commissionAmount;
  final ValueChanged<PaymentMethodType> onSelected;

  const PaymentSelectionSheet({
    super.key,
    required this.totalAmount,
    this.deliveryFee,
    this.commissionAmount,
    required this.onSelected,
  });

  @override
  State<PaymentSelectionSheet> createState() => _PaymentSelectionSheetState();
}

class _PaymentSelectionSheetState extends State<PaymentSelectionSheet> {
  PaymentMethodType _selected = PaymentMethodType.shamCash;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TayyebGoTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Payment Method', style: TayyebGoTheme.heading3),
          const SizedBox(height: 20),
          _optionTile(PaymentMethodType.stripe, Icons.credit_card, 'Visa / Mastercard', 'Secure online payment via Stripe', comingSoon: true),
          const SizedBox(height: 8),
          _optionTile(PaymentMethodType.shamCash, Icons.money, 'Sham Cash', 'Pay with cash on delivery'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: TayyebGoTheme.cardDecoration,
            child: Column(children: [
              _row('Subtotal', widget.totalAmount.format()),
              if (widget.deliveryFee != null) _row('Delivery Fee', '+${widget.deliveryFee!.format()}'),
              if (widget.commissionAmount != null) _row('Service Fee', widget.commissionAmount!.format()),
              const Divider(height: 20),
              _row('Total', widget.totalAmount.format(), bold: true),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == PaymentMethodType.stripe
                  ? null
                  : () {
                      widget.onSelected(_selected);
                      Navigator.pop(context, _selected);
                    },
              child: Text(
                _selected == PaymentMethodType.stripe
                    ? 'Coming Soon'
                    : 'Place Order — ${widget.totalAmount.format()}',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _optionTile(PaymentMethodType type, IconData icon, String title, String subtitle, {bool comingSoon = false}) {
    final selected = _selected == type;
    final effective = comingSoon ? false : selected;
    return InkWell(
      onTap: comingSoon
          ? null
          : () => setState(() => _selected = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: comingSoon
                ? TayyebGoTheme.dividerColor
                : effective
                    ? TayyebGoTheme.primaryColor
                    : TayyebGoTheme.dividerColor,
            width: effective ? 2 : 1,
          ),
          color: effective
              ? TayyebGoTheme.primaryColor.withValues(alpha: 0.05)
              : TayyebGoTheme.surfaceColor,
        ),
        child: Row(children: [
          Icon(icon,
              color: comingSoon
                  ? TayyebGoTheme.textMuted
                  : effective
                      ? TayyebGoTheme.primaryColor
                      : TayyebGoTheme.textSecondary,
              size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: comingSoon
                              ? TayyebGoTheme.textMuted
                              : effective
                                  ? TayyebGoTheme.primaryColor
                                  : TayyebGoTheme.textPrimary,
                        )),
                    if (comingSoon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: TayyebGoTheme.warningColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Coming Soon',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TayyebGoTheme.warningColor)),
                      ),
                    ],
                  ],
                ),
                Text(subtitle,
                    style: TextStyle(
                        color: comingSoon ? TayyebGoTheme.textMuted : TayyebGoTheme.caption.color)),
              ],
            ),
          ),
          if (!comingSoon)
            Radio<PaymentMethodType>(
              value: type,
              groupValue: _selected,
              activeColor: TayyebGoTheme.primaryColor,
              onChanged: (v) => setState(() => _selected = v!),
            )
          else
            Icon(Icons.lock_outline, size: 18, color: TayyebGoTheme.textMuted),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: bold ? TayyebGoTheme.textPrimary : TayyebGoTheme.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ]),
    );
  }
}
