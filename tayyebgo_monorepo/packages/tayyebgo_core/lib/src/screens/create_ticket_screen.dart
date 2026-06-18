import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class CreateTicketScreen extends StatefulWidget {
  final String? orderId;

  const CreateTicketScreen({super.key, this.orderId});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  String _category = 'order_issue';
  final _descriptionCtrl = TextEditingController();
  bool _submitting = false;

  static const _categories = {
    'order_issue': 'Order Issue',
    'delivery_problem': 'Delivery Problem',
    'payment': 'Payment Issue',
    'missing_items': 'Missing Items',
    'quality': 'Food Quality',
    'driver': 'Driver Issue',
    'app_bug': 'App Problem',
    'other': 'Other',
  };

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descriptionCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please describe your issue (min 10 characters)'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'customerId': user?.id ?? '',
        'customerName': user?.displayName ?? '',
        'customerEmail': user?.email ?? '',
        'orderId': widget.orderId,
        'category': _category,
        'description': _descriptionCtrl.text.trim(),
        'status': 'open',
        'priority': 'medium',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ticket submitted. We'll get back to you soon."), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit ticket'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Create Support Ticket', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMutedColor, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.entries.map((e) {
              final selected = _category == e.key;
              return GestureDetector(
                onTap: () => setState(() => _category = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.1) : context.surfaceColor,
                    borderRadius: AppRadius.brXl,
                    border: Border.all(
                      color: selected ? AppColors.primary : context.borderColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.primary : context.textPrimaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Describe your issue', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMutedColor, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 5,
            style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
            decoration: InputDecoration(
              hintText: 'What happened? Include order number if applicable...',
              hintStyle: GoogleFonts.inter(color: context.textMutedColor),
              filled: true,
              fillColor: context.surfaceColor,
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
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Submit Ticket', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
