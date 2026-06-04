import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/services/app_events.dart';
import 'package:mahatask/services/auth_provider.dart';
import 'package:mahatask/services/task_service.dart';

enum _TaskFilter { all, todo, inProgress, completed }

enum _TaskSort { time, recommended }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  final TaskService _taskService = TaskService();
  final Set<String> _expandedTaskIds = <String>{};

  bool _isLoading = true;
  String? _error;
  DateTime? _selectedDay;
  _TaskFilter? _filter;
  _TaskSort _sort = _TaskSort.time;
  List<TaskItem> _tasks = const <TaskItem>[];
  List<GroupOption> _groups = const <GroupOption>[];
  StreamSubscription<void>? _taskChangedSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _taskChangedSubscription = AppEvents.taskChanged.listen((_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _taskChangedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _taskService.fetchTasks(),
        _taskService.fetchGroups(),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = results[0] as List<TaskItem>;
        _groups = results[1] as List<GroupOption>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateTaskSheet() async {
    final created = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (context) {
        return _CreateTaskSheet(
          service: _taskService,
          groups: _groups,
          initialDay: _currentSelectedDay,
        );
      },
    );

    if (created == true) {
      await _loadData();
      AppEvents.notifyTaskChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task berhasil dibuat.')));
    }
  }

  Future<void> _updateStatus(TaskItem task, String status) async {
    try {
      final updated = await _taskService.updateTaskStatus(
        taskId: task.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        if (status == 'DONE') {
          _tasks = _tasks.where((item) => item.id != task.id).toList();
        } else {
          _tasks = _tasks
              .map((item) => item.id == task.id ? updated : item)
              .toList(growable: false);
        }
      });
      AppEvents.notifyTaskChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    try {
      await _taskService.deleteTask(task.id);
      if (!mounted) return;
      setState(() {
        _tasks = _tasks.where((item) => item.id != task.id).toList();
      });
      AppEvents.notifyTaskChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _toggleExpanded(TaskItem task) {
    setState(() {
      if (!_expandedTaskIds.add(task.id)) {
        _expandedTaskIds.remove(task.id);
      }
    });
  }

  void _openCalendarPopup() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) {
        return _CalendarDialog(
          selectedDay: _currentSelectedDay,
          taskDateMarkers: _taskDateMarkers(_tasks),
          onSelect: (day) {
            setState(() => _selectedDay = day);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectedDay = _currentSelectedDay;
    final filter = _currentFilter;
    final allTasks = _tasks;
    final body = _TaskAgendaBody(
      isLoading: _isLoading,
      error: _error,
      tasks: _visibleTasks(),
      taskDateKeys: _taskDateKeys(allTasks),
      groupsById: _groupsById(_groups),
      selectedDay: selectedDay,
      filter: filter,
      expandedTaskIds: _expandedTaskIds,
      onReload: _loadData,
      onCreateTask: _openCreateTaskSheet,
      onOpenCalendar: _openCalendarPopup,
      onSelectDay: (day) => setState(() => _selectedDay = day),
      onSelectFilter: (filter) => setState(() => _filter = filter),
      sort: _sort,
      onSelectSort: (sort) => setState(() => _sort = sort),
      onToggleExpanded: _toggleExpanded,
      onStatusChanged: _updateStatus,
      onDelete: _deleteTask,
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: const Color(0xFF1D1D1F), body: body);
  }

  List<TaskItem> _visibleTasks() {
    final selectedDay = _currentSelectedDay;
    final filter = _currentFilter;
    final filtered = _tasks
        .where((task) {
          final status = task.status.toUpperCase();
          switch (filter) {
            case _TaskFilter.all:
              return true;
            case _TaskFilter.todo:
              return status == 'TODO';
            case _TaskFilter.inProgress:
              return status == 'IN_PROGRESS';
            case _TaskFilter.completed:
              return status == 'DONE' || status == 'COMPLETED';
          }
        })
        .toList(growable: false);

    final daily = filtered
        .where(
          (task) =>
              task.dueDate != null && _sameDay(task.dueDate!, selectedDay),
        )
        .toList(growable: false);
    daily.sort(_taskComparator);
    if (daily.isNotEmpty) return daily;

    final upcoming = filtered.where((task) => task.dueDate != null).toList()
      ..sort(_taskComparator);
    if (upcoming.isNotEmpty) return upcoming;

    return filtered..sort(_taskComparator);
  }

  DateTime get _currentSelectedDay => _selectedDay ??= DateTime.now();

  _TaskFilter get _currentFilter => _filter ??= _TaskFilter.all;

  int _taskComparator(TaskItem a, TaskItem b) {
    if (_sort == _TaskSort.recommended) {
      final score = _recommendationScore(b).compareTo(_recommendationScore(a));
      if (score != 0) return score;
    }
    final aDue = a.dueDate ?? DateTime(9999);
    final bDue = b.dueDate ?? DateTime(9999);
    return aDue.compareTo(bDue);
  }

  int _recommendationScore(TaskItem task) {
    final priority = switch (task.priority.toUpperCase()) {
      'HIGH' => 30,
      'MEDIUM' => 20,
      'LOW' => 10,
      _ => 15,
    };
    final status = switch (task.status.toUpperCase()) {
      'TODO' => 10,
      'IN_PROGRESS' => 18,
      _ => 0,
    };
    final due = task.dueDate;
    final urgency = due == null
        ? 0
        : 20 - due.difference(DateTime.now()).inDays.clamp(0, 20);
    return priority + status + urgency;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Set<int> _taskDateKeys(List<TaskItem> tasks) {
    return tasks
        .where((task) => task.dueDate != null)
        .map((task) => _dateKey(task.dueDate!))
        .toSet();
  }

  static Map<int, Color> _taskDateMarkers(List<TaskItem> tasks) {
    final ranks = <int, int>{};
    for (final task in tasks) {
      final dueDate = task.dueDate;
      if (dueDate == null) continue;
      final key = _dateKey(dueDate);
      final rank = _priorityRank(task.priority);
      if (rank > (ranks[key] ?? 0)) {
        ranks[key] = rank;
      }
    }
    return {
      for (final entry in ranks.entries)
        entry.key: _priorityMarkerColor(entry.value),
    };
  }

  static int _priorityRank(String priority) {
    final value = priority.toUpperCase();
    if (value == 'HIGH') return 3;
    if (value == 'MEDIUM') return 2;
    return 1;
  }

  static Color _priorityMarkerColor(int rank) {
    if (rank >= 3) return const Color(0xFFFF2F4F);
    if (rank == 2) return const Color(0xFFFFB24A);
    return const Color(0xFF60CF67);
  }

  static Map<String, GroupOption> _groupsById(List<GroupOption> groups) {
    return {for (final group in groups) group.id: group};
  }
}

class _TaskAgendaBody extends StatelessWidget {
  const _TaskAgendaBody({
    required this.isLoading,
    required this.error,
    required this.tasks,
    required this.taskDateKeys,
    required this.groupsById,
    required this.selectedDay,
    required this.filter,
    required this.expandedTaskIds,
    required this.onReload,
    required this.onCreateTask,
    required this.onOpenCalendar,
    required this.onSelectDay,
    required this.onSelectFilter,
    required this.sort,
    required this.onSelectSort,
    required this.onToggleExpanded,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final bool isLoading;
  final String? error;
  final List<TaskItem> tasks;
  final Set<int> taskDateKeys;
  final Map<String, GroupOption> groupsById;
  final DateTime selectedDay;
  final _TaskFilter filter;
  final Set<String> expandedTaskIds;
  final VoidCallback onReload;
  final VoidCallback onCreateTask;
  final VoidCallback onOpenCalendar;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<_TaskFilter> onSelectFilter;
  final _TaskSort sort;
  final ValueChanged<_TaskSort> onSelectSort;
  final ValueChanged<TaskItem> onToggleExpanded;
  final Future<void> Function(TaskItem task, String status) onStatusChanged;
  final Future<void> Function(TaskItem task) onDelete;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name.trim();
    final displayName = name == null || name.isEmpty ? 'Name' : name;
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = _AgendaScale(width: width, height: height);

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB), Color(0xFFE0C3FC)],
              stops: [0, 0.5, 1],
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              scale.x(30),
              topInset + scale.y(58),
              scale.x(30),
              scale.y(122),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AgendaHeader(
                  scale: scale,
                  displayName: displayName,
                  onCreateTask: onCreateTask,
                ),
                SizedBox(height: scale.h(17)),
                _ScheduleTitleRow(
                  scale: scale,
                  selectedDay: selectedDay,
                  onOpenCalendar: onOpenCalendar,
                ),
                SizedBox(height: scale.h(16)),
                _WeekStrip(
                  scale: scale,
                  selectedDay: selectedDay,
                  taskDateKeys: taskDateKeys,
                  onSelectDay: onSelectDay,
                ),
                SizedBox(height: scale.h(12)),
                _FilterStrip(
                  scale: scale,
                  selected: filter,
                  onSelect: onSelectFilter,
                  sort: sort,
                  onSelectSort: onSelectSort,
                ),
                SizedBox(height: scale.h(12)),
                Text(
                  "Today's Agenda",
                  style: TextStyle(
                    color: const Color(0xFF5E7A83),
                    fontSize: scale.font(16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: scale.h(8)),
                if (isLoading)
                  SizedBox(
                    height: scale.h(250),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2386A2),
                      ),
                    ),
                  )
                else if (error != null)
                  _AgendaError(scale: scale, error: error!, onReload: onReload)
                else if (tasks.isEmpty)
                  _EmptyAgenda(scale: scale)
                else
                  ...tasks.map((task) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: scale.h(14)),
                      child: _AgendaTaskCard(
                        scale: scale,
                        task: task,
                        groupsById: groupsById,
                        expanded: expandedTaskIds.contains(task.id),
                        onToggleExpanded: () => onToggleExpanded(task),
                        onStatusChanged: (status) =>
                            onStatusChanged(task, status),
                        onDelete: () => onDelete(task),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({
    required this.scale,
    required this.displayName,
    required this.onCreateTask,
  });

  final _AgendaScale scale;
  final String displayName;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PixelAvatar(scale: scale, size: 32),
        SizedBox(width: scale.x(7)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(13),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _CircleAction(
          scale: scale,
          color: Colors.black,
          icon: Icons.add,
          iconColor: Colors.white,
          onTap: onCreateTask,
        ),
        SizedBox(width: scale.x(10)),
        _CircleAction(
          scale: scale,
          color: Colors.white,
          icon: Icons.notifications_none_rounded,
          iconColor: Colors.black,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ScheduleTitleRow extends StatelessWidget {
  const _ScheduleTitleRow({
    required this.scale,
    required this.selectedDay,
    required this.onOpenCalendar,
  });

  final _AgendaScale scale;
  final DateTime selectedDay;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Schedule',
            style: TextStyle(
              color: Colors.black,
              fontSize: scale.font(25),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GestureDetector(
          onTap: onOpenCalendar,
          child: Container(
            height: scale.h(40),
            padding: EdgeInsets.symmetric(horizontal: scale.x(13)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(scale.radius(20)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: scale.w(25),
                  height: scale.w(25),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8D8D8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: scale.w(13),
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: scale.x(7)),
                Text(
                  'Calendar',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale.font(15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.scale,
    required this.selectedDay,
    required this.taskDateKeys,
    required this.onSelectDay,
  });

  final _AgendaScale scale;
  final DateTime selectedDay;
  final Set<int> taskDateKeys;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final start = selectedDay.subtract(Duration(days: selectedDay.weekday % 7));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children: days
          .map((day) {
            final active = _sameDay(day, selectedDay);
            final hasTask = taskDateKeys.contains(_dateKey(day));
            final weekday = labels[day.weekday % 7];
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelectDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: active ? scale.h(76) : scale.h(65),
                  margin: EdgeInsets.symmetric(
                    horizontal: scale.x(active ? 1.5 : 3),
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(scale.radius(28)),
                    boxShadow: active
                        ? const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 9,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekday,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: scale.font(9),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: scale.h(8)),
                      SizedBox(
                        width: scale.w(active ? 40 : 32),
                        height: scale.w(active ? 40 : 32),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: scale.w(active ? 38 : 30),
                              height: scale.w(active ? 38 : 30),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF111827)
                                    : hasTask
                                    ? Colors.white
                                    : const Color(0xFFE8E8E8),
                                shape: BoxShape.circle,
                                border: hasTask && !active
                                    ? Border.all(
                                        color: const Color(0xFFFF5D5D),
                                        width: 1.2,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: active ? Colors.white : Colors.black,
                                    fontSize: scale.font(active ? 12 : 10),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.scale,
    required this.selected,
    required this.onSelect,
    required this.sort,
    required this.onSelectSort,
  });

  final _AgendaScale scale;
  final _TaskFilter selected;
  final ValueChanged<_TaskFilter> onSelect;
  final _TaskSort sort;
  final ValueChanged<_TaskSort> onSelectSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            scale: scale,
            label: 'All',
            active: selected == _TaskFilter.all,
            onTap: () => onSelect(_TaskFilter.all),
          ),
        ),
        SizedBox(width: scale.x(6)),
        Expanded(
          child: _FilterChip(
            scale: scale,
            label: 'To do',
            active: selected == _TaskFilter.todo,
            onTap: () => onSelect(_TaskFilter.todo),
          ),
        ),
        SizedBox(width: scale.x(6)),
        Expanded(
          child: _FilterChip(
            scale: scale,
            label: 'Doing',
            active: selected == _TaskFilter.inProgress,
            onTap: () => onSelect(_TaskFilter.inProgress),
          ),
        ),
        SizedBox(width: scale.x(6)),
        Expanded(
          child: _FilterChip(
            scale: scale,
            label: 'Done',
            active: selected == _TaskFilter.completed,
            onTap: () => onSelect(_TaskFilter.completed),
          ),
        ),
        SizedBox(width: scale.x(6)),
        Expanded(
          child: _SortChip(scale: scale, sort: sort, onSelect: onSelectSort),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.scale,
    required this.sort,
    required this.onSelect,
  });

  final _AgendaScale scale;
  final _TaskSort sort;
  final ValueChanged<_TaskSort> onSelect;

  @override
  Widget build(BuildContext context) {
    final active = sort == _TaskSort.recommended;
    return PopupMenuButton<_TaskSort>(
      onSelected: onSelect,
      tooltip: 'Sort tasks',
      itemBuilder: (context) => const [
        PopupMenuItem(value: _TaskSort.time, child: Text('By time')),
        PopupMenuItem(value: _TaskSort.recommended, child: Text('Best queue')),
      ],
      child: Container(
        height: scale.h(32),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(scale.radius(18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Sort',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontSize: scale.font(10.5),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.scale,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final _AgendaScale scale;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: scale.h(32),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(scale.radius(18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontSize: scale.font(10.5),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaTaskCard extends StatelessWidget {
  const _AgendaTaskCard({
    required this.scale,
    required this.task,
    required this.groupsById,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final _AgendaScale scale;
  final TaskItem task;
  final Map<String, GroupOption> groupsById;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasDescription = task.description.trim().isNotEmpty;
    final due = task.dueDate ?? DateTime.now();
    final group = _groupForTask(task, groupsById);
    final memberNames =
        group?.members
            .map((member) => member.name)
            .where((name) => name.trim().isNotEmpty)
            .take(3)
            .join(', ') ??
        '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        scale.x(16),
        scale.h(11),
        scale.x(12),
        scale.h(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(scale.radius(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _timeLabel(due),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: scale.x(8)),
              Expanded(
                child: Container(height: 1, color: const Color(0xFF8F8F8F)),
              ),
              SizedBox(width: scale.x(8)),
              GestureDetector(
                onTap: () => _showTaskActions(context),
                child: Container(
                  width: scale.w(28),
                  height: scale.w(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.black.withValues(alpha: 0.62),
                    size: scale.w(18),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: scale.h(5)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale.font(18),
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: scale.x(8)),
              _MiniAvatars(scale: scale, task: task, group: group),
              SizedBox(width: scale.x(7)),
              _DoneTaskButton(
                scale: scale,
                onTap: () => onStatusChanged('DONE'),
              ),
              SizedBox(width: scale.x(7)),
              GestureDetector(
                onTap: onToggleExpanded,
                child: Container(
                  width: scale.w(27),
                  height: scale.w(27),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9E9E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.arrow_outward_rounded,
                    color: const Color(0xFF8A8A8A),
                    size: scale.w(19),
                  ),
                ),
              ),
            ],
          ),
          if (expanded && hasDescription) ...[
            SizedBox(height: scale.h(9)),
            Text(
              task.description,
              style: TextStyle(
                color: const Color(0xFF6F6F6F),
                fontSize: scale.font(9),
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (expanded && group != null) ...[
            SizedBox(height: scale.h(9)),
            _TaskGroupInfo(
              scale: scale,
              groupName: group.name,
              memberNames: memberNames.isEmpty
                  ? 'Belum ada member'
                  : memberNames,
            ),
          ],
          SizedBox(height: expanded ? scale.h(17) : scale.h(14)),
          Row(
            children: [
              _PriorityPill(scale: scale, priority: task.priority),
              const Spacer(),
              _StatusPill(scale: scale, task: task),
            ],
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime value) {
    final hour = value.hour == 0 ? 9 : value.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour > 12 ? hour - 12 : hour;
    return '$display:00 $suffix';
  }

  Future<void> _showTaskActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) {
        return _TaskActionSheet(task: task);
      },
    );
    if (action == null) return;
    if (action == 'delete') {
      onDelete();
    } else {
      onStatusChanged(action);
    }
  }
}

class _TaskActionSheet extends StatelessWidget {
  const _TaskActionSheet({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              task.title.isEmpty ? 'Task actions' : task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _TaskActionChip(
                  label: 'To do',
                  value: 'TODO',
                  color: Color(0xFFFFB25A),
                ),
                _TaskActionChip(
                  label: 'Doing',
                  value: 'IN_PROGRESS',
                  color: Color(0xFF2386A2),
                ),
                _TaskActionChip(
                  label: 'Done',
                  value: 'DONE',
                  color: Color(0xFF60CF67),
                ),
                _TaskActionChip(
                  label: 'Delete',
                  value: 'delete',
                  color: Color(0xFFFF5D5D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskActionChip extends StatelessWidget {
  const _TaskActionChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneTaskButton extends StatelessWidget {
  const _DoneTaskButton({required this.scale, required this.onTap});

  final _AgendaScale scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scale.w(27),
        height: scale.w(27),
        decoration: const BoxDecoration(
          color: Color(0xFF60CF67),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: scale.w(18),
        ),
      ),
    );
  }
}

class _TaskGroupInfo extends StatelessWidget {
  const _TaskGroupInfo({
    required this.scale,
    required this.groupName,
    required this.memberNames,
  });

  final _AgendaScale scale;
  final String groupName;
  final String memberNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: scale.x(10),
        vertical: scale.h(8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(scale.radius(12)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group: $groupName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: scale.font(8.5),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: scale.h(3)),
          Text(
            'Members: $memberNames',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: scale.font(7.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.scale, required this.priority});

  final _AgendaScale scale;
  final String priority;

  @override
  Widget build(BuildContext context) {
    final text = priority.toUpperCase();
    final color = switch (text) {
      'HIGH' => const Color(0xFFFF5D5D),
      'LOW' => const Color(0xFF60CF67),
      _ => const Color(0xFFFFB25A),
    };
    final label = switch (text) {
      'HIGH' => 'High Important',
      'LOW' => 'Low Important',
      _ => 'Medium Important',
    };

    return Container(
      height: scale.h(18),
      padding: EdgeInsets.symmetric(horizontal: scale.x(8)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(scale.radius(10)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: scale.font(7.2),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.scale, required this.task});

  final _AgendaScale scale;
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final normalized = task.status.toUpperCase();
    final color = switch (normalized) {
      'DONE' || 'COMPLETED' => const Color(0xFF60CF67),
      'IN_PROGRESS' => const Color(0xFF2386A2),
      _ => const Color(0xFFFFB25A),
    };
    final label = switch (normalized) {
      'DONE' || 'COMPLETED' => 'Done',
      'IN_PROGRESS' => 'Doing',
      _ => 'To Do',
    };

    return Container(
      height: scale.h(17),
      padding: EdgeInsets.symmetric(horizontal: scale.x(7)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(scale.radius(9)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: scale.font(7),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniAvatars extends StatelessWidget {
  const _MiniAvatars({
    required this.scale,
    required this.task,
    required this.group,
  });

  final _AgendaScale scale;
  final TaskItem task;
  final GroupOption? group;

  @override
  Widget build(BuildContext context) {
    final count = task.isGroupTask
        ? (group?.members.length ?? 3).clamp(1, 3)
        : 1;
    final avatars = SizedBox(
      width: scale.w(42),
      height: scale.w(24),
      child: Stack(
        alignment: Alignment.centerRight,
        children: List.generate(count, (index) {
          final colors = [
            const Color(0xFF55E377),
            const Color(0xFFFFC2E8),
            const Color(0xFFBFD4FF),
          ];
          return Positioned(
            right: scale.x(index * 13),
            child: _PixelAvatar(
              scale: scale,
              size: 22,
              color: colors[index],
              tiny: true,
            ),
          );
        }),
      ),
    );
    if (group == null) return avatars;
    return GestureDetector(
      onTap: () => _showGroupMembers(context, group!),
      child: avatars,
    );
  }

  void _showGroupMembers(BuildContext context, GroupOption group) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _GroupMembersDialog(group: group),
    );
  }
}

class _GroupMembersDialog extends StatelessWidget {
  const _GroupMembersDialog({required this.group});

  final GroupOption group;

  @override
  Widget build(BuildContext context) {
    final members = group.members;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada data anggota.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFBFEAF2),
                        child: Icon(Icons.person_rounded, color: Colors.black),
                      ),
                      title: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDialog extends StatelessWidget {
  const _CalendarDialog({
    required this.selectedDay,
    required this.taskDateMarkers,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final Map<int, Color> taskDateMarkers;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final month = DateTime(selectedDay.year, selectedDay.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday % 7;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, 393.0);
          final scale = _AgendaScale(
            width: width,
            height: constraints.maxHeight,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: scale.w(313),
                padding: EdgeInsets.fromLTRB(
                  scale.x(20),
                  scale.h(18),
                  scale.x(20),
                  scale.h(18),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(scale.radius(20)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_monthName(month.month)} ${month.year}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: scale.font(15),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_left_rounded, size: scale.w(20)),
                        Icon(Icons.chevron_right_rounded, size: scale.w(20)),
                      ],
                    ),
                    SizedBox(height: scale.h(14)),
                    Row(
                      children:
                          const [
                                'Sun',
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                              ]
                              .map(
                                (label) => Expanded(
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: Color(0xFF8A8A8A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    SizedBox(height: scale.h(9)),
                    for (var row = 0; row < rows; row++)
                      Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            Expanded(
                              child: Builder(
                                builder: (_) {
                                  final index = row * 7 + col;
                                  final dayNum = index - leading + 1;
                                  if (dayNum < 1 || dayNum > daysInMonth) {
                                    return SizedBox(height: scale.h(34));
                                  }
                                  final date = DateTime(
                                    month.year,
                                    month.month,
                                    dayNum,
                                  );
                                  final active = _sameDay(date, selectedDay);
                                  final markerColor =
                                      taskDateMarkers[_dateKey(date)];
                                  return GestureDetector(
                                    onTap: () => onSelect(date),
                                    child: SizedBox(
                                      height: scale.h(active ? 42 : 34),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            width: scale.w(active ? 40 : 34),
                                            height: scale.w(active ? 40 : 34),
                                            decoration: BoxDecoration(
                                              color: active
                                                  ? Colors.black
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$dayNum',
                                                style: TextStyle(
                                                  color: active
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: scale.font(11),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (markerColor != null)
                                            Positioned(
                                              bottom: active
                                                  ? scale.h(1)
                                                  : scale.h(0),
                                              child: Container(
                                                width: scale.w(5.5),
                                                height: scale.w(5.5),
                                                decoration: BoxDecoration(
                                                  color: markerColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              Positioned(
                right: scale.x(-10),
                top: scale.h(-10),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: scale.w(28),
                    height: scale.w(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFF8A8A8A),
                      size: scale.w(19),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet({
    required this.service,
    required this.groups,
    required this.initialDay,
  });

  final TaskService service;
  final List<GroupOption> groups;
  final DateTime initialDay;

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _priority = TaskPriority.high;
  var _scope = TaskScope.personal;
  String? _selectedGroupId;
  late DateTime _startDate;
  late DateTime _deadline;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _deadline = DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day,
      9,
    );
    if (_deadline.isBefore(DateTime.now())) {
      _deadline = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool deadline}) async {
    final current = deadline ? _deadline : _startDate;
    DateTime? picked;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) {
        return _CalendarDialog(
          selectedDay: current,
          taskDateMarkers: const <int, Color>{},
          onSelect: (day) {
            picked = day;
            Navigator.pop(context);
          },
        );
      },
    );
    if (picked == null) return;
    setState(() {
      final selected = picked!;
      final next = DateTime(
        selected.year,
        selected.month,
        selected.day,
        current.hour,
      );
      if (deadline) {
        _deadline = next;
      } else {
        _startDate = next;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _deadline = DateTime(
        _deadline.year,
        _deadline.month,
        _deadline.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title wajib diisi.');
      return;
    }
    if (_deadline.isBefore(_startDate)) {
      setState(() => _error = 'Deadline harus setelah start date.');
      return;
    }
    if (_scope == TaskScope.group &&
        (_selectedGroupId == null || _selectedGroupId!.isEmpty)) {
      setState(() => _error = 'Pilih group untuk group task.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.service.createTask(
        title: title,
        description: _descriptionController.text.trim(),
        priority: _priority,
        scope: _scope,
        groupId: _selectedGroupId,
        startDate: _startDate,
        dueDate: _deadline,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  GroupOption? get _selectedGroup {
    final id = _selectedGroupId;
    if (id == null) return null;
    for (final group in widget.groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white,
                elevation: 18,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6D6D6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Create Task',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SheetField(
                        label: 'Task Title',
                        child: TextField(
                          controller: _titleController,
                          decoration: _inputDecoration('Project Assignment'),
                        ),
                      ),
                      _SheetField(
                        label: 'Description',
                        child: TextField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: _inputDecoration(
                            'Pbfbabwfboauwbfbabfobabfasbfubasofbasbuasbfuoabsfasoutbasbdfbasoutbasbfasbfoasobfas',
                          ),
                        ),
                      ),
                      const Text(
                        'Due Date & Time',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PickerButton(
                              icon: Icons.calendar_today_outlined,
                              value: _dateLabel(_deadline),
                              onTap: () => _pickDate(deadline: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PickerButton(
                              icon: Icons.alarm_rounded,
                              value: _timeLabel(_deadline),
                              onTap: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Priority',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PriorityChoice(
                              label: 'Low',
                              active: _priority == TaskPriority.low,
                              onTap: () =>
                                  setState(() => _priority = TaskPriority.low),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PriorityChoice(
                              label: 'Medium',
                              active: _priority == TaskPriority.medium,
                              onTap: () => setState(
                                () => _priority = TaskPriority.medium,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PriorityChoice(
                              label: 'High',
                              active: _priority == TaskPriority.high,
                              onTap: () =>
                                  setState(() => _priority = TaskPriority.high),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Task For',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ScopeChoice(
                              label: 'Personal',
                              active: _scope == TaskScope.personal,
                              onTap: () => setState(() {
                                _scope = TaskScope.personal;
                                _selectedGroupId = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ScopeChoice(
                              label: 'Group',
                              active: _scope == TaskScope.group,
                              onTap: () => setState(() {
                                _scope = TaskScope.group;
                                _selectedGroupId ??= widget.groups.isNotEmpty
                                    ? widget.groups.first.id
                                    : null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (_scope == TaskScope.group) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGroupId,
                          decoration: _inputDecoration('Choose group'),
                          items: widget.groups
                              .map(
                                (group) => DropdownMenuItem(
                                  value: group.id,
                                  child: Text(group.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) =>
                              setState(() => _selectedGroupId = value),
                        ),
                        const SizedBox(height: 8),
                        _GroupMembersPreview(group: _selectedGroup),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFFF5D5D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5D5D),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Task',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -8,
                top: -8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7A90),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF8A95A3),
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1D9E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1D9E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2386A2), width: 1.5),
      ),
    );
  }

  String _dateLabel(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class _PriorityChoice extends StatelessWidget {
  const _PriorityChoice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        decoration: BoxDecoration(
          color: active ? Colors.black : const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopeChoice extends StatelessWidget {
  const _ScopeChoice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF60CF67) : const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupMembersPreview extends StatelessWidget {
  const _GroupMembersPreview({required this.group});

  final GroupOption? group;

  @override
  Widget build(BuildContext context) {
    final members = group?.members ?? const <GroupMemberOption>[];
    final text = members.isEmpty
        ? 'Members: belum ada data member'
        : 'Members: ${members.map((member) => member.name).take(4).join(', ')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaError extends StatelessWidget {
  const _AgendaError({
    required this.scale,
    required this.error,
    required this.onReload,
  });

  final _AgendaScale scale;
  final String error;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.x(14)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(scale.radius(16)),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFF5D5D),
              fontSize: scale.font(12),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: scale.h(8)),
          TextButton(onPressed: onReload, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({required this.scale});

  final _AgendaScale scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: scale.h(116),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(scale.radius(16)),
        border: Border.all(color: Colors.white),
      ),
      child: Center(
        child: Text(
          'No task for this day.',
          style: TextStyle(
            color: const Color(0xFF5E7A83),
            fontSize: scale.font(13),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.scale,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final _AgendaScale scale;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scale.w(34),
        height: scale.w(34),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: scale.w(21)),
      ),
    );
  }
}

class _PixelAvatar extends StatelessWidget {
  const _PixelAvatar({
    required this.scale,
    required this.size,
    this.color = const Color(0xFF78EF70),
    this.tiny = false,
  });

  final _AgendaScale scale;
  final double size;
  final Color color;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    final scaledSize = scale.w(size);
    return Container(
      width: scaledSize,
      height: scaledSize,
      padding: EdgeInsets.all(scaledSize * 0.07),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: tiny ? 1 : 1.4),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/img/LandingPage1_icon.png',
          fit: BoxFit.cover,
          cacheWidth: tiny ? 36 : 56,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}

class _AgendaScale {
  const _AgendaScale({required this.width, required this.height});

  final double width;
  final double height;

  double x(double value) => value * width / 393;
  double y(double value) => value * height / 852;
  double w(double value) => value * width / 393;
  double h(double value) => value * width / 393;
  double font(double value) => value * width / 393;
  double radius(double value) => value * width / 393;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _dateKey(DateTime value) {
  return value.year * 10000 + value.month * 100 + value.day;
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

GroupOption? _groupForTask(TaskItem task, Map<String, GroupOption> groupsById) {
  final groupId = task.groupId;
  if (groupId == null || groupId.isEmpty) return null;
  return groupsById[groupId];
}
