import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';

class DriverNewOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const DriverNewOrderScreen({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<DriverNewOrderScreen> createState() => _DriverNewOrderScreenState();
}

class _DriverNewOrderScreenState extends State<DriverNewOrderScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  int _secondsLeft = 30;
  Timer? _countdownTimer;
  bool _isLoading = false;
  GoogleMapController? _mapController;
  
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for urgency
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    
    // Slide in animation
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
    
    // Start countdown and play sound
    _startCountdown();
    _playAlertSound();
  }

  void _startCountdown() {
    // Urgency haptic
    HapticFeedback.heavyImpact();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsLeft--;
        });
        
        // Urgency feedback in last 10 seconds
        if (_secondsLeft <= 10 && _secondsLeft > 0) {
          HapticFeedback.lightImpact();
        }
        
        if (_secondsLeft <= 0) {
          timer.cancel();
          widget.onDecline();
        }
      }
    });
  }

  void _playAlertSound() async {
    // Play notification sound - in production use audioplayers
    // await AudioPlayer().play(AssetSource('sounds/new_order.mp3'));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Top Timer Bar
            _buildTimerBar(),
            
            // Map Area
            Expanded(
              flex: 2,
              child: _buildMapArea(order),
            ),
            
            // Order Details Card
            Expanded(
              flex: 3,
              child: _buildOrderCard(order, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBar() {
    final progress = _secondsLeft / 30;
    final urgencyColor = _secondsLeft > 15 ? Colors.green : _secondsLeft > 5 ? Colors.orange : Colors.red;
    
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    const Text('NEW ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Circular Timer
          ScaleTransition(
            scale: _pulseAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(urgencyColor),
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: urgencyColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            _secondsLeft > 0 ? 'Tap Accept or Decline' : 'Order Expired',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Placeholder map (add Google Maps API in production)
            Container(
              color: const Color(0xFF1A1A2E),
              child: CustomPaint(
                size: Size.infinite,
                painter: _MapGridPainter(),
              ),
            ),
            
            // Simulated locations
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Customer location marker
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 40),
                  
                  // Driver location marker
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            
            // Distance badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('${order['distance'] ?? '2.5'} km away', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            
            // Earnings badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.white, size: 16),
                    Text('Earn SAR ${(order['earnings'] ?? 15.00).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info
          _InfoRow(label: 'Order', value: '#${order['id']}'),
          _InfoRow(label: 'Items', value: '${order['items_count'] ?? 3} items'),
          _InfoRow(label: 'Distance', value: '${order['distance'] ?? '2.5'} km'),
          _InfoRow(label: 'Est. Time', value: '${order['eta'] ?? '15'} min'),
          
          const Divider(height: 24),
          
          // Customer Info
          const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['customer_name'] ?? 'Ahmed K.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      order['address'] ?? 'Riyadh, Al Olaya District',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () {}, // Call customer
              ),
            ],
          ),
          
          const Spacer(),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : widget.onDecline,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Decline', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleAccept,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Accepting...' : 'Accept Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    widget.onAccept();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw grid lines
    for (var i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    for (var i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}