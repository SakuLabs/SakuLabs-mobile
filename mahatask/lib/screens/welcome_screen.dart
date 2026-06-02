import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _scrollLocked = false;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      image: 'assets/img/LandingPage1.png',
      eyebrow: '',
      titlePrefix: 'Master Your Academic\nJourney ',
      titleBold: 'with Ease',
      bodyPrefix: 'Stop juggling multiple apps. ',
      bodyBold: 'MahaTask',
      bodySuffix:
          ' combines task management, smart scheduling, and study groups into one cohesive platform tailored for students.',
      imageShape: _ImageShape.arch,
      accent: Color(0xFF5B35C7),
    ),
    _OnboardingPage(
      image: 'assets/img/LandingPage2.png',
      eyebrow: 'Track ',
      titlePrefix: 'All of Your\nWork ',
      titleBold: 'On Your\nScreen',
      bodyPrefix:
          'Track all of your assignments and study progress anywhere, making organizing work a lot easier',
      bodyBold: '',
      bodySuffix: '',
      imageShape: _ImageShape.circle,
      accent: Color(0xFF24BFB4),
    ),
    _OnboardingPage(
      image: 'assets/img/LandingPage3.png',
      eyebrow: '',
      titlePrefix: 'Start ',
      titleBold: 'Managing',
      titleSuffix: '\nYour Tasks Now',
      bodyPrefix: 'Ready to make ',
      bodyBold: 'your',
      bodySuffix: ' student life a lot easier?',
      imageShape: _ImageShape.blob,
      accent: Color(0xFFFFD765),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_page == _pages.length - 1) {
      _openRegister();
      return;
    }

    _snapTo(_page + 1);
  }

  void _snapTo(int page) {
    final target = page.clamp(0, _pages.length - 1);
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _scrollLocked) return;

    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta.abs() < 10) return;

    _scrollLocked = true;
    _snapTo(delta > 0 ? _page + 1 : _page - 1);
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      _scrollLocked = false;
    });
  }

  void _openRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _openLogin() {
    context.read<AuthProvider>().clearError();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: PageView.builder(
              controller: _controller,
              physics: const PageScrollPhysics(),
              pageSnapping: true,
              onPageChanged: (index) => setState(() => _page = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _OnboardingSlide(
                  page: _pages[index],
                  pageIndex: index,
                  controller: _controller,
                  pageCount: _pages.length,
                  onNext: _goNext,
                  onSkip: _openLogin,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.page,
    required this.pageIndex,
    required this.controller,
    required this.pageCount,
    required this.onNext,
    required this.onSkip,
  });

  final _OnboardingPage page;
  final int pageIndex;
  final PageController controller;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLast = pageIndex == pageCount - 1;

    if (pageIndex == 0) {
      return _LandingPageOne(
        page: page,
        controller: controller,
        pageCount: pageCount,
        onNext: onNext,
        onSkip: onSkip,
      );
    }

    return Container(
      color: const Color(0xFF26156B),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomHeight = (constraints.maxHeight * 0.40).clamp(
              260.0,
              305.0,
            );
            final imageSize = (constraints.maxWidth * 0.72).clamp(235.0, 310.0);

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LandingBackgroundPainter(pageIndex: pageIndex),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomHeight,
                  child: Container(color: const Color(0xFF2788A5)),
                ),
                Positioned(
                  left: -22,
                  right: -22,
                  bottom: bottomHeight - 55,
                  height: 88,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF77AFC0),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _HeroImage(
                              page: page,
                              size: imageSize,
                              pageIndex: pageIndex,
                            ),
                            Positioned(
                              left: pageIndex == 1 ? 0 : null,
                              right: pageIndex == 0 ? 6 : null,
                              bottom: pageIndex == 2 ? 42 : 22,
                              child: _TitleBlock(
                                page: page,
                                alignLeft: pageIndex == 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: bottomHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: _BodyText(page: page),
                            ),
                            const SizedBox(height: 28),
                            _PrimaryButton(
                              text: isLast ? 'Start Now!' : 'Next',
                              onPressed: onNext,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                pageCount,
                                (index) => _PageDot(active: index == pageIndex),
                              ),
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: onSkip,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  minimumSize: const Size(48, 32),
                                  textStyle: const TextStyle(fontSize: 11),
                                ),
                                child: const Text('Skip'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.page,
    required this.size,
    required this.pageIndex,
  });

  final _OnboardingPage page;
  final double size;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      page.image,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    return Transform.translate(
      offset: Offset(
        pageIndex == 1
            ? 56
            : pageIndex == 2
            ? 44
            : -8,
        pageIndex == 1
            ? 8
            : pageIndex == 2
            ? -12
            : -36,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: ClipPath(
            clipper: _ImageClipper(page.imageShape),
            child: image,
          ),
        ),
      ),
    );
  }
}

