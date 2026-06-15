import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';
import 'commission_editor_view.dart';

const _purple = Color(0xFF8B5CF6);

class FinanceView extends StatelessWidget {
  const FinanceView();

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').limit(500).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: context.primaryColor));
            }
            if (snap.hasError) {
              return Center(child: Text('Error loading data', style: GoogleFonts.inter(color: context.textMutedColor)));
            }
            int totalOrders = 0;
            double grossRevenue = 0;
            double totalRefunds = 0;
            int refundCount = 0;
            final Map<String, double> restaurantRevenue = {};
            for (final doc in snap.data?.docs ?? []) {
              final d = doc.data() as Map<String, dynamic>;
              final amt = (d['totalAmount'] as num?)?.toDouble() ?? 0;
              final restId = d['restaurantId'] as String? ?? 'unknown';
              final status = d['status'] as String? ?? '';
              totalOrders++;
              grossRevenue += amt;
              restaurantRevenue[restId] = (restaurantRevenue[restId] ?? 0) + amt;
              if (status == 'refunded') {
                totalRefunds += (d['refundedAmount'] as num?)?.toDouble() ?? amt;
                refundCount++;
              }
            }
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('restaurants').orderBy('createdAt', descending: true).limit(500).snapshots(),
              builder: (context, restSnap) {
                if (restSnap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: context.primaryColor));
                }
                double totalCommission = 0;
                double driverPayouts = 0;
                double storePayouts = 0;
                final restaurantData = <Map<String, dynamic>>[];
                if (restSnap.hasData) {
                  for (final doc in restSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final rate = (d['commissionPercent'] as num?)?.toDouble() ?? 15.0;
                    final rev = restaurantRevenue[doc.id] ?? 0;
                    final comm = rev * rate / 100;
                    totalCommission += comm;
                    storePayouts += rev - comm;
                    restaurantData.add({'id': doc.id, 'name': d['name'] ?? 'Unknown', 'rate': rate, 'revenue': rev, 'commission': comm, 'payout': rev - comm});
                  }
                  driverPayouts = totalCommission * 0.6;
                }
                return _FinanceContent(
                  grossRevenue: grossRevenue,
                  totalCommission: totalCommission,
                  totalRefunds: totalRefunds,
                  refundCount: refundCount,
                  driverPayouts: driverPayouts,
                  storePayouts: storePayouts,
                  totalOrders: totalOrders,
                  restaurantData: restaurantData,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FinanceContent extends StatelessWidget {
  final double grossRevenue, totalCommission, totalRefunds, driverPayouts, storePayouts;
  final int refundCount, totalOrders;
  final List<Map<String, dynamic>> restaurantData;

  const _FinanceContent({
    required this.grossRevenue,
    required this.totalCommission,
    required this.totalRefunds,
    required this.refundCount,
    required this.driverPayouts,
    required this.storePayouts,
    required this.totalOrders,
    required this.restaurantData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Finance', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Financial Overview', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Revenue, commissions, and payouts', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _statCard(context, 'Gross Revenue', '\$${grossRevenue.toStringAsFixed(0)}', Icons.attach_money_rounded, context.primaryColor),
          const SizedBox(height: 10),
          _statCard(context, 'Platform Commission', '\$${totalCommission.toStringAsFixed(0)}', Icons.paid_rounded, context.successColor),
          const SizedBox(height: 10),
          _statCard(context, 'Refunds', '\$${totalRefunds.toStringAsFixed(0)}', Icons.money_off_rounded, context.errorColor, subtitle: '$refundCount orders'),
          const SizedBox(height: 10),
          _statCard(context, 'Driver Payouts', '\$${driverPayouts.toStringAsFixed(0)}', Icons.delivery_dining_rounded, _purple),
          const SizedBox(height: 10),
          _statCard(context, 'Store Payouts', '\$${storePayouts.toStringAsFixed(0)}', Icons.store_rounded, context.warningColor),
          const SizedBox(height: 24),
          Text('Quick Actions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          _actionButton(context, 'Export Revenue Report', Icons.download_rounded, context.primaryColor),
          const SizedBox(height: 8),
          _actionButton(context, 'Process Payouts', Icons.payments_rounded, context.successColor),
          const SizedBox(height: 8),
          _actionButton(context, 'Edit Commissions', Icons.percent_rounded, const Color(0xFF6366F1)),
          const SizedBox(height: 24),
          const _DemandForecastSection(),
          const SizedBox(height: 24),
          Text('Per-Restaurant Breakdown', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          ...restaurantData.map((rd) => _restaurantRow(context, rd)),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 13)),
                if (subtitle != null) Text(subtitle, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
              ],
            ),
          ),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _handleAction(context, label, color),
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String label, Color color) {
    if (label == 'Export Revenue Report') {
      _exportRevenueReport(context);
    } else if (label == 'Process Payouts') {
      _processPayouts(context);
    } else if (label == 'Edit Commissions') {
      _openCommissionEditor(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label exported', style: GoogleFonts.inter()), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  void _exportRevenueReport(BuildContext context) {
    final csv = StringBuffer();
    csv.writeln('Restaurant,Revenue,Commission,Payout');
    for (final rd in restaurantData) {
      csv.writeln('${rd['name']},${(rd['revenue'] as double).toStringAsFixed(2)},${(rd['commission'] as double).toStringAsFixed(2)},${(rd['payout'] as double).toStringAsFixed(2)}');
    }
    csv.writeln('');
    csv.writeln('Gross Revenue,,,\$$grossRevenue');
    csv.writeln('Total Commission,,,\$$totalCommission');
    csv.writeln('Driver Payouts,,,\$$driverPayouts');
    csv.writeln('Store Payouts,,,\$$storePayouts');
    csv.writeln('Refunds,,,\$$totalRefunds ($refundCount orders)');
    Clipboard.setData(ClipboardData(text: csv.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report copied to clipboard', style: GoogleFonts.inter()), backgroundColor: context.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  void _openCommissionEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommissionEditorView()),
    );
  }

  void _processPayouts(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Process Payouts', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _payoutSummaryRow(context, 'Store payouts', '\$${storePayouts.toStringAsFixed(0)}', context.primaryColor),
              _payoutSummaryRow(context, 'Driver payouts', '\$${driverPayouts.toStringAsFixed(0)}', context.successColor),
              Divider(color: context.borderColor),
              _payoutSummaryRow(context, 'Total', '\$${(storePayouts + driverPayouts).toStringAsFixed(0)}', context.textPrimaryColor, bold: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor))),
          ElevatedButton(
            onPressed: () async {
              try {
                final batch = FirebaseFirestore.instance.batch();
                for (final rd in restaurantData) {
                  if ((rd['payout'] as double) > 0) {
                    final ref = FirebaseFirestore.instance.collection('payouts').doc();
                    batch.set(ref, {
                      'restaurantId': rd['id'],
                      'restaurantName': rd['name'],
                      'amount': rd['payout'],
                      'commission': rd['commission'],
                      'revenue': rd['revenue'],
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                }
                await batch.commit();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${restaurantData.length} payouts recorded', style: GoogleFonts.inter()), backgroundColor: context.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e', style: GoogleFonts.inter()), backgroundColor: context.errorColor),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.successColor, foregroundColor: context.textPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Confirm Payouts', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _payoutSummaryRow(BuildContext context, String label, String value, Color valueColor, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _restaurantRow(BuildContext context, Map<String, dynamic> rd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rd['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor)),
                Text('Commission: ${(rd['rate'] as double).toStringAsFixed(0)}%', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rev: \$${(rd['revenue'] as double).toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor)),
              Text('Fee: \$${(rd['commission'] as double).toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: context.primaryColor)),
              Text('Payout: \$${(rd['payout'] as double).toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: context.successColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemandForecastSection extends StatefulWidget {
  const _DemandForecastSection();

  @override
  State<_DemandForecastSection> createState() => _DemandForecastSectionState();
}

class _DemandForecastSectionState extends State<_DemandForecastSection> {
  final _demandService = DemandPredictionService();
  Map<String, dynamic>? _summary;
  List<DemandForecast> _forecasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await _demandService.getDemandSummary();
    final forecasts = await _demandService.predictNext24Hours();
    if (mounted) {
      setState(() {
        _summary = summary;
        _forecasts = forecasts.take(12).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 10),
              Text('Demand Forecast', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
              const Spacer(),
              if (!_isLoading && _summary != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _levelColor(_summary!['currentLevel'] ?? 'low').withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_summary!['currentLevel'] as String? ?? 'low').toUpperCase()} DEMAND',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: _levelColor(_summary!['currentLevel'] ?? 'low')),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                _forecastStat('Peak Hour', _summary?['peakHour'] ?? 'N/A', const Color(0xFFEF4444)),
                const SizedBox(width: 12),
                _forecastStat('Peak Orders', '${_summary?['peakOrders'] ?? 0}', const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _forecastStat('24h Total', '${_summary?['totalPredicted'] ?? 0}', context.primaryColor),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _forecasts.length,
                itemBuilder: (context, i) {
                  final f = _forecasts[i];
                  final maxVal = _forecasts.fold<int>(0, (m, x) => x.predictedOrders > m ? x.predictedOrders : m);
                  final barHeight = maxVal > 0 ? (f.predictedOrders / maxVal * 60) : 0.0;
                  final color = _levelColor(f.demandLevel);
                  return Container(
                    width: 40,
                    margin: const EdgeInsets.only(right: 6),
                    child: Column(
                      children: [
                        Text('${f.predictedOrders}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 20,
                              height: barHeight.toDouble(),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(f.hourLabel.substring(0, 2), style: GoogleFonts.inter(fontSize: 9, color: context.textMutedColor)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _forecastStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
          ],
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFF10B981);
    }
  }
}
