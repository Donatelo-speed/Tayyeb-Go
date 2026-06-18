import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import 'shared.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return pageContainer(
      context,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          backgroundColor: context.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildComposer(context),
              const SizedBox(height: 24),
              Text('Recent Notifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              const SizedBox(height: 12),
              _buildNotificationList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.send_rounded, color: context.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text('Send Notification', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.inter(color: context.textPrimaryColor),
            decoration: _inputDecoration(context, 'Title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            style: GoogleFonts.inter(color: context.textPrimaryColor),
            maxLines: 3,
            decoration: _inputDecoration(context, 'Message'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Audience:', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
              const SizedBox(width: 8),
              _chip('all', 'All', context),
              const SizedBox(width: 6),
              _chip('customers', 'Customers', context),
              const SizedBox(width: 6),
              _chip('drivers', 'Drivers', context),
              const SizedBox(width: 6),
              _chip('stores', 'Stores', context),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendNotification,
              icon: _sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_sending ? 'Sending...' : 'Send', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.textPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, BuildContext context) {
    final selected = _audience == value;
    return GestureDetector(
      onTap: () => setState(() => _audience = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor.withValues(alpha: 0.15) : context.surfaceAltColor,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: selected ? context.primaryColor : context.borderColor),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? context.primaryColor : context.textMutedColor)),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: context.textMutedColor),
      filled: true,
      fillColor: context.surfaceAltColor,
      border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: context.primaryColor)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildNotificationList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').orderBy('sentAt', descending: true).limit(50).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.primaryColor));
        if (snap.hasError) return Center(child: Text('Error loading', style: GoogleFonts.inter(color: context.textMutedColor)));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text('No notifications sent yet', style: GoogleFonts.inter(color: context.textMutedColor)));
        return Column(
          children: docs.map((doc) => _notificationItem(context, doc)).toList(),
        );
      },
    );
  }

  Widget _notificationItem(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final title = d['title'] as String? ?? '';
    final body = d['body'] as String? ?? '';
    final audience = d['audience'] as String? ?? 'all';
    final recipientCount = d['recipientCount'] as int? ?? 0;
    final sentAt = d['sentAt'] as Timestamp?;
    final sentText = sentAt != null ? _formatTime(sentAt.toDate()) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined, color: context.primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                    if (sentText.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(sentText, style: GoogleFonts.inter(fontSize: 10, color: context.textMutedColor)),
                    ],
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body, style: GoogleFonts.inter(fontSize: 12, color: context.textMutedColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: AppRadius.brMd),
                child: Text(audience, style: GoogleFonts.inter(fontSize: 10, color: context.primaryColor)),
              ),
              if (recipientCount > 0) ...[
                const SizedBox(height: 2),
                Text('$recipientCount recipients', style: GoogleFonts.inter(fontSize: 9, color: context.textMutedColor)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  Future<void> _sendNotification() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in title and message', style: GoogleFonts.inter()), backgroundColor: context.warningColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final audienceFilter = _audience == 'all' ? null : _audience;
      int recipientCount = 0;
      if (audienceFilter != null) {
        final roleMap = {'customers': 'customer', 'drivers': 'driver', 'stores': 'owner'};
        final role = roleMap[audienceFilter];
        if (role != null) {
          final snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role).where('isActive', isEqualTo: true).get();
          recipientCount = snap.docs.length;
        }
      } else {
        final snap = await FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: true).get();
        recipientCount = snap.docs.length;
      }
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'audience': _audience,
        'sentAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
        'recipientCount': recipientCount,
        'status': 'sent',
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification sent to $recipientCount users', style: GoogleFonts.inter()), backgroundColor: context.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e', style: GoogleFonts.inter()), backgroundColor: context.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
