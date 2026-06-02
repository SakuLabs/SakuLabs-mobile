import 'package:flutter/material.dart';

import 'onboarding_layout.dart';

enum OnboardingVectorShape { topTeal, topYellow, heroBlob }

class OnboardingVector extends StatelessWidget {
  const OnboardingVector({
    required this.shape,
    required this.color,
    this.elevation = 0,
    super.key,
  });

  final OnboardingVectorShape shape;
  final Color color;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: OnboardingVectorClipper(shape),
      color: color,
      elevation: elevation,
      shadowColor: const Color(0x66000000),
    );
  }
}

class OnboardingHeroImage extends StatelessWidget {
  const OnboardingHeroImage({
    required this.asset,
    required this.shape,
    required this.fit,
    super.key,
  });

  final String asset;
  final OnboardingImageShape shape;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: OnboardingImageClipper(shape),
        child: Image.asset(asset, fit: fit),
      ),
    );
  }
}

class OnboardingBottomPanel extends StatelessWidget {
  const OnboardingBottomPanel({required this.scale, this.top = 600, super.key});

  final FigmaScale scale;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: scale.x(0),
      top: scale.y(top),
      width: scale.w(393),
      height: scale.h(252),
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
    super.key,
  });

  final FigmaScale scale;
  final double left;
  final double top;
  final double width;
  final double height;

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
            topRight: Radius.circular(scale.font(44)),
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

enum OnboardingImageShape { pageOne, circle, blob }

class OnboardingImageClipper extends CustomClipper<Path> {
  const OnboardingImageClipper(this.shape);

  final OnboardingImageShape shape;

  @override
  Path getClip(Size size) {
    return switch (shape) {
      OnboardingImageShape.pageOne => _pageOne(size),
      OnboardingImageShape.circle =>
        Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height)),
      OnboardingImageShape.blob => _blob(size),
    };
  }

  Path _pageOne(Size size) {
    final sx = size.width / 402;
    final sy = size.height / 428;

    Offset p(double x, double y) => Offset(x * sx, y * sy);
    void c(
      Path path,
      double x1,
      double y1,
      double x2,
      double y2,
      double x3,
      double y3,
    ) {
      path.cubicTo(
        p(x1, y1).dx,
        p(x1, y1).dy,
        p(x2, y2).dx,
        p(x2, y2).dy,
        p(x3, y3).dx,
        p(x3, y3).dy,
      );
    }

    final path = Path()..moveTo(p(205, 0).dx, p(205, 0).dy);
    c(path, 272, -2, 330, 21, 378, 68);
    c(path, 420, 109, 400, 171, 398, 222);
    c(path, 399, 295, 346, 304, 330, 351);
    c(path, 303, 431, 166, 438, 86, 392);
    c(path, 7, 347, -16, 249, 13, 181);
    c(path, 41, 114, 103, 124, 152, 89);
    c(path, 190, 62, 166, 8, 205, 0);
    return path..close();
  }

  Path _blob(Size size) {
    return Path()
      ..moveTo(size.width * 0.12, size.height * 0.43)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.20,
        size.width * 0.42,
        size.height * 0.33,
        size.width * 0.53,
        size.height * 0.22,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.03,
        size.width * 0.99,
        size.height * 0.20,
        size.width * 0.90,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.68,
        size.width * 0.99,
        size.height * 0.77,
        size.width * 0.76,
        size.height * 0.89,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 1.05,
        size.width * 0.13,
        size.height * 0.94,
        size.width * 0.08,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.04,
        size.height * 0.56,
        size.width * 0.05,
        size.height * 0.49,
        size.width * 0.12,
        size.height * 0.43,
      )
      ..close();
  }

  @override
  bool shouldReclip(OnboardingImageClipper oldClipper) {
    return oldClipper.shape != shape;
  }
}

class OnboardingVectorClipper extends CustomClipper<Path> {
  const OnboardingVectorClipper(this.shape);

  final OnboardingVectorShape shape;

  @override
  Path getClip(Size size) {
    return switch (shape) {
      OnboardingVectorShape.topTeal => _topTeal(size),
      OnboardingVectorShape.topYellow => _topYellow(size),
      OnboardingVectorShape.heroBlob => _heroBlob(size),
    };
  }

  Path _topTeal(Size size) {
    return Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.82,
        size.width * 0.68,
        size.height * 0.54,
        size.width * 0.42,
        size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.70,
        size.width * 0.14,
        size.height * 0.34,
        size.width * 0.34,
        size.height * 0.18,
      )
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.02,
        size.width * 0.78,
        size.height * 0.18,
        size.width,
        0,
      )
      ..close();
  }

  Path _topYellow(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.50, 0)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.24,
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.52,
        size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.62,
        size.width * 0.46,
        size.height * 0.82,
        0,
        size.height,
      )
      ..close();
  }

  Path _heroBlob(Size size) {
    return Path()
      ..moveTo(size.width * 0.13, size.height * 0.42)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.20,
        size.width * 0.48,
        size.height * 0.31,
        size.width * 0.58,
        size.height * 0.18,
      )
      ..cubicTo(
        size.width * 0.75,
        -size.height * 0.01,
        size.width,
        size.height * 0.17,
        size.width * 0.92,
        size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.66,
        size.width * 1.02,
        size.height * 0.78,
        size.width * 0.76,
        size.height * 0.91,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 1.06,
        size.width * 0.15,
        size.height * 0.92,
        size.width * 0.09,
        size.height * 0.67,
      )
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.55,
        size.width * 0.06,
        size.height * 0.48,
        size.width * 0.13,
        size.height * 0.42,
      )
      ..close();
  }

  @override
  bool shouldReclip(OnboardingVectorClipper oldClipper) {
    return oldClipper.shape != shape;
  }
}
