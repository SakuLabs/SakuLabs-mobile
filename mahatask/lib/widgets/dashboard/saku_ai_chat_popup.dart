import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/agent_service.dart';
import '../../services/auth_provider.dart';

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
    final width = size.width.clamp(320.0, 480.0);
    final maxHeight = (size.height - 32 - insets.bottom).clamp(460.0, 760.0);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + insets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: const Color(0xFF111725),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(child: _ChatBackdrop()),
                        ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(26, 28, 26, 18),
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
  const _Header({required this.onClose, required this.onNew});

  final VoidCallback onClose;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          const _Logo(size: 46, asset: 'assets/img/black-logo.png'),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Saku AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your scheduling assistant',
                  style: TextStyle(
                    color: Color(0xFF9BA1AE),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'New chat',
            onPressed: onNew,
            icon: const Icon(Icons.add_rounded, color: Color(0xFFC6CBD6)),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Color(0xFFC6CBD6)),
          ),
        ],
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
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Saya bisa bantu atur tugas dan jadwalmu. Coba tanya:',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9BA1AE),
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
        minHeight: 76,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(suggestion.icon, color: const Color(0xFFC6D1FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                suggestion.text,
                style: const TextStyle(
                  color: Color(0xFFE2E6EE),
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7D8490)),
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
              ? const Color(0xFF7B61FF)
              : Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFFE8ECF5),
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
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
        color: const Color(0xFF263044).withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Message Saku AI...',
                hintStyle: const TextStyle(color: Color(0xFF8B92A1)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFB7D0FF)),
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
                backgroundColor: Colors.white.withValues(alpha: 0.16),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 0.9,
          colors: [
            const Color(0xFF59647A).withValues(alpha: 0.4),
            const Color(0xFF141B2A).withValues(alpha: 0.98),
            const Color(0xFF1F2D43),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
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
