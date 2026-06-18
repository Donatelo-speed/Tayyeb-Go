import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen> {
  int _selectedAmount = 10;
  final _recipientCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _amounts = [5, 10, 25, 50, 100];

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Row(
              children: [
                AnimatedPressScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_rounded, color: context.textPrimaryColor, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Gift Cards', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor, letterSpacing: 0)),
              ],
            ),
            const SizedBox(height: 32),
            // Hero
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.adminAccent, Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: AppRadius.brXxl,
                boxShadow: [BoxShadow(color: AppColors.adminAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.brXxl),
                    child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text('Send a Gift Card', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white, letterSpacing: 0)),
                  const SizedBox(height: 8),
                  Text('Share the joy of food delivery with friends and family', textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Select Amount', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _amounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return AnimatedPressScale(
                  onTap: () => setState(() => _selectedAmount = amount),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100, height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : context.surfaceColor,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: isSelected ? AppColors.primary : context.borderColor.withValues(alpha: 0.3), width: isSelected ? 2 : 0.5),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8)] : null,
                    ),
                    child: Center(
                      child: Text('\$$amount', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: isSelected ? Colors.white : context.textPrimaryColor)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text('Recipient Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: context.textPrimaryColor)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: AppRadius.brMd, border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5)),
              child: TextField(
                controller: _recipientCtrl,
                style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Who is this for?', hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: Container(padding: const EdgeInsets.all(14), child: Icon(Icons.person_outline_rounded, size: 20, color: context.textMutedColor)),
                  border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Personal Message', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: context.textPrimaryColor)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: AppRadius.brMd, border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5)),
              child: TextField(
                controller: _messageCtrl, maxLines: 3,
                style: GoogleFonts.inter(color: context.textPrimaryColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Add a personal note (optional)', hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: Container(padding: const EdgeInsets.all(14), child: Icon(Icons.message_outlined, size: 20, color: context.textMutedColor)),
                  border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedPressScale(
              onTap: () => _purchaseGiftCard(),
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.adminAccent, Color(0xFF6366F1)]),
                  borderRadius: AppRadius.brLg,
                  boxShadow: [BoxShadow(color: AppColors.adminAccent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text('Buy Gift Card — \$_selectedAmount', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseGiftCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gift card feature coming soon!', style: GoogleFonts.inter()), backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
    );
  }
}
