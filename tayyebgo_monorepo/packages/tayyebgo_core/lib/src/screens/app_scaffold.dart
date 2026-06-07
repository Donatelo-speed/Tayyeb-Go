import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/tayyebgo_theme.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? bottom;
  final bool showCart;
  final bool showNotifications;
  final bool showAppBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.bottom,
    this.showCart = false,
    this.showNotifications = false,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              bottom: bottom,
              actions: [
                if (actions != null) ...actions!,
                if (showNotifications) _NotificationBadge(),
                if (showCart) _CartBadge(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle_outlined),
                  onSelected: (value) async {
                    if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      context.go('/settings');
                    } else if (value == 'logout') {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Text('Profile'),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        final unread = snap.hasData ? snap.data!.docs.length : 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go('/notifications'),
            ),
            if (unread > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 10,
                  height: 10,
              decoration: BoxDecoration(color: TayyebGoTheme.errorColor, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CartBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.isEmpty) return const SizedBox.shrink();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => context.go('/cart'),
        ),
        if (cart.totalQuantity > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: TayyebGoTheme.errorColor, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '${cart.totalQuantity}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
