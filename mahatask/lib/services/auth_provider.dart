import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'session_store.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => SessionStore.isLoggedIn;
  SessionUser? get user => SessionStore.user;

  Future<bool> login({required String email, required String password}) async {
    return _authenticate(
      () => _service.login(email: email, password: password),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _authenticate(
      () => _service.register(name: name, email: email, password: password),
    );
  }

  void logout() {
    SessionStore.clear();
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<dynamic> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
