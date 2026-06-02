import 'package:flutter/material.dart';

import 'onboarding_layout.dart';

class OnboardingControls extends StatelessWidget {
  const OnboardingControls({
    required this.scale,
    required this.pageIndex,
    required this.pageCount,
    required this.buttonText,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final FigmaScale scale;
  final int pageIndex;
  final int pageCount;
  final String buttonText;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: scale.x(145),
          top: scale.y(742),
          width: scale.w(102),
          height: scale.h(36),
          child: OnboardingPrimaryButton(
            text: buttonText,
            scale: scale,
            onPressed: onNext,
          ),
        ),
        Positioned(
          left: scale.x(169),
          top: scale.y(790),
          width: scale.w(55),
          height: scale.h(7),
          child: OnboardingPageDots(
            activeIndex: pageIndex,
            pageCount: pageCount,
          ),
        ),
        Positioned(
          left: scale.x(320),
          top: scale.y(782),
          width: scale.w(60),
          height: scale.h(28),
          child: OnboardingSkipButton(scale: scale, onPressed: onSkip),
        ),
      ],
    );
  }
}

class OnboardingPrimaryButton extends StatefulWidget {
  const OnboardingPrimaryButton({
    required this.text,
    required this.scale,
    required this.onPressed,
    super.key,
  });

  final String text;
  final FigmaScale scale;
  final VoidCallback onPressed;

  @override
  State<OnboardingPrimaryButton> createState() =>
      _OnboardingPrimaryButtonState();
}

class _OnboardingPrimaryButtonState extends State<OnboardingPrimaryButton> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    if (_pressed) return;
    setState(() => _pressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() => _pressed = false);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.90 : 1,
      duration: const Duration(milliseconds: 170),
      curve: _pressed ? Curves.easeOut : Curves.elasticOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFF5D5D),
          borderRadius: BorderRadius.circular(widget.scale.font(35)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextButton(
          onPressed: _handleTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.scale.font(35)),
            ),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.scale.font(16),
              height: 19 / 16,
              fontWeight: FontWeight.w400,
              shadows: const [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPageDots extends StatelessWidget {
  const OnboardingPageDots({
    required this.activeIndex,
    required this.pageCount,
    super.key,
  });

  final int activeIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dotWidth = constraints.maxWidth * 0.18;
        final activeWidth = constraints.maxWidth * 0.34;
        final gap = (constraints.maxWidth - activeWidth - (dotWidth * 2)) / 2;
        final travel = dotWidth + gap;
        final activeLeft =
            activeIndex.clamp(0, pageCount - 1).toDouble() * travel;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(pageCount, (index) {
                return Container(
                  width: dotWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(11),
                  ),
                );
              }),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              left: activeLeft,
              width: activeWidth,
              height: constraints.maxHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({
    required this.scale,
    required this.onPressed,
    super.key,
  });

  final FigmaScale scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Skip',
        style: TextStyle(
          color: Colors.white,
          fontSize: scale.font(12),
          height: 14 / 12,
          fontWeight: FontWeight.w400,
          shadows: const [
            Shadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}
