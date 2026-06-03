import 'package:flutter/material.dart';

class KitchenSettings {
  bool smartModeEnabled;
  bool autoAcceptOrders;
  bool soundEnabled;
  int soundVolume;
  String? customSoundUrl;
  bool printerEnabled;
  String? printerName;
  String? printerIp;
  int printerPort;
  bool alertForPickup;
  bool alertForDelivery;

  KitchenSettings({
    this.smartModeEnabled = false,
    this.autoAcceptOrders = false,
    this.soundEnabled = true,
    this.soundVolume = 100,
    this.customSoundUrl,
    this.printerEnabled = false,
    this.printerName,
    this.printerIp,
    this.printerPort = 9100,
    this.alertForPickup = true,
    this.alertForDelivery = true,
  });

  factory KitchenSettings.fromJson(Map<String, dynamic> json) {
    return KitchenSettings(
      smartModeEnabled: json['smartModeEnabled'] ?? false,
      autoAcceptOrders: json['autoAcceptOrders'] ?? false,
      soundEnabled: json['soundEnabled'] ?? true,
      soundVolume: json['soundVolume'] ?? 100,
      customSoundUrl: json['customSoundUrl'],
      printerEnabled: json['printerEnabled'] ?? false,
      printerName: json['printerName'],
      printerIp: json['printerIp'],
      printerPort: json['printerPort'] ?? 9100,
      alertForPickup: json['alertForPickup'] ?? true,
      alertForDelivery: json['alertForDelivery'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'smartModeEnabled': smartModeEnabled,
    'autoAcceptOrders': autoAcceptOrders,
    'soundEnabled': soundEnabled,
    'soundVolume': soundVolume,
    'customSoundUrl': customSoundUrl,
    'printerEnabled': printerEnabled,
    'printerName': printerName,
    'printerIp': printerIp,
    'printerPort': printerPort,
    'alertForPickup': alertForPickup,
    'alertForDelivery': alertForDelivery,
  };
}

class KitchenSettingsProvider extends ChangeNotifier {
  KitchenSettings _settings = KitchenSettings();
  bool _isLoading = false;

  KitchenSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // Convenience getters
  bool get isSmartModeEnabled => _settings.smartModeEnabled;
  bool get isAutoAcceptEnabled => _settings.autoAcceptOrders;
  bool get isPrinterEnabled => _settings.printerEnabled;

  Future<void> loadSettings(String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));

      // Mock settings for demo
      _settings = KitchenSettings(
        smartModeEnabled: true,
        autoAcceptOrders: true,
        soundEnabled: true,
        soundVolume: 80,
        printerEnabled: true,
        printerName: 'Thermal-Printer-01',
        printerIp: '192.168.1.100',
        printerPort: 9100,
      );
    } catch (e) {
      debugPrint('Failed to load kitchen settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setSmartMode(bool enabled) async {
    _settings.smartModeEnabled = enabled;
    if (enabled) {
      // When smart mode is on, auto-accept should also be on
      _settings.autoAcceptOrders = true;
    }
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setAutoAccept(bool enabled) async {
    _settings.autoAcceptOrders = enabled;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _settings.soundEnabled = enabled;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setSoundVolume(int volume) async {
    _settings.soundVolume = volume;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setPrinterEnabled(bool enabled) async {
    _settings.printerEnabled = enabled;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setPrinterConfig({String? name, String? ip, int? port}) async {
    if (name != null) _settings.printerName = name;
    if (ip != null) _settings.printerIp = ip;
    if (port != null) _settings.printerPort = port;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setAlertForPickup(bool enabled) async {
    _settings.alertForPickup = enabled;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setAlertForDelivery(bool enabled) async {
    _settings.alertForDelivery = enabled;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    // In production: Save to API
    // await ApiService.put('/kitchen/settings', _settings.toJson());
    debugPrint('Saving kitchen settings: ${_settings.toJson()}');
  }
}

// =====================================================
// SMART KITCHEN MODE WIDGET
// =====================================================

class KitchenSettingsDialog extends StatelessWidget {
  final KitchenSettingsProvider provider;

  const KitchenSettingsDialog({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final settings = provider.settings;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.kitchen, color: Color(0xFF16A085)),
          SizedBox(width: 8),
          Text('Kitchen Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Mode Section
            const Text(
              'Smart Kitchen Mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Enable Smart Mode'),
              subtitle: const Text('Optimize for busy hours'),
              value: settings.smartModeEnabled,
              onChanged: (v) => provider.setSmartMode(v),
              activeThumbColor: const Color(0xFF16A085),
            ),

            if (settings.smartModeEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-Accept Orders'),
                      subtitle: const Text(
                        'Automatically accept incoming orders',
                      ),
                      value: settings.autoAcceptOrders,
                      onChanged: (v) => provider.setAutoAccept(v),
                    ),
                    ListTile(
                      title: const Text('Sound Volume'),
                      subtitle: Slider(
                        value: settings.soundVolume.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 10,
                        label: '${settings.soundVolume}%',
                        onChanged: (v) => provider.setSoundVolume(v.round()),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 32),

            // Printer Section
            const Text(
              'Thermal Printer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Enable Printer'),
              subtitle: const Text('Auto-print invoices'),
              value: settings.printerEnabled,
              onChanged: (v) => provider.setPrinterEnabled(v),
              activeThumbColor: const Color(0xFF16A085),
            ),

            if (settings.printerEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Printer Name',
                        hintText: 'e.g., Kitchen-Printer',
                      ),
                      controller: TextEditingController(
                        text: settings.printerName,
                      ),
                      onSubmitted: (v) => provider.setPrinterConfig(name: v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'IP Address',
                        hintText: 'e.g., 192.168.1.100',
                      ),
                      controller: TextEditingController(
                        text: settings.printerIp,
                      ),
                      onSubmitted: (v) => provider.setPrinterConfig(ip: v),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 32),

            // Alert Settings
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Alert for Pickup Orders'),
              value: settings.alertForPickup,
              onChanged: (v) => provider.setAlertForPickup(v),
            ),
            SwitchListTile(
              title: const Text('Alert for Delivery Orders'),
              value: settings.alertForDelivery,
              onChanged: (v) => provider.setAlertForDelivery(v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
