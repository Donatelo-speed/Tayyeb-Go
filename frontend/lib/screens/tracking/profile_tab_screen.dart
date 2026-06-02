import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/tayyebgo_theme.dart';

class ProfileTabScreen extends StatelessWidget {
  final String tab;
  const ProfileTabScreen({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAddresses = tab == 'addresses';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAddresses ? 'My Addresses' : 'Personal Info'),
        backgroundColor: TayyebGoTheme.surfaceColor,
      ),
      body: isAddresses ? _buildAddresses(context) : _buildPersonalInfo(context, user),
    );
  }

  Widget _buildAddresses(BuildContext context) {
    final addresses = [
      {'label': 'Home', 'address': '123 Main Street, Riyadh', 'isDefault': true},
      {'label': 'Work', 'address': '456 Business Ave, Riyadh', 'isDefault': false},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length + 1,
      itemBuilder: (context, index) {
        if (index == addresses.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TayyebGoTheme.primaryColor,
                  side: const BorderSide(color: TayyebGoTheme.primaryColor),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          );
        }
        final addr = addresses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TayyebGoTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TayyebGoTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: TayyebGoTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(addr['label'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (addr['isDefault'] as bool) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TayyebGoTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Default',
                                style: TextStyle(
                                    color: TayyebGoTheme.primaryColor, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(addr['address'] as String,
                        style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfo(BuildContext context, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoField(label: 'Name', value: user?.displayName ?? 'User'),
          _InfoField(label: 'Email', value: user?.email ?? ''),
          _InfoField(label: 'Phone', value: user?.phone ?? 'Not set'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: TayyebGoTheme.primaryColor,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Edit Profile',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TayyebGoTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: TayyebGoTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, size: 18, color: TayyebGoTheme.textMuted),
        ],
      ),
    );
  }
}
