import 'package:flutter/material.dart';

import 'package:mahatask/services/scheduler_service.dart';
import 'package:mahatask/services/task_service.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen>
    with AutomaticKeepAliveClientMixin {
  final SchedulerService _service = SchedulerService();
  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _selectedDay = DateTime.now();

  bool _loading = true;
  String? _error;
  List<ScheduleItem> _schedules = const <ScheduleItem>[];
  List<TaskItem> _deadlines = const <TaskItem>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.fetchSchedules(),
        _service.fetchDeadlines(),
      ]);
      if (!mounted) return;
      setState(() {
        _schedules = results[0] as List<ScheduleItem>;
        _deadlines = results[1] as List<TaskItem>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    final body = SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduler',
              style: TextStyle(
                color: titleColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Monthly calendar, timeline, and upcoming deadlines.',
              style: TextStyle(color: subColor),
            ),
            const SizedBox(height: 18),
            _buildMonthCalendar(),
            const SizedBox(height: 16),
            if (_loading)
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else if (_error != null)
              _buildError()
            else ...[
              _buildDailyTimeline(),
              const SizedBox(height: 16),
              _buildUpcomingDeadlines(),
            ],
          ],
        ),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
    );
  }

  Widget _buildMonthCalendar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark ? Colors.white10 : Colors.white;
    final heading = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white38 : const Color(0xFF64748B);
    final dayColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final border = isDark ? Colors.transparent : const Color(0xFFE2E8F0);
    final monthLabel = _monthName(_focusedMonth.month);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthLabel ${_focusedMonth.year}',
                style: TextStyle(color: heading, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month - 1,
                          1,
                        );
                      });
                    },
                    icon: Icon(Icons.chevron_left, color: dayColor),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month + 1,
                          1,
                        );
                      });
                    },
                    icon: Icon(Icons.chevron_right, color: dayColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final index = row * 7 + col;
                        final dayNum = index - leadingEmpty + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox(height: 34);
                        }
                        final date = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month,
                          dayNum,
                        );
                        final selected = _isSameDate(date, _selectedDay);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = date),
                          child: Container(
                            height: 34,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$dayNum',
                                style: TextStyle(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : dayColor,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
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
  }

  Widget _buildDailyTimeline() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark ? Colors.white10 : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white54 : const Color(0xFF64748B);
    final border = isDark ? Colors.transparent : const Color(0xFFE2E8F0);
    final itemBg = isDark ? Colors.black26 : const Color(0xFFF8FAFC);
    final itemBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final daily = _schedules
        .where((item) => _isSameDate(item.startTime, _selectedDay))
        .toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Timeline (${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year})',
            style: TextStyle(color: text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (daily.isEmpty)
            Text(
              'No schedule for this day.',
              style: TextStyle(color: muted),
            )
          else
            ...daily.map((item) {
              final start = _hhmm(item.startTime);
              final end = _hhmm(item.endTime);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: itemBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$start - $end',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark ? Colors.white10 : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white54 : const Color(0xFF64748B);
    final border = isDark ? Colors.transparent : const Color(0xFFE2E8F0);
    final itemBg = isDark ? Colors.black26 : const Color(0xFFF8FAFC);
    final itemBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final upcoming =
        _deadlines.where((task) => task.dueDate != null).toList(growable: false)
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Deadlines',
            style: TextStyle(color: text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            Text(
              'No upcoming deadlines.',
              style: TextStyle(color: muted),
            )
          else
            ...upcoming.take(8).map((task) {
              final due = task.dueDate!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: itemBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(task.title, style: TextStyle(color: text)),
                    ),
                    Text('${due.day}/${due.month}', style: TextStyle(color: muted)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 10),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
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
    return names[month - 1];
  }

  String _hhmm(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

