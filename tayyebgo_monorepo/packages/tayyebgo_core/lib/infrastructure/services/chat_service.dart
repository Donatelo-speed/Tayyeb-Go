import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Real-time chat between customer and driver during an order.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': isRead,
  };
}

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _messagesStream;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  Stream<QuerySnapshot>? get messagesStream => _messagesStream;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  /// Starts listening to messages for an order's chat room.
  void startChat(String orderId) {
    _isLoading = true;
    notifyListeners();

    _messagesStream = _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    _messagesStream?.listen((snapshot) {
      _messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Sends a message in the chat room.
  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    await _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .add(ChatMessage(
          id: '',
          senderId: senderId,
          senderName: senderName,
          text: text.trim(),
          timestamp: DateTime.now(),
        ).toMap());

    // Update chat room metadata
    await _firestore.collection('chats').doc(orderId).set({
      'orderId': orderId,
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Marks messages as read.
  Future<void> markAsRead(String orderId, String userId) async {
    final unread = await _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Gets unread message count for an order.
  Stream<int> getUnreadCount(String orderId, String userId) {
    return _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Ends the chat for a delivered order.
  Future<void> endChat(String orderId) async {
    await _firestore.collection('chats').doc(orderId).update({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _messagesStream = null;
    _messages = [];
    super.dispose();
  }
}
