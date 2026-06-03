import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/storefront_theme.dart';
import '../../providers/storefront_theme_provider.dart';
import '../../theme/tayyebgo_theme.dart';

/// Full storefront theme editor for restaurant vendors.
/// Changes are previewed live (via StorefrontThemeProvider.previewTheme)
/// before being persisted.
class VendorThemeEditorScreen extends StatefulWidget {
  final String vendorId;

  const VendorThemeEditorScreen({super.key, required this.vendorId});

  @override
  State<VendorThemeEditorScreen> createState() =>
      _VendorThemeEditorScreenState();
}

class _VendorThemeEditorScreenState extends State<VendorThemeEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late StorefrontTheme _draft;
  bool _saving = false;

  // Color picker state.

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);

    final provider = context.read<StorefrontThemeProvider>();
    _draft = provider.active ?? StorefrontTheme.defaultFor(widget.vendorId);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _preview(StorefrontTheme updated) {
    setState(() => _draft = updated);
    context.read<StorefrontThemeProvider>().previewTheme(updated);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<StorefrontThemeProvider>().saveTheme(_draft);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Theme saved!' : 'Save failed — try again.'),
        backgroundColor: ok
            ? TayyebGoTheme.primaryColor
            : TayyebGoTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shop Design',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: TayyebGoTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.palette_outlined), text: 'Colors'),
            Tab(icon: Icon(Icons.image_outlined), text: 'Banner'),
            Tab(icon: Icon(Icons.grid_view_outlined), text: 'Layout'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ColorsTab(draft: _draft, onUpdate: _preview),
          _BannerTab(draft: _draft, onUpdate: _preview),
          _LayoutTab(draft: _draft, onUpdate: _preview),
        ],
      ),
      bottomNavigationBar: _PreviewStrip(draft: _draft),
    );
  }
}

// ─── Colors Tab ───────────────────────────────────────────────────────────────

class _ColorsTab extends StatelessWidget {
  final StorefrontTheme draft;
  final ValueChanged<StorefrontTheme> onUpdate;

