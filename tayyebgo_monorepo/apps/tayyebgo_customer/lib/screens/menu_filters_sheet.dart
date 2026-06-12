import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class MenuFiltersSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const MenuFiltersSheet({super.key, this.currentFilters = const {}});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic> currentFilters = const {},
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuFiltersSheet(currentFilters: currentFilters),
    );
  }

  @override
  State<MenuFiltersSheet> createState() => _MenuFiltersSheetState();
}

class _MenuFiltersSheetState extends State<MenuFiltersSheet> {
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;

  final Set<String> _selectedDietary = {};
  String _sortBy = 'relevance';
  final Set<String> _selectedPrepTime = {};

  static const _dietaryOptions = ['Vegetarian', 'Vegan', 'Halal', 'Gluten-Free'];
  static const _sortOptions = {
    'relevance': 'Relevance',
    'price_asc': 'Price Low \u2192 High',
    'price_desc': 'Price High \u2192 Low',
    'rating': 'Rating',
    'popularity': 'Popularity',
  };
  static const _prepTimeOptions = ['Under 15 min', 'Under 30 min'];

  @override
  void initState() {
    super.initState();
    _minPriceCtrl = TextEditingController(
      text: widget.currentFilters['minPrice']?.toString() ?? '',
    );
    _maxPriceCtrl = TextEditingController(
      text: widget.currentFilters['maxPrice']?.toString() ?? '',
    );

    final dietary = widget.currentFilters['dietary'] as List<dynamic>?;
    if (dietary != null) _selectedDietary.addAll(dietary.map((e) => e.toString()));

    _sortBy = widget.currentFilters['sortBy'] as String? ?? 'relevance';

    final prepTime = widget.currentFilters['preparationTime'] as List<dynamic>?;
    if (prepTime != null) _selectedPrepTime.addAll(prepTime.map((e) => e.toString()));
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _selectedDietary.clear();
      _sortBy = 'relevance';
      _selectedPrepTime.clear();
    });
  }

  void _apply() {
    final filters = <String, dynamic>{
      'sortBy': _sortBy,
    };

    if (_minPriceCtrl.text.isNotEmpty) {
      filters['minPrice'] = double.tryParse(_minPriceCtrl.text);
    }
    if (_maxPriceCtrl.text.isNotEmpty) {
      filters['maxPrice'] = double.tryParse(_maxPriceCtrl.text);
    }
    if (_selectedDietary.isNotEmpty) {
      filters['dietary'] = _selectedDietary.toList();
    }
    if (_selectedPrepTime.isNotEmpty) {
      filters['preparationTime'] = _selectedPrepTime.toList();
    }

    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceSection(),
                  const SizedBox(height: 24),
                  _buildDietarySection(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const SizedBox(height: 24),
                  _buildPrepTimeSection(),
                ],
              ),
            ),
          ),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filters',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 22, color: AppColors.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return _Section(
      title: 'Price Range',
      child: Row(
        children: [
          Expanded(
            child: _FilterTextField(
              controller: _minPriceCtrl,
              hint: 'Min',
              prefixText: '\$',
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '\u2014',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 18),
            ),
          ),
          Expanded(
            child: _FilterTextField(
              controller: _maxPriceCtrl,
              hint: 'Max',
              prefixText: '\$',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietarySection() {
    return _Section(
      title: 'Dietary',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _dietaryOptions.map((option) {
          final selected = _selectedDietary.contains(option);
          return _ToggleChip(
            label: option,
            selected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedDietary.remove(option);
                } else {
                  _selectedDietary.add(option);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortSection() {
    return _Section(
      title: 'Sort By',
      child: Column(
        children: _sortOptions.entries.map((entry) {
          final isSelected = _sortBy == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _sortBy = entry.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrepTimeSection() {
    return _Section(
      title: 'Preparation Time',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _prepTimeOptions.map((option) {
          final selected = _selectedPrepTime.contains(option);
          return _ToggleChip(
            label: option,
            selected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedPrepTime.remove(option);
                } else {
                  _selectedPrepTime.add(option);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _FilterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefixText;
  final TextInputType keyboardType;

  const _FilterTextField({
    required this.controller,
    required this.hint,
    this.prefixText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          prefixText: prefixText,
          prefixStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
