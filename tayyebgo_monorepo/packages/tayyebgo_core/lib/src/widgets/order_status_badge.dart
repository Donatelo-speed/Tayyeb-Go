import 'package:flutter/material.dart';
import '../../presentation/theme/app_radius.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final double padding;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = 6,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: padding + 2, vertical: padding),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: fontSize + 2, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _config(String s) {
    switch (s) {
      case 'placed':
      case 'pending':
        return _StatusConfig(Colors.orange, Icons.schedule, 'Placed');
      case 'accepted':
        return _StatusConfig(Colors.blue, Icons.check_circle_outline, 'Accepted');
      case 'preparing':
        return _StatusConfig(Colors.purple, Icons.restaurant, 'Preparing');
      case 'ready':
      case 'ready_for_driver':
        return _StatusConfig(Colors.teal, Icons.checklist, 'Ready');
      case 'dispatched':
      case 'picked_up':
        return _StatusConfig(Colors.indigo, Icons.delivery_dining, 'Dispatched');
      case 'delivered':
        return _StatusConfig(Colors.green, Icons.task_alt, 'Delivered');
      case 'cancelled':
        return _StatusConfig(Colors.red, Icons.cancel, 'Cancelled');
      default:
        return _StatusConfig(Colors.grey, Icons.help_outline, s);
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusConfig(this.color, this.icon, this.label);
}
