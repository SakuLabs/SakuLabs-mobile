import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/session_store.dart';
import 'video_call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.isGroup,
  });

  final String id;
  final String title;
  final bool isGroup;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<ChatMessage> _messages = const <ChatMessage>[];
  Timer? _polling;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _polling = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _polling?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = widget.isGroup
          ? await _chatService.getGroupMessages(widget.id)
          : await _chatService.getDirectMessages(widget.id);
      if (!mounted) return;
      setState(() => _messages = list);
      _jumpToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      if (widget.isGroup) {
        await _chatService.sendGroupMessage(groupId: widget.id, content: text);
      } else {
        await _chatService.sendDirectMessage(userId: widget.id, content: text);
      }
      _messageController.clear();
      await _loadMessages(silent: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 70,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openVideoCall() {
    final me = SessionStore.user?.id ?? 'me';
    final ids = [me, widget.id]..sort();
    final roomId = 'dm-${ids.join('-')}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(roomId: roomId, title: widget.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1F),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(0.0, 393.0);
              final height = constraints.maxHeight;
              final scale = _BubbleScale(width: width, height: height);

              return SizedBox(
                width: width,
                height: height,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    scale.x(39),
                    scale.y(31),
                    scale.x(39),
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isGroup ? 'Group Chat' : 'Direct Chat',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: scale.font(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: scale.y(12)),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFA1C4FD),
                                Color(0xFFC2E9FB),
                                Color(0xFFE0C3FC),
                              ],
                              stops: [0, 0.5, 1],
                            ),
                          ),
                          child: Column(
                            children: [
                              _ChatDetailHeader(
                                scale: scale,
                                title: widget.title,
                                isGroup: widget.isGroup,
                                onBack: () => Navigator.pop(context),
                                onVideo: widget.isGroup ? null : _openVideoCall,
                              ),
                              Expanded(
                                child: _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF2386A2),
                                        ),
                                      )
                                    : _error != null
                                    ? _ChatDetailError(
                                        scale: scale,
                                        error: _error!,
                                        onReload: () => _loadMessages(),
                                      )
                                    : _MessageList(
                                        scale: scale,
                                        messages: _messages,
                                        controller: _scrollController,
                                      ),
                              ),
                              _MessageComposer(
                                scale: scale,
                                controller: _messageController,
                                sending: _sending,
                                onSend: _send,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatDetailHeader extends StatelessWidget {
  const _ChatDetailHeader({
    required this.scale,
    required this.title,
    required this.isGroup,
    required this.onBack,
    required this.onVideo,
  });

  final _BubbleScale scale;
  final String title;
  final bool isGroup;
  final VoidCallback onBack;
  final VoidCallback? onVideo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        scale.x(14),
        scale.h(28),
        scale.x(14),
        scale.h(16),
      ),
      child: Row(
        children: [
          _RoundIconButton(
            scale: scale,
            icon: Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            iconColor: Colors.black,
            onTap: onBack,
          ),
          SizedBox(width: scale.x(10)),
          _ChatAvatar(scale: scale, isGroup: isGroup, title: title),
          SizedBox(width: scale.x(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale.font(17),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isGroup ? 'Group room' : 'Simple bubble chat',
                  style: TextStyle(
                    color: const Color(0xFF5E7A83),
                    fontSize: scale.font(10),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onVideo != null)
            _RoundIconButton(
              scale: scale,
              icon: Icons.videocam_rounded,
              color: Colors.black,
              iconColor: Colors.white,
              onTap: onVideo!,
            ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scale,
    required this.messages,
    required this.controller,
  });

  final _BubbleScale scale;
  final List<ChatMessage> messages;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Container(
          width: scale.w(250),
          padding: EdgeInsets.all(scale.x(16)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(scale.radius(18)),
          ),
          child: Text(
            'No messages yet. Start with something small.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5E7A83),
              fontSize: scale.font(12),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        scale.x(14),
        scale.h(4),
        scale.x(14),
        scale.h(14),
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final mine = message.senderId == SessionStore.user?.id;
        return _BubbleMessage(scale: scale, message: message, mine: mine);
      },
    );
  }
}

class _BubbleMessage extends StatelessWidget {
  const _BubbleMessage({
    required this.scale,
    required this.message,
    required this.mine,
  });

  final _BubbleScale scale;
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: scale.w(245)),
        margin: EdgeInsets.symmetric(vertical: scale.h(4)),
        padding: EdgeInsets.fromLTRB(
          scale.x(12),
          scale.h(9),
          scale.x(12),
          scale.h(7),
        ),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF2386A2).withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(scale.radius(17)),
            topRight: Radius.circular(scale.radius(17)),
            bottomLeft: Radius.circular(scale.radius(mine ? 17 : 5)),
            bottomRight: Radius.circular(scale.radius(mine ? 5 : 17)),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: mine ? Colors.white : Colors.black,
                fontSize: scale.font(13),
                height: 1.22,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: scale.h(4)),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: mine
                    ? Colors.white.withValues(alpha: 0.72)
                    : const Color(0xFF8A8A8A),
                fontSize: scale.font(8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.scale,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final _BubbleScale scale;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        scale.x(14),
        scale.h(8),
        scale.x(14),
        scale.h(16),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(scale.x(12), 0, scale.x(6), 0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(scale.radius(28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 13,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF5E7A83),
              size: scale.w(18),
            ),
            SizedBox(width: scale.x(8)),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(13),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8A8A8A),
                    fontSize: scale.font(13),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                width: scale.w(42),
                height: scale.w(42),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5D5D),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: sending
                      ? SizedBox(
                          width: scale.w(16),
                          height: scale.w(16),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: scale.w(20),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatDetailError extends StatelessWidget {
  const _ChatDetailError({
    required this.scale,
    required this.error,
    required this.onReload,
  });

  final _BubbleScale scale;
  final String error;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: scale.w(270),
        padding: EdgeInsets.all(scale.x(14)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(scale.radius(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFFF5D5D),
                fontSize: scale.font(12),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: scale.h(8)),
            TextButton(onPressed: onReload, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.scale,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final _BubbleScale scale;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scale.w(34),
        height: scale.w(34),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: scale.w(18)),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.scale,
    required this.isGroup,
    required this.title,
  });

  final _BubbleScale scale;
  final bool isGroup;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: scale.w(38),
      height: scale.w(38),
      decoration: BoxDecoration(
        color: isGroup
            ? const Color(0xFF2386A2).withValues(alpha: 0.18)
            : const Color(0xFF78EF70),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Center(
        child: isGroup
            ? Icon(
                Icons.groups_2_outlined,
                color: Colors.black,
                size: scale.w(19),
              )
            : Text(
                title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(14),
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _BubbleScale {
  const _BubbleScale({required this.width, required this.height});

  final double width;
  final double height;

  double x(double value) => value * width / 393;
  double y(double value) => value * height / 852;
  double w(double value) => value * width / 393;
  double h(double value) => value * width / 393;
  double font(double value) => value * width / 393;
  double radius(double value) => value * width / 393;
}
