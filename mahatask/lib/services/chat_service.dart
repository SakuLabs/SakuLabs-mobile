import 'api_client.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class ChatService {
  ChatService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ChatMessage>> getGroupMessages(String groupId) async {
    final data = await _client.get('/chat/group/$groupId');
    if (data is! List) return const <ChatMessage>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList(growable: false);
  }

  Future<List<ChatMessage>> getDirectMessages(String userId) async {
    final data = await _client.get('/chat/dm/$userId');
    if (data is! List) return const <ChatMessage>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList(growable: false);
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String content,
  }) async {
    await _client.post(
      '/chat/messages',
      body: <String, dynamic>{
        'groupId': groupId,
        'content': content.trim(),
      },
    );
  }

  Future<void> sendDirectMessage({
    required String userId,
    required String content,
  }) async {
    await _client.post(
      '/chat/messages',
      body: <String, dynamic>{
        'directMessageUserId': userId,
        'content': content.trim(),
      },
    );
  }

  Future<Map<String, int>> getDirectUnreadCounts() async {
    final data = await _client.get('/chat/unread');
    if (data is! Map) return const <String, int>{};
    final counts = <String, int>{};
    data.forEach((key, value) {
      final id = key.toString();
      if (id.isEmpty) return;
      if (value is num) {
        counts[id] = value.toInt();
      } else {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) counts[id] = parsed;
      }
    });
    return counts;
  }
}
