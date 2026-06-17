import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class StoreThemeScreen extends StatefulWidget {
  final String? restaurantId;
  const StoreThemeScreen({super.key, this.restaurantId});

  @override
  State<StoreThemeScreen> createState() => _StoreThemeScreenState();
}

class _StoreThemeScreenState extends State<StoreThemeScreen> {
  String _selectedTemplate = 'classic';
  Color _selectedBrandColor = const Color(0xFFF59E0B);
  String? _bannerUrl;
  bool _isSaving = false;
  bool _isLoading = true;

  String get _rid => widget.restaurantId ?? context.read<AuthProvider>().user?.vendorId ?? '';

  bool get _hasRestaurant => _rid.isNotEmpty;

  static const _templates = [
    _TemplateCard(id: 'classic', label: 'Classic', icon: Icons.storefront_rounded),
    _TemplateCard(id: 'modern', label: 'Modern', icon: Icons.auto_awesome_rounded),
    _TemplateCard(id: 'minimal', label: 'Minimal', icon: Icons.view_agenda_rounded),
    _TemplateCard(id: 'bold', label: 'Bold', icon: Icons.format_bold_rounded),
  ];

  static const _presetColors = [
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final data = await context
        .read<PartnerHomeProvider>()
        .getRestaurant(_rid);
    if (data != null && mounted) {
      setState(() {
        _selectedTemplate = data['template'] as String? ?? 'classic';
        final colorVal = data['brandColor'] as String?;
        if (colorVal != null) {
          final parsed = int.tryParse(colorVal, radix: 16);
          if (parsed != null) _selectedBrandColor = Color(0xFF000000 | parsed);
        }
        _bannerUrl = data['bannerUrl'] as String?;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      // In production, upload to Firebase Storage and get URL.
      // For now, store local path as placeholder.
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last;
      final ref = FirebaseStorage.instance
          .ref()
          .child('banners/${_rid}.$ext');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();
      setState(() => _bannerUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e', style: GoogleFonts.inter())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<PartnerHomeProvider>().updateRestaurant(
        _rid,
        {
          'template': _selectedTemplate,
          'brandColor': _selectedBrandColor.value.toRadixString(16).padLeft(8, '0'),
          'bannerUrl': _bannerUrl,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Theme saved', style: GoogleFonts.inter())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Store Theme', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: !_hasRestaurant
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_rounded, size: 64, color: context.textMutedColor),
                  const SizedBox(height: 16),
                  Text('No Store Found', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor)),
                  const SizedBox(height: 8),
                  Text('Please create your store first.', style: GoogleFonts.inter(color: context.textMutedColor)),
                ],
              ),
            )
          : _isLoading
          ? Center(child: CircularProgressIndicator(color: context.primaryColor))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('Template', [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _templates.length,
                    itemBuilder: (ctx, i) {
                      final t = _templates[i];
                      final selected = _selectedTemplate == t.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTemplate = t.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected ? _selectedBrandColor.withValues(alpha: 0.15) : context.surfaceAltColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? _selectedBrandColor : context.borderColor,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(t.icon, size: 32, color: selected ? _selectedBrandColor : context.textMutedColor),
                              const SizedBox(height: 8),
                              Text(t.label, style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: selected ? _selectedBrandColor : context.textPrimaryColor,
                              )),
                              if (selected) ...[
                                const SizedBox(height: 4),
                                Icon(Icons.check_circle_rounded, size: 16, color: _selectedBrandColor),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _section('Brand Color', [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _presetColors.map((c) {
                      final isSelected = _selectedBrandColor == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBrandColor = c),
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
                const SizedBox(height: 16),
                _section('Banner', [
                  GestureDetector(
                    onTap: _isSaving ? null : _pickBanner,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderColor),
                        image: _bannerUrl != null && _bannerUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(_bannerUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _bannerUrl == null || _bannerUrl!.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_rounded, size: 36, color: context.textMutedColor),
                                const SizedBox(height: 8),
                                Text('Upload Banner Image', style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: context.textMutedColor,
                                )),
                                const SizedBox(height: 4),
                                Text('Recommended: 1200x400px', style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: context.textMutedColor,
                                )),
                              ],
                            )
                          : Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _section('Preview', [
                  _StorePreview(
                    template: _selectedTemplate,
                    brandColor: _selectedBrandColor,
                    bannerUrl: _bannerUrl,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.backgroundColor))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('Save Theme', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
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
}

class _TemplateCard {
  final String id;
  final String label;
  final IconData icon;
  const _TemplateCard({required this.id, required this.label, required this.icon});
}

class _StorePreview extends StatelessWidget {
  final String template;
  final Color brandColor;
  final String? bannerUrl;

  const _StorePreview({required this.template, required this.brandColor, this.bannerUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: context.backgroundColor,
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
        children: [
          // Banner
          Container(
            height: 80,
            width: double.infinity,
            color: brandColor.withValues(alpha: 0.2),
            child: bannerUrl != null && bannerUrl!.isNotEmpty
                ? Image.network(bannerUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bannerPlaceholder(brandColor))
                : _bannerPlaceholder(brandColor),
          ),
          // Store name bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: context.surfaceColor,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: brandColor, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Store Name', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimaryColor)),
                      Text('Open now · Delivery in 30 min', style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu items preview based on template
          Expanded(child: _templateBody(context)),
        ],
        ),
      ),
    );
  }

  Widget _bannerPlaceholder(Color color) {
    return Center(
      child: Icon(Icons.storefront_rounded, size: 36, color: color.withValues(alpha: 0.6)),
    );
  }

  Widget _templateBody(BuildContext context) {
    switch (template) {
      case 'modern':
        return _modernPreview(context);
      case 'minimal':
        return _minimalPreview(context);
      case 'bold':
        return _boldPreview(context);
      default:
        return _classicPreview(context);
    }
  }

  Widget _classicPreview(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _previewItem(context, 'Shawarma Plate', 'SYP 2,500'),
        const SizedBox(height: 6),
        _previewItem(context, 'Grilled Chicken', 'SYP 3,200'),
        const SizedBox(height: 6),
        _previewItem(context, 'Fresh Juice', 'SYP 800'),
      ],
    );
  }

  Widget _modernPreview(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      children: [
        _previewCard(context, 'Shawarma', 'SYP 2,500'),
        const SizedBox(width: 8),
        _previewCard(context, 'Chicken', 'SYP 3,200'),
        const SizedBox(width: 8),
        _previewCard(context, 'Juice', 'SYP 800'),
      ],
    );
  }

  Widget _minimalPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _previewDividerItem(context, 'Shawarma Plate', 'SYP 2,500'),
          const Divider(height: 1),
          _previewDividerItem(context, 'Grilled Chicken', 'SYP 3,200'),
          const Divider(height: 1),
          _previewDividerItem(context, 'Fresh Juice', 'SYP 800'),
        ],
      ),
    );
  }

  Widget _boldPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _previewBoldItem(context, 'Shawarma Plate', 'SYP 2,500'),
          const SizedBox(height: 6),
          _previewBoldItem(context, 'Grilled Chicken', 'SYP 3,200'),
          const SizedBox(height: 6),
          _previewBoldItem(context, 'Fresh Juice', 'SYP 800'),
        ],
      ),
    );
  }

  Widget _previewItem(BuildContext context, String name, String price) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surfaceAltColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(6))),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimaryColor))),
          Text(price, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.accent)),
        ],
      ),
    );
  }

  Widget _previewCard(BuildContext context, String name, String price) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.surfaceAltColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(width: 80, height: 50, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10, color: context.textPrimaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(price, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 10, color: AppColors.accent)),
        ],
      ),
    );
  }

  Widget _previewDividerItem(BuildContext context, String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: context.textPrimaryColor))),
          Text(price, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.accent)),
        ],
      ),
    );
  }

  Widget _previewBoldItem(BuildContext context, String name, String price) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brandColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.restaurant_rounded, size: 18, color: brandColor),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: context.textPrimaryColor))),
          Text(price, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: brandColor)),
        ],
      ),
    );
  }
}
