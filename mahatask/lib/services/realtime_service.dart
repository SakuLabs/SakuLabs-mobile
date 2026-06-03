import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';
import 'session_store.dart';

class RealtimeEvent {
  const RealtimeEvent(this.type, [this.payload]);

  final String type;
  final Map<String, dynamic>? payload;
}

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  final StreamController<RealtimeEvent> _socialController =
      StreamController<RealtimeEvent>.broadcast();
  final StreamController<RealtimeEvent> _messageController =
      StreamController<RealtimeEvent>.broadcast();

  io.Socket? _socket;
  String? _token;

  Stream<RealtimeEvent> get socialEvents => _socialController.stream;
  Stream<RealtimeEvent> get messageEvents => _messageController.stream;
  bool get isConnected => _socket?.connected == true;

  void connect() {
    final token = SessionStore.accessToken;
    if (token == null || token.isEmpty) return;

    if (_socket != null && _token == token) {
      if (_socket!.connected) return;
      _socket!.connect();
      return;
    }

    disconnect();
    _token = token;
    _socket = io.io(
      ApiClient().baseUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': <String, dynamic>{'token': token},
      },
    );

    _socket!
      ..on('friendRequest', (data) {
        _emitSocial('friendRequest', data);
      })
      ..on('friendRequestAccepted', (data) {
        _emitSocial('friendRequestAccepted', data);
      })
      ..on('friendRequestRejected', (data) {
        _emitSocial('friendRequestRejected', data);
      })
      ..on('groupInvite', (data) {
        _emitSocial('groupInvite', data);
      })
      ..on('groupInviteAccepted', (data) {
        _emitSocial('groupInviteAccepted', data);
      })
      ..on('groupInviteRejected', (data) {
        _emitSocial('groupInviteRejected', data);
      })
      ..on('message_notification', (data) {
        _emitMessage('message_notification', data);
      })
      ..on('receive_message', (data) {
        _emitMessage('receive_message', data);
      })
      ..on('presence:update', (data) {
        _emitSocial('presence:update', data);
      })
      ..onDisconnect((_) {
        _emitSocial('disconnect');
      });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _token = null;
  }

  void joinDirectMessage(String userId) {
    connect();
    if (userId.isEmpty) return;
    _socket?.emit('joinDM', <String, dynamic>{'userId': userId});
  }

  void joinGroup(String groupId) {
    connect();
    if (groupId.isEmpty) return;
    _socket?.emit('joinGroup', <String, dynamic>{'groupId': groupId});
  }

  void _emitSocial(String type, [dynamic data]) {
    if (_socialController.isClosed) return;
    _socialController.add(RealtimeEvent(type, _normalizePayload(data)));
  }

  void _emitMessage(String type, [dynamic data]) {
    if (_messageController.isClosed) return;
    _messageController.add(RealtimeEvent(type, _normalizePayload(data)));
  }

  Map<String, dynamic>? _normalizePayload(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
