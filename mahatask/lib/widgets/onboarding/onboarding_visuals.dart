import 'package:flutter/material.dart';

import 'onboarding_layout.dart';

class OnboardingBottomPanel extends StatelessWidget {
  const OnboardingBottomPanel({
    required this.scale,
    this.top = 600,
    this.height = 252,
    super.key,
  });

  final FigmaScale scale;
  final double top;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: scale.x(0),
      top: scale.y(top),
      width: scale.w(393),
      height: scale.h(height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF227C9D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(scale.font(72)),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 9.6,
              spreadRadius: 1,
              offset: Offset(-5, -7),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingShelf extends StatelessWidget {
  const OnboardingShelf({
    required this.scale,
    this.left = -14,
    this.top = 524,
    this.width = 240,
    this.height = 179,
    this.roundTopLeft = false,
    this.roundTopRight = true,
    super.key,
  });

  final FigmaScale scale;
  final double left;
  final double top;
  final double width;
  final double height;
  final bool roundTopLeft;
  final bool roundTopRight;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: scale.x(left),
      top: scale.y(top),
      width: scale.w(width),
      height: scale.h(height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF6DA2B5),
          borderRadius: BorderRadius.only(
            topLeft: roundTopLeft
                ? Radius.circular(scale.font(44))
                : Radius.zero,
            topRight: roundTopRight
                ? Radius.circular(scale.font(44))
                : Radius.zero,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 9.6,
              spreadRadius: 1,
              offset: Offset(-5, -7),
            ),
          ],
        ),
      ),
    );
  }
}
