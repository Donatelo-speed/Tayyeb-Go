import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../design/design.dart';
import '../widgets/admin_widgets.dart';

class AICopilotScreen extends StatefulWidget {
  const AICopilotScreen({super.key});
  @override
  State<AICopilotScreen> createState() => _AICopilotScreenState();
}

class _ChatMessage {
  final String role;
  final String content;
  const _ChatMessage({required this.role, required this.content});
}

class _AICopilotScreenState extends State<AICopilotScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  static const _systemPrompt = 'You are the TayyebGo Operations AI Copilot. You can create stores, drivers, and campaigns. Generate reports and analyze performance. Detect problems and recommend solutions. Design store themes and layouts. Monitor platform health. You are direct, professional, and action-oriented. Suggest actions that admins can approve and execute. Current context: Homs, Syria delivery platform. Cash on delivery and Sham Cash payments.';

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      role: 'assistant',
      content: '\u{1F44B} Welcome to TayyebGo Operations Copilot. I can help you manage the platform.\n\nTry asking:\n- "Show weak stores"\n- "Create a pharmacy called Al Shifa"\n- "What is our revenue trend?"\n- "Create a Ramadan campaign"\n- "Show driver performance report"',
    ));
  }

  @override
  void dispose() { _inputCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();

    setState(() { _messages.add(_ChatMessage(role: 'user', content: text)); _loading = true; });
    _scrollDown();

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': ''},
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ..._messages.map((m) => {'role': m.role, 'content': m.content}),
          ],
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 15));

      String reply;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['choices'][0]['message']['content'] as String;
      } else {
        reply = _ruleBasedResponse(text);
      }
      setState(() => _messages.add(_ChatMessage(role: 'assistant', content: reply)));
    } catch (_) {
      setState(() => _messages.add(_ChatMessage(role: 'assistant', content: _ruleBasedResponse(text))));
    }
    setState(() => _loading = false);
    _scrollDown();
  }

  String _ruleBasedResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('weak') && q.contains('store')) {
      return '**Weak Store Analysis**\n\nI have identified stores with low performance. Check the Analytics section for store metrics - look at order volume, revenue, and rating. Common issues: low ratings, high cancellation rates, long preparation times.\n\nRecommendation: Contact underperforming stores and offer optimization support.';
    }
    if (q.contains('create') && q.contains('pharmacy')) {
      return '**Store Creation Draft**\n\nI will prepare a pharmacy store:\n\n- Name: Al Shifa Pharmacy\n- Business Type: Pharmacy\n- Delivery Mode: Platform\n- Status: Draft\n\nTo create this store, go to Stores > Create Business. I can help configure categories, theme colors, and featured sections.';
    }
    if (q.contains('ramadan') || q.contains('campaign')) {
      return '**Ramadan Campaign Draft**\n\nI have prepared a campaign:\n\n- Name: Ramadan Special Offer\n- Type: 20% discount on all orders\n- Target: All customers\n- Duration: Full Ramadan month\n- Status: Draft\n\nTo publish, go to Marketing > Create Campaign.';
    }
    if (q.contains('driver') && (q.contains('perform') || q.contains('report'))) {
      return '**Driver Performance Report**\n\nGo to the Drivers section for full driver analytics. Key metrics: online drivers vs total, completed deliveries per driver, average rating, response times. Filter by status to drill down.';
    }
    if (q.contains('revenue') || q.contains('trend')) {
      return '**Revenue Analysis**\n\nView the Finance section and Analytics section for detailed revenue data. Finance: revenue, commissions, refunds, settlements. Analytics: revenue trends, top stores, forecasting. Export reports as PDF or Excel.';
    }
    return 'I understand you are asking about that. Here is what I can help with:\n\n- Create stores, drivers, campaigns, notifications\n- Analyze performance, revenue, drivers, stores\n- Monitor platform health and detect issues\n- Export reports and data\n\nTry being more specific with your request, or use the dedicated sections in the sidebar for direct management.';
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: AdminDuration.fast, curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      const AdminSectionHeader(title: 'AI Operations Copilot'),
      Expanded(
        child: Container(
          color: AdminColors.bg(isDark),
          child: Column(children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(AdminSpacing.xl),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _ChatBubble(isDark: isDark, message: _messages[i]),
              ),
            ),
            if (_loading) Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary)),
                const SizedBox(width: AdminSpacing.sm),
                Text('Analyzing...', style: AdminTypography.caption(isDark)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              decoration: BoxDecoration(color: AdminColors.card(isDark), border: Border(top: BorderSide(color: AdminColors.border(isDark)))),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(hintText: 'Ask the Copilot...', prefixIcon: Icon(Icons.smart_toy_rounded, size: 20), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AdminSpacing.md),
                ElevatedButton.icon(onPressed: _loading ? null : _sendMessage, icon: const Icon(Icons.send_rounded, size: 18), label: const Text('Send')),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isDark;
  final _ChatMessage message;
  const _ChatBubble({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AdminSpacing.md),
        padding: const EdgeInsets.all(AdminSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: isUser ? AdminColors.primary : AdminColors.card(isDark),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AdminRadius.xl),
            topRight: const Radius.circular(AdminRadius.xl),
            bottomLeft: Radius.circular(isUser ? AdminRadius.xl : AdminRadius.xs),
            bottomRight: Radius.circular(isUser ? AdminRadius.xs : AdminRadius.xl),
          ),
          border: isUser ? null : Border.all(color: AdminColors.border(isDark)),
        ),
        child: _buildContent(isDark, isUser),
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isUser) {
    final color = isUser ? Colors.white : AdminColors.textPrimary(isDark);
    final lines = message.content.split('\n');
    final spans = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('**') && line.endsWith('**')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line.substring(2, line.length - 2), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        ));
      } else if (line.startsWith('- ')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(bottom: 2, left: 8),
          child: Text(line, style: TextStyle(fontSize: 13, color: color, height: 1.6)),
        ));
      } else {
        spans.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(line, style: TextStyle(fontSize: 13, color: color, height: 1.5)),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: spans);
  }
}