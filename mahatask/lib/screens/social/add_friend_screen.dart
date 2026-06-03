import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mahatask/services/session_store.dart';
import 'package:mahatask/services/social_service.dart';

class AddFriendScreen extends StatelessWidget {
  const AddFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1F),
      body: Center(
        child: AddFriendDialog(onClose: () => Navigator.pop(context)),
      ),
    );
  }
}

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final SocialService _socialService = SocialService();
  final TextEditingController _codeController = TextEditingController();

  bool _sending = false;
  bool _loadingRequests = true;
  String? _message;
  bool _success = false;
  List<dynamic> _requests = const <dynamic>[];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _copyMyCode() async {
    final code = SessionStore.user?.userCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() {
      _success = true;
      _message = 'Kode kamu sudah dicopy.';
    });
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await _socialService.getFriendRequests();
      if (!mounted) return;
      setState(() => _requests = requests);
    } catch (_) {
      if (!mounted) return;
      setState(() => _requests = const <dynamic>[]);
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _respondRequest(String id, {required bool accept}) async {
    setState(() => _sending = true);
    try {
      if (accept) {
        await _socialService.acceptFriendRequest(id);
      } else {
        await _socialService.rejectFriendRequest(id);
      }
      if (!mounted) return;
      setState(() {
        _success = true;
        _message = accept ? 'Friend request accepted.' : 'Request rejected.';
        _requests = _requests.where((item) => _requestId(item) != id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _success = false;
        _message = 'Kode teman harus diisi.';
      });
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await _socialService.addFriendByCode(code);
      if (!mounted) return;
      setState(() {
        _success = true;
        _message = 'Friend request berhasil dikirim.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final myCode = SessionStore.user?.userCode ?? 'N/A';

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(18, 18, 18, media.viewInsets.bottom + 18),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: media.size.width * 0.9,
            maxHeight: media.size.height * 0.82,
          ),
          child: Material(
            color: Colors.white,
            elevation: 18,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add Friend',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            widget.onClose ?? () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Share your code or enter a friend code.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your friend code',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _copyMyCode,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFEAF2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              myCode,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(Icons.copy_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FriendRequestsPreview(
                    loading: _loadingRequests,
                    requests: _requests,
                    sending: _sending,
                    onAccept: (id) => _respondRequest(id, accept: true),
                    onReject: (id) => _respondRequest(id, accept: false),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Friend code',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter friend code',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8A95A3),
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD1D9E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD1D9E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF2386A2),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _success
                            ? const Color(0xFF2386A2)
                            : const Color(0xFFFF5D5D),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5D5D),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Send Request',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
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

class _FriendRequestsPreview extends StatelessWidget {
  const _FriendRequestsPreview({
    required this.loading,
    required this.requests,
    required this.sending,
    required this.onAccept,
    required this.onReject,
  });

  final bool loading;
  final List<dynamic> requests;
  final bool sending;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 38,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2386A2),
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (requests.isEmpty) return const SizedBox.shrink();

    final visible = requests.take(2).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incoming requests',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...visible.map((request) {
          final id = _requestId(request);
          final name = _requestSenderName(request);
          if (id.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD1D9E6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBFEAF2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: sending ? null : () => onReject(id),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: sending ? null : () => onAccept(id),
                  icon: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF2386A2),
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String _requestId(dynamic request) {
  if (request is Map<String, dynamic>) return (request['id'] ?? '').toString();
  return '';
}

String _requestSenderName(dynamic request) {
  if (request is Map<String, dynamic>) {
    final sender = request['sender'];
    if (sender is Map<String, dynamic>) {
      return (sender['name'] ?? 'Unknown user').toString();
    }
    return (request['senderName'] ?? 'Unknown user').toString();
  }
  return 'Unknown user';
}

