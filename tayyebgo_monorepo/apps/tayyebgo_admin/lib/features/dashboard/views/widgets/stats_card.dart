import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../shared.dart';

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
          gradient: AppGradients.statCyan,
          subtitle: 'Of $driverCount registered',
        );
      },
    );
  }
}
