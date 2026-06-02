import 'package:flutter/material.dart';

class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    required this.child,
    required this.gradient,
    super.key,
  });

  static const Size figmaSize = Size(393, 852);

  final Widget child;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
            child: SizedBox.expand(child: child),
          ),
        );
      },
    );
  }
}

class FigmaFrame extends StatelessWidget {
  const FigmaFrame({required this.builder, super.key});

  final Widget Function(BuildContext context, FigmaScale scale) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = FigmaScale(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        return builder(context, scale);
      },
    );
  }
}

class FigmaScale {
  const FigmaScale({required this.width, required this.height});

  static const Size designSize = Size(393, 852);

  final double width;
  final double height;

  double x(double value) => value * width / designSize.width;

  double y(double value) => value * height / designSize.height;

  double w(double value) => value * width / designSize.width;

  double h(double value) => value * height / designSize.height;

  double font(double value) {
    final sx = width / designSize.width;
    final sy = height / designSize.height;
    return value * ((sx + sy) / 2);
  }
}

class OnboardingGradients {
  const OnboardingGradients._();

  static const pageOne = LinearGradient(
    begin: Alignment(-0.12, 1),
    end: Alignment(0.12, -1),
    colors: [Color(0xFFEFAE36), Color(0xFF4B2CA9)],
    stops: [0.142, 0.8831],
  );

  static const pageTwoThree = LinearGradient(
    begin: Alignment(0.03, 1),
    end: Alignment(-0.03, -1),
    colors: [Color(0xFFEFAE36), Color(0xFF4B2CA9)],
    stops: [0.1581, 0.9125],
  );
}
