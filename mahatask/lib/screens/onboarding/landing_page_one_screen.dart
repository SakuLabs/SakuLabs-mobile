import 'package:flutter/material.dart';

import '../../widgets/onboarding/onboarding_controls.dart';
import '../../widgets/onboarding/onboarding_layout.dart';
import '../../widgets/onboarding/onboarding_text.dart';
import '../../widgets/onboarding/onboarding_visuals.dart';

class LandingPageOneScreen extends StatelessWidget {
  const LandingPageOneScreen({
    required this.pageCount,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  static const String heroAsset = 'assets/img/LandingPage1_icon.png';
  static const String deepVectorAsset = 'assets/img/LandingPage1_1.png';
  static const String blueVectorAsset = 'assets/img/LandingPage1_2.png';

  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      gradient: OnboardingGradients.pageOne,
      child: FigmaFrame(
        builder: (context, scale) {
          return Stack(
            children: [
              Positioned(
                left: scale.x(247),
                top: scale.y(74),
                width: scale.w(149),
                height: scale.h(336),
                child: Image.asset(blueVectorAsset, fit: BoxFit.fill),
              ),
              Positioned(
                left: scale.x(0),
                top: scale.y(0),
                width: scale.w(393),
                height: scale.h(436),
                child: Image.asset(heroAsset, fit: BoxFit.fill),
              ),
              Positioned(
                left: scale.x(-4),
                top: scale.y(340),
                width: scale.w(190),
                height: scale.h(247),
                child: Image.asset(deepVectorAsset, fit: BoxFit.fill),
              ),
              OnboardingShelf(scale: scale),
              OnboardingBottomPanel(scale: scale),
              Positioned(
                left: scale.x(125),
                top: scale.y(440),
                width: scale.w(289),
                height: scale.h(74),
                child: OnboardingTitle(
                  scale: scale,
                  children: const [
                    TextSpan(text: 'Master Your Academic\nJourney '),
                    TextSpan(
                      text: 'with Ease',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: scale.x(47),
                top: scale.y(650),
                width: scale.w(298),
                height: scale.h(96),
                child: OnboardingBodyText(
                  scale: scale,
                  children: const [
                    TextSpan(text: 'Stop juggling multiple apps. '),
                    TextSpan(
                      text: 'MahaTask',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text:
                          ' combines task management, smart scheduling, and study groups into one cohesive platform tailored for students.',
                    ),
                  ],
                ),
              ),
              OnboardingControls(
                scale: scale,
                pageIndex: 0,
                pageCount: pageCount,
                buttonText: 'Next',
                onNext: onNext,
                onSkip: onSkip,
              ),
            ],
          );
        },
      ),
    );
  }
}
