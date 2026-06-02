import 'dart:async';

import 'package:flutter/foundation.dart';

import 'chat_service.dart';

class UnreadProvider extends ChangeNotifier {
  UnreadProvider({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  Timer? _timer;
  Map<String, int> _directUnreadByUser = const <String, int>{};
  bool _loading = false;
  bool _active = false;

  Map<String, int> get directUnreadByUser => _directUnreadByUser;
  bool get isLoading => _loading;
  int get totalUnread =>
      _directUnreadByUser.values.fold<int>(0, (a, b) => a + b);

  void start() {
    if (_active) return;
    _active = true;
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (!_active) return;
    if (!_loading) {
      _loading = true;
      notifyListeners();
    }
    try {
      final counts = await _chatService.getDirectUnreadCounts();
      if (!_active) return;
      if (!_isSameMap(_directUnreadByUser, counts)) {
        _directUnreadByUser = counts;
      }
    } catch (_) {
      // Keep last known unread counts if refresh fails.
    } finally {
      if (_loading) _loading = false;
      if (_active) notifyListeners();
    }
  }

  void clear() {
    _directUnreadByUser = const <String, int>{};
    notifyListeners();
  }

  bool _isSameMap(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
