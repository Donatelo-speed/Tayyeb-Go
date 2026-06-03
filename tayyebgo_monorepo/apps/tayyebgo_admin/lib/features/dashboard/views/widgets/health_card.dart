import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:tayyebgo_multi_tenant/tayyebgo_multi_tenant.dart';
import '../shared.dart';
import 'data_models.dart';

class OperationsHealthCard extends StatelessWidget {
  final AdminStatsProvider stats;
  final TodayData todayData;
  final double avgPrepTime;

  const OperationsHealthCard({required this.stats, required this.todayData, required this.avgPrepTime});

  @override
  Widget build(BuildContext context) {
    final issues = <String>[];
    if (stats.stats.activeOrders > 50) issues.add('${stats.stats.activeOrders} active orders');
    if (todayData.cancelled > 5) issues.add('${todayData.cancelled} cancellations today');
    if (stats.stats.restaurantCount < 5) issues.add('Low store count (${stats.stats.restaurantCount})');
    if (avgPrepTime > 30) issues.add('High avg prep time (${avgPrepTime.toStringAsFixed(0)}min)');

    final healthScore = _computeHealthScore();
    final healthLabel = healthScore >= 80 ? 'Healthy' : healthScore >= 50 ? 'Fair' : 'Critical';
    final healthColor = healthScore >= 80 ? AppColors.success : healthScore >= 50 ? AppColors.warning : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Operations Health', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(healthLabel, style: TextStyle(color: healthColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: healthScore / 100,
              backgroundColor: context.dividerColor.withValues(alpha: 0.3),
              color: healthColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _healthMetric(context, '${stats.stats.restaurantCount}', 'Active Stores', Icons.store),
              _healthMetric(context, '${stats.stats.driverCount}', 'Total Drivers', Icons.delivery_dining),
              _healthMetric(context, '${todayData.delivered}', 'Delivered Today', Icons.check_circle),
              _healthMetric(context, '${avgPrepTime.toStringAsFixed(0)}min', 'Avg Prep Time', Icons.timer),
            ],
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issues.join(' • '),
                      style: TextStyle(fontSize: 12, color: AppColors.warning.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _computeHealthScore() {
    int score = 100;
    if (stats.stats.activeOrders > 50) score -= 15;
    if (stats.stats.activeOrders > 100) score -= 10;
    if (todayData.cancelled > 5) score -= 10;
    if (todayData.cancelled > 10) score -= 10;
    if (stats.stats.restaurantCount < 5) score -= 15;
    if (stats.stats.restaurantCount < 10) score -= 10;
    if (avgPrepTime > 30) score -= 10;
    if (avgPrepTime > 45) score -= 10;
    if (stats.stats.userCount < 100) score -= 10;
    return score.clamp(0, 100);
  }

  Widget _healthMetric(BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: context.textMutedColor),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
          Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
        ],
      ),
    );
  }
}
