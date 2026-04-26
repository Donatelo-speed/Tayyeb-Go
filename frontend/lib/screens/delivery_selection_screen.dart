import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'address_screen.dart';
import 'checkout_screen.dart';

class DeliverySelectionScreen extends StatefulWidget {
  const DeliverySelectionScreen({super.key});

  @override
  State<DeliverySelectionScreen> createState() => _DeliverySelectionScreenState();
}

class _DeliverySelectionScreenState extends State<DeliverySelectionScreen> {
  String _orderType = 'delivery';
  String? _selectedTimeSlot;
  List<Map<String, dynamic>> _addresses = [];
  List<Map<String, dynamic>> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // In demo mode, load from static
    setState(() {
      _addresses = [
        {'id': 1, 'label': 'Home', 'address': 'Riyadh, Al Olaya', 'is_default': true},
        {'id': 2, 'label': 'Work', 'address': 'Riyadh, King Abdullah Financial District', 'is_default': false},
      ];
      _timeSlots = [
        {'id': 1, 'time': '09:00 AM - 11:00 AM', 'available': true},
        {'id': 2, 'time': '11:00 AM - 01:00 PM', 'available': true},
        {'id': 3, 'time': '01:00 PM - 03:00 PM', 'available': true},
        {'id': 4, 'time': '03:00 PM - 05:00 PM', 'available': false},
        {'id': 5, 'time': '05:00 PM - 07:00 PM', 'available': true},
        {'id': 6, 'time': '07:00 PM - 09:00 PM', 'available': true},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Method'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type Selection
            const Text('How do you want your order?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _OrderTypeCard(
              icon: Icons.local_shipping,
              title: 'Delivery',
              description: 'Get it delivered to your door',
              isSelected: _orderType == 'delivery',
              onTap: () => setState(() => _orderType = 'delivery'),
            ),
            const SizedBox(height: 12),
            _OrderTypeCard(
              icon: Icons.store,
              title: 'Pickup',
              description: 'Pick up from store',
              isSelected: _orderType == 'pickup',
              onTap: () => setState(() => _orderType = 'pickup'),
            ),

            if (_orderType == 'delivery') ...[
              const SizedBox(height: 32),
              // Address Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())), child: const Text('Manage')),
                ],
              ),
              const SizedBox(height: 12),
              ...(_addresses.map((address) => _AddressRadioCard(
                address: address,
                isSelected: address['is_default'] == true,
                onTap: () => _selectAddress(address['id']),
              ))),

              const SizedBox(height: 32),
              // Time Slot Selection
              const Text('Delivery Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) => _TimeSlotChip(
                  slot: slot,
                  isSelected: _selectedTimeSlot == slot['time'],
                  onTap: slot['available'] == true ? () => setState(() => _selectedTimeSlot = slot['time']) : null,
                )).toList(),
              ),
            ],

            if (_orderType == 'pickup') ...[
              const SizedBox(height: 32),
              // Store Location
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('OmniMarket Store', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Riyadh, Al Olaya District', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Open until 11:00 PM', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.map), onPressed: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Pickup Time
              const Text('Pickup Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) => _TimeSlotChip(
                  slot: slot,
                  isSelected: _selectedTimeSlot == slot['time'],
                  onTap: slot['available'] == true ? () => setState(() => _selectedTimeSlot = slot['time']) : null,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _orderType == 'delivery' && _selectedTimeSlot == null
                ? null
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Continue to Checkout'),
          ),
        ),
      ),
    );
  }

  void _selectAddress(int id) {
    setState(() {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = {..._addresses[i], 'is_default': _addresses[i]['id'] == id};
      }
    });
  }
}

class _OrderTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _AddressRadioCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressRadioCard({required this.address, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(address['address'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final Map<String, dynamic> slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TimeSlotChip({required this.slot, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final available = slot['available'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : (available ? Colors.grey[100] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: !available ? Border.all(color: Colors.grey[300]!) : null,
        ),
        child: Text(
          slot['time'],
          style: TextStyle(
            color: isSelected ? Colors.white : (available ? Colors.black87 : Colors.grey),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}