import 'package:flutter/material.dart';

import '../../widgets/onboarding/onboarding_controls.dart';
import '../../widgets/onboarding/onboarding_layout.dart';
import '../../widgets/onboarding/onboarding_text.dart';
import '../../widgets/onboarding/onboarding_visuals.dart';

class LandingPageThreeScreen extends StatelessWidget {
  const LandingPageThreeScreen({
    required this.pageCount,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  static const String yellowVectorAsset = 'assets/img/LandingPage3_1.png';
  static const String tealVectorAsset = 'assets/img/LandingPage3_2.png';
  static const String iconAsset = 'assets/img/LandingPage3_icon.png';

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
                left: scale.x(0),
                top: scale.y(0),
                width: scale.w(221),
                height: scale.h(395),
                child: Image.asset(yellowVectorAsset, fit: BoxFit.fill),
              ),
              Positioned(
                left: scale.x(279),
                top: scale.y(0),
                width: scale.w(114),
                height: scale.h(168),
                child: Image.asset(tealVectorAsset, fit: BoxFit.fill),
              ),
              Positioned(
                left: scale.x(88),
                top: scale.y(112),
                width: scale.w(301),
                height: scale.h(315),
                child: Image.asset(iconAsset, fit: BoxFit.fill),
              ),
              Positioned(
                left: scale.x(47),
                top: scale.y(432),
                width: scale.w(238),
                height: scale.h(74),
                child: OnboardingTitle(
                  scale: scale,
                  textAlign: TextAlign.left,
                  children: const [
                    TextSpan(text: 'Start '),
                    TextSpan(
                      text: 'Managing',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: '\nYour Tasks Now'),
                  ],
                ),
              ),
              OnboardingShelf(
                scale: scale,
                left: 286,
                top: 514,
                width: 160,
                height: 112,
              ),
              OnboardingBottomPanel(scale: scale),
              Positioned(
                left: scale.x(47),
                top: scale.y(648),
                width: scale.w(298),
                height: scale.h(76),
                child: OnboardingBodyText(
                  scale: scale,
                  children: const [
                    TextSpan(text: 'Ready to make '),
                    TextSpan(
                      text: 'your',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' student life a lot easier?'),
                  ],
                ),
              ),
              OnboardingControls(
                scale: scale,
                pageIndex: 2,
                pageCount: pageCount,
                buttonText: 'Start Now!',
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
