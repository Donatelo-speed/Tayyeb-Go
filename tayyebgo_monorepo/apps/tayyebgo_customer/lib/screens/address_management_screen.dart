import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  void _loadAddresses() {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId != null) {
      context.read<AddressProvider>().loadAddresses(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id ?? '';
    final addressProvider = context.watch<AddressProvider>();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Addresses',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: context.textPrimaryColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: addressProvider.isLoading && addressProvider.addresses.isEmpty
          ? Center(child: CircularProgressIndicator(color: context.primaryColor))
          : addressProvider.addresses.isEmpty
              ? _buildEmptyState(context)
              : _buildAddressList(context, userId, addressProvider),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _showAddAddressSheet(context, userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Address',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(Icons.location_off_outlined, size: 36, color: context.textMutedColor),
            ),
            const SizedBox(height: 20),
            Text(
              'No saved addresses',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your delivery addresses so we can bring your orders right to your door.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textMutedColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context, String userId, AddressProvider provider) {
    return RefreshIndicator(
      color: context.primaryColor,
      backgroundColor: context.surfaceColor,
      onRefresh: () async => _loadAddresses(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: provider.addresses.length,
        itemBuilder: (_, i) => _AddressCard(
          address: provider.addresses[i],
          isSelected: provider.selectedAddress?.id == provider.addresses[i].id,
          onSelect: () => provider.selectAddress(provider.addresses[i]),
          onEdit: () => _showEditAddressSheet(context, userId, provider.addresses[i]),
          onDelete: () => _showDeleteConfirmation(context, userId, provider.addresses[i]),
        ),
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        onSave: (data) async {
          final auth = context.read<AuthProvider>();
          final uid = auth.user?.id;
          if (uid == null) return;
          final provider = context.read<AddressProvider>();
          await provider.addAddress(
            userId: uid,
            label: data['label']!,
            fullAddress: data['fullAddress']!,
            city: data['city'],
            street: data['street'],
            building: data['building'],
            floor: data['floor'],
          );
        },
      ),
    );
  }

  void _showEditAddressSheet(BuildContext context, String userId, SmartAddress address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        address: address,
        onSave: (data) async {
          final auth = context.read<AuthProvider>();
          final uid = auth.user?.id;
          if (uid == null) return;
          final provider = context.read<AddressProvider>();
          final updated = address.copyWith(
            label: data['label']!,
            fullAddress: data['fullAddress']!,
            city: data['city'],
            street: data['street'],
            building: data['building'],
            floor: data['floor'],
          );
          await provider.updateAddress(uid, updated);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String userId, SmartAddress address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: context.borderColor),
        ),
        title: Text(
          'Delete Address',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor),
        ),
        content: Text(
          'Are you sure you want to delete "${address.label}" address? This action cannot be undone.',
          style: GoogleFonts.inter(color: context.textSecondaryColor, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: context.textMutedColor, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = context.read<AddressProvider>();
              await provider.deleteAddress(userId, address.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Address deleted', style: GoogleFonts.inter()),
                    backgroundColor: context.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: context.errorColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SmartAddress address;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _labelIcon() {
    switch (address.label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor.withValues(alpha: 0.08) : context.surfaceColor,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: isSelected ? context.primaryColor : context.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? context.primaryColor.withValues(alpha: 0.15) : context.surfaceAltColor,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(
                    _labelIcon(),
                    size: 18,
                    color: isSelected ? context.primaryColor : context.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address.label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      'Default',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 20, color: context.primaryColor),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address.fullAddress,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecondaryColor,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (_buildDetailParts().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _buildDetailParts(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMutedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _actionButton(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: onEdit,
                ),
                const SizedBox(width: 12),
                _actionButton(
                  context,
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  onTap: onDelete,
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildDetailParts() {
    final parts = <String>[
      if (address.street != null && address.street!.isNotEmpty) 'St: ${address.street}',
      if (address.building != null && address.building!.isNotEmpty) 'Bld: ${address.building}',
      if (address.floor != null && address.floor!.isNotEmpty) 'Fl: ${address.floor}',
      if (address.city != null && address.city!.isNotEmpty) address.city!,
    ];
    return parts.join('  •  ');
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? context.errorColor : context.textSecondaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDestructive ? context.errorColor.withValues(alpha: 0.08) : context.surfaceAltColor,
          borderRadius: AppRadius.brButton,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final SmartAddress? address;
  final Future<void> Function(Map<String, String?> data) onSave;

  const _AddressFormSheet({this.address, required this.onSave});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullAddressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();

  String _selectedLabel = 'Home';
  bool _isSaving = false;

  final List<String> _labelOptions = const ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final a = widget.address!;
      _selectedLabel = a.label;
      _fullAddressCtrl.text = a.fullAddress;
      _cityCtrl.text = a.city ?? '';
      _streetCtrl.text = a.street ?? '';
      _buildingCtrl.text = a.building ?? '';
      _floorCtrl.text = a.floor ?? '';
    }
  }

  @override
  void dispose() {
    _fullAddressCtrl.dispose();
    _cityCtrl.dispose();
    _streetCtrl.dispose();
    _buildingCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.address != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: AppRadius.brXs,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Address' : 'Add New Address',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: context.textMutedColor, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelSelector(context),
                    const SizedBox(height: 20),
                    _buildField(
                      context,
                      controller: _fullAddressCtrl,
                      label: 'Full Address',
                      hint: 'e.g. 123 Main Street, Downtown',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      context,
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'e.g. Beirut',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      context,
                      controller: _streetCtrl,
                      label: 'Street',
                      hint: 'e.g. Hamra Street',
                      icon: Icons.route_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            context,
                            controller: _buildingCtrl,
                            label: 'Building',
                            hint: 'e.g. 45A',
                            icon: Icons.apartment_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            context,
                            controller: _floorCtrl,
                            label: 'Floor',
                            hint: 'e.g. 3',
                            icon: Icons.stairs_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.primaryColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Add Address',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _labelOptions.map((label) {
            final isSelected = _selectedLabel == label;
            final icon = label == 'Home'
                ? Icons.home_rounded
                : label == 'Work'
                    ? Icons.work_rounded
                    : Icons.location_on_rounded;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedLabel = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: label != _labelOptions.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? context.primaryColor.withValues(alpha: 0.1) : context.surfaceAltColor,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(
                      color: isSelected ? context.primaryColor : context.borderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected ? context.primaryColor : context.textMutedColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? context.primaryColor : context.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: context.textMutedColor),
            filled: true,
            fillColor: context.surfaceAltColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: context.errorColor, width: 1.5),
            ),
            errorStyle: GoogleFonts.inter(fontSize: 12, color: context.errorColor),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, String?>{
      'label': _selectedLabel,
      'fullAddress': _fullAddressCtrl.text.trim(),
      'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      'street': _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
      'building': _buildingCtrl.text.trim().isEmpty ? null : _buildingCtrl.text.trim(),
      'floor': _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
    };

    try {
      await widget.onSave(data);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Address updated' : 'Address added',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address', style: GoogleFonts.inter()),
            backgroundColor: context.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
        );
      }
    }
  }
}
