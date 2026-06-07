import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'business_type.dart';

class CreateBusinessWizard extends StatefulWidget {
  const CreateBusinessWizard({super.key});

  @override
  State<CreateBusinessWizard> createState() => _CreateBusinessWizardState();
}

class _CreateBusinessWizardState extends State<CreateBusinessWizard> {
  int _step = 0;
  bool _saving = false;

  BusinessCategory? _category;
  BusinessType? _businessType;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();

  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Homs');
  final _zoneCtrl = TextEditingController();
  final _landmarksCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  String _deliveryMode = 'platform_only';
  BusinessPackage _package = BusinessPackage.starter;
  String _designTemplate = 'modern';
  String _primaryColor = '#2563EB';
  String _logoUrl = '';
  String _bannerUrl = '';
  bool _publishActive = true;

  void _openMapPicker() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    showDialog<void>(
      context: context,
      builder: (ctx) => _MapPickerDialog(
        initialLat: lat ?? 33.5138,
        initialLng: lng ?? 36.2765,
        onPick: (la, ln) {
          _latCtrl.text = la.toStringAsFixed(6);
          _lngCtrl.text = ln.toStringAsFixed(6);
        },
      ),
    );
  }

  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _ownerNameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _zoneCtrl.dispose();
    _landmarksCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_step) {
      case 0: return _category != null && _businessType != null;
      case 1: return _nameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.trim().isNotEmpty;
      case 2: return _cityCtrl.text.trim().isNotEmpty && _streetCtrl.text.trim().isNotEmpty;
      case 3: return _deliveryMode.isNotEmpty;
      case 4: return true;
      case 5: return true;
      default: return true;
    }
  }

  void _next() {
    if (_step < 5) {
      if (!_canProceed()) return;
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      final sections = _businessType?.suggestedSections ?? [];
      final data = {
        'name': _nameCtrl.text.trim(),
        'businessCategory': _category?.value,
        'businessType': _businessType?.id,
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'ownerName': _ownerNameCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'zone': _zoneCtrl.text.trim(),
        'landmarks': _landmarksCtrl.text.trim(),
        'latitude': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
        'deliveryMode': _deliveryMode,
        'package': _package.value,
        'designTemplate': _designTemplate,
        'enabledSections': sections,
        'primaryColor': _primaryColor,
        'logoUrl': _logoUrl,
        'bannerUrl': _bannerUrl,
        'businessStatus': 'pending_approval',
        'isActive': _publishActive,
        'status': _publishActive ? 'active' : 'pending_approval',
        'rating': 0.0,
        'revenue': 0,
        'orderCount': 0,
        'commissionPercent': 15.0,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('restaurants').add(data);
      await FirebaseFirestore.instance.collection('activity_log').add({
        'type': 'business_created',
        'message': 'New ${_businessType?.name} created: ${_nameCtrl.text.trim()}',
        'businessType': _businessType?.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_publishActive ? 'Business published successfully' : 'Saved as draft'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(child: _buildStep()),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['Business Type', 'Business Information', 'Location', 'Delivery Model', 'Business Package', 'Store Design Studio'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_business, color: context.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Step ${_step + 1} of 6 · ${titles[_step]}', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(6, (i) {
              final isActive = i <= _step;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? context.primaryColor : context.dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _step1Type();
      case 1: return _step2Info();
      case 2: return _step3Location();
      case 3: return _step4Delivery();
      case 4: return _step5Package();
      case 5: return _step6Design();
      default: return const SizedBox.shrink();
    }
  }

  Widget _step1Type() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BusinessCategory.values.map((c) {
              final selected = _category == c;
              return InkWell(
                onTap: () => setState(() {
                  _category = c;
                  _businessType = null;
                }),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.7)])
                        : null,
                    color: selected ? null : context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? context.primaryColor : context.dividerColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(businessIcon(c.iconKey), color: selected ? Colors.white : context.primaryColor, size: 28),
                      const SizedBox(height: 8),
                      Text(c.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : context.textPrimaryColor)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_category != null) ...[
            const SizedBox(height: 20),
            Text('Choose a business type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BusinessTypes.byCategory(_category!).map((t) {
                final selected = _businessType?.id == t.id;
                return InkWell(
                  onTap: () => setState(() {
                    _businessType = t;
                    _designTemplate = t.defaultTemplate;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? context.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? context.primaryColor : context.dividerColor),
                    ),
                    child: Text(t.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : context.textPrimaryColor)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step2Info() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Business name *'),
          TextField(controller: _nameCtrl, onChanged: (_) => setState(() {}), decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Al-Mashwi Al-Homsi')),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Phone *'),
                TextField(controller: _phoneCtrl, onChanged: (_) => setState(() {}), keyboardType: TextInputType.phone, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '+963 ...')),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('WhatsApp'),
                TextField(controller: _whatsappCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '+963 ...')),
              ])),
            ],
          ),
          const SizedBox(height: 14),
          _label('Email'),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'contact@business.com')),
          const SizedBox(height: 14),
          _label('Owner name'),
          TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ahmed Khalil')),
        ],
      ),
    );
  }

  Widget _step3Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Street address *'),
          TextField(controller: _streetCtrl, onChanged: (_) => setState(() {}), decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Shariaa Al-Khalij')),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('City *'),
                TextField(controller: _cityCtrl, onChanged: (_) => setState(() {}), decoration: const InputDecoration(border: OutlineInputBorder())),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Zone'),
                TextField(controller: _zoneCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Al Waer')),
              ])),
            ],
          ),
          const SizedBox(height: 14),
          _label('Landmarks'),
          TextField(controller: _landmarksCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Near Al-Rawda pharmacy, opposite the bakery')),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Latitude'),
                TextField(controller: _latCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '34.7324')),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Longitude'),
                TextField(controller: _lngCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '36.7137')),
              ])),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: OutlinedButton.icon(
                  onPressed: () => _openMapPicker(),
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Map'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _step4Delivery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How will this business handle deliveries?', style: TextStyle(fontSize: 13, color: context.textMutedColor)),
          const SizedBox(height: 14),
          _deliveryCard('platform_only', 'Platform Drivers Only', 'TayyebGo drivers deliver all orders.', Icons.delivery_dining),
          const SizedBox(height: 10),
          _deliveryCard('store_only', 'Store Drivers Only', 'Business uses its own drivers.', Icons.motorcycle),
          const SizedBox(height: 10),
          _deliveryCard('hybrid', 'Hybrid', 'Store drivers first, platform fallback.', Icons.swap_horiz),
        ],
      ),
    );
  }

  Widget _deliveryCard(String value, String title, String subtitle, IconData icon) {
    final selected = _deliveryMode == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _deliveryMode = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? context.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? context.primaryColor : context.dividerColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (selected ? context.primaryColor : context.textMutedColor).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: selected ? context.primaryColor : context.textMutedColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimaryColor)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: context.primaryColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step5Package() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: BusinessPackage.values.map((p) {
          final selected = _package == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _package = p),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? context.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? context.primaryColor : context.dividerColor, width: selected ? 1.5 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(p == BusinessPackage.enterprise ? Icons.workspace_premium : p == BusinessPackage.professional ? Icons.star : Icons.bolt, color: selected ? context.primaryColor : context.textMutedColor, size: 18),
                        const SizedBox(width: 6),
                        Text(p.displayName, style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('\$${p.priceUSD.toStringAsFixed(0)}/mo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: selected ? context.primaryColor : context.textPrimaryColor)),
                    const SizedBox(height: 8),
                    Text(p.description, style: TextStyle(fontSize: 11, color: context.textMutedColor, height: 1.3)),
                    const SizedBox(height: 10),
                    if (selected) Icon(Icons.check_circle, color: context.primaryColor, size: 18),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _step6Design() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a design template', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Each template has a unique layout optimized for this business type.', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
          const SizedBox(height: 14),
          ...DesignTemplate.all.map((t) {
            final selected = _designTemplate == t.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _designTemplate = t.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? context.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? context.primaryColor : context.dividerColor, width: selected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(businessIcon(t.iconKey), color: context.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name, style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
                              Text(t.description, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                            ],
                          ),
                        ),
                        if (selected) Icon(Icons.check_circle, color: context.primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _publishActive,
            title: const Text('Publish as active'),
            subtitle: const Text('Visible to customers immediately'),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _publishActive = v),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondaryColor)),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_step > 0) OutlinedButton(onPressed: _saving ? null : _back, child: const Text('Back')),
          const Spacer(),
          TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_saving || !_canProceed()) ? null : _next,
            child: _saving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_step == 5 ? (_publishActive ? 'Publish' : 'Save Draft') : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _MapPickerDialog extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng) onPick;
  const _MapPickerDialog({required this.initialLat, required this.initialLng, required this.onPick});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late double _lat = widget.initialLat;
  late double _lng = widget.initialLng;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick store location'),
      content: SizedBox(
        width: 360,
        height: 360,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(_lat, _lng),
                    initialZoom: 14,
                    onTap: (_, point) => setState(() {
                      _lat = point.latitude;
                      _lng = point.longitude;
                    }),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tayyebgo.admin',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat, _lng),
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.onPick(_lat, _lng);
            Navigator.pop(context);
          },
          child: const Text('Use location'),
        ),
      ],
    );
  }
}
