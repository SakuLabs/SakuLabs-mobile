import 'dart:async';

import 'package:flutter/foundation.dart';

import 'chat_service.dart';

class UnreadProvider extends ChangeNotifier {
  UnreadProvider({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  Timer? _timer;
  Map<String, int>? _directUnreadByUser = const <String, int>{};
  Map<String, int>? _groupUnreadById = const <String, int>{};
  bool _loading = false;
  bool _active = false;

  Map<String, int> get directUnreadByUser =>
      _directUnreadByUser ?? const <String, int>{};
  Map<String, int> get groupUnreadById =>
      _groupUnreadById ?? const <String, int>{};
  bool get isLoading => _loading;
  int get totalUnread =>
      _sumUnread(directUnreadByUser) + _sumUnread(groupUnreadById);

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
      final direct = <String, int>{};
      final groups = <String, int>{};
      for (final entry in counts.entries) {
        if (entry.key.startsWith('dm:')) {
          direct[entry.key.substring(3)] = entry.value;
        } else if (entry.key.startsWith('group:')) {
          groups[entry.key.substring(6)] = entry.value;
        } else {
          direct[entry.key] = entry.value;
        }
      }
      if (!_isSameMap(directUnreadByUser, direct) ||
          !_isSameMap(groupUnreadById, groups)) {
        _directUnreadByUser = direct;
        _groupUnreadById = groups;
      }
    } catch (_) {
      // Keep last known unread counts if refresh fails.
    } finally {
      if (_loading) _loading = false;
      if (_active) notifyListeners();
    }
  }

  void clear() {
    if (directUnreadByUser.isEmpty && groupUnreadById.isEmpty && !_loading) {
      return;
    }
    _directUnreadByUser = const <String, int>{};
    _groupUnreadById = const <String, int>{};
    _loading = false;
    notifyListeners();
  }

  bool _isSameMap(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  int _sumUnread(Map<String, int> source) {
    var total = 0;
    for (final value in source.values) {
      total += value;
    }
    return total;
  }
}
