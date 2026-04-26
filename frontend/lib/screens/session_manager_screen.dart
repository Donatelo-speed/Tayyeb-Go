import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class SessionManagerScreen extends StatefulWidget {
  const SessionManagerScreen({super.key});

  @override
  State<SessionManagerScreen> createState() => _SessionManagerScreenState();
}

class _SessionManagerScreenState extends State<SessionManagerScreen> {
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessions = _auth.getSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
        centerTitle: true,
      ),
      body: _sessions.isEmpty
          ? _EmptyState(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return _SessionCard(
                  session: session,
                  isDark: isDark,
                  onLogout: () => _logoutSession(session['id']),
                  onLogoutAll: index == 0 ? null : () => _logoutAll(),
                );
              },
            ),
    );
  }

  void _logoutSession(int sessionId) async {
    final confirm = await _showConfirmDialog('Logout this device?');
    if (confirm == true) {
      await _auth.logoutSession(sessionId);
      _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device logged out')));
      }
    }
  }

  void _logoutAll() async {
    final confirm = await _showConfirmDialog('Logout all other devices? This device will stay logged in.');
    if (confirm == true) {
      await _auth.logoutAllOtherSessions();
      _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All other devices logged out')));
      }
    }
  }

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.devices, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text('No active sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Login to see your devices here', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isDark;
  final VoidCallback onLogout;
  final VoidCallback? onLogoutAll;

  const _SessionCard({
    required this.session,
    required this.isDark,
    required this.onLogout,
    this.onLogoutAll,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = session['current'] == true;
    final method = session['method'] ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getMethodColor(method).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getMethodIcon(method),
              color: _getMethodColor(method),
            ),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getDeviceName(method),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('This device', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(session['ip'] ?? 'Unknown IP', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(
                  _formatTime(session['createdAt']),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          
          // Actions
          if (!isCurrent)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: onLogout,
            )
          else if (onLogoutAll != null)
            TextButton(
              onPressed: onLogoutAll,
              child: const Text('Logout Others', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  String _getDeviceName(String method) {
    switch (method) {
      case 'email': return 'Email Login';
      case 'google': return 'Google';
      case 'apple': return 'Apple';
      case 'phone': return 'Phone OTP';
      case 'biometric': return 'Biometric';
      default: return 'Device';
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'email': return Icons.email;
      case 'google': return Icons.g_mobiledata;
      case 'apple': return Icons.apple;
      case 'phone': return Icons.phone_android;
      case 'biometric': return Icons.fingerprint;
      default: return Icons.device_unknown;
    }
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'email': return Colors.blue;
      case 'google': return Colors.red;
      case 'apple': return Colors.black;
      case 'phone': return Colors.green;
      case 'biometric': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return 'Just now';
    try {
      final dt = DateTime.parse(isoTime);
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return 'Just now';
    }
  }
}