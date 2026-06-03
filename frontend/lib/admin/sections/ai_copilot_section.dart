import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin_design.dart';

class AICopilotSection extends StatefulWidget {
  const AICopilotSection({super.key});
  @override
  State<AICopilotSection> createState() => _AICopilotSectionState();
}

class _AICopilotSectionState extends State<AICopilotSection> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_CopilotMessage> _messages = [];
  bool _loading = false;
  Timer? _dataRefreshTimer;

  final _systemPrompt = '''You are the TayyebGo Admin AI Copilot. You have deep platform knowledge and can assist with:
1. Creating and managing stores, drivers, campaigns.
2. Analyzing performance data and detecting problems.
3. Generating reports and insights.
4. Recommending actions: "weak stores need promotion", "driver shortage in zone X", "refund spike detected".
5. Creating campaign drafts.
6. Explaining platform features.
Always be concise, actionable, and data-driven. Suggest specific actions. Mention exact numbers when possible. Format responses with clear sections. Use **bold** for key terms.''';

  @override
  void initState() {
    super.initState();
    _messages.add(_CopilotMessage(role: 'ai', content: 'I\'m your AI Copilot. I can manage stores, analyze performance, create campaigns, and monitor the platform.\n\nTry:\n• "Show weak stores"\n• "Create Ramadan campaign"\n• "Analyze driver performance"\n• "Detect platform problems"'));
    _dataRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); _dataRefreshTimer?.cancel(); super.dispose(); }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() { _messages.add(_CopilotMessage(role: 'user', content: text)); _loading = true; });
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () => _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer YOUR_API_KEY'},
        body: jsonEncode({'model': 'gpt-4o-mini', 'messages': [{'role': 'system', 'content': _systemPrompt}, ..._messages.map((m) => {'role': m.role == 'ai' ? 'assistant' : 'user', 'content': m.content})], 'temperature': 0.7, 'max_tokens': 600}),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200 && mounted) {
        final reply = jsonDecode(response.body)['choices']?[0]?['message']?['content'] ?? 'No response.';
        setState(() => _messages.add(_CopilotMessage(role: 'ai', content: reply.toString().trim())));
      } else { _fallback(text); }
    } catch (_) { _fallback(text); }
    if (mounted) setState(() => _loading = false);
  }

  void _fallback(String query) {
    final q = query.toLowerCase();
    String r;
    if (q.contains('weak') || q.contains('problem')) {
      r = '**Platform Health Report**\n\nBased on data analysis:\n• Check Restaurants tab for stores with low ratings or high cancellation rates.\n• Monitor Commission tab for stores near debt ceiling — these may need intervention.\n• Review Orders tab for pattern of cancellations.\n\n**Recommendation:** Run a weekly performance review on all stores with rating < 3.5.';
    } else if (q.contains('campaign') || q.contains('ramadan') || q.contains('promotion')) r = '**Campaign Draft Created**\n\n📋 **Ramadan Campaign**\n• Type: Percentage Discount (15%)\n• Target: All customers\n• Duration: Ramadan month\n• Push notification: "Ramadan Kareem! 15% off all orders"\n\nDo you want me to create this campaign? Go to the Marketing tab to finalize.';
    else if (q.contains('driver') || q.contains('perf')) r = '**Driver Performance Summary**\n\nTo analyze driver performance:\n1. Go to Drivers tab — see online/offline status\n2. Check delivery completion rates\n3. Review ratings per driver\n\n**Suggestion:** Reward top 5 drivers monthly with bonus or reduced subscription.';
    else if (q.contains('store') || q.contains('restaurant')) r = '**Store Management**\n\nTo manage stores:\n1. Go to **Stores** tab\n2. Click **Create** to add a new store\n3. Fill business type, name, location\n4. Toggle open/closed status\n5. Set commission ceiling in **Finance** tab\n\nEach store type has different settings. Restaurants need menu, pharmacies need inventory.';
    else if (q.contains('revenue') || q.contains('report') || q.contains('analytics')) r = '**Quick Analytics**\n\nGo to **Analytics** tab for full data. Current snapshot includes:\n• Revenue tracking\n• Order volume\n• Store performance rankings\n• Customer growth\n\nFor detailed reports, use **Finance** tab for commission and settlement data.';
    else r = 'I can help with: Store management, driver analysis, campaign creation, performance monitoring, revenue reports, and platform troubleshooting.\n\nTry: "Show weak stores", "Create campaign", "Analyze drivers", "Revenue report"';
    if (mounted) setState(() => _messages.add(_CopilotMessage(role: 'ai', content: r)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AdminColors.primary, Color(0xFF8B5CF6)]), boxShadow: AdminShadows.topBar),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AdminRadius.lg)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Operations Copilot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Ask me to analyze, create, or manage', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_loading ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _messages.length) return const Padding(padding: EdgeInsets.all(12), child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary)), SizedBox(width: 8), Text('Thinking...', style: TextStyle(color: AdminColors.textDarkMuted, fontSize: 12))]));
            final m = _messages[i];
            final isUser = m.role == 'user';
            return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
              if (!isUser) Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 8), decoration: const BoxDecoration(color: AdminColors.primary, shape: BoxShape.circle), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: isUser ? AdminColors.primary : (isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard), borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4), bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16)), boxShadow: isUser ? null : AdminShadows.card(isDark)),
                  child: _renderMarkdown(m.content, isUser ? Colors.white : (isDark ? AdminColors.textDarkPrimary : AdminColors.textLightPrimary)),
                ),
              ),
              if (isUser) const SizedBox(width: 8, child: CircleAvatar(radius: 16, backgroundColor: AdminColors.primary, child: Icon(Icons.person_rounded, color: Colors.white, size: 16))),
            ]));
          },
        ),
      ),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isDark ? AdminColors.bgDarkCard : AdminColors.bgLightCard, boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, -2))]), child: Row(children: [
        Expanded(child: TextField(controller: _msgCtrl, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'Ask the AI Copilot...', filled: true, fillColor: isDark ? AdminColors.bgDarkInput : AdminColors.bgLightInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.lg), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), isDense: true))),
        const SizedBox(width: 8),
        Container(decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(AdminRadius.lg)), child: IconButton(onPressed: _loading ? null : _send, icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
      ])),
    ]);
  }

  Widget _renderMarkdown(String text, Color color) {
    final parts = text.split(RegExp(r'(\*\*.*?\*\*)'));
    return RichText(text: TextSpan(children: parts.map((p) {
      if (p.startsWith('**') && p.endsWith('**')) return TextSpan(text: p.substring(2, p.length - 2), style: TextStyle(fontWeight: FontWeight.bold, color: color));
      return TextSpan(text: p, style: TextStyle(color: color, fontSize: 13, height: 1.5));
    }).toList()));
  }
}

class _CopilotMessage {
  final String role, content;
  _CopilotMessage({required this.role, required this.content});
}