class _LandingPageOne extends StatelessWidget {
  const _LandingPageOne({
    required this.page,
    required this.controller,
    required this.pageCount,
    required this.onNext,
    required this.onSkip,
  });

  static const Size _figmaSize = Size(393, 852);

  final _OnboardingPage page;
  final PageController controller;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sx = constraints.maxWidth / _figmaSize.width;
        final sy = constraints.maxHeight / _figmaSize.height;

        double x(double value) => value * sx;
        double y(double value) => value * sy;
        double w(double value) => value * sx;
        double h(double value) => value * sy;
        double s(double value) => value * ((sx + sy) / 2);

        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.12, 1),
                      end: Alignment(0.12, -1),
                      colors: [Color(0xFFEFAE36), Color(0xFF4B2CA9)],
                      stops: [0.142, 0.8831],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x(245),
                top: y(60),
                width: w(334.52),
                height: h(229.15),
                child: Transform.rotate(
                  angle: 84.53 * 3.141592653589793 / 180,
                  child: PhysicalShape(
                    clipper: const _LandingOneVectorClipper(
                      _LandingOneVectorKind.blue,
                    ),
                    color: const Color(0xFF6087D0),
                    elevation: 4,
                    shadowColor: const Color(0x66000000),
                  ),
                ),
              ),
              Positioned(
                left: x(0),
                top: y(-13),
                width: w(402),
                height: h(428),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 7.8,
                        offset: Offset(2, 13),
                      ),
                    ],
                  ),
                  child: ClipPath(
                    clipper: const _LandingOneImageClipper(),
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxWidth: w(450.43),
                      maxHeight: h(449.06),
                      child: Transform.translate(
                        offset: Offset(x(-5.65), y(-26.91)),
                        child: Image.asset(
                          page.image,
                          width: w(450.43),
                          height: h(449.06),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x(-43),
                top: y(403),
                width: w(254.14),
                height: h(175.82),
                child: Transform.rotate(
                  angle: -111 * 3.141592653589793 / 180,
                  child: PhysicalShape(
                    clipper: const _LandingOneVectorClipper(
                      _LandingOneVectorKind.deep,
                    ),
                    color: const Color(0xFF2E1C63),
                    elevation: 5,
                    shadowColor: const Color(0x66000000),
                  ),
                ),
              ),
              Positioned(
                left: x(-14),
                top: y(524),
                width: w(240),
                height: h(179),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6DA2B5),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(s(44)),
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
              ),
              Positioned(
                left: x(0),
                top: y(600),
                width: w(393),
                height: h(252),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF227C9D),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(s(72)),
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
              ),
              Positioned(
                left: x(125),
                top: y(440),
                width: w(289),
                height: h(74),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: s(24),
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
                    children: const [
                      TextSpan(text: 'Master Your Academic\nJourney '),
                      TextSpan(
                        text: 'with Ease',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: x(47),
                top: y(650),
                width: w(298),
                height: h(96),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: s(16),
                      height: 19 / 16,
                      fontWeight: FontWeight.w400,
                    ),
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
              ),
              Positioned(
                left: x(145),
                top: y(760),
                width: w(102),
                height: h(36),
                child: _FigmaNextButton(
                  scale: (sx + sy) / 2,
                  onPressed: onNext,
                ),
              ),
              Positioned(
                left: x(172),
                top: y(809),
                width: w(49),
                height: h(7),
                child: _FigmaPageDots(pageCount: pageCount),
              ),
              Positioned(
                left: x(320),
                top: y(802),
                width: w(60),
                height: h(28),
                child: TextButton(
                  onPressed: onSkip,
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
                      fontSize: s(12),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FigmaNextButton extends StatelessWidget {
  const _FigmaNextButton({required this.scale, required this.onPressed});

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFFF5D5D),
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(35 * scale),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35 * scale),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Next',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 * scale,
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
    );
  }
}

