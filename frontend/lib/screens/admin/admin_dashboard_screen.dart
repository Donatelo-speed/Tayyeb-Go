import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../theme/tayyebgo_theme.dart';
import '../../widgets/responsive_layout.dart' show DashboardShell, DestItem;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final destinations = const [
    DestItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    DestItem(label: 'Restaurants', icon: Icons.store_outlined, selectedIcon: Icons.store),
    DestItem(label: 'Users', icon: Icons.people_outline, selectedIcon: Icons.people),
    DestItem(label: 'Drivers', icon: Icons.delivery_dining_outlined, selectedIcon: Icons.delivery_dining),
    DestItem(label: 'Live Map', icon: Icons.map_outlined, selectedIcon: Icons.map),
    DestItem(label: 'Commissions', icon: Icons.paid_outlined, selectedIcon: Icons.paid),
    DestItem(label: 'Reports', icon: Icons.report_outlined, selectedIcon: Icons.report),
    DestItem(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return DashboardShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: destinations,
      screens: [
        const _DashboardView(),
        _RestaurantsView(key: ValueKey('restaurants_$_selectedIndex')),
        const _UsersView(),
        const _DriversView(),
        const _LiveMapView(),
        const _CommissionsView(),
        const _ReportsView(),
        const _AdminSettingsView(),
      ],
      header: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(gradient: TayyebGoTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Super Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.power_settings_new, color: TayyebGoTheme.errorColor, size: 20),
                  onPressed: () => _showKillSwitchDialog(context),
                  tooltip: 'Emergency Kill Switch',
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () => auth.logout(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKillSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.warning, color: Colors.red.shade400),
          const SizedBox(width: 8),
          const Text('Emergency Kill Switch'),
        ]),
        content: const Text('This will disable the entire platform. All users will be logged out.\n\nUse only in case of critical system failures.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Platform has been disabled!'), backgroundColor: TayyebGoTheme.errorColor));
            },
            icon: const Icon(Icons.power_off),
            label: const Text('Disable Platform'),
            style: ElevatedButton.styleFrom(backgroundColor: TayyebGoTheme.errorColor),
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: TayyebGoTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [
              Icon(Icons.analytics, color: Colors.white, size: 48),
              SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome, Super Admin!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Full platform control at your fingertips', style: TextStyle(color: Colors.white70)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            const Text('Platform Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TayyebGoTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.analytics_outlined, size: 14, color: TayyebGoTheme.warningColor),
                const SizedBox(width: 4),
                Text('Sandbox View', style: TextStyle(fontSize: 11, color: TayyebGoTheme.warningColor, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          _LiveStatRow(),
          const SizedBox(height: 32),
          const Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _RecentActivityFeed(),
        ],
      ),
    );
  }
}

class _LiveStatRow extends StatefulWidget {
  const _LiveStatRow();

  @override
  State<_LiveStatRow> createState() => _LiveStatRowState();
}

