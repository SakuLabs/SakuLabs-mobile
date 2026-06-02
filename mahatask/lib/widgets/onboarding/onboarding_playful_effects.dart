import 'dart:math' as math;

import 'package:flutter/material.dart';

class OnboardingBurstOverlay extends StatefulWidget {
  const OnboardingBurstOverlay({required this.trigger, super.key});

  final int trigger;

  @override
  State<OnboardingBurstOverlay> createState() => _OnboardingBurstOverlayState();
}

class _OnboardingBurstOverlayState extends State<OnboardingBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  @override
  void didUpdateWidget(OnboardingBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BurstPainter(progress: _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final origin = Offset(size.width * 0.50, size.height * 0.913);
    final eased = Curves.easeOutBack.transform(progress.clamp(0, 1));
    final fade = (1 - progress).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withValues(alpha: 0.38 * fade);

    canvas.drawCircle(origin, 18 + 34 * eased, ringPaint);

    final colors = [
      const Color(0xFFFFFFFF),
      const Color(0xFFFFD765),
      const Color(0xFF26BFB6),
      const Color(0xFFFF5D5D),
    ];

    for (var i = 0; i < 14; i++) {
      final angle = (math.pi * 2 / 14) * i - math.pi / 2;
      final distance = 18 + (34 + (i % 4) * 7) * eased;
      final center = Offset(
        origin.dx + math.cos(angle) * distance,
        origin.dy + math.sin(angle) * distance,
      );
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade);
      if (i.isEven) {
        canvas.drawCircle(center, 2.2 + (i % 3), paint);
      } else {
        _drawDiamond(canvas, center, 3.2 + (i % 3), paint);
      }
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
