import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class WalletSendScreen extends StatefulWidget {
  const WalletSendScreen({super.key});

  @override
  State<WalletSendScreen> createState() => _WalletSendScreenState();
}

class _WalletSendScreenState extends State<WalletSendScreen> {
  final _recipientCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _error;
  String? _recipientName;
  String? _recipientId;
  bool _isSearching = false;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Send Money', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildRecipientField(),
          if (_recipientName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.successColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 20, color: context.successColor),
                  const SizedBox(width: 8),
                  Text(_recipientName!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.successColor)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 24),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 24),
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 24, color: context.textPrimaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              controller: _noteCtrl,
              style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.message_rounded, size: 18, color: context.textMutedColor),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.inter(color: context.errorColor, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Send Money', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientField() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: _recipientCtrl,
        style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 14),
        onChanged: _onRecipientChanged,
        decoration: InputDecoration(
          hintText: 'Phone number or email',
          hintStyle: GoogleFonts.inter(color: context.textMutedColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(Icons.person_search_rounded, size: 20, color: context.textMutedColor),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : _recipientId != null
                  ? Icon(Icons.check_circle_rounded, size: 20, color: context.successColor)
                  : null,
        ),
      ),
    );
  }

  void _onRecipientChanged(String value) {
    _recipientId = null;
    _recipientName = null;
    if (value.length >= 3) {
      _searchRecipient(value);
    }
  }

  Future<void> _searchRecipient(String query) async {
    setState(() => _isSearching = true);
    try {
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: query.toLowerCase())
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        final doc = emailQuery.docs.first;
        setState(() {
          _recipientId = doc.id;
          _recipientName = doc.data()['displayName'] as String? ?? doc.data()['email'] as String? ?? 'User';
          _isSearching = false;
        });
        return;
      }

      final phoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: query)
          .limit(1)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        final doc = phoneQuery.docs.first;
        setState(() {
          _recipientId = doc.id;
          _recipientName = doc.data()['displayName'] as String? ?? doc.data()['phone'] as String? ?? 'User';
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _recipientId = null;
        _recipientName = null;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _send() async {
    if (_recipientId == null) {
      setState(() => _error = 'Please search and select a recipient');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }
    if (amount > 500) {
      setState(() => _error = 'Maximum transfer is \$500');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Transfer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Send \$${amount.toStringAsFixed(2)} to $_recipientName?',
          style: GoogleFonts.inter(fontSize: 15),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Send', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.primaryColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await StripeCheckoutService.transferFunds(
        recipientId: _recipientId!,
        amountInDollars: amount,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (!result.success) {
        setState(() {
          _error = result.errorMessage ?? 'Transfer failed';
          _isProcessing = false;
        });
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\$${amount.toStringAsFixed(2)} sent to $_recipientName!', style: GoogleFonts.inter()),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Transfer failed: $e';
          _isSearching = false;
        });
      }
    }
  }
}
