import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'package:url_launcher/url_launcher.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: context.textPrimaryColor,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your store and account',
                    style: GoogleFonts.inter(
                      color: context.textMutedColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _profileHeader(context, initial, displayName, email),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _section(context, 'Store', [
                _row(context, Icons.store_rounded, 'Store Details', () {
                  _showStoreDetailsSheet(context, restaurantId);
                }),
                _row(context, Icons.access_time_rounded, 'Business Hours', () {
                  _showBusinessHoursSheet(context, restaurantId);
                }),
                _row(context, Icons.delivery_dining_rounded, 'Delivery Fee', () {
                  _showDeliveryFeeSheet(context, restaurantId);
                }),
                _row(context, Icons.palette_rounded, 'Store Theme', () {
                  context.push('/store-theme');
                }),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _section(context, 'Management', [
                _row(context, Icons.restaurant_menu_rounded, 'Menu Management', () {
                  if (restaurantId != null) {
                    context.push('/menu/$restaurantId');
                  }
                }),
                _row(context, Icons.local_offer_rounded, 'Promotions', () {
                  context.push('/marketing-center');
                }),
                _row(context, Icons.analytics_rounded, 'Analytics', () {
                  context.push('/analytics');
                }),
                _row(context, Icons.delivery_dining_rounded, 'Dispatch Center', () {
                  context.push('/dispatch-center');
                }),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _section(context, 'Business', [
                _row(context, Icons.description_rounded, 'Contracts', () {
                  context.push('/contracts');
                }),
                _row(context, Icons.account_balance_wallet_rounded, 'Payouts', () {
                  context.push('/payouts');
                }),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _section(context, 'Preferences', [
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
                            onChanged: (v) {
                              locale.setLocale(v!);
                              Navigator.pop(ctx);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('العربية'),
                            value: 'ar',
                            groupValue: locale.locale.languageCode,
                            onChanged: (v) {
                              locale.setLocale(v!);
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _section(context, 'Account', [
                _row(context, Icons.person_rounded, 'Personal Info', () {
                  _showPersonalInfoSheet(context, user);
                }),
                _row(context, Icons.lock_outline_rounded, 'Change Password', () {
                  _showChangePasswordSheet(context);
                }),
                _row(context, Icons.info_outline_rounded, 'About', () async {
                  final info = await PackageInfo.fromPlatform();
                  if (context.mounted) {
                    showAboutDialog(
                      context: context,
                      applicationName: 'TayyebGo Partner',
                      applicationVersion: '${info.version}+${info.buildNumber}',
                      children: [
                        Text('Restaurant partner management app', style: GoogleFonts.inter()),
                        const SizedBox(height: 8),
                        Text(
                          'Build: ${info.buildNumber}',
                          style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12),
                        ),
                      ],
                    );
                  }
                }),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _section(context, 'Support', [
                _row(context, Icons.help_outline_rounded, 'Help Center', () {
                  context.push('/help-support');
                }),
                _row(context, Icons.mail_outline_rounded, 'Contact Support', () {
                  _launchSupportEmail(context);
                }),
                _row(context, Icons.privacy_tip_outlined, 'Privacy Policy', () {
                  context.push('/privacy-policy');
                }),
                _row(context, Icons.description_outlined, 'Terms of Service', () {
                  context.push('/terms-conditions');
                }),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _section(context, 'App', [
                _row(context, Icons.smartphone_rounded, 'App Version', () async {
                  final info = await PackageInfo.fromPlatform();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('TayyebGo Partner v${info.version} (${info.buildNumber})')),
                    );
                  }
                }),
                _row(context, Icons.delete_outline_rounded, 'Delete Account', () {
                  _showDeleteAccountDialog(context);
                }, color: context.errorColor),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.errorColor),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.errorColor),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showStoreDetailsSheet(BuildContext context, String? restaurantId) {
    if (restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No restaurant linked to this account')),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: AppRadius.brSm,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Store Details',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  _inputField('Store Name', nameCtrl),
                  const SizedBox(height: 12),
                  _inputField('Description', descCtrl, maxLines: 3),
                  const SizedBox(height: 12),
                  _inputField('Delivery Fee (\$)', feeCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('restaurants')
                          .doc(restaurantId)
                          .update({
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'deliveryFee': double.tryParse(feeCtrl.text) ?? 0,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Store updated')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.partnerAccent,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
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
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get(),
          builder: (context, snap) {
            final data = snap.data?.data() as Map<String, dynamic>?;
            final existing = data?['operatingHours'] as Map<String, dynamic>? ?? data?['businessHours'] as Map<String, dynamic>? ?? {};
            return StatefulBuilder(
              builder: (ctx, setModalState) => Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: AppRadius.brSm,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Business Hours',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                    ),
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
                            SizedBox(
                              width: 90,
                              child: Text(
                                day,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: closed
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: context.surfaceColor,
                                        borderRadius: AppRadius.brMd,
                                        border: Border.all(color: context.borderColor),
                                      ),
                                      child: Text(
                                        'Closed',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: context.surfaceColor,
                                              borderRadius: AppRadius.brMd,
                                              border: Border.all(color: context.borderColor),
                                            ),
                                            child: Text(
                                              '$open - $close',
                                              style: GoogleFonts.inter(fontSize: 13),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
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
                        await FirebaseFirestore.instance
                            .collection('restaurants')
                            .doc(restaurantId)
                            .update({
                          'operatingHours': hours.isNotEmpty ? hours : existing,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hours updated')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.partnerAccent,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                      ),
                      child: const Text(
                        'Save Hours',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: AppRadius.brSm,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delivery Fee',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            const SizedBox(height: 16),
            _inputField('Delivery Fee (\$)', feeCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(restaurantId)
                    .update({
                  'deliveryFee': double.tryParse(feeCtrl.text) ?? 0,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delivery fee updated')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.partnerAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSettings(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
    final prefs = (doc.data()?['notificationPrefs'] as Map<String, dynamic>?) ?? {};
    bool newOrders = prefs['newOrders'] ?? true;
    bool orderUpdates = prefs['orderUpdates'] ?? true;
    bool promotions = prefs['promotions'] ?? false;
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: AppRadius.brSm,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Notification Settings',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('New Order Alerts', style: GoogleFonts.inter(fontSize: 14)),
                value: newOrders,
                onChanged: (v) => setModalState(() => newOrders = v),
                activeColor: AppColors.partnerAccent,
              ),
              SwitchListTile(
                title: Text('Order Status Updates', style: GoogleFonts.inter(fontSize: 14)),
                value: orderUpdates,
                onChanged: (v) => setModalState(() => orderUpdates = v),
                activeColor: AppColors.partnerAccent,
              ),
              SwitchListTile(
                title: Text('Promotion Alerts', style: GoogleFonts.inter(fontSize: 14)),
                value: promotions,
                onChanged: (v) => setModalState(() => promotions = v),
                activeColor: AppColors.partnerAccent,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').doc(user.id).update({
                    'notificationPrefs': {
                      'newOrders': newOrders,
                      'orderUpdates': orderUpdates,
                      'promotions': promotions,
                    },
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification preferences saved')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.partnerAccent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoSheet(BuildContext context, dynamic user) {
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: AppRadius.brSm,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Personal Info',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
            ),
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.partnerAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    bool isLoading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: AppRadius.brSm,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Password',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 16),
                _inputField('Current Password', currentPwCtrl, obscureText: true),
                const SizedBox(height: 12),
                _inputField('New Password', newPwCtrl, obscureText: true),
                const SizedBox(height: 12),
                _inputField('Confirm New Password', confirmPwCtrl, obscureText: true),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPwCtrl.text != confirmPwCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match')),
                            );
                            return;
                          }
                          if (newPwCtrl.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 6 characters')),
                            );
                            return;
                          }
                          setModalState(() => isLoading = true);
                          try {
                            final fbUser = fb.FirebaseAuth.instance.currentUser;
                            if (fbUser == null || fbUser.email == null) return;
                            final credential = fb.EmailAuthProvider.credential(
                              email: fbUser.email!,
                              password: currentPwCtrl.text,
                            );
                            await fbUser.reauthenticateWithCredential(credential);
                            await fbUser.updatePassword(newPwCtrl.text);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password updated successfully')),
                              );
                            }
                          } on fb.FirebaseAuthException catch (e) {
                            setModalState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.code == 'wrong-password' ? 'Current password is incorrect' : 'Failed to update password')),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update password')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.partnerAccent,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Delete Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is permanent and cannot be undone. All your data, including store information, menu, and order history will be permanently deleted.',
                style: GoogleFonts.inter(fontSize: 14, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Type "DELETE" to confirm:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: context.textMutedColor)),
            ),
            TextButton(
              onPressed: confirmCtrl.text == 'DELETE'
                  ? () async {
                      Navigator.pop(ctx);
                      try {
                        final fbUser = fb.FirebaseAuth.instance.currentUser;
                        if (fbUser == null) return;
                        await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).delete();
                        await fbUser.delete();
                        if (context.mounted) context.go('/login');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete account')),
                          );
                        }
                      }
                    }
                  : null,
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: confirmCtrl.text == 'DELETE' ? context.errorColor : context.textMutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchSupportEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@tayyebgo.com',
      query: 'subject=TayyebGo Partner Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client')),
      );
    }
  }

  Widget _profileHeader(BuildContext context, String initial, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.partnerAccent.withValues(alpha: 0.08),
            AppColors.partnerAccent.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: AppColors.partnerAccent.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.partnerAccent, Color(0xFFFCD34D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.brLg,
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: context.textPrimaryColor,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      color: context.textMutedColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.textMutedColor,
            size: 20,
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
        borderRadius: AppRadius.brCard,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: context.textMutedColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? context.textPrimaryColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? context.textMutedColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, color: c),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: AppRadius.brMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
