import 'package:cloud_firestore/cloud_firestore.dart';

class DemandForecast {
  final String hourLabel;
  final int predictedOrders;
  final double confidence;
  final String demandLevel;

  const DemandForecast({
    required this.hourLabel,
    required this.predictedOrders,
    required this.confidence,
    required this.demandLevel,
  });
}

class DemandPredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Predict demand for the next 24 hours based on historical order patterns.
  Future<List<DemandForecast>> predictNext24Hours({String? restaurantId}) async {
    try {
      final hourlyData = await _getHistoricalHourlyData(restaurantId: restaurantId);
      if (hourlyData.isEmpty) return _getDefaultForecast();

      final now = DateTime.now();
      final forecasts = <DemandForecast>[];

      for (int h = 0; h < 24; h++) {
        final targetHour = (now.hour + h) % 24;
        final dayOfWeek = now.add(Duration(hours: h)).weekday;

        final dayAvg = hourlyData
            .where((d) => d['hour'] == targetHour && d['dayOfWeek'] == dayOfWeek)
            .map((d) => (d['avgOrders'] as num).toDouble())
            .fold<double>(0, (a, b) => a + b);

        final overallAvg = hourlyData
            .where((d) => d['hour'] == targetHour)
            .map((d) => (d['avgOrders'] as num).toDouble())
            .fold<double>(0, (a, b) => a + b);

        final predicted = dayAvg > 0 ? dayAvg.round() : overallAvg.round();

        final dataPoints = hourlyData.where((d) => d['hour'] == targetHour).length;
        final confidence = (dataPoints / 7.0).clamp(0.3, 1.0);

        final level = _demandLevel(predicted, hourlyData);

        final hour = now.add(Duration(hours: h));
        final label = '${hour.hour.toString().padLeft(2, '0')}:00';

        forecasts.add(DemandForecast(
          hourLabel: label,
          predictedOrders: predicted,
          confidence: confidence,
          demandLevel: level,
        ));
      }

      return forecasts;
    } catch (e) {
      return _getDefaultForecast();
    }
  }

  /// Get peak hours for today.
  Future<List<Map<String, dynamic>>> getPeakHours({String? restaurantId}) async {
    try {
      final hourlyData = await _getHistoricalHourlyData(restaurantId: restaurantId);
      final now = DateTime.now();
      final today = now.weekday;

      final todayData = hourlyData.where((d) => d['dayOfWeek'] == today).toList();
      if (todayData.isEmpty) return [];

      todayData.sort((a, b) =>
          (b['avgOrders'] as num).compareTo(a['avgOrders'] as num));

      return todayData.take(5).map((d) => {
        'hour': d['hour'],
        'avgOrders': d['avgOrders'],
        'label': '${(d['hour'] as int).toString().padLeft(2, '0')}:00',
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Predict required drivers for a given time slot.
  Future<int> predictRequiredDrivers({
    required DateTime time,
    String? zoneId,
  }) async {
    try {
      final forecasts = await predictNext24Hours();
      final hour = time.hour;
      final forecast = forecasts.firstWhere(
        (f) => f.hourLabel == '${hour.toString().padLeft(2, '0')}:00',
        orElse: () => const DemandForecast(hourLabel: '', predictedOrders: 5, confidence: 0.5, demandLevel: 'medium'),
      );

      final ordersPerDriver = 3.0;
      return (forecast.predictedOrders / ordersPerDriver).ceil().clamp(2, 50);
    } catch (e) {
      return 5;
    }
  }

  /// Get demand level summary for the dashboard.
  Future<Map<String, dynamic>> getDemandSummary({String? restaurantId}) async {
    try {
      final forecasts = await predictNext24Hours(restaurantId: restaurantId);
      if (forecasts.isEmpty) {
        return {'peakHour': 'N/A', 'totalPredicted': 0, 'currentLevel': 'low'};
      }

      final peak = forecasts.reduce((a, b) =>
          a.predictedOrders > b.predictedOrders ? a : b);
      final total = forecasts.fold<int>(0, (sum, f) => sum + f.predictedOrders);
      final currentHour = DateTime.now().hour;
      final current = forecasts.firstWhere(
        (f) => f.hourLabel == '${currentHour.toString().padLeft(2, '0')}:00',
        orElse: () => forecasts.first,
      );

      return {
        'peakHour': peak.hourLabel,
        'peakOrders': peak.predictedOrders,
        'totalPredicted': total,
        'currentLevel': current.demandLevel,
        'currentOrders': current.predictedOrders,
      };
    } catch (e) {
      return {'peakHour': 'N/A', 'totalPredicted': 0, 'currentLevel': 'low'};
    }
  }

  Future<List<Map<String, dynamic>>> _getHistoricalHourlyData({String? restaurantId}) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 28));
    Query query = _firestore.collection('orders')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff));

    if (restaurantId != null) {
      query = query.where('restaurantId', isEqualTo: restaurantId);
    }

    final snap = await query.limit(2000).get();

    final bucketMap = <String, Map<String, dynamic>>{};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      final hour = date.hour;
      final dow = date.weekday;

      final key = '${dow}_$hour';
      if (!bucketMap.containsKey(key)) {
        bucketMap[key] = {
          'dayOfWeek': dow,
          'hour': hour,
          'totalOrders': 0,
          'daysSeen': <int>{},
        };
      }
      final b = bucketMap[key]!;
      b['totalOrders'] = (b['totalOrders'] as int) + 1;
      (b['daysSeen'] as Set<int>).add(date.day);
    }

    return bucketMap.values.map((b) {
      final daysSeen = (b['daysSeen'] as Set<int>).length;
      return {
        'dayOfWeek': b['dayOfWeek'],
        'hour': b['hour'],
        'totalOrders': b['totalOrders'],
        'avgOrders': daysSeen > 0 ? (b['totalOrders'] as int) / daysSeen : 0.0,
      };
    }).toList();
  }

  String _demandLevel(int predicted, List<Map<String, dynamic>> allData) {
    if (allData.isEmpty) return 'low';
    final avg = allData.map((d) => (d['avgOrders'] as num).toDouble()).fold<double>(0, (a, b) => a + b) / allData.length;
    if (predicted > avg * 1.5) return 'high';
    if (predicted > avg * 0.8) return 'medium';
    return 'low';
  }

  List<DemandForecast> _getDefaultForecast() {
    return List.generate(24, (h) {
      final isPeak = h >= 11 && h <= 14 || h >= 18 && h <= 21;
      final predicted = isPeak ? 15 : 5;
      return DemandForecast(
        hourLabel: '${h.toString().padLeft(2, '0')}:00',
        predictedOrders: predicted,
        confidence: 0.3,
        demandLevel: isPeak ? 'medium' : 'low',
      );
    });
  }
}
