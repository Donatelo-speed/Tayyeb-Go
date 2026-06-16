import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

const _statGreen = LinearGradient(colors: [AppColors.driverAccent, Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _statPurple = LinearGradient(colors: [AppColors.adminAccent, Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _statBlue = LinearGradient(colors: [AppColors.cyan, Color(0xFF0891B2)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _statOrange = LinearGradient(colors: [AppColors.primary, AppColors.primaryHover], begin: Alignment.topLeft, end: Alignment.bottomRight);

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView();
  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('subscriptions')
              .orderBy('createdAt', descending: true)
              .limit(500)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: context.primaryColor));
            }
            if (snap.hasError) {
              return Center(child: Text('Error loading subscriptions', style: GoogleFonts.inter(color: context.textMutedColor)));
            }
            final docs = snap.data?.docs ?? [];
            int totalSubscribers = docs.length;
            int activeCount = 0;
            double monthlyRevenue = 0;
            int basicCount = 0;
            int plusCount = 0;
            int premiumCount = 0;
            final Map<String, int> monthlyRevMap = {};

            for (final doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              final status = d['status'] as String? ?? '';
              final pricePaid = (d['pricePaid'] as num?)?.toDouble() ?? 0;
              final plan = d['plan'] as String? ?? 'basic';
              final createdAt = d['createdAt'] as String? ?? '';

              if (status == 'active') activeCount++;

              if (plan == 'basic') basicCount++;
              else if (plan == 'plus') plusCount++;
              else if (plan == 'premium') premiumCount++;

              if (createdAt.isNotEmpty) {
                final dt = DateTime.tryParse(createdAt);
                if (dt != null) {
                  final now = DateTime.now();
                  if (dt.year == now.year && dt.month == now.month) {
                    monthlyRevenue += pricePaid;
                  }
                  final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
                  monthlyRevMap[key] = (monthlyRevMap[key] ?? 0) + pricePaid.toInt();
                }
              }
            }

            String avgPlan = 'Basic';
            if (plusCount > basicCount && plusCount > premiumCount) avgPlan = 'Plus';
            else if (premiumCount > basicCount && premiumCount > plusCount) avgPlan = 'Premium';

            var filtered = docs;
            if (_statusFilter != 'all') {
              filtered = filtered.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return (d['status'] as String? ?? '') == _statusFilter;
              }).toList();
            }
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              filtered = filtered.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final userId = (d['userId'] as String? ?? '').toLowerCase();
                final plan = (d['plan'] as String? ?? '').toLowerCase();
                return userId.contains(q) || plan.contains(q);
              }).toList();
            }

            return _SubscriptionsContent(
              totalSubscribers: totalSubscribers,
              activeCount: activeCount,
              monthlyRevenue: monthlyRevenue,
              avgPlan: avgPlan,
              basicCount: basicCount,
              plusCount: plusCount,
              premiumCount: premiumCount,
              filteredDocs: filtered,
              monthlyRevMap: monthlyRevMap,
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              onFilterChanged: (v) => setState(() => _statusFilter = v),
            );
          },
        ),
      ),
    );
  }
}

