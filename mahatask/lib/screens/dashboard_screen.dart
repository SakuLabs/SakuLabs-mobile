import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/navigation_provider.dart';
import '../services/unread_provider.dart';
import '../widgets/dashboard/bottom_nav_bar.dart';
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
      _SakuAiHome(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1F),
      body: Stack(
        children: [
          IndexedStack(index: nav.index, children: pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: nav.index,
              onTap: (value) {
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

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = _DashScale(width: width, height: height);

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
                scale.x(30),
                topInset + scale.y(58),
                scale.x(30),
                scale.y(122),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(scale: scale),
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
                  _ProgressCard(scale: scale),
                  SizedBox(height: scale.y(15)),
                  _TaskSectionHeader(scale: scale),
                  SizedBox(height: scale.y(8)),
                  _TaskFilters(scale: scale),
                  SizedBox(height: scale.y(10)),
                  _TaskCard(
                    scale: scale,
                    title: 'Design Landing Page',
                    due: '09:00 AM',
                    tags: const ['Design', 'Work'],
                    avatars: const [
                      Color(0xFF55E377),
                      Color(0xFFFFC2E8),
                      Color(0xFFBFD4FF),
                    ],
                  ),
                  SizedBox(height: scale.y(8)),
                  _TaskCard(
                    scale: scale,
                    title: 'Send Invoice To Clients',
                    due: '11:00 AM',
                    tags: const ['Work'],
                    avatars: const [Color(0xFF55E377)],
                  ),
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
  const _HeaderRow({required this.scale});

  final _DashScale scale;

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
                'Name',
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
        ),
        SizedBox(width: scale.x(10)),
        _CircleIconButton(
          scale: scale,
          color: Colors.white,
          icon: Icons.notifications_none_rounded,
          iconColor: Colors.black,
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.scale});

  final _DashScale scale;

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
                    painter: _ProgressRingPainter(progress: 0.75),
                    child: Center(
                      child: Text(
                        '75%',
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
                  number: '0',
                  label: 'Total Tasks',
                  color: Color(0xFF6C45FF),
                ),
                _ProgressLegend(
                  scale: scale,
                  number: '0',
                  label: 'To Do',
                  color: Color(0xFFFF5D5D),
                ),
                _ProgressLegend(
                  scale: scale,
                  number: '0',
                  label: 'In Progress',
                  color: Color(0xFFFFA640),
                ),
                _ProgressLegend(
                  scale: scale,
                  number: '0',
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
  const _TaskSectionHeader({required this.scale});

  final _DashScale scale;

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
        Text(
          'View All',
          style: TextStyle(
            color: Colors.black,
            fontSize: scale.font(11),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TaskFilters extends StatelessWidget {
  const _TaskFilters({required this.scale});

  final _DashScale scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(scale: scale, count: '4', label: 'ToDo', active: true),
        SizedBox(width: scale.x(6)),
        _FilterChip(scale: scale, count: '4', label: 'In Progress'),
        SizedBox(width: scale.x(6)),
        _FilterChip(scale: scale, count: '4', label: 'Complete'),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.scale,
    required this.title,
    required this.due,
    required this.tags,
    required this.avatars,
  });

  final _DashScale scale;
  final String title;
  final String due;
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
                text: 'Priority: High',
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.scale,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final _DashScale scale;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: scale.w(36),
      height: scale.w(36),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: scale.w(22)),
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

class _SakuAiHome extends StatelessWidget {
  const _SakuAiHome();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = _DashScale(width: width, height: height);

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
              scale.x(30),
              topInset + scale.y(58),
              scale.x(30),
              scale.y(122),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(scale: scale),
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
