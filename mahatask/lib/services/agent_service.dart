import 'api_client.dart';

class AgentChatResult {
  const AgentChatResult({
    required this.conversationId,
    required this.reply,
    this.actions = const <AgentAction>[],
  });

  final String conversationId;
  final String reply;
  final List<AgentAction> actions;

  factory AgentChatResult.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    return AgentChatResult(
      conversationId: (json['conversationId'] ?? '').toString(),
      reply: (json['reply'] ?? '').toString(),
      actions: rawActions is List
          ? rawActions
              .whereType<Map<String, dynamic>>()
              .map(AgentAction.fromJson)
              .toList(growable: false)
          : const <AgentAction>[],
    );
  }
}

class AgentAction {
  const AgentAction({required this.tool, required this.ok});

  final String tool;
  final bool ok;

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      tool: (json['tool'] ?? '').toString(),
      ok: json['ok'] == true,
    );
  }
}

class AgentConversation {
  const AgentConversation({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime? updatedAt;

  factory AgentConversation.fromJson(Map<String, dynamic> json) {
    return AgentConversation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Percakapan Saku AI').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }
}

class AgentMessage {
  const AgentMessage({required this.role, required this.content});

  final String role;
  final String content;

  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    return AgentMessage(
      role: (json['role'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }
}

class AgentService {
  AgentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AgentChatResult> sendMessage({
    required String content,
    String? conversationId,
  }) async {
    final data = await _client.post(
      '/agent/chat',
      body: {
        'content': content,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
      },
    );
    if (data is Map<String, dynamic>) {
      return AgentChatResult.fromJson(data);
    }
    return const AgentChatResult(
      conversationId: '',
      reply: 'Saya belum bisa memproses balasan dari server.',
    );
  }

  Future<List<AgentConversation>> fetchConversations() async {
    final data = await _client.get('/agent/conversations');
    if (data is! List) return const <AgentConversation>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AgentConversation.fromJson)
        .where((conversation) => conversation.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<AgentMessage>> fetchMessages(String conversationId) async {
    final data = await _client.get('/agent/conversations/$conversationId/messages');
    if (data is! List) return const <AgentMessage>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AgentMessage.fromJson)
        .where((message) => message.content.trim().isNotEmpty)
        .toList(growable: false);
  }
}