class _FigmaPageDots extends StatelessWidget {
  const _FigmaPageDots({required this.pageCount});

  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        pageCount,
        (index) => Container(
          width: index == 0 ? 20 : 9.3,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.page, required this.alignLeft});

  final _OnboardingPage page;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: alignLeft ? 190 : 245,
      child: RichText(
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.18,
            fontWeight: FontWeight.w300,
          ),
          children: [
            if (page.eyebrow.isNotEmpty) TextSpan(text: page.eyebrow),
            TextSpan(text: page.titlePrefix),
            TextSpan(
              text: page.titleBold,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (page.titleSuffix.isNotEmpty) TextSpan(text: page.titleSuffix),
          ],
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          height: 1.16,
          fontWeight: FontWeight.w400,
        ),
        children: [
          TextSpan(text: page.bodyPrefix),
          if (page.bodyBold.isNotEmpty)
            TextSpan(
              text: page.bodyBold,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          TextSpan(text: page.bodySuffix),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF5E64),
        foregroundColor: Colors.white,
        minimumSize: const Size(82, 38),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 5,
        shadowColor: const Color(0x66000000),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: Text(text),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 11 : 8,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _LandingBackgroundPainter extends CustomPainter {
  const _LandingBackgroundPainter({required this.pageIndex});

  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final purple = Paint()..color = const Color(0xFF4E2ABA);
    final teal = Paint()..color = const Color(0xFF26BFB6);
    final yellow = Paint()..color = const Color(0xFFFFD765);
    final tan = Paint()..color = const Color(0xFFC08B5F);
    final deep = Paint()..color = const Color(0xFF1E145D);

    canvas.drawRect(Offset.zero & size, purple);

    final tanPath = Path()
      ..moveTo(0, size.height * 0.48)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.38,
        size.width * 0.20,
        size.height * 0.68,
        size.width * 0.34,
        size.height * 0.59,
      )
      ..cubicTo(
        size.width * 0.52,
        size.height * 0.47,
        size.width * 0.72,
        size.height * 0.54,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, size.height * 0.79)
      ..lineTo(0, size.height * 0.79)
      ..close();
    canvas.drawPath(tanPath, tan);

    if (pageIndex == 0) {
      canvas.drawOval(
        Rect.fromLTWH(size.width * 0.73, size.height * 0.16, 150, 210),
        Paint()..color = const Color(0xFF6B93D8),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, size.height * 0.53)
          ..cubicTo(
            25,
            size.height * 0.47,
            24,
            size.height * 0.62,
            46,
            size.height * 0.54,
          )
          ..cubicTo(
            72,
            size.height * 0.43,
            76,
            size.height * 0.73,
            116,
            size.height * 0.60,
          )
          ..lineTo(0, size.height * 0.67)
          ..close(),
        deep,
      );
    } else if (pageIndex == 1) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height * 0.48)
          ..cubicTo(
            size.width * 0.82,
            size.height * 0.40,
            size.width * 0.76,
            size.height * 0.25,
            size.width * 0.62,
            size.height * 0.34,
          )
          ..cubicTo(
            size.width * 0.52,
            size.height * 0.40,
            size.width * 0.52,
            size.height * 0.13,
            size.width * 0.70,
            size.height * 0.10,
          )
          ..cubicTo(
            size.width * 0.86,
            size.height * 0.06,
            size.width * 0.82,
            size.height * 0.24,
            size.width,
            0,
          )
          ..close(),
        teal,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width * 0.25, 0)
          ..cubicTo(
            size.width * 0.36,
            size.height * 0.12,
            size.width * 0.11,
            size.height * 0.19,
            size.width * 0.29,
            size.height * 0.28,
          )
          ..cubicTo(
            size.width * 0.46,
            size.height * 0.37,
            size.width * 0.30,
            size.height * 0.46,
            0,
            size.height * 0.47,
          )
          ..close(),
        yellow,
      );
      canvas.drawPath(
        Path()
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height * 0.22)
          ..cubicTo(
            size.width * 0.84,
            size.height * 0.24,
            size.width * 0.78,
            size.height * 0.17,
            size.width * 0.93,
            size.height * 0.12,
          )
          ..cubicTo(
            size.width * 0.72,
            size.height * 0.13,
            size.width * 0.78,
            0,
            size.width * 0.87,
            0,
          )
          ..close(),
        teal,
      );
    }
  }

  @override
  bool shouldRepaint(_LandingBackgroundPainter oldDelegate) {
    return oldDelegate.pageIndex != pageIndex;
  }
}

