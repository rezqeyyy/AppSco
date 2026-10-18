import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../../core/i18n/tr_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'ansco_chat.dart';
import 'floating_ansco.dart';

/// Layar chat dengan AnSco.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();

  static const List<String> _suggestions = <String>[
    'Jelaskan hasil screening terakhirku',
    'Apa itu skoliosis?',
    'Kapan aku perlu ke dokter?',
    'Gimana cara foto punggung yang benar?',
  ];

  @override
  void initState() {
    super.initState();
    anscoBubble.chatOpen = true;
    anscoChat.ensureLoaded();
  }

  @override
  void dispose() {
    anscoBubble.chatOpen = false;
    _input.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final String t = (text ?? _input.text).trim();
    if (t.isEmpty || anscoChat.sending) return;
    _input.clear();
    anscoChat.send(t);
  }

  Future<void> _confirmClear() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Hapus percakapan?'),
        content: const Text('Semua pesan dengan AnSco di HP ini akan dihapus.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: ts(14, weight: FontWeight.w700, color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true) anscoChat.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            const AnScoAvatar(size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('AnSco', translate: false, style: ts(17, weight: FontWeight.w800, height: 22)),
                  Text('Asisten AppSco · bukan dokter', style: ts(12, color: AppColors.muted, height: 16)),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          AnimatedBuilder(
            animation: anscoChat,
            builder: (BuildContext context, Widget? child) => anscoChat.messages.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: tr('Hapus percakapan'),
                    onPressed: _confirmClear,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: AnimatedBuilder(
              animation: anscoChat,
              builder: (BuildContext context, Widget? child) => _buildList(),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildList() {
    final List<ChatMessage> msgs = anscoChat.messages;
    // Daftar dibalik (reverse) supaya selalu menempel ke pesan terbaru di bawah.
    final List<Widget> items = <Widget>[
      if (anscoChat.error != null) _ErrorCard(message: anscoChat.error!, onRetry: anscoChat.retry),
      if (anscoChat.sending) const _TypingBubble(),
      for (final ChatMessage m in msgs.reversed) _Bubble(message: m),
      if (msgs.isEmpty) ...<Widget>[
        _buildSuggestions(),
        const SizedBox(height: 4),
        _Bubble(
          message: ChatMessage(
            fromUser: false,
            text: tr('Hai! Aku AnSco 👋 Aku bisa bantu jelasin hasil screening-mu, '
                'cerita soal skoliosis, atau cara pakai aplikasi ini. Mau tanya apa?'),
            time: DateTime.now(),
          ),
        ),
      ],
    ];
    return ListView(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: items,
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final String s in _suggestions)
            ActionChip(
              label: Text(s, style: ts(13, weight: FontWeight.w600, color: AppColors.tealDark)),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.line),
              onPressed: () => _send(tr(s)),
            ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: tr('Tulis pesan untuk AnSco…'),
                filled: true,
                fillColor: AppColors.ground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: anscoChat,
            builder: (BuildContext context, Widget? child) => Material(
              color: anscoChat.sending ? AppColors.line : AppColors.teal,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: anscoChat.sending ? null : _send,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kepala AnSco di lingkaran gelap (gambarnya putih, jadi butuh latar gelap).
class AnScoAvatar extends StatelessWidget {
  const AnScoAvatar({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.15),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealDeep),
      child: Image.asset(anscoHeadAsset, fit: BoxFit.contain),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool me = message.fromUser;
    final Widget bubble = Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: me ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(me ? 18 : 4),
            bottomRight: Radius.circular(me ? 4 : 18),
          ),
          boxShadow: me ? null : AppColors.softShadow,
        ),
        child: Text.rich(
          _rich(message.text, me ? Colors.white : AppColors.ink),
          translate: false,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!me) ...<Widget>[const AnScoAvatar(), const SizedBox(width: 8)],
          bubble,
          if (me) const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Tebal untuk **teks** dan titik untuk baris yang diawali "- " atau "* ".
  static TextSpan _rich(String text, Color color) {
    final TextStyle base = ts(14, color: color, height: 20);
    final List<InlineSpan> spans = <InlineSpan>[];
    final List<String> lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      final String trimmed = line.trimLeft();
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        line = '•  ${trimmed.substring(2)}';
      }
      final List<String> parts = line.split('**');
      for (int j = 0; j < parts.length; j++) {
        if (parts[j].isEmpty) continue;
        spans.add(TextSpan(
          text: parts[j],
          style: j.isOdd ? base.copyWith(fontWeight: FontWeight.w800) : base,
        ));
      }
      if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: base));
    }
    return TextSpan(style: base, children: spans);
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          const AnScoAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.softShadow,
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (BuildContext context, Widget? child) => Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Transform.translate(
                        offset: Offset(0, -3 * math.max(0, math.sin((_c.value - i * 0.15) * 2 * math.pi))),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: AppColors.muted, shape: BoxShape.circle),
                        ),
                      ),
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4, left: 42),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: ts(13, color: AppColors.ink, height: 18))),
          TextButton(
            onPressed: onRetry,
            child: Text('Coba lagi', style: ts(13, weight: FontWeight.w700, color: AppColors.teal)),
          ),
        ],
      ),
    );
  }
}