import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerContractsScreen extends StatelessWidget {
  const PartnerContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final restaurantId = user?.vendorId;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Contracts & Commission',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: restaurantId == null
          ? const Center(child: Text('No restaurant associated with this account.'))
          : _ContractsBody(restaurantId: restaurantId),
    );
  }
}

class _ContractsBody extends StatelessWidget {
  final String restaurantId;
  const _ContractsBody({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contracts')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return EmptyState(
            icon: Icons.description_outlined,
            title: 'No Contracts Yet',
            subtitle: 'You don\'t have any contracts on file. Contact support to get started.',
          );
        }

        final activeContracts =
            docs.where((d) => (d.data() as Map)['status'] == 'active').toList();
        final latest =
            activeContracts.isNotEmpty ? activeContracts.first : docs.first;
        final latestData = latest.data() as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(data: latestData),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'All Contracts',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: context.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                _RequestChangeButton(restaurantId: restaurantId),
              ],
            ),
            const SizedBox(height: 12),
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContractCard(data: doc.data() as Map<String, dynamic>),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] as String?) ?? 'Basic';
    final commissionRate = (data['commissionRate'] as num?)?.toDouble() ?? 0.0;
    final monthlyMin = (data['monthlyMinimum'] as num?)?.toDouble() ?? 0.0;
    final renewalDate = (data['endDate'] as Timestamp?)?.toDate();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.warningColor,
            context.warningColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.brCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(
                  '$type Plan',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.handshake_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 22),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Current Commission',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${commissionRate.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _summaryStat(
                context,
                'Monthly Min.',
                'SYP ${monthlyMin.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 20),
              _summaryStat(
                context,
                'Next Renewal',
                renewalDate != null
                    ? '${renewalDate.day}/${renewalDate.month}/${renewalDate.year}'
                    : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ContractCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ContractCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] as String?) ?? 'Basic';
    final commissionRate = (data['commissionRate'] as num?)?.toDouble() ?? 0.0;
    final status = (data['status'] as String?) ?? 'pending';
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();

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
              _typeBadge(context, type),
              const Spacer(),
              _statusBadge(context, status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoTile(context, 'Commission', '${commissionRate.toStringAsFixed(1)}%'),
              const SizedBox(width: 16),
              _infoTile(
                context,
                'Start',
                startDate != null
                    ? '${startDate.day}/${startDate.month}/${startDate.year}'
                    : '—',
              ),
              const SizedBox(width: 16),
              _infoTile(
                context,
                'End',
                endDate != null
                    ? '${endDate.day}/${endDate.month}/${endDate.year}'
                    : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(BuildContext context, String type) {
    final color = switch (type) {
      'Enterprise' => context.premiumColor,
      'Premium' => context.warningColor,
      _ => context.primaryColor,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        type,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final isActive = status == 'active';
    final isPending = status == 'pending';
    final color = isActive
        ? context.successColor
        : isPending
            ? context.warningColor
            : context.errorColor;
    final bg = isActive
        ? context.successSoftColor
        : isPending
            ? context.warningSoftColor
            : context.errorSoftColor;
    final label = status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: context.textMutedColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestChangeButton extends StatelessWidget {
  final String restaurantId;
  const _RequestChangeButton({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showRequestSheet(context),
      icon: const Icon(Icons.edit_note_rounded, size: 18),
      label: Text(
        'Request Change',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      style: TextButton.styleFrom(foregroundColor: context.warningColor),
    );
  }

  void _showRequestSheet(BuildContext context) {
    TGBottomSheet.show(
      context: context,
      title: 'Request Contract Change',
      child: _ContractChangeForm(restaurantId: restaurantId),
    );
  }
}

class _ContractChangeForm extends StatefulWidget {
  final String restaurantId;
  const _ContractChangeForm({required this.restaurantId});

  @override
  State<_ContractChangeForm> createState() => _ContractChangeFormState();
}

class _ContractChangeFormState extends State<_ContractChangeForm> {
  String? _selectedReason;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    'Commission too high',
    'Need more features',
    'Business growing',
    'Other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Reason',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.surfaceAltColor,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              isExpanded: true,
              hint: Text(
                'Select a reason',
                style: GoogleFonts.inter(color: context.textMutedColor),
              ),
              dropdownColor: context.surfaceColor,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textPrimaryColor,
              ),
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedReason = v),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Message',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 4,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: context.textPrimaryColor,
          ),
          decoration: InputDecoration(
            hintText: 'Tell us more about your request...',
            hintStyle: GoogleFonts.inter(color: context.textMutedColor),
            filled: true,
            fillColor: context.surfaceAltColor,
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.primaryColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.warningColor,
              foregroundColor: context.backgroundColor,
              disabledBackgroundColor: context.warningColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.brMd,
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.backgroundColor,
                    ),
                  )
                : Text(
                    'Submit Request',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('contract_requests').add({
        'restaurantId': widget.restaurantId,
        'reason': _selectedReason,
        'message': _messageController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }
}