class _SubscriptionsContent extends StatelessWidget {
  final int totalSubscribers;
  final int activeCount;
  final double monthlyRevenue;
  final String avgPlan;
  final int basicCount;
  final int plusCount;
  final int premiumCount;
  final List<QueryDocumentSnapshot> filteredDocs;
  final Map<String, int> monthlyRevMap;
  final String searchQuery;
  final String statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const _SubscriptionsContent({
    required this.totalSubscribers,
    required this.activeCount,
    required this.monthlyRevenue,
    required this.avgPlan,
    required this.basicCount,
    required this.plusCount,
    required this.premiumCount,
    required this.filteredDocs,
    required this.monthlyRevMap,
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Subscriptions', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Subscription Management', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Manage subscriber plans, revenue, and churn', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
          const SizedBox(height: 24),
          _buildStatCards(context),
          const SizedBox(height: 24),
          _buildRevenueChart(context),
          const SizedBox(height: 24),
          _buildPlanDistribution(context),
          const SizedBox(height: 24),
          _buildFilters(context),
          const SizedBox(height: 12),
          _buildDataTable(context),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 4 : 2;
        final childWidth = (constraints.maxWidth - (crossCount - 1) * 12) / crossCount;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: childWidth, child: _statCard(context, 'Total Subscribers', '$totalSubscribers', Icons.people_rounded, _statOrange)),
            SizedBox(width: childWidth, child: _statCard(context, 'Active', '$activeCount', Icons.check_circle_rounded, _statGreen)),
            SizedBox(width: childWidth, child: _statCard(context, 'Monthly Revenue', '\$${monthlyRevenue.toStringAsFixed(0)}', Icons.attach_money_rounded, _statPurple)),
            SizedBox(width: childWidth, child: _statCard(context, 'Most Popular', avgPlan, Icons.star_rounded, _statBlue)),
          ],
        );
      },
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, LinearGradient gradient) {
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
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 13)),
                Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: context.textPrimaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    final sortedKeys = monthlyRevMap.keys.toList()..sort();
    final last6 = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;
    if (last6.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Center(child: Text('No revenue data yet', style: GoogleFonts.inter(color: context.textMutedColor))),
      );
    }
    final maxVal = last6.fold<int>(0, (m, k) {
      final v = monthlyRevMap[k] ?? 0;
      return v > m ? v : m;
    });
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
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart_rounded, color: context.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Monthly Revenue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: last6.map((key) {
                final val = monthlyRevMap[key] ?? 0;
                final barHeight = maxVal > 0 ? (val / maxVal * 100) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('\$$val', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: _statOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(key.length >= 7 ? key.substring(5) : key, style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDistribution(BuildContext context) {
    final total = basicCount + plusCount + premiumCount;
    if (total == 0) return const SizedBox.shrink();
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
                  color: AppColors.adminAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pie_chart_rounded, color: AppColors.adminAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Plan Distribution', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 20),
          _planBar(context, 'Basic', basicCount, total, context.primaryColor),
          const SizedBox(height: 12),
          _planBar(context, 'Plus', plusCount, total, AppColors.adminAccent),
          const SizedBox(height: 12),
          _planBar(context, 'Premium', premiumCount, total, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _planBar(BuildContext context, String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
            Text('$count (${(pct * 100).toStringAsFixed(0)}%)', style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: context.surfaceAltColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by user or plan...',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.textMutedColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: statusFilter,
              isDense: true,
              style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'expired', child: Text('Expired')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (v) {
                if (v != null) onFilterChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.surfaceAltColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('User', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textMutedColor))),
                Expanded(flex: 2, child: Text('Plan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textMutedColor))),
                Expanded(flex: 2, child: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textMutedColor))),
                Expanded(flex: 2, child: Text('Start', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textMutedColor))),
                Expanded(flex: 2, child: Text('Expiry', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textMutedColor))),
                Expanded(flex: 2, child: Text('Amount', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textMutedColor))),
              ],
            ),
          ),
          if (filteredDocs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No subscriptions found', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
            )
          else
            ...filteredDocs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final userId = d['userId'] as String? ?? '-';
              final plan = d['plan'] as String? ?? 'basic';
              final status = d['status'] as String? ?? 'pending';
              final startDate = _formatDate(d['startDate'] as String?);
              final expiryDate = _formatDate(d['expiryDate'] as String?);
              final pricePaid = (d['pricePaid'] as num?)?.toDouble() ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.borderColor.withValues(alpha: 0.5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(userId.length > 12 ? '${userId.substring(0, 12)}...' : userId, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimaryColor))),
                    Expanded(flex: 2, child: _planBadge(context, plan)),
                    Expanded(flex: 2, child: _statusBadge(context, status)),
                    Expanded(flex: 2, child: Text(startDate, style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor))),
                    Expanded(flex: 2, child: Text(expiryDate, style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor))),
                    Expanded(flex: 2, child: Text('\$${pricePaid.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _planBadge(BuildContext context, String plan) {
    final color = plan == 'premium'
        ? const Color(0xFFF59E0B)
        : plan == 'plus'
            ? AppColors.adminAccent
            : context.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(plan[0].toUpperCase() + plan.substring(1), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final color = status == 'active'
        ? context.successColor
        : status == 'cancelled'
            ? context.errorColor
            : context.warningColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status[0].toUpperCase() + status.substring(1), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
