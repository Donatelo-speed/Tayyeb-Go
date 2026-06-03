import 'dart:math';
import 'package:flutter/material.dart';

class DeliveryPinService {
  static String generatePin() {
    final random = Random();
    return (random.nextInt(9000) + 1000).toString(); // 1000-9999
  }
  
  static Future<String> createDeliveryPin(String orderId) async {
    // In production: Save to database
    // await ApiService.post('/orders/$orderId/pin', { 'pin': generatedPin });
    
    final pin = generatePin();
    debugPrint('Generated PIN $pin for order $orderId');
    return pin;
  }
  
  static Future<bool> verifyPin(String orderId, String inputPin) async {
    // In production: Check against database
    // final response = await ApiService.post('/orders/$orderId/verify-pin', { 'pin': inputPin });
    
    // Demo: Always accept for testing
    await Future.delayed(const Duration(milliseconds: 500));
    return inputPin.length == 4;
  }
}

// =====================================================
// DELIVERY PIN VERIFICATION WIDGET
// =====================================================

class DeliveryPinVerification extends StatefulWidget {
  final String orderId;
  final Function(bool) onVerificationComplete;
  
  const DeliveryPinVerification({
    super.key,
    required this.orderId,
    required this.onVerificationComplete,
  });

  @override
  State<DeliveryPinVerification> createState() => _DeliveryPinVerificationState();
}

class _DeliveryPinVerificationState extends State<DeliveryPinVerification> {
  final List<TextEditingController> _controllers = List.generate(
    4, (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  
  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
  
  String get _pin => _controllers.map((c) => c.text).join();
  
  Future<void> _verify() async {
    if (_pin.length != 4) return;
    
    setState(() => _isLoading = true);
    
    final isValid = await DeliveryPinService.verifyPin(widget.orderId, _pin);
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      widget.onVerificationComplete(isValid);
      
      if (!isValid) {
        // Clear and show error
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PIN. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF16A085)),
          SizedBox(width: 8),
          Text('Delivery Verification'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ask the customer for their 4-digit PIN to confirm delivery.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // PIN Inputs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => 
              Container(
                width: 50,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 3) {
                      _focusNodes[index + 1].requestFocus();
                    }
                    if (value.isNotEmpty && index == 3) {
                      _verify();
                    }
                  },
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// =====================================================
// DRIVER APP: PIN INPUT SCREEN
// =====================================================

class DriverPinInputScreen extends StatelessWidget {
  const DriverPinInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Delivery'),
        backgroundColor: const Color(0xFF16A085),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.pin_outlined,
              size: 64,
              color: Color(0xFF16A085),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Customer PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask the customer for their 4-digit verification PIN',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // PIN input with keypad
            _PinKeypad(
              onComplete: (pin) {
                // Verify PIN
                debugPrint('Verifying PIN: $pin');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PinKeypad extends StatefulWidget {
  final Function(String) onComplete;
  
  const _PinKeypad({required this.onComplete});

  @override
  State<_PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<_PinKeypad> {
  String _pin = '';
  
  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        widget.onComplete(_pin);
      }
    }
  }
  
  void _deleteDigit() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PIN Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => 
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length 
                    ? const Color(0xFF16A085) 
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Keypad
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 1; i <= 9; i++)
              _KeypadButton(label: '$i', onTap: () => _addDigit('$i')),
            _KeypadButton(label: '⌫', onTap: _deleteDigit, isAction: true),
            _KeypadButton(label: '0', onTap: () => _addDigit('0')),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  
  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAction ? Colors.grey.shade200 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isAction ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: isAction ? Colors.black : null,
            ),
          ),
        ),
      ),
    );
  }
}