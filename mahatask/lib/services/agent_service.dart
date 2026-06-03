import 'api_client.dart';

class AgentChatResult {
  const AgentChatResult({required this.conversationId, required this.reply});

  final String conversationId;
  final String reply;

  factory AgentChatResult.fromJson(Map<String, dynamic> json) {
    return AgentChatResult(
      conversationId: (json['conversationId'] ?? '').toString(),
      reply: (json['reply'] ?? '').toString(),
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
}
