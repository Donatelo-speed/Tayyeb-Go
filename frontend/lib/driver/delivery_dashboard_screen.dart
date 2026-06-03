import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/tayyebgo_theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/responsive_layout.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<DriverProvider>().loadDriverData(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final data = provider.data;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: TayyebGoTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delivery_dining,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Driver Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => auth.logout(context),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(provider, data, auth),
        desktop: _buildDesktopLayout(provider, data, auth),
      ),
    );
  }

  Widget _buildMobileLayout(
      DriverProvider provider, DriverData? data, AuthProvider auth) {
    return Column(
      children: [
        _ProfileCard(data: data, provider: provider, auth: auth),
        Expanded(child: _buildTabContent(provider, data)),
      ],
    );
  }

  Widget _buildDesktopLayout(
      DriverProvider provider, DriverData? data, AuthProvider auth) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _ProfileCard(data: data, provider: provider, auth: auth),
              Expanded(child: _StatsView(data: data)),
            ],
          ),
        ),
        Container(width: 1, color: TayyebGoTheme.dividerColor),
        Expanded(child: _buildTabContent(provider, data)),
      ],
    );
  }

  Widget _buildTabContent(DriverProvider provider, DriverData? data) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _TabChip(
                label: 'Available Jobs',
                icon: Icons.work_outline,
                isSelected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Active Deliveries',
                icon: Icons.delivery_dining,
                isSelected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
                count: data?.activeDeliveries.length,
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedTab == 0
              ? _AvailableJobsSection(provider: provider)
              : _ActiveDeliveriesSection(provider: provider, data: data),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? TayyebGoTheme.primaryColor
              : TayyebGoTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? TayyebGoTheme.primaryColor
                : TayyebGoTheme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? Colors.white : TayyebGoTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : TayyebGoTheme.textSecondary,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : TayyebGoTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : TayyebGoTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final DriverData? data;
  final DriverProvider provider;
  final AuthProvider auth;

  const _ProfileCard({
    required this.data,
    required this.provider,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const ShimmerLoading(height: 120, borderRadius: 16),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: TayyebGoTheme.primaryCardDecoration,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: TayyebGoTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (data?.name ?? 'D').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data?.name ?? 'Driver',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      (data?.rating ?? 0).toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: data?.isOnline == true
                            ? TayyebGoTheme.successColor
                            : TayyebGoTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data?.isOnline == true ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: data?.isOnline == true
                            ? TayyebGoTheme.successColor
                            : TayyebGoTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: data?.isOnline ?? false,
            onChanged: (v) {
              if (auth.user != null) {
                provider.toggleAvailability(auth.user!.id, v);
              }
            },
            activeThumbColor: TayyebGoTheme.successColor,
          ),
        ],
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  final DriverData? data;

  const _StatsView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _StatBox(
            icon: Icons.delivery_dining,
            label: 'Deliveries',
            value: '${data?.todayDeliveries ?? 0}',
            color: TayyebGoTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          _StatBox(
            icon: Icons.attach_money,
            label: 'Earnings',
            value: '\$${(data?.todayEarnings ?? 0).toStringAsFixed(0)}',
            color: TayyebGoTheme.successColor,
          ),
          const SizedBox(height: 8),
          _StatBox(
            icon: Icons.timer_outlined,
            label: 'Online Time',
            value: data?.onlineTime ?? '0h',
            color: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TayyebGoTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: TayyebGoTheme.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _AvailableJobsSection extends StatelessWidget {
  final DriverProvider provider;

  const _AvailableJobsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready_for_driver')
          .where('driverId', isNull: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: TayyebGoTheme.errorColor),
                const SizedBox(height: 12),
                const Text('Could not load available jobs',
                    style: TextStyle(color: TayyebGoTheme.textSecondary)),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const ShimmerList();
        }
        final jobs = snapshot.data!.docs;
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 64, color: TayyebGoTheme.textMuted),
                const SizedBox(height: 16),
                const Text('No available jobs',
                    style:
                        TextStyle(fontSize: 16, color: TayyebGoTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('Check back soon!',
                    style: TextStyle(
                        fontSize: 13, color: TayyebGoTheme.textMuted)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final doc = jobs[index];
            final d = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: TayyebGoTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant,
                          color: TayyebGoTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(d['vendorName'] as String? ?? 'Restaurant',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Text(
                        '\$${(d['totalAmount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: TayyebGoTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: TayyebGoTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d['deliveryAddress'] is Map
                              ? '${(d['deliveryAddress'] as Map)['street'] ?? ''}, ${(d['deliveryAddress'] as Map)['city'] ?? ''}'
                              : 'Address not specified',
                          style: const TextStyle(
                              fontSize: 13,
                              color: TayyebGoTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: TayyebGoTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(d['customerName'] as String? ?? 'Guest',
                          style: const TextStyle(
                              fontSize: 13,
                              color: TayyebGoTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => provider.claimDeliveryJob(doc.id),
                      icon: const Icon(Icons.handshake, size: 18),
                      label: const Text('Claim Delivery'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveDeliveriesSection extends StatelessWidget {
  final DriverProvider provider;
  final DriverData? data;

  const _ActiveDeliveriesSection({
    required this.provider,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final deliveries = data?.activeDeliveries ?? [];

    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_outlined,
                size: 64, color: TayyebGoTheme.textMuted),
            const SizedBox(height: 16),
            const Text('No active deliveries',
                style:
                    TextStyle(fontSize: 16, color: TayyebGoTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('Claim a job from Available Jobs tab',
                style: TextStyle(fontSize: 13, color: TayyebGoTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        final statusColor = TayyebGoTheme.statusColor(delivery.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: TayyebGoTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      delivery.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${delivery.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: TayyebGoTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: TayyebGoTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(delivery.address,
                        style: const TextStyle(
                            fontSize: 13,
                            color: TayyebGoTheme.textSecondary)),
                  ),
                ],
              ),
              if (delivery.distance > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.map,
                        size: 14, color: TayyebGoTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${delivery.distance.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                          fontSize: 13, color: TayyebGoTheme.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Navigation started (demo)')),
                        );
                      },
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          provider.completeDelivery(delivery.orderId),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TayyebGoTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
