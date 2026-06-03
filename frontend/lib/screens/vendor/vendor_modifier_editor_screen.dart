import 'package:flutter/material.dart';
import '../../models/modifier.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../services/api_service_extensions.dart';
import '../../theme/tayyebgo_theme.dart';

/// Vendor-facing modifier management screen.
/// Shows all ModifierGroups for a product; allows creating / editing / deleting
/// groups and their individual options in-line with full price delta support.
class VendorModifierEditorScreen extends StatefulWidget {
  final Product product;
  final String vendorId;

  const VendorModifierEditorScreen({
    super.key,
    required this.product,
    required this.vendorId,
  });

  @override
  State<VendorModifierEditorScreen> createState() =>
      _VendorModifierEditorScreenState();
}

class _VendorModifierEditorScreenState
    extends State<VendorModifierEditorScreen> {
  final ApiService _api = ApiService();

  List<ModifierGroup> _groups = [];
  bool _loading = true;
  bool _saving  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getProductModifiers(
        widget.vendorId, widget.product.id.toString());
      setState(() {
        _groups = (data['modifier_groups'] as List? ?? [])
            .map((g) => ModifierGroup.fromJson(g as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createGroup() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GroupFormSheet(existing: null),
    );
    if (result == null) return;

    setState(() => _saving = true);
    try {
      await _api.createModifierGroup(
        widget.vendorId, widget.product.id.toString(), result);
      await _loadGroups();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _editGroup(ModifierGroup group) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupFormSheet(existing: group),
    );
    if (result == null) return;

    setState(() => _saving = true);
    try {
      await _api.updateModifierGroup(
        widget.vendorId, widget.product.id.toString(), group.id, result);
      await _loadGroups();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteGroup(ModifierGroup group) async {
    final confirmed = await _confirm('Delete "${group.name}"?',
        'All options in this group will be removed.');
    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      await _api.deleteModifierGroup(
        widget.vendorId, widget.product.id.toString(), group.id);
      await _loadGroups();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _toggleOption(ModifierGroup group, ModifierOption option) async {
    try {
      await _api.patchModifierOption(
        widget.vendorId,
        widget.product.id.toString(),
        group.id,
        option.id,
        {'is_available': !option.isAvailable},
      );
      await _loadGroups();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: TayyebGoTheme.errorColor),
    );
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: TayyebGoTheme.errorColor,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: TayyebGoTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Modifier Groups',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadGroups)
              : _groups.isEmpty
                  ? _EmptyState(onAdd: _createGroup)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _groups.length,
                      itemBuilder: (_, i) => _GroupCard(
                        group: _groups[i],
                        onEdit:         () => _editGroup(_groups[i]),
                        onDelete:       () => _deleteGroup(_groups[i]),
                        onToggleOption: (opt) =>
                            _toggleOption(_groups[i], opt),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TayyebGoTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Group', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _createGroup,
      ),
    );
  }
}

// ─── Group Card ───────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final ModifierGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<ModifierOption> onToggleOption;

  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleOption,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Column(
        children: [
          // Header row.
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Row(
              children: [
                Text(group.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                if (group.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Required',
                        style: TextStyle(
                            fontSize: 10, color: Colors.red.shade700,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            subtitle: Text(
              '${group.selectionType == ModifierSelectionType.single ? 'Single' : 'Multi'} select  •  '
              '${group.options.length} option${group.options.length != 1 ? 's' : ''}  •  '
              'max ${group.maxSelections}',
              style: const TextStyle(
                  fontSize: 12, color: TayyebGoTheme.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: TayyebGoTheme.primaryColor, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit group',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: TayyebGoTheme.errorColor, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete group',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Option rows.
          ...group.options.map((opt) => _OptionRow(
                option: opt,
                onToggle: () => onToggleOption(opt),
              )),
          if (group.options.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No options — edit to add.',
                  style: TextStyle(
                      color: TayyebGoTheme.textMuted, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final ModifierOption option;
  final VoidCallback onToggle;

  const _OptionRow({required this.option, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        option.isDefault ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 18,
        color: TayyebGoTheme.primaryColor.withOpacity(0.6),
      ),
      title: Text(option.name, style: const TextStyle(fontSize: 13)),
      subtitle: option.caloriesDelta != null
          ? Text('${option.caloriesDelta! > 0 ? '+' : ''}${option.caloriesDelta} cal',
              style: const TextStyle(fontSize: 11))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            option.priceLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: option.priceDelta > 0
                  ? TayyebGoTheme.primaryColor
                  : option.priceDelta < 0
                      ? Colors.green
                      : TayyebGoTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: option.isAvailable,
              onChanged: (_) => onToggle(),
              activeColor: TayyebGoTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Group form sheet ─────────────────────────────────────────────────────────

class _GroupFormSheet extends StatefulWidget {
  final ModifierGroup? existing;
  const _GroupFormSheet({this.existing});

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  String _selectionType = 'single';
  bool   _isRequired    = false;
  int    _minSelections = 0;
  int    _maxSelections = 1;

  // Local options before save.
  final List<_DraftOption> _options = [];

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    if (g != null) {
      _nameCtrl.text    = g.name;
      _selectionType    = g.selectionType == ModifierSelectionType.multi ? 'multi' : 'single';
      _isRequired       = g.isRequired;
      _minSelections    = g.minSelections;
      _maxSelections    = g.maxSelections;
      _options.addAll(g.options.map((o) => _DraftOption(
            name:          o.name,
            priceDelta:    o.priceDelta,
            isDefault:     o.isDefault,
            isAvailable:   o.isAvailable,
            caloriesDelta: o.caloriesDelta,
          )));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() => _options.add(_DraftOption()));
  }

  void _removeOption(int i) {
    setState(() => _options.removeAt(i));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'name':            _nameCtrl.text.trim(),
      'selection_type':  _selectionType,
      'is_required':     _isRequired,
      'min_selections':  _minSelections,
      'max_selections':  _maxSelections,
      'options': _options.map((o) => {
        'name':           o.name,
        'price_delta':    o.priceDelta,
        'is_default':     o.isDefault,
        'is_available':   o.isAvailable,
        'calories_delta': o.caloriesDelta,
      }).toList(),
    };

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize:     0.95,
      expand:           false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Handle.
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.existing == null
                            ? 'New Modifier Group'
                            : 'Edit Group',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: _submit,
                      child: const Text('Save',
                          style: TextStyle(
                              color: TayyebGoTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    // Group name.
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'e.g. Protein, Extras, Remove Items',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Type + required.
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectionType,
                            decoration: InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'single', child: Text('Single (radio)')),
                              DropdownMenuItem(
                                  value: 'multi', child: Text('Multi (checkbox)')),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _selectionType = v!;
                                if (v == 'single') _maxSelections = 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text('Required',
                                style: TextStyle(fontSize: 12)),
                            Switch(
                              value: _isRequired,
                              onChanged: (v) =>
                                  setState(() => _isRequired = v),
                              activeColor: TayyebGoTheme.primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_selectionType == 'multi') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _IntStepper(
                              label: 'Min selections',
                              value: _minSelections,
                              min: 0,
                              onChanged: (v) =>
                                  setState(() => _minSelections = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _IntStepper(
                              label: 'Max selections',
                              value: _maxSelections,
                              min: 1,
                              onChanged: (v) =>
                                  setState(() => _maxSelections = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Options.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Options',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Option'),
                        ),
                      ],
                    ),
                    ..._options.asMap().entries.map((e) => _OptionFormRow(
                          index: e.key,
                          option: e.value,
                          onChanged: (o) =>
                              setState(() => _options[e.key] = o),
                          onRemove: () => _removeOption(e.key),
                        )),
                    if (_options.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No options yet.',
                              style:
                                  TextStyle(color: TayyebGoTheme.textSecondary)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Draft option (mutable local) ────────────────────────────────────────────

class _DraftOption {
  String  name;
  double  priceDelta;
  bool    isDefault;
  bool    isAvailable;
  int?    caloriesDelta;

  _DraftOption({
    this.name          = '',
    this.priceDelta    = 0.0,
    this.isDefault     = false,
    this.isAvailable   = true,
    this.caloriesDelta,
  });

  _DraftOption copyWith({
    String? name,
    double? priceDelta,
    bool? isDefault,
    bool? isAvailable,
    int? caloriesDelta,
  }) => _DraftOption(
    name:          name          ?? this.name,
    priceDelta:    priceDelta    ?? this.priceDelta,
    isDefault:     isDefault     ?? this.isDefault,
    isAvailable:   isAvailable   ?? this.isAvailable,
    caloriesDelta: caloriesDelta ?? this.caloriesDelta,
  );
}

class _OptionFormRow extends StatelessWidget {
  final int          index;
  final _DraftOption option;
  final ValueChanged<_DraftOption> onChanged;
  final VoidCallback onRemove;

  const _OptionFormRow({
    required this.index,
    required this.option,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: option.name,
                  decoration: InputDecoration(
                    labelText: 'Option ${index + 1} Name',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => onChanged(option.copyWith(name: v)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: option.priceDelta.toString(),
                  decoration: InputDecoration(
                    labelText: '± Price',
                    prefixText: '\$',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (v) => onChanged(
                    option.copyWith(priceDelta: double.tryParse(v) ?? 0),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: TayyebGoTheme.errorColor, size: 18),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _SmallChip(
                label: 'Default',
                active: option.isDefault,
                onTap: () =>
                    onChanged(option.copyWith(isDefault: !option.isDefault)),
              ),
              const SizedBox(width: 8),
              _SmallChip(
                label: 'Available',
                active: option.isAvailable,
                activeColor: Colors.green,
                onTap: () => onChanged(
                    option.copyWith(isAvailable: !option.isAvailable)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _SmallChip({
    required this.label,
    required this.active,
    this.activeColor = TayyebGoTheme.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? activeColor : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? activeColor : TayyebGoTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Int stepper ──────────────────────────────────────────────────────────────

class _IntStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  const _IntStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: TayyebGoTheme.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 22),
              color: TayyebGoTheme.primaryColor,
              onPressed:
                  value > min ? () => onChanged(value - 1) : null,
            ),
            Text('$value',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              color: TayyebGoTheme.primaryColor,
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No modifier groups yet.',
              style: TextStyle(
                  color: TayyebGoTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add First Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TayyebGoTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: TayyebGoTheme.errorColor, size: 48),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center,
                style: const TextStyle(color: TayyebGoTheme.errorColor)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
