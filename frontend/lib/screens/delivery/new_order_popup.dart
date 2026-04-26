import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DriverNewOrderPopup extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const DriverNewOrderPopup({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<DriverNewOrderPopup> createState() => _DriverNewOrderPopupState();
}

class _DriverNewOrderPopupState extends State<DriverNewOrderPopup> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _countdownTimer;
  int _secondsLeft = 30;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);
    _animationController.forward();
    
    _startCountdown();
    _playSound();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsLeft--;
        });
        if (_secondsLeft <= 0) {
          timer.cancel();
          widget.onDecline();
        }
      }
    });
  }

  void _playSound() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    
    // Play notification sound
    const androidDetails = AndroidNotificationDetails(
      'new_order_channel',
      'New Order Notifications',
      channelDescription: 'Notifications for new order alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);
    
    await _notifications.show(0, '🚚 New Order!', 'Order #${widget.order['id']} is waiting for you!', details);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / 30;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with countdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_shipping, color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      const Text('NEW ORDER!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Countdown timer
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          Text(
                            '$_secondsLeft',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Order details
                _OrderDetailRow(label: 'Order #', value: '#${widget.order['id']}'),
                _OrderDetailRow(label: 'Items', value: '${widget.order['items_count']} items'),
                _OrderDetailRow(label: 'Distance', value: '${widget.order['distance'] ?? '2.5'} km'),
                _OrderDetailRow(
                  label: 'Earnings', 
                  value: 'SAR ${widget.order['earnings']?.toStringAsFixed(2) ?? '15.00'}',
                  valueStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                
                // Customer info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.order['customer_name'] ?? 'Ahmed K.', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(widget.order['address'] ?? 'Riyadh, Al Olaya', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onDecline,
                        icon: const Icon(Icons.close),
                        label: const Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red, width: 2),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onAccept,
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _OrderDetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}