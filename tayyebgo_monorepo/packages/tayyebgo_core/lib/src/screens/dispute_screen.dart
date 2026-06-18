import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DisputeScreen extends StatefulWidget {
  final String orderId;

  const DisputeScreen({super.key, required this.orderId});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedReason;
  String _resolution = 'refund';
  final List<String> _photoPaths = [];
  bool _submitting = false;
  bool _submitted = false;

  static const _reasons = [
    'Item missing',
    'Wrong items',
    'Quality issue',
    'Late delivery',
    'Driver behavior',
    'Other',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Report Issue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (data != null) _buildOrderSummary(data),
              const SizedBox(height: 24),
              _buildDisputeForm(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Issue Reported', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'We\'ve received your dispute. Our team will review it within 24 hours and get back to you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Back to Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    final restaurantName = order['restaurantName'] as String? ?? 'Restaurant';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.brMd,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurantName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    if (createdAt != null)
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} SYP',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            ...items.take(5).map((item) {
              final name = item['name'] as String? ?? '';
              final qty = item['quantity'] as int? ?? 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('x$qty', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
                  ],
                ),
              );
            }),
            if (items.length > 5)
              Text('...and ${items.length - 5} more', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _buildDisputeForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Describe the Problem', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 16),

          Text('Reason', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedReason,
            hint: Text('Select a reason', style: GoogleFonts.inter(color: AppColors.textMuted)),
            dropdownColor: AppColors.surface,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _selectedReason = v),
            validator: (v) => v == null ? 'Please select a reason' : null,
          ),
          const SizedBox(height: 20),

          Text('Description', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe what went wrong (min 20 characters)...',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Description is required';
              if (v.trim().length < 20) return 'Please provide more detail (min 20 chars)';
              return null;
            },
          ),
          const SizedBox(height: 20),

          Text('Photos (optional)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _buildPhotoSection(),
          const SizedBox(height: 20),

          Text('Requested Resolution', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _buildResolutionOption('refund', 'Refund', Icons.money_off_rounded),
          const SizedBox(height: 6),
          _buildResolutionOption('redelivery', 'Re-delivery', Icons.replay_rounded),
          const SizedBox(height: 6),
          _buildResolutionOption('credit', 'Account Credit', Icons.account_balance_wallet_rounded),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_photoPaths.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.brMd,
                      child: Image.file(
                        File(_photoPaths[index]),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _photoPaths.removeAt(index)),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_photoPaths.isNotEmpty) const SizedBox(height: 12),
        if (_photoPaths.length < 3)
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, color: AppColors.textMuted, size: 22),
                  const SizedBox(width: 8),
                  Text('Add Photo', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
        if (_photoPaths.isEmpty)
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, color: AppColors.textMuted, size: 22),
                  const SizedBox(width: 8),
                  Text('Add Photo', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= 3) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (picked != null) {
      setState(() => _photoPaths.add(picked.path));
    }
  }

  Widget _buildResolutionOption(String value, String label, IconData icon) {
    final selected = _resolution == value;
    return GestureDetector(
      onTap: () => setState(() => _resolution = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceAlt,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.inter(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              )),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submitDispute,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primarySoft,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
        child: _submitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('Submit Report', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final customerUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      List<String> photoUrls = [];
      if (_photoPaths.isNotEmpty) {
        final storage = FirebaseStorage.instance;
        for (int i = 0; i < _photoPaths.length; i++) {
          final ref = storage.ref().child('disputes/${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}_$i');
          await ref.putFile(File(_photoPaths[i]));
          photoUrls.add(await ref.getDownloadURL());
        }
      }

      await FirebaseFirestore.instance.collection('disputes').add({
        'orderId': widget.orderId,
        'customerId': customerUid,
        'reason': _selectedReason,
        'description': _descController.text.trim(),
        'photoUrls': photoUrls,
        'resolution': _resolution,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _submitted = true;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e', style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
