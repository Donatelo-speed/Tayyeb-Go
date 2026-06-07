import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../infrastructure/services/auto_dispatcher.dart';

class AutoDispatchListener extends StatefulWidget {
  final Widget child;

  const AutoDispatchListener({super.key, required this.child});

  @override
  State<AutoDispatchListener> createState() => _AutoDispatchListenerState();
}

class _AutoDispatchListenerState extends State<AutoDispatchListener> {
  final Set<String> _processed = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dispatch_requests')
          .where('status', whereIn: ['pending', 'reassigning'])
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            if (_processed.contains(doc.id)) continue;
            _processed.add(doc.id);
            final d = doc.data() as Map<String, dynamic>;
            final restaurantId = d['restaurantId'] as String? ?? '';
            AutoDispatcher.instance.findAndAssignDriver(doc.id, restaurantId);
          }
        }
        return widget.child;
      },
    );
  }
}
