import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class CreateBusinessWizard extends StatefulWidget {
  const CreateBusinessWizard({super.key});

  @override
  State<CreateBusinessWizard> createState() => _CreateBusinessWizardState();
}

class _CreateBusinessWizardState extends State<CreateBusinessWizard> {
  int _step = 0;
  String _role = 'driver';
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Create User', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: _step > 0
              ? IconButton(
                  onPressed: () => setState(() => _step--),
                  icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
                )
              : null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgress(context),
              const SizedBox(height: 24),
              if (_step == 0) _buildStep1(context),
              if (_step == 1) _buildStep2(context),
              if (_step == 2) _buildStep3(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final steps = ['Role', 'Details', 'Confirm'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _step;
        final isDone = i < _step;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone ? context.successColor : (isActive ? context.primaryColor : context.surfaceAltColor),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check_rounded, size: 16, color: context.textPrimaryColor)
                      : Text('${i + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? context.textPrimaryColor : context.textMutedColor)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(steps[i], style: GoogleFonts.inter(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? context.textPrimaryColor : context.textMutedColor)),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDone ? context.successColor : context.borderColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Role', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        const SizedBox(height: 8),
        Text('Choose the role for this user', style: GoogleFonts.inter(color: context.textMutedColor)),
        const SizedBox(height: 20),
        _roleCard(context, Icons.person_rounded, 'Customer', 'customer', 'Browse stores, place orders, track deliveries'),
        const SizedBox(height: 10),
        _roleCard(context, Icons.delivery_dining_rounded, 'Driver', 'driver', 'Accept deliveries, navigate routes, earn money'),
        const SizedBox(height: 10),
        _roleCard(context, Icons.store_rounded, 'Store Owner', 'restaurant_owner', 'Manage menu, orders, and analytics'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: context.textPrimaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            ),
            child: Text('Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _roleCard(BuildContext context, IconData icon, String label, String value, String desc) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: selected ? context.primaryColor : context.borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (selected ? context.primaryColor : context.textMutedColor).withValues(alpha: 0.1),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icon, color: selected ? context.primaryColor : context.textMutedColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                  const SizedBox(height: 2),
                  Text(desc, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: context.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        const SizedBox(height: 8),
        Text('Enter the user\'s information', style: GoogleFonts.inter(color: context.textMutedColor)),
        const SizedBox(height: 20),
        _field(context, 'Full Name', _nameCtrl, Icons.person_outline_rounded),
        const SizedBox(height: 12),
        _field(context, 'Phone', _phoneCtrl, Icons.phone_outlined, keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _field(context, 'Email (optional)', _emailCtrl, Icons.email_outlined, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(context, 'Address (optional)', _addressCtrl, Icons.location_on_outlined),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: context.textPrimaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            ),
            child: Text('Review & Create', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _field(BuildContext context, String hint, TextEditingController ctrl, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.inter(color: context.textPrimaryColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: context.textMutedColor),
        prefixIcon: Icon(icon, color: context.textMutedColor, size: 18),
        filled: true,
        fillColor: context.surfaceAltColor,
        border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.primaryColor)),
      ),
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Confirm', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        const SizedBox(height: 8),
        Text('Review the information before creating', style: GoogleFonts.inter(color: context.textMutedColor)),
        const SizedBox(height: 20),
        _reviewCard(context, [
          _reviewRow(context, 'Role', _role.toUpperCase()),
          _reviewRow(context, 'Name', _nameCtrl.text.isNotEmpty ? _nameCtrl.text : '—'),
          _reviewRow(context, 'Phone', _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '—'),
          _reviewRow(context, 'Email', _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '—'),
          _reviewRow(context, 'Address', _addressCtrl.text.isNotEmpty ? _addressCtrl.text : '—'),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveUser,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded, size: 16),
            label: Text(_saving ? 'Creating...' : 'Create User', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: context.textPrimaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _reviewRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUser() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name and phone are required', style: GoogleFonts.inter()), backgroundColor: context.warningColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final coll = _role == 'restaurant_owner' ? 'restaurants' : 'users';
      await FirebaseFirestore.instance.collection(coll).add({
        'name': _nameCtrl.text.trim(),
        'displayName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'role': _role,
        'status': 'pending',
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User created successfully', style: GoogleFonts.inter()), backgroundColor: context.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e', style: GoogleFonts.inter()), backgroundColor: context.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
