import 'api_client.dart';

enum TaskScope { personal, group }

enum TaskPriority { low, medium, high }

class GroupOption {
  const GroupOption({required this.id, required this.name});

  final String id;
  final String name;

  factory GroupOption.fromJson(Map<String, dynamic> json) {
    return GroupOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.progress,
    this.groupId,
    this.dueDate,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int progress;
  final String? groupId;
  final DateTime? dueDate;

  bool get isGroupTask => groupId != null && groupId!.isNotEmpty;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDueDate;
    final rawDueDate = json['dueDate'] ?? json['deadline'];
    if (rawDueDate is String && rawDueDate.isNotEmpty) {
      parsedDueDate = DateTime.tryParse(rawDueDate);
    }

    return TaskItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'TODO').toString(),
      priority: _taskPriorityLabel(json['priority']),
      progress: (json['progress'] is num)
          ? (json['progress'] as num).toInt()
          : 0,
      groupId: json['groupId']?.toString(),
      dueDate: parsedDueDate,
    );
  }
}

class TaskRecommendation {
  const TaskRecommendation({
    required this.id,
    required this.title,
    required this.priority,
    required this.score,
    required this.estimatedMinutes,
    this.groupId,
  });

  final String id;
  final String title;
  final String priority;
  final double score;
  final int estimatedMinutes;
  final String? groupId;

  factory TaskRecommendation.fromJson(Map<String, dynamic> json) {
    return TaskRecommendation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      priority: (json['priority'] ?? 'MEDIUM').toString(),
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : 0,
      estimatedMinutes: (json['estimatedMinutes'] is num)
          ? (json['estimatedMinutes'] as num).toInt()
          : 0,
      groupId: json['groupId']?.toString(),
    );
  }
}

class TaskService {
  TaskService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<TaskItem>> fetchTasks() async {
    final data = await _client.get('/tasks');
    if (data is! List) return const <TaskItem>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(TaskItem.fromJson)
        .toList(growable: false);
  }

  Future<List<GroupOption>> fetchGroups() async {
    final data = await _client.get('/social/groups');
    if (data is! List) return const <GroupOption>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(GroupOption.fromJson)
        .where((group) => group.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<TaskItem> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskScope scope,
    String? groupId,
    DateTime? startDate,
    DateTime? dueDate,
    int? progress,
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'priority': _toApiPriority(priority),
    };

    if (startDate != null) {
      payload['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (dueDate != null) {
      payload['deadline'] = dueDate.toUtc().toIso8601String();
    }
    if (progress != null) {
      payload['progress'] = progress.clamp(0, 100);
    }

    final result = await _client.post('/tasks', body: payload);
    if (result is Map<String, dynamic>) {
      return TaskItem.fromJson(result);
    }
    throw Exception('Response create task tidak valid.');
  }

  Future<List<TaskRecommendation>> fetchRecommendations({
    int? availableMinutes,
    int limit = 5,
    String algorithm = 'auto',
  }) async {
    final query = <String>[
      if (availableMinutes != null) 'availableMinutes=$availableMinutes',
      'limit=$limit',
      'algorithm=$algorithm',
    ].join('&');
    final data = await _client.get('/tasks/recommendations?$query');
    if (data is! Map) return const <TaskRecommendation>[];
    final raw = data['recommendations'];
    if (raw is! List) return const <TaskRecommendation>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TaskRecommendation.fromJson)
        .toList(growable: false);
  }

  Future<TaskItem> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    final result = await _client.patch(
      '/tasks/$taskId/status',
      body: <String, dynamic>{'status': status},
    );
    if (result is Map<String, dynamic>) {
      return TaskItem.fromJson(result);
    }
    throw Exception('Response update status tidak valid.');
  }

  Future<TaskItem> updateTaskProgress({
    required String taskId,
    required int progress,
  }) async {
    final result = await _client.patch(
      '/tasks/$taskId/progress',
      body: <String, dynamic>{'progress': progress},
    );
    if (result is Map<String, dynamic>) {
      return TaskItem.fromJson(result);
    }
    throw Exception('Response update progress tidak valid.');
  }

  Future<void> deleteTask(String taskId) async {
    await _client.delete('/tasks/$taskId');
  }

  String _toApiPriority(TaskPriority value) {
    switch (value) {
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.medium:
        return 'MEDIUM';
    }
  }
}

String _taskPriorityLabel(Object? value) {
  if (value is num) {
    if (value <= 1) return 'LOW';
    if (value >= 3) return 'HIGH';
    return 'MEDIUM';
  }
  final text = (value ?? 'MEDIUM').toString().toUpperCase();
  if (text == '1') return 'LOW';
  if (text == '3') return 'HIGH';
  if (text == '2') return 'MEDIUM';
  return text;
}
