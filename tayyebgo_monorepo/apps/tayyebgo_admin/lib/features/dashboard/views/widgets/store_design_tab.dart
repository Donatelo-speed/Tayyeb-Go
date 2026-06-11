import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../business_type.dart';
import '../shared.dart';
import 'store_detail_dialogs.dart';

class StoreDesignTab extends StatelessWidget {
  final Map<String, dynamic> store;
  final String storeId;
  const StoreDesignTab({required this.store, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TemplatePicker(store: store, storeId: storeId),
      const SizedBox(height: 16),
      _DesignSection(
        store: store, storeId: storeId,
        title: 'Store Logo', icon: Icons.image_outlined,
        subtitle: 'Upload your store logo (recommended: 512x512px)',
        field: 'logoUrl',
      ),
      const SizedBox(height: 16),
      _DesignSection(
        store: store, storeId: storeId,
        title: 'Banner Image', icon: Icons.panorama_outlined,
        subtitle: 'Upload your store banner (recommended: 1200x400px)',
        field: 'bannerUrl',
      ),
      const SizedBox(height: 16),
      _BrandColors(store: store, storeId: storeId),
      const SizedBox(height: 16),
      _FeaturedProductsSection(store: store, storeId: storeId),
    ]);
  }
}

class _TemplatePicker extends StatelessWidget {
  final Map<String, dynamic> store;
  final String storeId;
  const _TemplatePicker({required this.store, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final currentId = store['designTemplate'] as String? ?? 'modern';
    final current = DesignTemplate.byId(currentId);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.dashboard_customize_outlined, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text('Storefront Template', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(businessIcon(current.iconKey), size: 14, color: context.primaryColor),
              const SizedBox(width: 4),
              Text('Current: ${current.name}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Choose how this store appears to customers in the app', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (ctx, c) {
          final perRow = c.maxWidth > 800 ? 3 : c.maxWidth > 500 ? 2 : 1;
          return Wrap(spacing: 12, runSpacing: 12, children: DesignTemplate.all.map((t) {
            final selected = currentId == t.id;
            final w = (c.maxWidth - (perRow - 1) * 12) / perRow;
            return GestureDetector(
              onTap: () async {
                try {
                  await AdminFirestoreService.instance.updateStore(storeId, {'designTemplate': t.id});
                  if (context.mounted) context.showSuccess('Template set to ${t.name}');
                } catch (e) {
                  if (context.mounted) context.showError('Failed to update template');
                }
              },
              child: Container(
                width: w,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? context.primaryColor.withValues(alpha: 0.05) : context.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? context.primaryColor : context.borderColor, width: selected ? 1.5 : 1),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: (selected ? context.primaryColor : context.textMutedColor).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(businessIcon(t.iconKey), color: selected ? context.primaryColor : context.textMutedColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(t.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                    Text(t.description, style: GoogleFonts.inter(fontSize: 11, color: context.textMutedColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  if (selected) Icon(Icons.check_circle, color: context.primaryColor, size: 18),
                ]),
              ),
            );
          }).toList());
        }),
      ]),
    );
  }
}

class _DesignSection extends StatelessWidget {
  final Map<String, dynamic> store;
  final String storeId;
  final String title;
  final IconData icon;
  final String subtitle;
  final String field;
  const _DesignSection({required this.store, required this.storeId, required this.title, required this.icon, required this.subtitle, required this.field});

  @override
  Widget build(BuildContext context) {
    final existingUrl = store[field] as String?;
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
          const Spacer(),
          if (hasExisting)
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: context.borderColor.withValues(alpha: 0.3))),
              child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.network(existingUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            ),
        ]),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showImageUploadDialog(context, title, store, storeId, field),
          icon: const Icon(Icons.upload, size: 16),
          label: Text(hasExisting ? 'Replace' : 'Upload', style: GoogleFonts.inter()),
          style: OutlinedButton.styleFrom(foregroundColor: context.primaryColor),
        ),
      ]),
    );
  }
}

class _BrandColors extends StatelessWidget {
  final Map<String, dynamic> store;
  final String storeId;
  const _BrandColors({required this.store, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final primary = store['brandColor'] as String? ?? '#2563EB';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.palette_outlined, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text('Brand Colors', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
        ]),
        const SizedBox(height: 12),
        Text('Primary brand color used across store presence', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor)),
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(int.parse(primary.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(8), border: Border.all(color: context.borderColor))),
          const SizedBox(width: 12),
          Text(primary, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.textPrimaryColor)),
          const Spacer(),
          OutlinedButton(
            onPressed: () => pickBrandColor(context, store, storeId),
            child: Text('Change', style: GoogleFonts.inter()),
          ),
        ]),
      ]),
    );
  }
}

class _FeaturedProductsSection extends StatelessWidget {
  final Map<String, dynamic> store;
  final String storeId;
  const _FeaturedProductsSection({required this.store, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final featured = (store['featuredProducts'] as List<dynamic>?) ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.star_outlined, size: 20, color: context.primaryColor),
          const SizedBox(width: 10),
          Text('Featured Products', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => pickFeaturedProducts(context, store, storeId, featured),
            icon: const Icon(Icons.add, size: 16),
            label: Text('Add', style: GoogleFonts.inter(color: context.primaryColor)),
          ),
        ]),
        const SizedBox(height: 12),
        if (featured.isEmpty)
          Text('No featured products selected. Choose products to highlight on the store page.', style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor))
        else
          ...featured.map((p) => ListTile(
            dense: true,
            title: Text(p.toString(), style: GoogleFonts.inter(color: context.textPrimaryColor)),
            trailing: IconButton(
              icon: Icon(Icons.close, size: 16, color: context.textMutedColor),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('restaurants').doc(storeId).update({
                    'featuredProducts': FieldValue.arrayRemove([p]),
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product removed from featured')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
                  }
                }
              },
            ),
          )),
      ]),
    );
  }
}
