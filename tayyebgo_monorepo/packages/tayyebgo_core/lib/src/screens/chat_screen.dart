import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

/// Real-time chat screen for customer-driver communication during an order.
class ChatScreen extends StatefulWidget {
  final String orderId;
  final String currentUserId;
  final String currentUserName;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _chatService.startChat(widget.orderId);
    _chatService.addListener(_scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      orderId: widget.orderId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      text: text,
    );
    _controller.clear();
  }

  @override
  void dispose() {
    _chatService.removeListener(_scrollToBottom);
    _chatService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListenableBuilder(
              listenable: _chatService,
              builder: (context, _) {
                if (_chatService.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_chatService.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start a conversation',
                      style: GoogleFonts.inter(color: context.textMutedColor),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatService.messages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatService.messages[index];
                    final isMe = msg.senderId == widget.currentUserId;
                    return _ChatBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.inter(color: context.textMutedColor),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.brFull,
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.brFull,
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: context.primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? context.primaryColor : context.surfaceColor,
          borderRadius: AppRadius.brCard.copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white70 : context.primaryColor,
                ),
              ),
            Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isMe ? Colors.white : context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isMe ? Colors.white60 : context.textMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
