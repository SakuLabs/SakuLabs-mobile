import 'package:flutter/material.dart';

import 'onboarding_layout.dart';

class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle({
    required this.scale,
    required this.children,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final FigmaScale scale;
  final List<InlineSpan> children;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: scale.font(24),
          height: 29 / 24,
          fontWeight: FontWeight.w200,
          shadows: const [
            Shadow(
              color: Color(0x40000000),
              blurRadius: 4.9,
              offset: Offset(0, 4),
            ),
          ],
        ),
        children: children,
      ),
    );
  }
}

class OnboardingBodyText extends StatelessWidget {
  const OnboardingBodyText({
    required this.scale,
    required this.children,
    super.key,
  });

  final FigmaScale scale;
  final List<InlineSpan> children;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: scale.font(16),
          height: 19 / 16,
          fontWeight: FontWeight.w400,
        ),
        children: children,
      ),
    );
  }
}
