import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order.dart';
import '../services/realtime_service.dart';
import '../theme/omni_theme.dart';
import '../utils/haptic_utils.dart';

class DriverDispatchOverlay extends StatefulWidget {
  final OrderBroadcast broadcast;
  final Driver currentDriver;
  final Function(String orderId, Driver driver, bool accepted) onResponse;

  const DriverDispatchOverlay({
    super.key,
    required this.broadcast,
    required this.currentDriver,
    required this.onResponse,
  });

  @override
  State<DriverDispatchOverlay> createState() => _DriverDispatchOverlayState();
}

class _DriverDispatchOverlayState extends State<DriverDispatchOverlay>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _timerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  int _remainingSeconds = 30;
  bool _isExpired = false;
  Timer? _secondTimer;

  @override
  void initState() {
    super.initState();

    _remainingSeconds = widget.broadcast.remainingSeconds;

    _timerController = AnimationController(
      duration: Duration(seconds: _remainingSeconds),
      vsync: this,
    );

    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _startTimer();
    _slideController.forward();

    HapticUtils.heavyImpact();
  }

  void _startTimer() {
    _timerController.forward();

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isExpired = true;
          _onDecline();
        }
      });
    });
  }

  void _onAccept() {
    HapticUtils.mediumImpact();
    widget.onResponse(
      widget.broadcast.order.id,
      widget.currentDriver,
      true,
    );
    Navigator.of(context).pop();
  }

  void _onDecline() {
    HapticUtils.lightImpact();
    widget.onResponse(
      widget.broadcast.order.id,
      widget.currentDriver,
      false,
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _secondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.broadcast.order;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        color: Colors.black54,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _isExpired ? Colors.red : OmniTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isExpired
                                    ? Colors.red
                                    : OmniTheme.primaryColor)
                                .withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpired ? 'EXPIRED' : '$_remainingSeconds',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (!_isExpired)
                            const Text(
                              'SECONDS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                                letterSpacing: 4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: OmniTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#${order.orderNumber}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: OmniTheme.primaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: order.isHighPriority
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  order.isHighPriority
                                      ? Icons.priority_high
                                      : Icons.check_circle_outline,
                                  size: 16,
                                  color: order.isHighPriority
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.isHighPriority ? 'URGENT' : 'Normal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: order.isHighPriority
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NEW ORDER',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${order.itemCount} items • ${order.formattedTotal}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.location_on,
                        'Distance',
                        '${widget.broadcast.distanceKm.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.attach_money,
                        'Est. Payout',
                        '\$${widget.broadcast.estimatedPayout.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.store,
                        'From',
                        'Main Warehouse',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.home,
                        'To',
                        order.deliveryAddress.label,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isExpired ? null : _onDecline,
                              icon: const Icon(Icons.close),
                              label: const Text('DECLINE'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.red, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isExpired ? null : _onAccept,
                              icon: const Icon(Icons.check),
                              label: const Text('ACCEPT'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: OmniTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: OmniTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: OmniTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DispatchBroadcastDialog {
  static void show(
    BuildContext context, {
    required OrderBroadcast broadcast,
    required Driver currentDriver,
    required Function(String orderId, Driver driver, bool accepted) onResponse,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order Broadcast',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return DriverDispatchOverlay(
          broadcast: broadcast,
          currentDriver: currentDriver,
          onResponse: onResponse,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

class OrderAcceptanceScreen extends StatefulWidget {
  final OrderBroadcast broadcast;
  final Driver currentDriver;
  final Function(String orderId, Driver driver, bool accepted) onResponse;

  const OrderAcceptanceScreen({
    super.key,
    required this.broadcast,
    required this.currentDriver,
    required this.onResponse,
  });

  @override
  State<OrderAcceptanceScreen> createState() => _OrderAcceptanceScreenState();
}

class _OrderAcceptanceScreenState extends State<OrderAcceptanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmniTheme.primaryColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final remaining = (30 * (1 - _controller.value)).ceil();
            return Column(
              children: [
                LinearProgressIndicator(
                  value: _controller.value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                Expanded(child: child),
              ],
            );
          },
          child: DriverDispatchOverlay(
            broadcast: widget.broadcast,
            currentDriver: widget.currentDriver,
            onResponse: widget.onResponse,
          ),
        ),
      ),
    );
  }
}