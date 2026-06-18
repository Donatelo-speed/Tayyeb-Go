import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerPayoutsScreen extends StatefulWidget {
  const PartnerPayoutsScreen({super.key});

  @override
  State<PartnerPayoutsScreen> createState() => _PartnerPayoutsScreenState();
}

class _PartnerPayoutsScreenState extends State<PartnerPayoutsScreen> {
  String _selectedFilter = 'All';
  static const _filters = ['All', 'Completed', 'Pending', 'Failed'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vendorId = auth.user?.vendorId ?? '';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Payout History',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: vendorId.isEmpty
          ? _emptyState(context, 'Not signed in', Icons.person_off_rounded)
          : RefreshIndicator(
              color: context.warningColor,
              backgroundColor: context.surfaceColor,
              onRefresh: () async => setState(() {}),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payouts')
                    .where('vendorId', isEqualTo: vendorId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: context.primaryColor));
                  }

                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _emptyState(context,
                        'No payouts yet', Icons.account_balance_wallet_rounded);
                  }

                  final parsed = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return _PayoutData(
                      id: d.id,
                      amount: (data['amount'] as num?)?.toDouble() ?? 0,
                      status: data['status'] as String? ?? 'pending',
                      createdAt: data['createdAt'] as Timestamp?,
                      transactionId: data['transactionId'] as String? ?? '',
                      paymentMethod: data['paymentMethod'] as String? ?? '',
                    );
                  }).toList();

                  final filtered = _selectedFilter == 'All'
                      ? parsed
                      : parsed
                          .where((p) =>
                              p.status.toLowerCase() ==
                              _selectedFilter.toLowerCase())
                          .toList();

                  final totalEarned = parsed
                      .where((p) => p.status == 'completed')
                      .fold(0.0, (s, p) => s + p.amount);

                  final now = DateTime.now();
                  final thisMonth = parsed
                      .where((p) =>
                          p.status == 'completed' &&
                          p.createdAt != null &&
                          p.createdAt!.toDate().month == now.month &&
                          p.createdAt!.toDate().year == now.year)
                      .fold(0.0, (s, p) => s + p.amount);

                  final pendingTotal = parsed
                      .where((p) => p.status == 'pending')
                      .fold(0.0, (s, p) => s + p.amount);

                  final lastCompleted = parsed
                      .where((p) =>
                          p.status == 'completed' && p.createdAt != null)
                      .isNotEmpty
                      ? parsed
                          .where((p) =>
                              p.status == 'completed' && p.createdAt != null)
                          .first
                          .createdAt!
                          .toDate()
                      : null;

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _summarySection(
                          context,
                          totalEarned,
                          thisMonth,
                          pendingTotal,
                          lastCompleted,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _filterChips(context),
                      ),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _emptyState(
                            context,
                            'No $_selectedFilter payouts',
                            Icons.filter_list_off_rounded,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          sliver: SliverList.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) =>
                                _payoutCard(context, filtered[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _summarySection(
    BuildContext context,
    double totalEarned,
    double thisMonth,
    double pendingTotal,
    DateTime? lastPayout,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _summaryCard(
                      context,
                      'Total Earned',
                      'SYP ${totalEarned.toStringAsFixed(0)}',
                      Icons.account_balance_rounded,
                      context.warningColor)),
              const SizedBox(width: 10),
              Expanded(
                  child: _summaryCard(
                      context,
                      'This Month',
                      'SYP ${thisMonth.toStringAsFixed(0)}',
                      Icons.calendar_month_rounded,
                      context.primaryColor)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _summaryCard(
                      context,
                      'Pending',
                      'SYP ${pendingTotal.toStringAsFixed(0)}',
                      Icons.hourglass_top_rounded,
                      context.warningColor)),
              const SizedBox(width: 10),
              Expanded(
                  child: _summaryCard(
                      context,
                      'Last Payout',
                      lastPayout != null ? _formatDate(lastPayout) : 'N/A',
                      Icons.receipt_long_rounded,
                      context.successColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String label, String value,
      IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: context.textPrimaryColor)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: context.textMutedColor)),
        ],
      ),
    );
  }

  Widget _filterChips(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final filter = _filters[i];
          final selected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? context.warningColor : context.surfaceColor,
                borderRadius: AppRadius.brXl,
                border: Border.all(
                    color:
                        selected ? context.warningColor : context.borderColor),
              ),
              child: Text(filter,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected
                          ? context.backgroundColor
                          : context.textMutedColor)),
            ),
          );
        },
      ),
    );
  }

  Widget _payoutCard(BuildContext context, _PayoutData payout) {
    final statusColor = _statusColor(context, payout.status);
    final statusBg = _statusBg(context, payout.status);
    final dateStr =
        payout.createdAt != null ? _formatDate(payout.createdAt!.toDate()) : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SYP ${payout.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: context.textPrimaryColor),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: AppRadius.brXl,
                ),
                child: Text(
                  payout.status[0].toUpperCase() + payout.status.substring(1),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _detailRow(context, Icons.calendar_today_rounded, 'Date', dateStr),
          if (payout.transactionId.isNotEmpty)
            _detailRow(context, Icons.tag_rounded, 'Transaction ID',
                payout.transactionId),
          if (payout.paymentMethod.isNotEmpty)
            _detailRow(context, Icons.payment_rounded, 'Method',
                payout.paymentMethod),
        ],
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.textMutedColor),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.inter(
                  fontSize: 12, color: context.textMutedColor)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message, IconData icon) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Icon(icon, size: 64, color: context.textMutedColor),
        const SizedBox(height: 16),
        Center(
          child: Text(message,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: context.textPrimaryColor)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('Your payout history will appear here',
              style: GoogleFonts.inter(
                  fontSize: 13, color: context.textMutedColor)),
        ),
      ],
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return context.successColor;
      case 'pending':
        return context.warningColor;
      case 'failed':
        return context.errorColor;
      default:
        return context.textMutedColor;
    }
  }

  Color _statusBg(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return context.successSoftColor;
      case 'pending':
        return context.warningSoftColor;
      case 'failed':
        return context.errorSoftColor;
      default:
        return context.surfaceAltColor;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _PayoutData {
  final String id;
  final double amount;
  final String status;
  final Timestamp? createdAt;
  final String transactionId;
  final String paymentMethod;

  const _PayoutData({
    required this.id,
    required this.amount,
    required this.status,
    this.createdAt,
    required this.transactionId,
    required this.paymentMethod,
  });
}
