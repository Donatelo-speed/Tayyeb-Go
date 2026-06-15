import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class PartnerSettingsScreen extends StatefulWidget {
  const PartnerSettingsScreen({super.key});

  @override
  State<PartnerSettingsScreen> createState() => _PartnerSettingsScreenState();
}

class _PartnerSettingsScreenState extends State<PartnerSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Store';
    final email = user?.email.isNotEmpty == true ? user!.email : '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';
    final restaurantId = user?.vendorId;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileHeader(context, initial, displayName, email),
          const SizedBox(height: 20),

          _section(context, 'Store', [
            _row(context, Icons.store_rounded, 'Store Details', () {
              _showStoreDetailsSheet(context, restaurantId);
            }),
            _row(context, Icons.access_time_rounded, 'Business Hours', () {
              _showBusinessHoursSheet(context, restaurantId);
            }),
            _row(context, Icons.delivery_dining_rounded, 'Delivery Fee', () {
              _showDeliveryFeeSheet(context, restaurantId);
            }),
          ]),

          const SizedBox(height: 14),
          _section(context, 'Quick Links', [
            _row(context, Icons.restaurant_menu_rounded, 'Menu Management', () {
              context.push('/menu-management');
            }),
            _row(context, Icons.local_offer_rounded, 'Promotions', () {
              context.push('/marketing');
            }),
            _row(context, Icons.analytics_rounded, 'Analytics', () {
              context.push('/analytics');
            }),
          ]),

          const SizedBox(height: 14),
          _section(context, 'Preferences', [
            _row(context, Icons.notifications_outlined, 'Notifications', () {
              _showNotificationsSettings(context);
            }),
            _row(context, Icons.language_rounded, 'Language', () {
              final locale = context.read<LocaleProvider>();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Language', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('English'),
                        value: 'en',
                        groupValue: locale.locale.languageCode,
                        onChanged: (v) { locale.setLocale(v!); Navigator.pop(ctx); },
                      ),
                      RadioListTile<String>(
                        title: const Text('العربية'),
                        value: 'ar',
                        groupValue: locale.locale.languageCode,
                        onChanged: (v) { locale.setLocale(v!); Navigator.pop(ctx); },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ]),

          const SizedBox(height: 14),
          _section(context, 'Account', [
            _row(context, Icons.person_rounded, 'Personal Info', () {
              _showPersonalInfoSheet(context, user);
            }),
          ]),

          const SizedBox(height: 14),
          _section(context, 'Support', [
            _row(context, Icons.help_outline_rounded, 'Help Center', () {
              context.push('/help-support');
            }),
            _row(context, Icons.info_outline_rounded, 'About', () {
              showAboutDialog(
                context: context,
                applicationName: 'TayyebGo Partner',
                applicationVersion: '1.0.0',
                children: [Text('Restaurant partner management app', style: GoogleFonts.inter())],
              );
            }),
          ]),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.errorColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.errorColor)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showStoreDetailsSheet(BuildContext context, String? restaurantId) {
    if (restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No restaurant linked to this account')));
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
        builder: (ctx, scrollCtrl) => FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get(),
          builder: (context, snap) {
            final data = snap.data?.data() as Map<String, dynamic>?;
            if (data != null && nameCtrl.text.isEmpty) {
              nameCtrl.text = data['name'] ?? '';
              descCtrl.text = data['description'] ?? '';
              feeCtrl.text = (data['deliveryFee'] ?? 0).toString();
            }
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Store Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
                  const SizedBox(height: 20),
                  _inputField('Store Name', nameCtrl),
                  const SizedBox(height: 12),
                  _inputField('Description', descCtrl, maxLines: 3),
                  const SizedBox(height: 12),
                  _inputField('Delivery Fee (\$)', feeCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).update({
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'deliveryFee': double.tryParse(feeCtrl.text) ?? 0,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store updated')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.partnerAccent, minimumSize: const Size(double.infinity, 48)),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showBusinessHoursSheet(BuildContext context, String? restaurantId) {
    if (restaurantId == null) return;
    final hours = <String, Map<String, dynamic>>{};
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (ctx, scrollCtrl) => FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get(),
          builder: (context, snap) {
            final data = snap.data?.data() as Map<String, dynamic>?;
            final existing = data?['businessHours'] as Map<String, dynamic>? ?? {};
            return StatefulBuilder(
              builder: (ctx, setModalState) => Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text('Business Hours', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
                    const SizedBox(height: 20),
                    ...days.map((day) {
                      final h = existing[day] as Map<String, dynamic>? ?? {};
                      final open = h['open'] ?? '09:00';
                      final close = h['close'] ?? '22:00';
                      final closed = h['closed'] ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(width: 90, child: Text(day, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: closed
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.borderColor)),
                                      child: Text('Closed', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                          decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.borderColor)),
                                          child: Text('$open - $close', style: GoogleFonts.inter(fontSize: 13), textAlign: TextAlign.center),
                                        )),
                                      ],
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: !closed,
                              onChanged: (v) {
                                hours[day] = {'open': open, 'close': close, 'closed': !v};
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).update({
                          'businessHours': hours.isNotEmpty ? hours : existing,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hours updated')));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.partnerAccent, minimumSize: const Size(double.infinity, 48)),
                      child: const Text('Save Hours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeliveryFeeSheet(BuildContext context, String? restaurantId) {
    if (restaurantId == null) return;
    final feeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Delivery Fee', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(height: 16),
            _inputField('Delivery Fee (\$)', feeCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).update({
                  'deliveryFee': double.tryParse(feeCtrl.text) ?? 0,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery fee updated')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.partnerAccent, minimumSize: const Size(double.infinity, 48)),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSettings(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Notification Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('New Order Alerts', style: GoogleFonts.inter(fontSize: 14)),
              value: true,
              onChanged: (v) {},
              activeColor: AppColors.partnerAccent,
            ),
            SwitchListTile(
              title: Text('Order Status Updates', style: GoogleFonts.inter(fontSize: 14)),
              value: true,
              onChanged: (v) {},
              activeColor: AppColors.partnerAccent,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPersonalInfoSheet(BuildContext context, dynamic user) {
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Personal Info', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(height: 16),
            _inputField('Name', nameCtrl),
            const SizedBox(height: 12),
            _inputField('Phone', phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(user!.id).update({
                  'displayName': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.partnerAccent, minimumSize: const Size(double.infinity, 48)),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context, String initial, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: context.warningColor, borderRadius: BorderRadius.circular(14)), child: Center(child: Text(initial, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: context.backgroundColor)))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimaryColor)),
                if (email.isNotEmpty)
                  Text(email, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textMutedColor)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.textMutedColor),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor))),
            Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
