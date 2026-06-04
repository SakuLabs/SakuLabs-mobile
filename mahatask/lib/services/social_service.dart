import 'api_client.dart';

class SocialUser {
  const SocialUser({
    required this.id,
    required this.name,
    this.userCode,
    this.bio,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? userCode;
  final String? bio;
  final String? avatarUrl;

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      userCode: json['userCode']?.toString(),
      bio: json['bio']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class SocialGroup {
  const SocialGroup({
    required this.id,
    required this.name,
    required this.members,
  });

  final String id;
  final String name;
  final List<SocialUser> members;

  factory SocialGroup.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = rawMembers is List
        ? rawMembers
              .whereType<Map<String, dynamic>>()
              .map(SocialUser.fromJson)
              .toList(growable: false)
        : const <SocialUser>[];
    return SocialGroup(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Group').toString(),
      members: members,
    );
  }
}

class SocialService {
  SocialService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<SocialUser>> getFriends() async {
    final data = await _client.get('/social/friends');
    if (data is! List) return const <SocialUser>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SocialUser.fromJson)
        .toList(growable: false);
  }

  Future<List<SocialGroup>> getGroups() async {
    final data = await _client.get('/social/groups');
    if (data is! List) return const <SocialGroup>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SocialGroup.fromJson)
        .toList(growable: false);
  }

  Future<SocialGroup> createGroup(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw Exception('Nama grup harus diisi.');
    }
    final data = await _client.post(
      '/social/groups',
      body: <String, dynamic>{'name': normalized},
    );
    if (data is Map<String, dynamic>) {
      return SocialGroup.fromJson(data);
    }
    throw Exception('Grup gagal dibuat.');
  }

  Future<void> addFriendByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw Exception('Kode teman harus diisi.');
    }
    await _client.post(
      '/social/friends/request',
      body: <String, dynamic>{'userCode': normalized},
    );
  }

  Future<List<SocialUser>> searchUsersByName(String query) async {
    final data = await _client.post(
      '/social/friends/search-name',
      body: <String, dynamic>{'name': query.trim()},
    );
    if (data is! List) return const <SocialUser>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SocialUser.fromJson)
        .toList(growable: false);
  }

  Future<List<dynamic>> getFriendRequests() async {
    final data = await _client.get('/social/friends/requests');
    if (data is! List) return const <dynamic>[];
    return data;
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _client.post('/social/friends/requests/$requestId/accept');
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _client.post('/social/friends/requests/$requestId/reject');
  }

  Future<List<dynamic>> getGroupInvites() async {
    final data = await _client.get('/social/groups/invites');
    if (data is! List) return const <dynamic>[];
    return data;
  }

  Future<void> inviteToGroup({
    required String groupId,
    required String userId,
    String role = 'MEMBER',
    bool canCreateSchedule = false,
  }) async {
    await _client.post(
      '/social/groups/$groupId/invites',
      body: <String, dynamic>{
        'userId': userId,
        'role': role == 'MODERATOR' ? 'MODERATOR' : 'MEMBER',
        'canCreateSchedule': canCreateSchedule,
      },
    );
  }

  Future<void> acceptGroupInvite(String inviteId) async {
    await _client.post('/social/groups/invites/$inviteId/accept');
  }

  Future<void> rejectGroupInvite(String inviteId) async {
    await _client.post('/social/groups/invites/$inviteId/reject');
  }
}
