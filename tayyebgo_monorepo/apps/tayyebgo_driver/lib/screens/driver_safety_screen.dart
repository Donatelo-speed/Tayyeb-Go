import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverSafetyScreen extends StatelessWidget {
  const DriverSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Safety',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red.withOpacity(0.1),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.sos, color: Colors.white),
              ),
              title: const Text('SOS Emergency', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: const Text('Alert support team immediately'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSosDialog(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.warning, color: Colors.white),
              ),
              title: const Text('Report an Issue'),
              subtitle: const Text('Harassment, unsafe area, accident'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReportDialog(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.verified_user, color: Colors.white),
              ),
              title: const Text('Identity Verification'),
              subtitle: const Text('Verify your identity for safety'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profile'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.phone, color: Colors.white),
              ),
              title: const Text('Emergency Contact'),
              subtitle: const Text('Call support: 0XX-XXX-XXX'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SOS Emergency'),
        content: const Text('Your location and details will be sent to our support team immediately. Do you want to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS alert sent to support')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Issue'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
