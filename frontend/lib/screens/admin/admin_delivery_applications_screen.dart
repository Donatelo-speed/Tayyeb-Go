import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/omni_theme.dart';
import '../../main.dart';

class AdminDeliveryApplicationsScreen extends StatefulWidget {
  const AdminDeliveryApplicationsScreen({super.key});

  @override
  State<AdminDeliveryApplicationsScreen> createState() => _AdminDeliveryApplicationsScreenState();
}

class _AdminDeliveryApplicationsScreenState extends State<AdminDeliveryApplicationsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      _applications = await _api.getDeliveryApplications();
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _respondToApplication(int id, String status) async {
    try {
      await _api.respondToApplication(id, status);
      await _loadApplications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? 'Application approved!' : 'Application rejected'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleBox>();
    final isArabic = locale.isArabic;

    String t(String en, String ar) => isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Delivery Applications', 'طلبات السائقين')),
        backgroundColor: OmniTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(t('No applications', 'لا توجد طلبات'), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      return _buildApplicationCard(_applications[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildApplicationCard(dynamic app) {
    final locale = context.read<LocaleBox>();
    final isArabic = locale.isArabic;

    String t(String en, String ar) => isArabic ? ar : en;

    String status = app['status'] ?? 'pending';
    Color statusColor;
    if (status == 'pending') statusColor = Colors.orange;
    else if (status == 'approved') statusColor = Colors.green;
    else statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: OmniTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        (app['firstName'] ?? 'A')[0].toString().toUpperCase(),
                        style: const TextStyle(color: OmniTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${app['firstName'] ?? ''} ${app['middleName'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (app['nickname'] != null && app['nickname'].toString().isNotEmpty)
                          Text(
                            app['nickname'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
                Chip(
                  label: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10)),
                  backgroundColor: statusColor.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Info
            _buildInfoRow(Icons.email, app['email'] ?? ''),
            _buildInfoRow(Icons.phone, app['phone'] ?? ''),
            if (app['altPhone'] != null) _buildInfoRow(Icons.phone_android, app['altPhone']),
            _buildInfoRow(Icons.location_city, app['city'] ?? ''),
            _buildInfoRow(Icons.directions_car, app['vehicleType'] ?? ''),
            if (app['vehicleDetails'] != null) _buildInfoRow(Icons.info, app['vehicleDetails']),

            const SizedBox(height: 16),

            // Actions
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToApplication(app['id'], 'rejected'),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text(t('Reject', 'رفض'), style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToApplication(app['id'], 'approved'),
                      icon: const Icon(Icons.check),
                      label: Text(t('Approve', 'موافقة')),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}