import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CommissionEditorView extends StatefulWidget {
  const CommissionEditorView({super.key});

  @override
  State<CommissionEditorView> createState() => _CommissionEditorViewState();
}

class _CommissionEditorViewState extends State<CommissionEditorView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.adminAccent.withValues(alpha: 0.1),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.percent_rounded, color: AppColors.adminAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commission Rates', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor)),
                    Text('Manage per-store platform fees', style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('restaurants').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No stores found', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 15)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final storeId = docs[index].id;
                      final name = data['name'] as String? ?? 'Unknown';
                      final commission = (data['commissionPercent'] as num?)?.toDouble() ?? 15.0;

                      return _CommissionCard(
                        storeId: storeId,
                        storeName: name,
                        commissionPercent: commission,
                        onUpdate: () => setState(() {}),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionCard extends StatefulWidget {
  final String storeId;
  final String storeName;
  final double commissionPercent;
  final VoidCallback onUpdate;

  const _CommissionCard({
    required this.storeId,
    required this.storeName,
    required this.commissionPercent,
    required this.onUpdate,
  });

  @override
  State<_CommissionCard> createState() => _CommissionCardState();
}

class _CommissionCardState extends State<_CommissionCard> {
  late double _currentPercent;
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _currentPercent = widget.commissionPercent;
    _ctrl = TextEditingController(text: _currentPercent.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _tierColor {
    if (_currentPercent <= 10) return AppColors.success;
    if (_currentPercent <= 20) return AppColors.warning;
    return AppColors.error;
  }

  String get _tierLabel {
    if (_currentPercent <= 10) return 'Low';
    if (_currentPercent <= 20) return 'Standard';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _tierColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(Icons.store_rounded, color: _tierColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.storeName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tierColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.brSm,
                      ),
                      child: Text(_tierLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _tierColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isEditing) ...[
            SizedBox(
              width: 80,
              child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textMutedColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: const BorderSide(color: AppColors.adminAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: const BorderSide(color: AppColors.adminAccent, width: 2),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _iconBtn(Icons.check_rounded, AppColors.success, _save),
            const SizedBox(width: 4),
            _iconBtn(Icons.close_rounded, context.textMutedColor, () => setState(() {
              _isEditing = false;
              _ctrl.text = _currentPercent.toStringAsFixed(1);
            })),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _tierColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.brMd,
              ),
              child: Text(
                '${_currentPercent.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _tierColor),
              ),
            ),
            const SizedBox(width: 8),
            _iconBtn(Icons.edit_rounded, AppColors.adminAccent, () => setState(() => _isEditing = true)),
          ],
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.brMd),
        child: _isSaving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 18, color: color),
      ),
    );
  }

  Future<void> _save() async {
    final newPercent = double.tryParse(_ctrl.text);
    if (newPercent == null || newPercent < 0 || newPercent > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commission must be 0-50%', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(widget.storeId).update({
        'commissionPercent': newPercent,
        'commissionUpdatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _currentPercent = newPercent;
        _isEditing = false;
        _isSaving = false;
      });
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commission updated to ${newPercent.toStringAsFixed(1)}%', style: GoogleFonts.inter()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e', style: GoogleFonts.inter()), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
