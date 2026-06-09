import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../../presentation/theme/theme_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: userId == null
          ? Center(child: Text('Not logged in', style: GoogleFonts.inter(color: context.textMutedColor)))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<NotificationsProvider>().watchNotifications(userId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: context.errorColor),
                        const SizedBox(height: 12),
                        Text('Failed to load', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14)),
                      ],
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: context.primaryColor));
                }
                final docs = snap.data ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Icon(Icons.notifications_none_rounded, size: 36, color: context.textMutedColor),
                        ),
                        const SizedBox(height: 16),
                        Text('No notifications yet', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('We\'ll let you know when something happens', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: context.primaryColor,
                  backgroundColor: context.surfaceColor,
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final read = d['read'] as bool? ?? false;
                      final title = d['title'] as String? ?? '';
                      final body = d['body'] as String? ?? '';
                      final time = d['createdAt'] as String? ?? '';
                      return GestureDetector(
                        onTap: () {
                          if (!read) {
                            context.read<NotificationsProvider>().markAsRead(d['id'] as String);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: read ? context.surfaceColor : context.surfaceColor.withValues(alpha: 1.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: read ? context.borderColor : context.primaryColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: read ? Colors.transparent : context.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.inter(
                                        fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                                        fontSize: 14,
                                        color: read ? context.textMutedColor : context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 13),
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(_timeAgo(time), style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
