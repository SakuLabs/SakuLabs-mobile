import 'package:flutter/material.dart';

class AuthFrame extends StatelessWidget {
  const AuthFrame({required this.child, super.key});

  static const Size designSize = Size(393, 852);

  final Widget Function(BuildContext context, AuthScale scale) child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1A1A1D),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(0.0, designSize.width);
            final height = (width * designSize.height / designSize.width).clamp(
              0.0,
              constraints.maxHeight,
            );

            return SizedBox(
              width: height * designSize.width / designSize.height,
              height: height,
              child: ClipRect(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF6C00C7),
                        Color(0xFFB15D93),
                        Color(0xFFFFB25A),
                      ],
                      stops: [0.0, 0.50, 0.84],
                    ),
                  ),
                  child: FigmaAuthFrame(child: child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FigmaAuthFrame extends StatelessWidget {
  const FigmaAuthFrame({required this.child, super.key});

  final Widget Function(BuildContext context, AuthScale scale) child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return child(
          context,
          AuthScale(width: constraints.maxWidth, height: constraints.maxHeight),
        );
      },
    );
  }
}

class AuthScale {
  const AuthScale({required this.width, required this.height});

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

class AuthBackgroundDecor extends StatelessWidget {
  const AuthBackgroundDecor({required this.scale, super.key});

  final AuthScale scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: scale.x(0),
          bottom: scale.y(0),
          width: scale.w(146),
          height: scale.h(100),
          child: Image.asset(
            'assets/img/login1.png',
            fit: BoxFit.fill,
            cacheWidth: 292,
          ),
        ),
        Positioned(
          left: scale.x(0),
          bottom: scale.y(0),
          width: scale.w(97),
          height: scale.h(107),
          child: Image.asset(
            'assets/img/login2.png',
            fit: BoxFit.fill,
            cacheWidth: 194,
          ),
        ),
        Positioned(
          right: scale.x(-6),
          bottom: scale.y(0),
          width: scale.w(214),
          height: scale.h(173),
          child: Image.asset(
            'assets/img/login_vector.png',
            fit: BoxFit.fill,
            cacheWidth: 428,
          ),
        ),
      ],
    );
  }
}