class _ImageClipper extends CustomClipper<Path> {
  const _ImageClipper(this.shape);

  final _ImageShape shape;

  @override
  Path getClip(Size size) {
    switch (shape) {
      case _ImageShape.arch:
        return Path()
          ..moveTo(size.width * 0.10, size.height * 0.45)
          ..cubicTo(
            size.width * 0.12,
            size.height * 0.13,
            size.width * 0.36,
            0,
            size.width * 0.60,
            0,
          )
          ..cubicTo(
            size.width * 0.86,
            size.height * 0.02,
            size.width * 0.99,
            size.height * 0.28,
            size.width * 0.93,
            size.height * 0.54,
          )
          ..cubicTo(
            size.width * 1.03,
            size.height * 0.80,
            size.width * 0.78,
            size.height,
            size.width * 0.46,
            size.height * 0.96,
          )
          ..cubicTo(
            size.width * 0.11,
            size.height * 0.92,
            0,
            size.height * 0.70,
            size.width * 0.10,
            size.height * 0.45,
          )
          ..close();
      case _ImageShape.circle:
        return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
      case _ImageShape.blob:
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
  }

  @override
  bool shouldReclip(_ImageClipper oldClipper) => oldClipper.shape != shape;
}

class _LandingOneVectorClipper extends CustomClipper<Path> {
  const _LandingOneVectorClipper(this.kind);

  final _LandingOneVectorKind kind;

  @override
  Path getClip(Size size) {
    return switch (kind) {
      _LandingOneVectorKind.blue => _bluePath(size),
      _LandingOneVectorKind.deep => _deepPath(size),
    };
  }

  Path _bluePath(Size size) {
    return Path()
      ..moveTo(size.width * 0.10, size.height * 0.48)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.16,
        size.width * 0.48,
        -size.height * 0.05,
        size.width * 0.75,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 1.05,
        size.height * 0.27,
        size.width * 1.06,
        size.height * 0.72,
        size.width * 0.76,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.49,
        size.height * 1.03,
        size.width * 0.28,
        size.height * 0.82,
        size.width * 0.14,
        size.height * 0.64,
      )
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.55,
        size.width * 0.04,
        size.height * 0.53,
        size.width * 0.10,
        size.height * 0.48,
      )
      ..close();
  }

  Path _deepPath(Size size) {
    return Path()
      ..moveTo(size.width * 0.08, size.height * 0.48)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.18,
        size.width * 0.45,
        -size.height * 0.10,
        size.width * 0.68,
        size.height * 0.11,
      )
      ..cubicTo(
        size.width * 0.90,
        size.height * 0.31,
        size.width * 0.97,
        size.height * 0.62,
        size.width * 0.83,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.69,
        size.height * 1.07,
        size.width * 0.36,
        size.height * 0.99,
        size.width * 0.18,
        size.height * 0.82,
      )
      ..cubicTo(
        -size.width * 0.04,
        size.height * 0.61,
        size.width * 0.02,
        size.height * 0.56,
        size.width * 0.08,
        size.height * 0.48,
      )
      ..close();
  }

  @override
  bool shouldReclip(_LandingOneVectorClipper oldClipper) {
    return oldClipper.kind != kind;
  }
}

class _LandingOneImageClipper extends CustomClipper<Path> {
  const _LandingOneImageClipper();

  @override
  Path getClip(Size size) {
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

  @override
  bool shouldReclip(_LandingOneImageClipper oldClipper) => false;
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.image,
    required this.eyebrow,
    required this.titlePrefix,
    required this.titleBold,
    required this.bodyPrefix,
    required this.bodyBold,
    required this.bodySuffix,
    required this.imageShape,
    required this.accent,
    this.titleSuffix = '',
  });

  final String image;
  final String eyebrow;
  final String titlePrefix;
  final String titleBold;
  final String titleSuffix;
  final String bodyPrefix;
  final String bodyBold;
  final String bodySuffix;
  final _ImageShape imageShape;
  final Color accent;
}

enum _ImageShape { arch, circle, blob }

enum _LandingOneVectorKind { blue, deep }
