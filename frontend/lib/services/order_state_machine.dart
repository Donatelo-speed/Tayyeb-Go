import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// -------------------------------------------------------------------
/// OrderStateMachine — canonical status transitions with Firestore write
/// and error feedback via SnackBar.
///
/// Valid transitions:
///   pending  ──► accepted  ──► preparing  ──► ready_for_driver
///                                                    │
///                                        (driver claims)
///                                                    ▼
///                                              picked_up  ──► delivered
///   Any state ──► cancelled
/// -------------------------------------------------------------------

class OrderStateMachine {
  /// Returns the next allowed status when advancing forward from [current].
  /// Returns null if [current] is terminal.
  static String? nextStatus(String current) {
    switch (current) {
      case 'pending':
        return 'accepted';
      case 'accepted':
        return 'preparing';
      case 'preparing':
        return 'ready_for_driver';
      case 'ready_for_driver':
        return 'picked_up';
      case 'picked_up':
        return 'delivered';
      default:
        return null; // terminal or unknown
    }
  }

  /// All statuses a human actor can jump to from [current] (including
  /// cancellation).  Used by cashier / vendor action buttons.
  static List<String> availableActions(String current) {
    final next = nextStatus(current);
    final actions = <String>[];
    if (next != null) actions.add(next);
    if (current != 'cancelled' && current != 'delivered') {
      actions.add('cancelled');
    }
    return actions;
  }

  /// Human-readable label for the "advance" button.
  static String actionLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accept Order';
      case 'preparing':
        return 'Start Preparing';
      case 'ready_for_driver':
        return 'Mark Ready';
      case 'picked_up':
        return 'Mark Picked Up';
      case 'delivered':
        return 'Complete Delivery';
      case 'cancelled':
        return 'Cancel Order';
      default:
        return status;
    }
  }

  /// Write a status transition to Firestore, record the event in
  /// statusHistory, and show a SnackBar on success or failure.
  static Future<bool> transition({
    required BuildContext context,
    required String orderId,
    required String newStatus,
    String? actorId,
    String? note,
  }) async {
    try {
      final ref = FirebaseFirestore.instance.collection('orders').doc(orderId);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Order not found');

        final history = List<Map<String, dynamic>>.from(
          (snap.data() as Map<String, dynamic>)['statusHistory'] ?? [],
        );
        history.add({
          'status': newStatus,
          'timestamp': FieldValue.serverTimestamp(),
          'actorId': actorId ?? '',
          'note': ?note,
        });

        tx.update(ref, {
          'status': newStatus,
          'statusHistory': history,
          'updatedAt': FieldValue.serverTimestamp(),
          if (newStatus == 'accepted')
            'acceptedAt': FieldValue.serverTimestamp(),
          if (newStatus == 'delivered')
            'deliveredAt': FieldValue.serverTimestamp(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $orderId → $newStatus'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transition failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }
}
