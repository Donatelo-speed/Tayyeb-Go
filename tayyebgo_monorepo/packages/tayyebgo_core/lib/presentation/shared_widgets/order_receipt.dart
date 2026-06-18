import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Shared Order Receipt Widget - used across all 4 apps
class OrderReceipt extends StatelessWidget {
  final String orderId;
  final String restaurantName;
  final List<ReceiptItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod;
  final String? deliveryAddress;
  final String? specialInstructions;
  final DateTime orderDate;
  final String? driverName;
  final String? customerName;
  final bool showDriverInfo;
  final bool showCustomerInfo;

  const OrderReceipt({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.deliveryAddress,
    this.specialInstructions,
    required this.orderDate,
    this.driverName,
    this.customerName,
    this.showDriverInfo = false,
    this.showCustomerInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: AppRadius.brXl,
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.border,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildOrderInfo(context),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildItems(context),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildSummary(context),
          if (specialInstructions != null && specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInstructions(context),
          ],
          if (showDriverInfo && driverName != null) ...[
            const SizedBox(height: 16),
            _buildDriverInfo(context),
          ],
          if (showCustomerInfo && customerName != null) ...[
            const SizedBox(height: 16),
            _buildCustomerInfo(context),
          ],
          const SizedBox(height: 20),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryHover],
            ),
            borderRadius: AppRadius.brLg,
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Receipt',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : const Color(0xFF0A0A0A),
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                restaurantName,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppRadius.brMd,
          ),
          child: Text(
            'COMPLETED',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: AppColors.success,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfo(BuildContext context) {
    return Row(
      children: [
        _infoColumn('Order ID', '#${orderId.substring(0, 8).toUpperCase()}'),
        const SizedBox(width: 24),
        _infoColumn('Date', _formatDate(orderDate)),
        const SizedBox(width: 24),
        _infoColumn('Payment', paymentMethod),
      ],
    );
  }

  Widget _infoColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x ${item.name}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textPrimary
                            : const Color(0xFF0A0A0A),
                      ),
                    ),
                    if (item.modifiers != null && item.modifiers!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.modifiers!,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Column(
      children: [
        _summaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _summaryRow('Delivery Fee', deliveryFee == 0 ? 'Free' : '\$${deliveryFee.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _summaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Discount', '-\$${discount.toStringAsFixed(2)}', valueColor: AppColors.success),
        ],
        const SizedBox(height: 12),
        Container(
          height: 1,
          color: AppColors.border,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimary
                    : const Color(0xFF0A0A0A),
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.note_alt_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              specialInstructions!,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.driverAccent.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.driverAccent.withValues(alpha: 0.15),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(Icons.delivery_dining_rounded, size: 18, color: AppColors.driverAccent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivered by',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                driverName!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order by',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                customerName!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Thank you for your order!',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TayyebGo — Delivery Made Simple',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final String? modifiers;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.modifiers,
  });
}