  const _ColorsTab({required this.draft, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader('Brand Colors'),
        _ColorRow(
          label: 'Primary Color',
          subtitle: 'App bar, buttons, category chips',
          color: draft.primaryColor,
          onChanged: (c) => onUpdate(draft.copyWith(primaryColor: c)),
        ),
        _ColorRow(
          label: 'Accent Color',
          subtitle: 'Highlights, promo banners',
          color: draft.accentColor,
          onChanged: (c) => onUpdate(draft.copyWith(accentColor: c)),
        ),
        _ColorRow(
          label: 'Background Color',
          subtitle: 'Page surface',
          color: draft.surfaceColor,
          onChanged: (c) => onUpdate(draft.copyWith(surfaceColor: c)),
        ),
        _ColorRow(
          label: 'Button Text Color',
          subtitle: 'Text on primary-colored elements',
          color: draft.onPrimaryColor,
          onChanged: (c) => onUpdate(draft.copyWith(onPrimaryColor: c)),
        ),
        const SizedBox(height: 16),
        _SectionHeader('Typography'),
        _DropdownRow<String>(
          label: 'Font Family',
          value: draft.fontFamily,
          items: const [
            'Poppins',
            'Lato',
            'Roboto',
            'Playfair Display',
            'Cairo',
            'Noto Sans Arabic',
            'Tajawal',
          ],
          onChanged: (f) => onUpdate(draft.copyWith(fontFamily: f!)),
        ),
        const SizedBox(height: 24),
        _PalettePreset(draft: draft, onUpdate: onUpdate),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorRow({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: () => _pickColor(context),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: TayyebGoTheme.textSecondary,
        ),
      ),
      trailing: TextButton(
        onPressed: () => _pickColor(context),
        child: Text(
          '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    Color picked = color;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ColorPickerDialog(initial: color, onChanged: (c) => picked = c),
    );
    if (confirmed == true) onChanged(picked);
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  final ValueChanged<Color> onChanged;

  const _ColorPickerDialog({required this.initial, required this.onChanged});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _current;
  final _hexCtrl = TextEditingController();

  static const _swatches = [
    Color(0xFF16A085),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFFD63031),
    Color(0xFF6C5CE7),
    Color(0xFF0984E3),
    Color(0xFFFDAB10),
    Color(0xFF2D3436),
    Color(0xFF636E72),
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFFF8F9FA),
  ];

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _hexCtrl.text =
        '#${_current.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  void _setColor(Color c) {
    setState(() => _current = c);
    _hexCtrl.text =
        '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    widget.onChanged(c);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview.
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            decoration: BoxDecoration(
              color: _current,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          // Swatches.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _swatches.map((c) {
              final selected = _current.value == c.value;
              return GestureDetector(
                onTap: () => _setColor(c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? TayyebGoTheme.primaryColor
                          : Colors.grey.shade200,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Hex input.
          TextField(
            controller: _hexCtrl,
            decoration: InputDecoration(
              labelText: 'Hex Code',
              hintText: '#RRGGBB',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.tag, size: 18),
            ),
            onSubmitted: (raw) {
              final hex = raw.startsWith('#') ? raw.substring(1) : raw;
              if (hex.length == 6) {
                try {
                  _setColor(Color(int.parse('FF$hex', radix: 16)));
                } catch (_) {}
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TayyebGoTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// ─── Banner Tab ───────────────────────────────────────────────────────────────

class _BannerTab extends StatelessWidget {
  final StorefrontTheme draft;
  final ValueChanged<StorefrontTheme> onUpdate;

  const _BannerTab({required this.draft, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader('Hero Banner'),
        _TextFieldRow(
          label: 'Banner Image URL',
          hint: 'https://…/banner.jpg',
          value: draft.heroBannerUrl ?? '',
          onChanged: (v) => onUpdate(
            draft.copyWith(heroBannerUrl: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        _DropdownRow<StorefrontBannerLayout>(
          label: 'Banner Layout',
          value: draft.bannerLayout,
          items: StorefrontBannerLayout.values,
          itemLabel: (e) => switch (e) {
            StorefrontBannerLayout.fullWidth => 'Full Width',
            StorefrontBannerLayout.splitLeft => 'Image Left, Info Right',
            StorefrontBannerLayout.splitRight => 'Info Left, Image Right',
          },
          onChanged: (v) => onUpdate(draft.copyWith(bannerLayout: v)),
        ),
        const SizedBox(height: 20),
        _SectionHeader('Tagline'),
        _TextFieldRow(
          label: 'Tagline Text',
          hint: 'Freshly made, every day.',
          value: draft.tagline ?? '',
          onChanged: (v) => onUpdate(
            draft.copyWith(tagline: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader('Promotional Banner'),
        _TextFieldRow(
          label: 'Promo Text',
          hint: 'Free delivery over \$30 today!',
          value: draft.promoText ?? '',
          onChanged: (v) => onUpdate(
            draft.copyWith(promoText: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        _TextFieldRow(
          label: 'Promo Image URL',
          hint: 'https://…/promo.jpg',
          value: draft.promoBannerUrl ?? '',
          onChanged: (v) => onUpdate(
            draft.copyWith(promoBannerUrl: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
      ],
    );
  }
}

// ─── Layout Tab ───────────────────────────────────────────────────────────────

class _LayoutTab extends StatelessWidget {
  final StorefrontTheme draft;
  final ValueChanged<StorefrontTheme> onUpdate;

  const _LayoutTab({required this.draft, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader('Product Grid'),
        _DropdownRow<StorefrontMenuLayout>(
          label: 'Menu Layout',
          value: draft.menuLayout,
          items: StorefrontMenuLayout.values,
          itemLabel: (e) => switch (e) {
            StorefrontMenuLayout.grid => 'Grid (2 columns)',
            StorefrontMenuLayout.list => 'List (full width)',
            StorefrontMenuLayout.compact => 'Compact (dense list)',
          },
          onChanged: (v) => onUpdate(draft.copyWith(menuLayout: v)),
        ),
        const SizedBox(height: 12),
        _SwitchRow(
          label: 'Show Category Bar',
          subtitle: 'Horizontal chip filter at top of menu',
          value: draft.showCategoryBar,
          onChanged: (v) => onUpdate(draft.copyWith(showCategoryBar: v)),
        ),
        _SwitchRow(
          label: 'Show Review Highlights',
          subtitle: 'Display top customer reviews',
          value: draft.showReviewHighlights,
          onChanged: (v) => onUpdate(draft.copyWith(showReviewHighlights: v)),
        ),
        const SizedBox(height: 20),
        _SectionHeader('Card Style'),
        _DropdownRow<StorefrontCardStyle>(
          label: 'Card Style',
          value: draft.cardStyle,
          items: StorefrontCardStyle.values,
          itemLabel: (e) => switch (e) {
            StorefrontCardStyle.rounded => 'Rounded (no shadow)',
            StorefrontCardStyle.flat => 'Flat (outlined border)',
            StorefrontCardStyle.elevated => 'Elevated (drop shadow)',
          },
          onChanged: (v) => onUpdate(draft.copyWith(cardStyle: v)),
        ),
        const SizedBox(height: 8),
        _SliderRow(
          label: 'Corner Radius',
          value: draft.cardBorderRadius,
          min: 0,
          max: 32,
          onChanged: (v) => onUpdate(draft.copyWith(cardBorderRadius: v)),
        ),
      ],
    );
  }
}

// ─── Preview strip ────────────────────────────────────────────────────────────

class _PreviewStrip extends StatelessWidget {
  final StorefrontTheme draft;

  const _PreviewStrip({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: draft.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: draft.accentColor,
              borderRadius: BorderRadius.circular(draft.cardBorderRadius * 0.3),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Live Preview  •  ${draft.fontFamily}',
            style: TextStyle(
              color: draft.onPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: draft.accentColor,
              borderRadius: BorderRadius.circular(draft.cardBorderRadius * 0.5),
            ),
            child: Text(
              'Add to Cart',
              style: TextStyle(
                color: draft.onPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Palette presets ──────────────────────────────────────────────────────────

class _PalettePreset extends StatelessWidget {
  final StorefrontTheme draft;
  final ValueChanged<StorefrontTheme> onUpdate;

  const _PalettePreset({required this.draft, required this.onUpdate});

  static const _presets = [
    ('Ocean Teal', Color(0xFF16A085), Color(0xFF00B894)),
    ('Fiesta Red', Color(0xFFD63031), Color(0xFFE17055)),
    ('Royal Blue', Color(0xFF0984E3), Color(0xFF74B9FF)),
    ('Night Dark', Color(0xFF2D3436), Color(0xFF636E72)),
    ('Saffron', Color(0xFFE67E22), Color(0xFFF39C12)),
    ('Berry Purple', Color(0xFF6C5CE7), Color(0xFFA29BFE)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Palette Presets'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presets.map((p) {
            return GestureDetector(
              onTap: () => onUpdate(
                draft.copyWith(primaryColor: p.$2, accentColor: p.$3),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [p.$2, p.$3],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.$1,
                    style: const TextStyle(
                      fontSize: 10,
                      color: TayyebGoTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Reusable form widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: TayyebGoTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _TextFieldRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<T>(
                value: e,
                child: Text(itemLabel != null ? itemLabel!(e) : e.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: TayyebGoTheme.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: TayyebGoTheme.primaryColor,
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 13,
                color: TayyebGoTheme.textSecondary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / 2).round(),
          activeColor: TayyebGoTheme.primaryColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
