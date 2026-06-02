import 'package:flutter/material.dart';

import '../../widgets/onboarding/onboarding_controls.dart';
import '../../widgets/onboarding/onboarding_layout.dart';
import '../../widgets/onboarding/onboarding_text.dart';
import '../../widgets/onboarding/onboarding_visuals.dart';

class LandingPageTwoScreen extends StatelessWidget {
  const LandingPageTwoScreen({
    required this.pageCount,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  static const String vectorAsset = 'assets/img/LandingPage2_1.png';
  static const String iconAsset = 'assets/img/LandingPage2_icon.png';

  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      gradient: OnboardingGradients.pageTwoThree,
      child: FigmaFrame(
        builder: (context, scale) {
          return Stack(
            children: [
              Positioned(
                left: scale.x(182),
                top: scale.y(0),
                width: scale.w(211),
                height: scale.h(496),
                child: Image.asset(vectorAsset, fit: BoxFit.fill),
              ),
              Positioned(
                left: scale.x(18),
                top: scale.y(100),
                width: scale.w(194),
                height: scale.h(96),
                child: OnboardingTitle(
                  scale: scale,
                  textAlign: TextAlign.left,
                  children: const [
                    TextSpan(text: 'Track '),
                    TextSpan(
                      text: 'All ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: 'of Your\nWork '),
                    TextSpan(
                      text: 'On Your\nScreen',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: scale.x(19),
                top: scale.y(202),
                width: scale.w(342),
                height: scale.h(384),
                child: Image.asset(iconAsset, fit: BoxFit.fill),
              ),
              OnboardingShelf(
                scale: scale,
                left: 58,
                top: 510,
                width: 285,
                height: 116,
              ),
              OnboardingBottomPanel(scale: scale),
              Positioned(
                left: scale.x(47),
                top: scale.y(650),
                width: scale.w(298),
                height: scale.h(88),
                child: OnboardingBodyText(
                  scale: scale,
                  children: const [
                    TextSpan(
                      text:
                          'Track all of your assignments and study progress anywhere, making organizing work a lot easier',
                    ),
                  ],
                ),
              ),
              OnboardingControls(
                scale: scale,
                pageIndex: 1,
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
