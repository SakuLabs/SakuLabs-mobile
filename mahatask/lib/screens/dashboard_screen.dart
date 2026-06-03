import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/navigation_provider.dart';
import '../services/task_service.dart';
import '../services/unread_provider.dart';
import '../widgets/dashboard/bottom_nav_bar.dart';
import '../widgets/dashboard/saku_ai_chat_popup.dart';
import 'messages_screen.dart';
import 'tasks_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final unread = context.watch<UnreadProvider>().totalUnread;
    const pages = <Widget>[
      _DashboardHome(),
      TasksScreen(embedded: true),
      MessagesScreen(embedded: true),
    ];
    final pageIndex = nav.index.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1F),
      body: Stack(
        children: [
          IndexedStack(index: pageIndex, children: pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: nav.index,
              onTap: (value) {
                if (value == 3) {
                  showSakuAiChatPopup(context);
                  return;
                }
                context.read<NavigationProvider>().setIndex(value);
              },
              messagesUnread: unread,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome>
    with AutomaticKeepAliveClientMixin {
  final TaskService _taskService = TaskService();

  bool _loading = true;
  String? _error;
  List<TaskItem> _tasks = const <TaskItem>[];
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _loadTasks(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final tasks = await _taskService.fetchTasks();
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final name = context.watch<AuthProvider>().user?.name.trim();
    final displayName = name == null || name.isEmpty ? 'Name' : name;
    final total = _tasks.length;
    final todo = _tasks
        .where((task) => task.status.toUpperCase() == 'TODO')
        .length;
    final inProgress = _tasks
        .where((task) => task.status.toUpperCase() == 'IN_PROGRESS')
        .length;
    final completed = _tasks.where((task) {
      final status = task.status.toUpperCase();
      return status == 'COMPLETED' || status == 'DONE';
    }).length;
    final progress = total == 0
        ? 0.0
        : _tasks.fold<int>(0, (sum, task) => sum + task.progress) / total / 100;
    final shownTasks = _tasks.take(3).toList(growable: false);
    final topInset = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = _DashScale(width: width, height: height);
        final sidePadding = width * 0.07;
        final topPadding = topInset + height * 0.052;
        final bottomPadding = height * 0.14;

        return RepaintBoundary(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFA8CBFF),
                  Color(0xFFD8F0FF),
                  Color(0xFFD9C2FF),
                ],
                stops: [0, 0.62, 1],
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                sidePadding,
                topPadding,
                sidePadding,
                bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(
                    scale: scale,
                    displayName: displayName,
                    onAdd: () => context.read<NavigationProvider>().setIndex(1),
                  ),
                  SizedBox(height: scale.y(19)),
                  Text(
                    "Let's Make\nToday Productive",
                    style: TextStyle(
                      color: const Color(0xFF020713),
                      fontSize: scale.font(23),
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: scale.y(16)),
                  _ProgressCard(
                    scale: scale,
                    progress: progress,
                    total: total,
                    todo: todo,
                    inProgress: inProgress,
                    completed: completed,
                  ),
                  SizedBox(height: scale.y(15)),
                  _TaskSectionHeader(
                    scale: scale,
                    onViewAll: () =>
                        context.read<NavigationProvider>().setIndex(1),
                  ),
                  SizedBox(height: scale.y(8)),
                  _TaskFilters(
                    scale: scale,
                    todo: todo,
                    inProgress: inProgress,
                    completed: completed,
                  ),
                  SizedBox(height: scale.y(10)),
                  if (_loading)
                    SizedBox(
                      height: scale.y(145),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2386A2),
                        ),
                      ),
                    )
                  else if (_error != null)
                    _DashboardError(
                      scale: scale,
                      error: _error!,
                      onReload: _loadTasks,
                    )
                  else if (shownTasks.isEmpty)
                    _DashboardEmpty(scale: scale)
                  else
                    ...shownTasks.map((task) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: scale.y(8)),
                        child: _TaskCard.fromTask(scale: scale, task: task),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.scale,
    required this.displayName,
    required this.onAdd,
  });

  final _DashScale scale;
  final String displayName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PixelAvatar(size: scale.w(32), color: const Color(0xFF78EF70)),
        SizedBox(width: scale.x(7)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning',
                style: TextStyle(
                  color: const Color(0xFF020713),
                  fontSize: scale.font(13),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF020713),
                  fontSize: scale.font(8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          scale: scale,
          color: Colors.black,
          icon: Icons.add,
          iconColor: Colors.white,
          onTap: onAdd,
        ),
        SizedBox(width: scale.x(10)),
        _CircleIconButton(
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.scale,
    required this.progress,
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.completed,
  });

  final _DashScale scale;
  final double progress;
  final int total;
  final int todo;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: scale.h(148),
      padding: EdgeInsets.fromLTRB(
        scale.x(18),
        scale.h(12),
        scale.x(14),
        scale.h(10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(scale.radius(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Today's Progress",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale.font(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: scale.h(8)),
                SizedBox(
                  width: scale.w(76),
                  height: scale.w(76),
                  child: CustomPaint(
                    painter: _ProgressRingPainter(progress: progress),
                    child: Center(
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          color: const Color(0xFF222222),
                          fontSize: scale.font(12),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: scale.h(103),
            color: Colors.black.withValues(alpha: 0.86),
          ),
          SizedBox(width: scale.x(13)),
          SizedBox(
            width: scale.w(83),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProgressLegend(
                  scale: scale,
                  number: '$total',
                  label: 'Total Tasks',
                  color: Color(0xFF6C45FF),
                ),
                _ProgressLegend(
                  scale: scale,
                  number: '$todo',
                  label: 'To Do',
                  color: Color(0xFFFF5D5D),
                ),
                _ProgressLegend(
                  scale: scale,
                  number: '$inProgress',
                  label: 'In Progress',
                  color: Color(0xFFFFA640),
                ),
                _ProgressLegend(
                  scale: scale,
                  number: '$completed',
                  label: 'Completed',
                  color: Color(0xFF5FE568),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSectionHeader extends StatelessWidget {
  const _TaskSectionHeader({required this.scale, required this.onViewAll});

  final _DashScale scale;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "Today's Tasks",
          style: TextStyle(
            color: Colors.black,
            fontSize: scale.font(17),
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            padding: EdgeInsets.zero,
            minimumSize: Size(scale.w(54), scale.h(26)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View All',
            style: TextStyle(
              color: Colors.black,
              fontSize: scale.font(11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskFilters extends StatelessWidget {
  const _TaskFilters({
    required this.scale,
    required this.todo,
    required this.inProgress,
    required this.completed,
  });

  final _DashScale scale;
  final int todo;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(scale: scale, count: '$todo', label: 'ToDo', active: true),
        SizedBox(width: scale.x(6)),
        _FilterChip(scale: scale, count: '$inProgress', label: 'In Progress'),
        SizedBox(width: scale.x(6)),
        _FilterChip(scale: scale, count: '$completed', label: 'Complete'),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.scale,
    required this.title,
    required this.due,
    required this.priority,
    required this.tags,
    required this.avatars,
  });

  factory _TaskCard.fromTask({
    required _DashScale scale,
    required TaskItem task,
  }) {
    return _TaskCard(
      scale: scale,
      title: task.title.isEmpty ? 'Untitled Task' : task.title,
      due: _formatTaskTime(task.dueDate),
      priority: _priorityLabel(task.priority),
      tags: [task.isGroupTask ? 'People' : 'Work'],
      avatars: task.isGroupTask
          ? const [Color(0xFF55E377), Color(0xFFFFC2E8)]
          : const [Color(0xFF55E377)],
    );
  }

  final _DashScale scale;
  final String title;
  final String due;
  final String priority;
  final List<String> tags;
  final List<Color> avatars;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: scale.y(104),
      padding: EdgeInsets.fromLTRB(
        scale.x(12),
        scale.y(12),
        scale.x(8),
        scale.y(9),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(scale.radius(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(15),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: scale.y(7)),
              _MetaLine(scale: scale, icon: Icons.alarm, text: 'Due: $due'),
              SizedBox(height: scale.y(4)),
              _MetaLine(
                scale: scale,
                icon: Icons.info_outline,
                text: 'Priority: $priority',
              ),
              const Spacer(),
              Row(
                children: [
                  ...tags.map((tag) {
                    return Padding(
                      padding: EdgeInsets.only(right: scale.x(4)),
                      child: _SmallTag(
                        scale: scale,
                        label: tag,
                        color: tag == 'Work'
                            ? const Color(0xFFFF5D5D)
                            : const Color(0xFF705DFF),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: scale.w(25),
              height: scale.w(25),
              decoration: const BoxDecoration(
                color: Color(0xFFE9E9E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_outward_rounded,
                color: const Color(0xFF8B8B8B),
                size: scale.w(18),
              ),
            ),
          ),
          Positioned(
            right: scale.x(0),
            bottom: scale.y(2),
            child: SizedBox(
              width: scale.w(82),
              height: scale.w(28),
              child: Stack(
                alignment: Alignment.centerRight,
                children: List.generate(avatars.length, (index) {
                  return Positioned(
                    right: scale.x(index * 18),
                    child: _PixelAvatar(
                      size: scale.w(25),
                      color: avatars[index],
                      tiny: true,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.scale,
    required this.error,
    required this.onReload,
  });

  final _DashScale scale;
  final String error;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.x(14)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(scale.radius(16)),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFFF5D5D),
              fontSize: scale.font(11),
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

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty({required this.scale});

  final _DashScale scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: scale.y(104),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(scale.radius(16)),
      ),
      child: Center(
        child: Text(
          'No tasks yet. Tap + to create one.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF5E7A83),
            fontSize: scale.font(12),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.scale,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final _DashScale scale;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: scale.w(36),
        height: scale.w(36),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: scale.w(22)),
        ),
      ),
    );
  }
}

class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend({
    required this.scale,
    required this.number,
    required this.label,
    required this.color,
  });

  final _DashScale scale;
  final String number;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scale.h(1)),
      child: Row(
        children: [
          Container(
            width: scale.w(23),
            height: scale.w(23),
            decoration: const BoxDecoration(
              color: Color(0xFFE5E5E5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_rounded, size: scale.w(12)),
          ),
          SizedBox(width: scale.x(5)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: TextStyle(
                  color: color,
                  fontSize: scale.font(9),
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFB7B7B7),
                  fontSize: scale.font(5.6),
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.scale,
    required this.count,
    required this.label,
    this.active = false,
  });

  final _DashScale scale;
  final String count;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: scale.y(30),
        padding: EdgeInsets.symmetric(horizontal: scale.x(6)),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF98EE93) : Colors.white,
          borderRadius: BorderRadius.circular(scale.radius(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: scale.w(24),
              height: scale.w(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale.font(10),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(width: scale.x(7)),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: scale.font(10),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.scale,
    required this.icon,
    required this.text,
  });

  final _DashScale scale;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: scale.w(12)),
        SizedBox(width: scale.x(3)),
        Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: scale.font(8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.scale,
    required this.label,
    required this.color,
  });

  final _DashScale scale;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: scale.y(16),
      padding: EdgeInsets.symmetric(horizontal: scale.x(6)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale.radius(9)),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: [
          Container(
            width: scale.w(4),
            height: scale.w(4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: scale.x(3)),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: scale.font(7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelAvatar extends StatelessWidget {
  const _PixelAvatar({
    required this.size,
    required this.color,
    this.tiny = false,
  });

  final double size;
  final Color color;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(tiny ? size * 0.06 : size * 0.08),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: tiny ? 1 : 1.4),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/img/LandingPage1_icon.png',
          fit: BoxFit.cover,
          cacheWidth: tiny ? 40 : 56,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 7;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.black;
    canvas.drawCircle(center, radius, track);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF65E875);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.28 * progress.clamp(0, 1),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ignore: unused_element
class _UnusedSakuAiHome extends StatelessWidget {
  const _UnusedSakuAiHome();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = _DashScale(width: width, height: height);
        final sidePadding = width * 0.07;
        final topPadding = topInset + height * 0.052;
        final bottomPadding = height * 0.14;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFA8CBFF), Color(0xFFD8F0FF), Color(0xFFD9C2FF)],
              stops: [0, 0.62, 1],
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              topPadding,
              sidePadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(
                  scale: scale,
                  displayName:
                      context.watch<AuthProvider>().user?.name ?? 'Name',
                  onAdd: () => context.read<NavigationProvider>().setIndex(1),
                ),
                SizedBox(height: scale.y(28)),
                Text(
                  'SakuAI',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale.font(30),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: scale.y(8)),
                Text(
                  'Ask for study plans, task summaries, or schedule ideas.',
                  style: TextStyle(
                    color: const Color(0xFF5E7A83),
                    fontSize: scale.font(13),
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: scale.y(24)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(scale.x(18)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(scale.radius(18)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today’s prompt',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: scale.font(16),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: scale.y(10)),
                      Text(
                        'Help me organize my highest priority tasks for this week.',
                        style: TextStyle(
                          color: const Color(0xFF5E7A83),
                          fontSize: scale.font(13),
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashScale {
  const _DashScale({required this.width, required this.height});

  final double width;
  final double height;

  double x(double value) => value * width / 393;
  double y(double value) => value * height / 852;
  double w(double value) => value * width / 393;
  double h(double value) => value * width / 393;
  double font(double value) => value * width / 393;
  double radius(double value) => value * width / 393;
}

String _formatTaskTime(DateTime? value) {
  if (value == null) return '--:--';
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _priorityLabel(String value) {
  final text = value.toUpperCase();
  if (text == 'LOW') return 'Low';
  if (text == 'HIGH') return 'High';
  return 'Medium';
}
