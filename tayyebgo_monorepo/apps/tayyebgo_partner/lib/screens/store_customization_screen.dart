import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class StoreCustomizationScreen extends StatefulWidget {
  final String restaurantId;
  const StoreCustomizationScreen({super.key, required this.restaurantId});
  @override
  State<StoreCustomizationScreen> createState() => _StoreCustomizationScreenState();
}

class _StoreCustomizationScreenState extends State<StoreCustomizationScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  Color _selectedColor = const Color(0xFFF59E0B);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurant() async {
    final d = await context.read<PartnerHomeProvider>().getRestaurant(widget.restaurantId);
    if (d != null && mounted) {
      _nameCtrl.text = d['name'] as String? ?? '';
      _descCtrl.text = d['description'] as String? ?? '';
      _feeCtrl.text = (d['deliveryFee'] as num?)?.toString() ?? '0';
      final colorVal = int.tryParse(d['brandColor'] as String? ?? '');
      if (colorVal != null) _selectedColor = Color(colorVal);
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<PartnerHomeProvider>().updateRestaurant(widget.restaurantId, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'deliveryFee': double.tryParse(_feeCtrl.text) ?? 0,
        'brandColor': _selectedColor.value.toRadixString(16).padLeft(8, '0'),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Store updated', style: GoogleFonts.inter())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Store Customization', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: context.read<PartnerHomeProvider>().watchRestaurant(widget.restaurantId),
        builder: (context, snap) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(context, 'Store Details', [
                _darkField(context: context, controller: _nameCtrl, label: 'Store Name', icon: Icons.store_rounded),
                const SizedBox(height: 14),
                _darkField(context: context, controller: _descCtrl, label: 'Description', icon: Icons.description_rounded, maxLines: 3),
                const SizedBox(height: 14),
                _darkField(context: context, controller: _feeCtrl, label: 'Delivery Fee (SYP)', icon: Icons.attach_money_rounded, keyboardType: TextInputType.number),
              ]),
              const SizedBox(height: 16),
              _section(context, 'Brand Color', [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    const Color(0xFFF59E0B),
                    const Color(0xFF6366F1),
                    const Color(0xFF10B981),
                    const Color(0xFFEF4444),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFF97316),
                    const Color(0xFF06B6D4),
                    const Color(0xFFEC4899),
                    const Color(0xFFA98D6B),
                    const Color(0xFF78716C),
                  ].map((c) {
                    final isSelected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: context.textPrimaryColor, width: 3) : null,
                          boxShadow: isSelected ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)] : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.warningColor,
                    foregroundColor: context.backgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.backgroundColor))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textMutedColor)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _darkField({required BuildContext context, required TextEditingController controller, required String label, IconData? icon, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: context.textPrimaryColor),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: context.textMutedColor, size: 20) : null,
            filled: true,
            fillColor: context.backgroundColor,
            border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.warningColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
