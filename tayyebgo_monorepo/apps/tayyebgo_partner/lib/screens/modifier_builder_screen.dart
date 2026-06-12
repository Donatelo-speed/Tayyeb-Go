import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class ModifierBuilderScreen extends StatefulWidget {
  final String menuItemId;
  const ModifierBuilderScreen({super.key, required this.menuItemId});

  @override
  State<ModifierBuilderScreen> createState() => _ModifierBuilderScreenState();
}

class _ModifierBuilderScreenState extends State<ModifierBuilderScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(widget.menuItemId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final raw = data['modifierGroups'] as List<dynamic>? ?? [];
        setState(() {
          _groups = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(widget.menuItemId)
          .update({
        'modifierGroups': _groups,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modifiers saved', style: GoogleFonts.inter())),
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

  void _addGroup() {
    final nameCtrl = TextEditingController();
    bool isRequired = false;
    final minCtrl = TextEditingController(text: '0');
    final maxCtrl = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Modifier Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Group name (e.g. Size, Extras)',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  filled: true,
                  fillColor: context.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.warningColor)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Required', style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: isRequired,
                    onChanged: (v) => setModalState(() => isRequired = v),
                    activeColor: context.warningColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: context.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'Min selections',
                        hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                        filled: true,
                        fillColor: context.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.warningColor)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: context.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'Max selections',
                        hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                        filled: true,
                        fillColor: context.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.warningColor)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Group name is required')),
                      );
                      return;
                    }
                    setState(() {
                      _groups.add({
                        'name': name,
                        'required': isRequired,
                        'minSelections': int.tryParse(minCtrl.text) ?? 0,
                        'maxSelections': int.tryParse(maxCtrl.text) ?? 1,
                        'modifiers': <Map<String, dynamic>>[],
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.warningColor,
                    foregroundColor: context.backgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _addModifier(int groupIndex) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Modifier name',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  filled: true,
                  fillColor: context.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.warningColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Price (SYP)',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  filled: true,
                  fillColor: context.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.warningColor)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Default on', style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: isDefault,
                    onChanged: (v) => setModalState(() => isDefault = v),
                    activeColor: context.warningColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modifier name is required')),
                      );
                      return;
                    }
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    setState(() {
                      (_groups[groupIndex]['modifiers'] as List).add({
                        'name': name,
                        'price': price,
                        'isDefault': isDefault,
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.warningColor,
                    foregroundColor: context.backgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteGroup(int groupIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Group?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
        content: Text(
          'This will remove "${_groups[groupIndex]['name']}" and all its modifiers.',
          style: GoogleFonts.inter(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _groups.removeAt(groupIndex));
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: context.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteModifier(int groupIndex, int modifierIndex) {
    setState(() {
      (_groups[groupIndex]['modifiers'] as List).removeAt(modifierIndex);
    });
  }

  void _reorderModifier(int groupIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final list = _groups[groupIndex]['modifiers'] as List;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Modifiers', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => _addGroup(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add Group', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: context.warningColor),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.primaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                      const SizedBox(height: 12),
                      Text(_error!, style: GoogleFonts.inter(color: context.textMutedColor)),
                    ],
                  ),
                )
              : _groups.isEmpty
                  ? _emptyState()
                  : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _groups.removeAt(oldIndex);
                    _groups.insert(newIndex, item);
                  },
                  itemBuilder: (ctx, i) => _groupCard(i),
                ),
      bottomNavigationBar: _groups.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
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
                              Text('Save Modifiers', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune_rounded, size: 64, color: context.textMutedColor),
          const SizedBox(height: 16),
          Text('No modifier groups', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Add groups like "Size", "Extras", or "Spice Level"', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addGroup,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.warningColor,
              foregroundColor: context.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupCard(int groupIndex) {
    final group = _groups[groupIndex];
    final modifiers = (group['modifiers'] as List<dynamic>?) ?? [];
    final isRequired = group['required'] as bool? ?? false;
    final minSel = group['minSelections'] as int? ?? 0;
    final maxSel = group['maxSelections'] as int? ?? 1;

    return Container(
      key: ValueKey('group_$groupIndex'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(Icons.drag_handle_rounded, color: context.textMutedColor),
          title: Row(
            children: [
              Expanded(
                child: Text(group['name'] as String? ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimaryColor)),
              ),
              if (isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: context.errorColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('Required', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10, color: context.errorColor)),
                ),
            ],
          ),
          subtitle: Text(
            '$minSel-$maxSel selections · ${modifiers.length} modifier${modifiers.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.errorColor),
            onPressed: () => _deleteGroup(groupIndex),
          ),
          children: [
            // Reorderable modifiers list
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modifiers.length,
              onReorder: (oldIndex, newIndex) => _reorderModifier(groupIndex, oldIndex, newIndex),
              itemBuilder: (ctx, mi) => _modifierTile(groupIndex, mi, modifiers[mi]),
            ),
            const SizedBox(height: 8),
            // Add modifier button
            GestureDetector(
              onTap: () => _addModifier(groupIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderColor, style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: context.textMutedColor),
                    const SizedBox(width: 6),
                    Text('Add Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textMutedColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modifierTile(int groupIndex, int modifierIndex, dynamic modifier) {
    final name = modifier['name'] as String? ?? '';
    final price = (modifier['price'] as num?)?.toDouble() ?? 0;
    final isDefault = modifier['isDefault'] as bool? ?? false;

    return Container(
      key: ValueKey('mod_${groupIndex}_$modifierIndex'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_handle_rounded, size: 16, color: context.textMutedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor)),
                Text('SYP ${price.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, color: context.warningColor)),
              ],
            ),
          ),
          if (isDefault)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: context.successColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text('Default', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 9, color: context.successColor)),
            ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: context.textMutedColor),
            onPressed: () => _deleteModifier(groupIndex, modifierIndex),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
