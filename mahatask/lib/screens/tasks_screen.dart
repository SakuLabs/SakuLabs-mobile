import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/task_service.dart';

enum _TaskFilter { all, work, people, favorite }

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
  DateTime _selectedDay = DateTime.now();
  _TaskFilter _filter = _TaskFilter.all;
  List<TaskItem> _tasks = const <TaskItem>[];
  List<GroupOption> _groups = const <GroupOption>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateTaskSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateTaskSheet(
          service: _taskService,
          groups: _groups,
          initialDay: _selectedDay,
        );
      },
    );

    if (created == true) {
      await _loadData();
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
        _tasks = _tasks
            .map((item) => item.id == task.id ? updated : item)
            .toList(growable: false);
      });
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
          selectedDay: _selectedDay,
          tasks: _tasks,
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
    final body = _TaskAgendaBody(
      isLoading: _isLoading,
      error: _error,
      tasks: _visibleTasks(),
      selectedDay: _selectedDay,
      filter: _filter,
      expandedTaskIds: _expandedTaskIds,
      onReload: _loadData,
      onCreateTask: _openCreateTaskSheet,
      onOpenCalendar: _openCalendarPopup,
      onSelectDay: (day) => setState(() => _selectedDay = day),
      onSelectFilter: (filter) => setState(() => _filter = filter),
      onToggleExpanded: _toggleExpanded,
      onStatusChanged: _updateStatus,
      onDelete: _deleteTask,
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: const Color(0xFF1D1D1F), body: body);
  }

  List<TaskItem> _visibleTasks() {
    final filtered = _tasks
        .where((task) {
          switch (_filter) {
            case _TaskFilter.all:
              return true;
            case _TaskFilter.work:
              return !task.isGroupTask;
            case _TaskFilter.people:
              return task.isGroupTask;
            case _TaskFilter.favorite:
              return task.priority == 'HIGH';
          }
        })
        .toList(growable: false);

    final daily = filtered
        .where(
          (task) =>
              task.dueDate != null && _sameDay(task.dueDate!, _selectedDay),
        )
        .toList(growable: false);
    if (daily.isNotEmpty) return daily;

    final upcoming = filtered.where((task) => task.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    if (upcoming.isNotEmpty) return upcoming.take(4).toList(growable: false);

    return filtered.take(4).toList(growable: false);
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _TaskAgendaBody extends StatelessWidget {
  const _TaskAgendaBody({
    required this.isLoading,
    required this.error,
    required this.tasks,
    required this.selectedDay,
    required this.filter,
    required this.expandedTaskIds,
    required this.onReload,
    required this.onCreateTask,
    required this.onOpenCalendar,
    required this.onSelectDay,
    required this.onSelectFilter,
    required this.onToggleExpanded,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final bool isLoading;
  final String? error;
  final List<TaskItem> tasks;
  final DateTime selectedDay;
  final _TaskFilter filter;
  final Set<String> expandedTaskIds;
  final VoidCallback onReload;
  final VoidCallback onCreateTask;
  final VoidCallback onOpenCalendar;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<_TaskFilter> onSelectFilter;
  final ValueChanged<TaskItem> onToggleExpanded;
  final Future<void> Function(TaskItem task, String status) onStatusChanged;
  final Future<void> Function(TaskItem task) onDelete;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name.trim();
    final displayName = name == null || name.isEmpty ? 'Name' : name;

    return SafeArea(
      bottom: false,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(0.0, 393.0);
            final height = constraints.maxHeight;
            final scale = _AgendaScale(width: width, height: height);

            return SizedBox(
              width: width,
              height: height,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  scale.x(39),
                  scale.y(31),
                  scale.x(39),
                  scale.y(96),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scheduler Calendar 2.0',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: scale.font(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: scale.y(12)),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: scale.h(785)),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFA1C4FD),
                            Color(0xFFC2E9FB),
                            Color(0xFFE0C3FC),
                          ],
                          stops: [0, 0.5, 1],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          scale.x(14),
                          scale.h(72),
                          scale.x(14),
                          scale.h(18),
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
                              onSelectDay: onSelectDay,
                            ),
                            SizedBox(height: scale.h(12)),
                            _FilterStrip(
                              scale: scale,
                              selected: filter,
                              onSelect: onSelectFilter,
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
                              _AgendaError(
                                scale: scale,
                                error: error!,
                                onReload: onReload,
                              )
                            else if (tasks.isEmpty)
                              _EmptyAgenda(scale: scale)
                            else
                              ...tasks.map((task) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: scale.h(14)),
                                  child: _AgendaTaskCard(
                                    scale: scale,
                                    task: task,
                                    expanded: expandedTaskIds.contains(task.id),
                                    onToggleExpanded: () =>
                                        onToggleExpanded(task),
                                    onStatusChanged: (status) =>
                                        onStatusChanged(task, status),
                                    onDelete: () => onDelete(task),
                                  ),
                                );
                              }),
                          ],
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
    required this.onSelectDay,
  });

  final _AgendaScale scale;
  final DateTime selectedDay;
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
            final weekday = labels[day.weekday % 7];
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelectDay(day),
                child: Container(
                  height: scale.h(65),
                  margin: EdgeInsets.symmetric(horizontal: scale.x(3)),
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
                      Container(
                        width: scale.w(30),
                        height: scale.w(30),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.black
                              : const Color(0xFFE8E8E8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: active ? Colors.white : Colors.black,
                              fontSize: scale.font(10),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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
  });

  final _AgendaScale scale;
  final _TaskFilter selected;
  final ValueChanged<_TaskFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            scale: scale,
            label: 'All',
            icon: null,
            active: selected == _TaskFilter.all,
            onTap: () => onSelect(_TaskFilter.all),
          ),
          _FilterChip(
            scale: scale,
            label: 'Work',
            icon: Icons.work_outline_rounded,
            active: selected == _TaskFilter.work,
            onTap: () => onSelect(_TaskFilter.work),
          ),
          _FilterChip(
            scale: scale,
            label: 'People',
            icon: Icons.groups_2_outlined,
            active: selected == _TaskFilter.people,
            onTap: () => onSelect(_TaskFilter.people),
          ),
          _FilterChip(
            scale: scale,
            label: 'Fav',
            icon: Icons.star_border_rounded,
            active: selected == _TaskFilter.favorite,
            onTap: () => onSelect(_TaskFilter.favorite),
          ),
        ],
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
    this.icon,
  });

  final _AgendaScale scale;
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: scale.x(8)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: scale.h(30),
          padding: EdgeInsets.symmetric(horizontal: scale.x(13)),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(scale.radius(18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: active ? Colors.white : Colors.black,
                  size: scale.w(14),
                ),
                SizedBox(width: scale.x(6)),
              ],
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.black,
                  fontSize: scale.font(12),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
    required this.expanded,
    required this.onToggleExpanded,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final _AgendaScale scale;
  final TaskItem task;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasDescription = task.description.trim().isNotEmpty;
    final due = task.dueDate ?? DateTime.now();

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
              PopupMenuButton<String>(
                tooltip: 'Task actions',
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.black.withValues(alpha: 0.58),
                  size: scale.w(17),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else {
                    onStatusChanged(value);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'TODO', child: Text('Set To Do')),
                  PopupMenuItem(
                    value: 'IN_PROGRESS',
                    child: Text('Set In Progress'),
                  ),
                  PopupMenuItem(value: 'DONE', child: Text('Set Done')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
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
              _MiniAvatars(scale: scale, task: task),
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
          SizedBox(height: expanded ? scale.h(17) : scale.h(14)),
          Row(
            children: [
              Text(
                'Links: www.${task.isGroupTask ? 'GroupTask' : 'Docstugas'}.com',
                style: TextStyle(
                  color: const Color(0xFF8B8B8B),
                  fontSize: scale.font(7),
                  fontWeight: FontWeight.w700,
                ),
              ),
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.scale, required this.task});

  final _AgendaScale scale;
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final color = switch (task.status) {
      'DONE' => const Color(0xFF60CF67),
      'IN_PROGRESS' => const Color(0xFF2386A2),
      _ => const Color(0xFFFFB25A),
    };
    final label = switch (task.status) {
      'DONE' => 'Done',
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
  const _MiniAvatars({required this.scale, required this.task});

  final _AgendaScale scale;
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final count = task.isGroupTask ? 3 : 1;
    return SizedBox(
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
  }
}

class _CalendarDialog extends StatelessWidget {
  const _CalendarDialog({
    required this.selectedDay,
    required this.tasks,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final List<TaskItem> tasks;
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
          return Container(
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
                      const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
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
                              final hasTask = tasks.any(
                                (task) =>
                                    task.dueDate != null &&
                                    _sameDay(task.dueDate!, date),
                              );
                              return GestureDetector(
                                onTap: () => onSelect(date),
                                child: SizedBox(
                                  height: scale.h(34),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: scale.w(34),
                                        height: scale.w(34),
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
                                      if (hasTask)
                                        Positioned(
                                          bottom: scale.h(3),
                                          child: Container(
                                            width: scale.w(4),
                                            height: scale.w(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF60CF67),
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
  var _progress = 0;
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
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() {
      final next = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
      );
      if (deadline) {
        _deadline = next;
      } else {
        _startDate = next;
      }
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

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.service.createTask(
        title: title,
        description: _descriptionController.text.trim(),
        priority: _priority,
        scope: TaskScope.personal,
        startDate: _startDate,
        dueDate: _deadline,
        progress: _progress,
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 14),
              _SheetField(
                label: 'Title',
                child: TextField(
                  controller: _titleController,
                  decoration: _inputDecoration('Project Assignment'),
                ),
              ),
              _SheetField(
                label: 'Description',
                child: TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _inputDecoration('Apa saja isi tugasnya?'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Start',
                      value: _dateLabel(_startDate),
                      onTap: () => _pickDate(deadline: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(
                      label: 'Deadline',
                      value: _dateLabel(_deadline),
                      onTap: () => _pickDate(deadline: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                decoration: _inputDecoration('Priority'),
                items: const [
                  DropdownMenuItem(value: TaskPriority.low, child: Text('LOW')),
                  DropdownMenuItem(
                    value: TaskPriority.medium,
                    child: Text('MEDIUM'),
                  ),
                  DropdownMenuItem(
                    value: TaskPriority.high,
                    child: Text('HIGH'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Progress $_progress%',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Slider(
                value: _progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 10,
                activeColor: const Color(0xFF2386A2),
                inactiveColor: const Color(0xFFD7ECF2),
                onChanged: (value) => setState(() => _progress = value.round()),
              ),
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
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    return '${value.day}/${value.month}/${value.year}';
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

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD1D9E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
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