class _LiveStatRowState extends State<_LiveStatRow> {
  int _restaurantCount = 0;
  int _userCount = 0;
  int _orderCount = 0;
  double _revenue = 0;
  int _driverCount = 0;
  int _pendingOrders = 0;
  double _commissionTotal = 0;
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _subscriptions = [
      FirebaseFirestore.instance.collection('orders').snapshots().listen((s) {
        if (mounted) setState(() {
          _orderCount = s.docs.length;
          _revenue = s.docs.fold(0.0, (sum, d) {
            final data = d.data();
            return sum + ((data['totalAmount'] as num?)?.toDouble() ?? 0);
          });
          _pendingOrders = s.docs.where((d) => d.data()['status'] == 'pending').length;
        });
      }),
      FirebaseFirestore.instance.collection('restaurants').snapshots().listen((s) {
        if (mounted) setState(() => _restaurantCount = s.docs.length);
      }),
      FirebaseFirestore.instance.collection('users').snapshots().listen((s) {
        if (mounted) setState(() => _userCount = s.docs.length);
      }),
      FirebaseFirestore.instance.collection('drivers').snapshots().listen((s) {
        if (mounted) setState(() => _driverCount = s.docs.length);
      }),
    ];
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _loadStats() async {
    final ordersSnap = await FirebaseFirestore.instance.collection('orders').get();
    final restaurantsSnap = await FirebaseFirestore.instance.collection('restaurants').get();
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final driversSnap = await FirebaseFirestore.instance.collection('drivers').get();
    final commissionsSnap = await FirebaseFirestore.instance.collection('commissions').get();
    if (mounted) setState(() {
      _orderCount = ordersSnap.docs.length;
      _restaurantCount = restaurantsSnap.docs.length;
      _userCount = usersSnap.docs.length;
      _driverCount = driversSnap.docs.length;
      _revenue = ordersSnap.docs.fold(0.0, (sum, d) => sum + ((d.data()['totalAmount'] as num?)?.toDouble() ?? 0));
      _pendingOrders = ordersSnap.docs.where((d) => d.data()['status'] == 'pending').length;
      _commissionTotal = commissionsSnap.docs.fold(0.0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _StatCard(title: 'Total Restaurants', value: '$_restaurantCount', icon: Icons.store, color: Colors.blue),
        _StatCard(title: 'Active Users', value: '$_userCount', icon: Icons.people, color: Colors.green),
        _StatCard(title: 'Total Orders', value: '$_orderCount', icon: Icons.shopping_bag, color: Colors.orange),
        _StatCard(title: 'Total Revenue', value: '\$${_revenue.toStringAsFixed(0)}', icon: Icons.attach_money, color: Colors.purple),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _StatCard(title: 'Active Drivers', value: '$_driverCount', icon: Icons.delivery_dining, color: Colors.cyan),
        _StatCard(title: 'Pending Orders', value: '$_pendingOrders', icon: Icons.pending_actions, color: Colors.red),
        _StatCard(title: 'Avg Rating', value: _orderCount > 0 ? '4.7' : '--', icon: Icons.star, color: Colors.amber),
        _StatCard(title: 'Commission', value: '\$${_commissionTotal.toStringAsFixed(1)}', icon: Icons.paid, color: Colors.teal),
      ]),
    ]);
  }
}

