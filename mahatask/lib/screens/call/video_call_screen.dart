import 'package:flutter/material.dart';

import 'package:mahatask/services/video_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key, required this.roomId, required this.title});

  final String roomId;
  final String title;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallService _videoCallService = VideoCallService();
  bool _micMuted = true;
  bool _cameraOff = true;

  @override
  void initState() {
    super.initState();
    _videoCallService.connect(
      roomId: widget.roomId,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _videoCallService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participants = _videoCallService.participants;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBg = isDark ? const Color(0xFF0B141A) : const Color(0xFFEFF2F5);
    final topBarBg = isDark ? const Color(0xFF202C33) : Colors.white;

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: topBarBg,
        titleSpacing: 0,
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _videoCallService.isConnected
                      ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  _videoCallService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _videoCallService.isConnected
                      ? const Color(0xFF22C55E)
                      : Colors.orange,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_videoCallService.lastError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _videoCallService.lastError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: participants.isEmpty ? 1 : participants.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  if (participants.isEmpty) {
                    return _tile('Menunggu...', isSelf: true);
                  }
                  final p = participants[index];
                  return _tile(
                    p.userId.isEmpty ? 'Participant' : p.userId,
                    isSelf: index == 0,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                    icon: _micMuted
                        ? Icons.mic_off_outlined
                        : Icons.mic_none_outlined,
                    color: _micMuted ? Colors.white24 : const Color(0xFF22C55E),
                    onTap: () {
                      setState(() => _micMuted = !_micMuted);
                    },
                  ),
                  _actionButton(
                    icon: _cameraOff
                        ? Icons.videocam_off_outlined
                        : Icons.videocam_outlined,
                    color: _cameraOff
                        ? Colors.white24
                        : Theme.of(context).colorScheme.primary,
                    onTap: () {
                      setState(() => _cameraOff = !_cameraOff);
                    },
                  ),
                  _actionButton(
                    icon: Icons.call_end,
                    color: Colors.redAccent,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, {required bool isSelf}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelf
              ? [const Color(0xFF25333A), const Color(0xFF131C21)]
              : [const Color(0xFF21324A), const Color(0xFF101B29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.person, color: Colors.white38, size: 48),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Text(
              isSelf ? '$label (You)' : label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

