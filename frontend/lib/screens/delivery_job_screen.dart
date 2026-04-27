import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../theme/omni_theme.dart';
import '../services/api_service.dart';

class DeliveryJobScreen extends StatefulWidget {
  const DeliveryJobScreen({super.key});

  @override
  State<DeliveryJobScreen> createState() => _DeliveryJobScreenState();
}

class _DeliveryJobScreenState extends State<DeliveryJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formKeys = {
    'firstName': TextEditingController(),
    'middleName': TextEditingController(),
    'nickname': TextEditingController(),
    'phone': TextEditingController(),
    'altPhone': TextEditingController(),
    'email': TextEditingController(),
    'city': TextEditingController(),
    'vehicleType': TextEditingController(),
    'vehicleDetails': TextEditingController(),
  };
  bool _isLoading = false;
  String? _selectedCity;
  String? _selectedVehicle;
  final ApiService _api = ApiService();

  final List<String> _syrianCities = [
    'Damascus', 'Aleppo', 'Homs', 'Hama', 'Latakia', 'Tartus',
    'Idlib', 'Daraa', 'Al-Hasakah', 'Deir ez-Zor', 'Raqqa', 'Qamishli',
  ];

  final List<String> _vehicleTypes = [
    'Bicycle', 'Motorcycle', 'Car', 'Van',
  ];

  @override
  void dispose() {
    for (var c in _formKeys.values) c.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _api.submitDeliveryApplication({
        'firstName': _formKeys['firstName']!.text,
        'middleName': _formKeys['middleName']!.text,
        'nickname': _formKeys['nickname']!.text,
        'phone': _formKeys['phone']!.text,
        'altPhone': _formKeys['altPhone']!.text,
        'email': _formKeys['email']!.text,
        'city': _selectedCity,
        'vehicleType': _selectedVehicle,
        'vehicleDetails': _formKeys['vehicleDetails']!.text,
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSuccessDialog() {
    final locale = context.read<LocaleBox>();
    final isArabic = locale.isArabic;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OmniTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: OmniTheme.successColor, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'Application Submitted!' : 'تم تقديم الطلب!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'We will review your application and contact you soon'
                  : 'سنراجع طلبك ونتواصل معك قريباً',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OmniTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isArabic ? 'Done' : 'تم'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 400;

    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Apply as Driver', 'التقدم كسائق')),
        backgroundColor: OmniTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 14 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmall ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [OmniTheme.primaryColor, OmniTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(Icons.delivery_dining, size: isSmall ? 36 : 44, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      t('Join Our Team', 'انضم فريقنا'),
                      style: TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('Earn money delivering', 'اربح المال بالتوصيل'),
                      style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmall ? 16 : 20),

              // Personal Info
              _buildSectionTitle(t('Personal Info', 'المعلومات'), isSmall),
              SizedBox(height: 8),
              _buildTextField('firstName', t('First Name', 'الاسم'), Icons.person, isSmall),
              SizedBox(height: 8),
              _buildTextField('middleName', t('Middle Name', 'الاسم الأوسط'), Icons.person_outline, isSmall),
              SizedBox(height: 8),
              _buildTextField('nickname', t('Nickname', 'اللقب'), Icons.badge, isSmall, required: false),
              SizedBox(height: isSmall ? 12 : 16),

              // Contact
              _buildSectionTitle(t('Contact', 'الاتصال'), isSmall),
              SizedBox(height: 8),
              _buildTextField('phone', t('Phone', 'الهاتف'), Icons.phone, isSmall, keyboard: TextInputType.phone),
              SizedBox(height: 8),
              _buildTextField('altPhone', t('Alt Phone', 'بديل'), Icons.phone_android, isSmall, keyboard: TextInputType.phone, required: false),
              SizedBox(height: 8),
              _buildTextField('email', t('Email', 'البريد'), Icons.email, isSmall, keyboard: TextInputType.emailAddress),
              SizedBox(height: isSmall ? 12 : 16),

              // Location
              _buildSectionTitle(t('Location', 'الموقع'), isSmall),
              SizedBox(height: 8),
              _buildDropdown('city', _syrianCities, t('City', 'المدينة'), Icons.location_city, isSmall),
              SizedBox(height: isSmall ? 12 : 16),

              // Vehicle
              _buildSectionTitle(t('Vehicle', 'المركبة'), isSmall),
              SizedBox(height: 8),
              _buildDropdown('vehicle', _vehicleTypes, t('Vehicle Type', 'النوع'), Icons.directions_car, isSmall),
              SizedBox(height: 8),
              _buildTextField('vehicleDetails', t('Details', 'التفاصيل'), Icons.info_outline, isSmall, required: false),
              SizedBox(height: isSmall ? 16 : 20),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OmniTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    shadowColor: OmniTheme.primaryColor.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(t('Submit', 'تقديم'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmall) {
    return Text(title, style: TextStyle(fontSize: isSmall ? 14 : 15, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(String key, String label, IconData icon, bool isSmall, {TextInputType? keyboard, bool required = true}) {
    return TextFormField(
      controller: _formKeys[key],
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14),
     decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: OmniTheme.primaryColor)),
      ),
      validator: required ? (v) => v?.isEmpty ?? true ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown(String key, List<String> items, String label, IconData icon, bool isSmall) {
    return DropdownButtonFormField<String>(
      value: key == 'city' ? _selectedCity : _selectedVehicle,
      style: TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
      items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) {
        setState(() {
          if (key == 'city') _selectedCity = v; else _selectedVehicle = v;
        });
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}