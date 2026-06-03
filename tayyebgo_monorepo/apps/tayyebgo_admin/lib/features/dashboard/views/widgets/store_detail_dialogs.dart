import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';

void showImageUploadDialog(BuildContext context, String title, Map<String, dynamic> d, String storeId, String field) {
  final urlCtrl = TextEditingController(text: d[field] as String? ?? '');
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title == 'Store Logo'
                  ? 'Recommended 512×512 px. PNG with transparent background looks best.'
                  : 'Recommended 1200×400 px landscape banner.',
              style: TextStyle(fontSize: 12, color: context.textMutedColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                hintText: 'https://…',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: upload via Firebase Console → Storage, then paste the public URL.',
              style: TextStyle(fontSize: 11, color: context.textMutedColor),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        if ((d[field] as String?)?.isNotEmpty == true)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminFirestoreService.instance.updateStore(storeId, {field: FieldValue.delete()});
              if (context.mounted) context.showSuccess('$title removed');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: () async {
            final url = urlCtrl.text.trim();
            if (url.isEmpty) {
              if (ctx.mounted) context.showError('URL cannot be empty');
              return;
            }
            Navigator.pop(ctx);
            await AdminFirestoreService.instance.updateStore(storeId, {field: url});
            if (context.mounted) context.showSuccess('$title updated');
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void pickBrandColor(BuildContext context, Map<String, dynamic> d, String storeId) {
  const swatches = <(String, Color)>[
    ('#2563EB', Color(0xFF2563EB)),
    ('#10B981', Color(0xFF10B981)),
    ('#F59E0B', Color(0xFFF59E0B)),
    ('#EF4444', Color(0xFFEF4444)),
    ('#8B5CF6', Color(0xFF8B5CF6)),
    ('#EC4899', Color(0xFFEC4899)),
    ('#0EA5E9', Color(0xFF0EA5E9)),
    ('#F97316', Color(0xFFF97316)),
    ('#14B8A6', Color(0xFF14B8A6)),
    ('#84CC16', Color(0xFF84CC16)),
    ('#1F2937', Color(0xFF1F2937)),
    ('#F3F4F6', Color(0xFFF3F4F6)),
  ];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Pick brand color'),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in swatches)
              Semantics(
                button: true,
                label: s.$1,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await AdminFirestoreService.instance.updateStore(storeId, {'brandColor': s.$1});
                    if (context.mounted) context.showSuccess('Brand color set to ${s.$1}');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: s.$2,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor, width: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

void pickFeaturedProducts(BuildContext context, Map<String, dynamic> d, String storeId, List<dynamic> current) {
  showDialog<void>(
    context: context,
    builder: (ctx) => FeaturedProductsDialog(
      storeId: storeId,
      initiallySelected: current.map((e) => e.toString()).toSet(),
    ),
  );
}

class FeaturedProductsDialog extends StatefulWidget {
  final String storeId;
  final Set<String> initiallySelected;
  const FeaturedProductsDialog({super.key, required this.storeId, required this.initiallySelected});

  @override
  State<FeaturedProductsDialog> createState() => _FeaturedProductsDialogState();
}

class _FeaturedProductsDialogState extends State<FeaturedProductsDialog> {
  late final Set<String> _selected = {...widget.initiallySelected};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Featured products'),
      content: SizedBox(
        width: 360, height: 360,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdminFirestoreService.instance.watchStoreProducts(widget.storeId, limit: 50),
          builder: (c, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final docs = snap.data ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'This store has no products yet.\n\nAdd products in the store\'s menu to feature them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textMutedColor),
                  ),
                ),
              );
            }
            return ListView(children: [
              for (final doc in docs)
                CheckboxListTile(
                  value: _selected.contains(doc['id'] as String? ?? ''),
                  dense: true,
                  title: Text((doc['name'] as String?) ?? 'Unnamed product', style: const TextStyle(fontSize: 13)),
                  onChanged: (v) => setState(() {
                    final id = doc['id'] as String? ?? '';
                    if (v == true) { _selected.add(id); } else { _selected.remove(id); }
                  }),
                ),
            ]);
          },
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : () async {
            setState(() => _saving = true);
            final ids = _selected.toList();
            await AdminFirestoreService.instance.updateStore(widget.storeId, {'featuredProducts': ids});
            if (!context.mounted) return;
            Navigator.pop(context);
            if (context.mounted) {
              context.showSuccess('${ids.length} featured product${ids.length == 1 ? '' : 's'} updated');
            }
          },
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