class _RecentActivityFeed extends StatelessWidget {
  const _RecentActivityFeed();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activity_log').orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('No recent activity', style: TextStyle(color: TayyebGoTheme.textMuted))),
          );
        }
        final activities = snapshot.data!.docs;
        if (activities.isEmpty) {
          return Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No recent activity', style: TextStyle(color: TayyebGoTheme.textMuted))));
        }
        return Column(children: activities.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final iconName = d['icon'] as String? ?? 'info';
          final colorName = d['color'] as String? ?? 'grey';
          return _StaticActivityItem(
            icon: _iconFromName(iconName),
            text: d['text'] as String? ?? '',
            time: _timeAgo((d['timestamp'] as Timestamp?)?.toDate()),
            color: _colorFromName(colorName),
          );
        }).toList());
      },
    );
  }

  IconData _iconFromName(String name) {
    switch (name) { case 'store': return Icons.store; case 'person': return Icons.person; case 'cart': return Icons.shopping_cart; case 'delivery': return Icons.delivery_dining; case 'money': return Icons.attach_money; default: return Icons.info; }
  }

  Color _colorFromName(String name) {
    switch (name) { case 'blue': return Colors.blue; case 'green': return Colors.green; case 'orange': return Colors.orange; case 'cyan': return Colors.cyan; case 'purple': return Colors.purple; default: return Colors.grey; }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _StaticActivityItem extends StatelessWidget {
  final IconData icon;
  final String text, time;
  final Color color;
  const _StaticActivityItem({required this.icon, required this.text, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        Text(time, style: const TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16), decoration: TayyebGoTheme.cardDecoration,
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}

class _RestaurantsView extends StatefulWidget {
  const _RestaurantsView({super.key});

  @override
  State<_RestaurantsView> createState() => _RestaurantsViewState();
}



class _RestaurantsViewState extends State<_RestaurantsView> {
  void _showAddRestaurantDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cuisineCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Restaurant'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Restaurant Name', prefixIcon: Icon(Icons.store))),
            const SizedBox(height: 12),
            TextField(controller: cuisineCtrl, decoration: const InputDecoration(labelText: 'Cuisine Type', prefixIcon: Icon(Icons.restaurant))),
            const SizedBox(height: 12),
            TextField(controller: imageUrlCtrl, decoration: const InputDecoration(labelText: 'Image URL (optional)', prefixIcon: Icon(Icons.image))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('restaurants').add({
                  'name': nameCtrl.text.trim(),
                  'cuisine': cuisineCtrl.text.trim(),
                  'imageUrl': imageUrlCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'isOpen': true,
                  'rating': 0.0,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restaurant "${nameCtrl.text.trim()}" added!')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: TayyebGoTheme.errorColor));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRestaurantStatus(String docId, bool currentlyOpen) async {
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(docId).update({'isOpen': !currentlyOpen});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: TayyebGoTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store, size: 64, color: TayyebGoTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('No restaurants yet', style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRestaurantDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Restaurant'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final isOpen = d['isOpen'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: TayyebGoTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 52, height: 52,
                          color: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                          child: d['imageUrl'] != null && (d['imageUrl'] as String).isNotEmpty
                              ? Image.network(d['imageUrl'] as String, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.store, color: TayyebGoTheme.primaryColor))
                              : const Icon(Icons.store, color: TayyebGoTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(d['name'] as String? ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            if (d['cuisine'] != null && (d['cuisine'] as String).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: TayyebGoTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                                child: Text(d['cuisine'] as String, style: TextStyle(fontSize: 10, color: TayyebGoTheme.primaryColor.withValues(alpha: 0.8))),
                              ),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(Icons.phone, size: 11, color: TayyebGoTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(d['phone'] as String? ?? '—', style: TextStyle(fontSize: 11, color: TayyebGoTheme.textSecondary)),
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, size: 11, color: TayyebGoTheme.textMuted),
                            const SizedBox(width: 4),
                            Expanded(child: Text(d['address'] as String? ?? '', style: TextStyle(fontSize: 11, color: TayyebGoTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                          ]),
                        ]),
                      ),
                      Switch(
                        value: isOpen,
                        onChanged: (_) => _toggleRestaurantStatus(docs[i].id, isOpen),
                        activeThumbColor: TayyebGoTheme.successColor,
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddRestaurantDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}



Future<void> _toggleIsActive(String docId, bool active, BuildContext context) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({'isActive': active});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(active ? 'Account activated' : 'Account suspended'),
        backgroundColor: Colors.green,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Update failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: TayyebGoTheme.textMuted),
                const SizedBox(height: 16),
                Text('No users yet', style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final role = d['role'] as String? ?? 'customer';
            final isActive = d['isActive'] != false;
            final roleColor = role == 'superAdmin' ? Colors.red : role == 'restaurantOwner' ? Colors.blue : role == 'driver' ? Colors.orange : Colors.green;
            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: TayyebGoTheme.cardDecoration,
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: roleColor.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: roleColor),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['displayName'] as String? ?? d['email'] as String? ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(d['email'] as String? ?? '', style: const TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                  Text(role, style: TextStyle(fontSize: 11, color: roleColor)),
                ])),
                Switch(
                  value: isActive,
                  onChanged: (v) => _toggleIsActive(docs[i].id, v, context),
                  activeThumbColor: TayyebGoTheme.successColor,
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

class _DriversView extends StatelessWidget {
  const _DriversView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delivery_dining_outlined, size: 64, color: TayyebGoTheme.textMuted),
                const SizedBox(height: 16),
                Text('No drivers registered', style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final isOnline = d['isOnline'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: TayyebGoTheme.cardDecoration,
              child: Row(children: [
                CircleAvatar(backgroundColor: TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.delivery_dining, color: TayyebGoTheme.primaryColor)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['name'] as String? ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Vehicle: ${d['vehicle'] as String? ?? 'N/A'}', style: const TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: (isOnline ? TayyebGoTheme.successColor : TayyebGoTheme.textMuted).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(isOnline ? 'Online' : 'Offline',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOnline ? TayyebGoTheme.successColor : TayyebGoTheme.textMuted)),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

class _LiveMapView extends StatelessWidget {
  const _LiveMapView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('driver_locations')
          .snapshots(),
      builder: (context, snapshot) {
        final locations = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];
        final count = locations.length;

        final markers = locations.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final lat = (d['lat'] as num?)?.toDouble() ?? 34.7324;
          final lng = (d['lng'] as num?)?.toDouble() ?? 36.7137;
          final name = d['driverName'] as String? ?? 'Driver';
          return Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: Tooltip(
              message: name,
              child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 32),
            ),
          );
        }).toList();

        return Column(children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(34.7324, 36.7137),
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tayyebgo.app',
                ),
                if (markers.isNotEmpty)
                  MarkerLayer(markers: markers),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? TayyebGoTheme.successColor.withValues(alpha: 0.1)
                        : TayyebGoTheme.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count > 0 ? '$count driver(s) on the map' : 'No driver locations yet',
                    style: TextStyle(
                      color: count > 0 ? TayyebGoTheme.successColor : TayyebGoTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }
}

class _CommissionsView extends StatelessWidget {
  const _CommissionsView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('commissions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final totalCommission = docs.fold(0.0, (sum, d) {
          final data = d.data() as Map<String, dynamic>;
          return sum + ((data['amount'] as num?)?.toDouble() ?? 0);
        });
        final settled = docs.where((d) => (d.data() as Map)['status'] == 'settled').length;
        final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            _StatCard(title: 'Total Commission', value: '\$${totalCommission.toStringAsFixed(2)}', icon: Icons.paid, color: Colors.teal),
            _StatCard(title: 'Settled', value: '$settled', icon: Icons.check_circle, color: Colors.green),
            _StatCard(title: 'Pending', value: '$pending', icon: Icons.pending, color: Colors.orange),
          ]),
          const SizedBox(height: 24),
          ...docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: TayyebGoTheme.cardDecoration,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['restaurantName'] as String? ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${((d['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: TayyebGoTheme.primaryColor)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (d['status'] == 'settled' ? TayyebGoTheme.successColor : TayyebGoTheme.warningColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(d['status'] as String? ?? 'pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                      color: d['status'] == 'settled' ? TayyebGoTheme.successColor : TayyebGoTheme.warningColor)),
                ),
              ]),
            );
          }),
        ]);
      },
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Reports & Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      _ReportCard(title: 'Sales Summary', subtitle: 'Daily, weekly, and monthly revenue breakdown', icon: Icons.trending_up, color: Colors.blue),
      _ReportCard(title: 'Order Analytics', subtitle: 'Order volume, peak hours, and popular items', icon: Icons.shopping_cart, color: Colors.green),
      _ReportCard(title: 'User Growth', subtitle: 'New user registrations and retention rates', icon: Icons.people, color: Colors.purple),
      _ReportCard(title: 'Driver Performance', subtitle: 'Delivery times, ratings, and completion rates', icon: Icons.delivery_dining, color: Colors.cyan),
      _ReportCard(title: 'Financial Reports', subtitle: 'Commission summaries and payout tracking', icon: Icons.attach_money, color: Colors.teal),
    ]);
  }
}

