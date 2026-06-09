import 'package:flutter/material.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../shared.dart';

const _cyanGradient = LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)], begin: Alignment.topLeft, end: Alignment.bottomRight);

class DriverStatCard extends StatelessWidget {
  final int driverCount;
  const DriverStatCard({required this.driverCount});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirestoreService.instance.watchDriversRaw(limit: 200),
      builder: (context, snap) {
        final online = snap.hasData ? snap.data!.where((d) {
          return d['isOnline'] == true || d['status'] == 'active';
        }).length : (driverCount * 0.6).toInt();
        return StatCard(
          title: 'Online Drivers',
          value: '$online',
          icon: Icons.delivery_dining,
          gradient: _cyanGradient,
          subtitle: 'Of $driverCount registered',
        );
      },
    );
  }
}
