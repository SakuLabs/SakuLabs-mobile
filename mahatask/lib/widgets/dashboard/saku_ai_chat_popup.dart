import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/services/agent_service.dart';
import 'package:mahatask/services/auth_provider.dart';

Future<void> showSakuAiChatPopup(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close Saku AI',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _SakuAiChatPopup();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _SakuAiChatPopup extends StatefulWidget {
  const _SakuAiChatPopup();

  @override
  State<_SakuAiChatPopup> createState() => _SakuAiChatPopupState();
}

class _SakuAiChatPopupState extends State<_SakuAiChatPopup> {
  final AgentService _agentService = AgentService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  String? _conversationId;
  bool _sending = false;

  static const _suggestions = <_Suggestion>[
    _Suggestion(
      icon: Icons.checklist_rounded,
      text: 'Apa saja tugas saya minggu ini?',
    ),
    _Suggestion(
      icon: Icons.calendar_month_rounded,
      text: 'Buat jadwal belajar besok jam 7 malam',
    ),
    _Suggestion(
      icon: Icons.local_fire_department_outlined,
      text: 'Tugas mana yang paling mendesak?',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage.user(text));
      _sending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await _agentService.sendMessage(
        content: text,
        conversationId: _conversationId,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = result.conversationId;
        _messages.add(_ChatMessage.assistant(result.reply));
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _messages.add(
          _ChatMessage.assistant(
            message.isEmpty
                ? 'Saku AI belum bisa dihubungi. Coba lagi nanti.'
                : message,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _newChat() {
    setState(() {
      _conversationId = null;
      _messages.clear();
      _controller.clear();
    });
  }

  Future<void> _showHistory() async {
    try {
      final conversations = await _agentService.fetchConversations();
      if (!mounted) return;
      if (conversations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada riwayat percakapan.')),
        );
        return;
      }
      final selected = await showDialog<AgentConversation>(
        context: context,
        builder: (context) => _HistoryDialog(conversations: conversations),
      );
      if (selected == null) return;
      await _loadConversation(selected.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    final messages = await _agentService.fetchMessages(conversationId);
    if (!mounted) return;
    setState(() {
      _conversationId = conversationId;
      _messages
        ..clear()
        ..addAll(
          messages.where((message) => message.role != 'tool').map((message) {
            if (message.role == 'user') return _ChatMessage.user(message.content);
            return _ChatMessage.assistant(message.content);
          }),
        );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final rawName = user?.name.trim();
    final name = rawName == null || rawName.isEmpty
        ? 'teman'
        : rawName.split(' ').first;
    final insets = MediaQuery.viewInsetsOf(context);
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 24).clamp(0.0, 480.0);
    final maxHeight = (size.height - 32 - insets.bottom).clamp(460.0, 760.0);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + insets.bottom),
        child: Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 28,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _Header(
                    onClose: () => Navigator.of(context).pop(),
                    onNew: _newChat,
                    onHistory: _showHistory,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(child: _ChatBackdrop()),
                        ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                          children: [
                            if (_messages.isEmpty) ...[
                              _Welcome(name: name),
                              const SizedBox(height: 26),
                              ..._suggestions.map((suggestion) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _SuggestionTile(
                                    suggestion: suggestion,
                                    onTap: () => _send(suggestion.text),
                                  ),
                                );
                              }),
                            ] else ...[
                              for (final message in _messages)
                                _MessageBubble(message: message),
                              if (_sending)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8, bottom: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _TypingIndicator(),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _Composer(
                    controller: _controller,
                    sending: _sending,
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onClose,
    required this.onNew,
    required this.onHistory,
  });

  final VoidCallback onClose;
  final VoidCallback onNew;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          const _Logo(size: 42, asset: 'assets/img/black-logo.png'),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Saku AI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your scheduling assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'History',
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            onPressed: onHistory,
            icon: const Icon(
              Icons.history_rounded,
              color: Color(0xFF334155),
              size: 21,
            ),
          ),
          IconButton(
            tooltip: 'New chat',
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            onPressed: onNew,
            icon: const Icon(
              Icons.add_rounded,
              color: Color(0xFF334155),
              size: 22,
            ),
          ),
          IconButton(
            tooltip: 'Close',
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF334155),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDialog extends StatelessWidget {
  const _HistoryDialog({required this.conversations});

  final List<AgentConversation> conversations;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Saku AI',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.black.withValues(alpha: 0.08),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.of(context).pop(conversation),
                      leading: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF3B82F6),
                      ),
                      title: Text(
                        conversation.title.isEmpty
                            ? 'Percakapan Saku AI'
                            : conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _formatHistoryDate(conversation.updatedAt),
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Logo(size: 72, asset: 'assets/img/black-logo.png'),
        const SizedBox(height: 18),
        Text(
          'Halo, $name',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Saya bisa bantu atur tugas dan jadwalmu. Coba tanya:',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(suggestion.icon, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                suggestion.text,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == _Sender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2563EB)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF1F2937),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Message Saku AI...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: sending ? null : onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBackdrop extends StatelessWidget {
  const _ChatBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFFFFFFF)),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size, required this.asset});

  final double size;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: const Color(0xFF090D1A),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF406CFF).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _ChatMessage {
  const _ChatMessage._({required this.sender, required this.text});

  factory _ChatMessage.user(String text) {
    return _ChatMessage._(sender: _Sender.user, text: text);
  }

  factory _ChatMessage.assistant(String text) {
    return _ChatMessage._(sender: _Sender.assistant, text: text);
  }

  final _Sender sender;
  final String text;
}

enum _Sender { user, assistant }

String _formatHistoryDate(DateTime? value) {
  if (value == null) return 'Tanpa tanggal';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