class _ReportCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  const _ReportCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.cardDecoration,
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right, color: TayyebGoTheme.textMuted),
      ]),
    );
  }
}

class _AdminSettingsView extends StatefulWidget {
  const _AdminSettingsView();

  @override
  State<_AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<_AdminSettingsView> {
  bool _auditLogEnabled = true;
  bool _maintenanceMode = false;
  bool _newRegistrationsAllowed = true;
  double _commissionRate = 15.0;
  int _maxDriversPerZone = 10;

  void _setAuditLog(bool v) => setState(() => _auditLogEnabled = v);
  void _setMaintenance(bool v) => setState(() => _maintenanceMode = v);
  void _setNewRegistrations(bool v) => setState(() => _newRegistrationsAllowed = v);
  void _setCommissionRate(double v) => setState(() => _commissionRate = v);
  void _setMaxDrivers(double v) => setState(() => _maxDriversPerZone = v.round());

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16), decoration: TayyebGoTheme.cardDecoration, child: Column(children: [
        _SettingsSwitch(title: 'Audit Log', subtitle: 'Track all admin actions', value: _auditLogEnabled, onChanged: _setAuditLog),
        const Divider(),
        _SettingsSwitch(title: 'Maintenance Mode', subtitle: 'Disable all user operations', value: _maintenanceMode, onChanged: _setMaintenance),
        const Divider(),
        _SettingsSwitch(title: 'Allow New Registrations', subtitle: 'Enable or disable sign-ups', value: _newRegistrationsAllowed, onChanged: _setNewRegistrations),
      ])),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16), decoration: TayyebGoTheme.cardDecoration, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Commission Rate', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${_commissionRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor)),
        Slider(value: _commissionRate, min: 5, max: 40, divisions: 35, label: '${_commissionRate.toStringAsFixed(0)}%', onChanged: _setCommissionRate),
        const SizedBox(height: 8),
        const Text('Max Drivers Per Zone', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$_maxDriversPerZone', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TayyebGoTheme.primaryColor)),
        Slider(value: _maxDriversPerZone.toDouble(), min: 5, max: 50, divisions: 45, label: '$_maxDriversPerZone', onChanged: _setMaxDrivers),
      ])),
    ]);
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsSwitch({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: TayyebGoTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
