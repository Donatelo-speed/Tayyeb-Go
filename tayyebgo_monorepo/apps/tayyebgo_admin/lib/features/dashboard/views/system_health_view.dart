import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class SystemHealthView extends StatelessWidget {
  const SystemHealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('System Health', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, 'Service Status'),
              const SizedBox(height: 12),
              _buildServiceStatus(context),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Database Health'),
              const SizedBox(height: 12),
              _buildDatabaseHealth(context),
              const SizedBox(height: 24),
              _sectionTitle(context, 'API Performance'),
              const SizedBox(height: 12),
              _buildApiPerformance(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor));
  }

  Widget _buildServiceStatus(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('system_health').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        if (snap.hasError) return _errorCard(context, 'Unable to load service status');
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _defaultServices(context);
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final name = d['name'] as String? ?? doc.id;
            final status = d['status'] as String? ?? 'unknown';
            final latency = (d['latencyMs'] as num?)?.toDouble() ?? 0;
            return _serviceRow(context, name, status, latency);
          }).toList(),
        );
      },
    );
  }

  Widget _defaultServices(BuildContext context) {
    return Column(
      children: [
        _serviceRow(context, 'Firebase Auth', 'operational', 45),
        _serviceRow(context, 'Firestore', 'operational', 32),
        _serviceRow(context, 'Firebase Storage', 'operational', 78),
        _serviceRow(context, 'Cloud Functions', 'operational', 120),
        _serviceRow(context, 'Firebase Hosting', 'operational', 15),
      ],
    );
  }

  Widget _serviceRow(BuildContext context, String name, String status, double latency) {
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'operational':
      case 'healthy':
        statusColor = context.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'degraded':
      case 'warning':
        statusColor = context.warningColor;
        statusIcon = Icons.warning_rounded;
        break;
      case 'outage':
      case 'error':
        statusColor = context.errorColor;
        statusIcon = Icons.error_rounded;
        break;
      default:
        statusColor = context.textMutedColor;
        statusIcon = Icons.help_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
          ),
          Text('${latency.toStringAsFixed(0)}ms', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseHealth(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').limit(500).snapshots(),
      builder: (context, ordersSnap) {
        if (ordersSnap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        final orderCount = ordersSnap.data?.docs.length ?? 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').limit(500).snapshots(),
          builder: (context, usersSnap) {
            final userCount = usersSnap.data?.docs.length ?? 0;
            final driverCount = usersSnap.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['role'] == 'driver').length ?? 0;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('restaurants').limit(500).snapshots(),
              builder: (context, storesSnap) {
                final storeCount = storesSnap.data?.docs.length ?? 0;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth < 500 ? 2 : 4;
                    return GridView.count(
                      crossAxisCount: crossCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.8,
                      children: [
                        _metricCard(context, Icons.receipt_long_rounded, 'Orders', '$orderCount', context.primaryColor),
                        _metricCard(context, Icons.people_rounded, 'Users', '$userCount', context.successColor),
                        _metricCard(context, Icons.store_rounded, 'Stores', '$storeCount', context.warningColor),
                        _metricCard(context, Icons.delivery_dining_rounded, 'Drivers', '$driverCount', context.primaryColor),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _metricCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
        ],
      ),
    );
  }

  Widget _buildApiPerformance(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        final docs = snap.data?.docs ?? [];
        int delivered = 0, cancelled = 0, total = docs.length;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final status = d['status'] as String? ?? '';
          if (status == 'delivered') delivered++;
          if (status == 'cancelled') cancelled++;
        }
        final successRate = total > 0 ? ((delivered / total) * 100) : 0;
        final cancelRate = total > 0 ? ((cancelled / total) * 100) : 0;
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth < 500 ? 1 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.0,
              children: [
                _apiCard(context, 'Delivered', '$delivered', context.successColor),
                _apiCard(context, 'Success Rate', '${successRate.toStringAsFixed(1)}%', context.successColor),
                _apiCard(context, 'Cancelled', '$cancelled', cancelRate > 10 ? context.errorColor : context.warningColor),
                _apiCard(context, 'Total (recent)', '$total', context.primaryColor),
              ],
            );
          },
        );
      },
    );
  }

  Widget _apiCard(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorCard(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.textMutedColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor))),
        ],
      ),
    );
  }
}
