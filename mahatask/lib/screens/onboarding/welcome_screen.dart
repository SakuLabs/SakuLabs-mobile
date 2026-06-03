import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/services/auth_provider.dart';
import 'package:mahatask/widgets/onboarding/onboarding_playful_effects.dart';
import 'package:mahatask/screens/auth/login_screen.dart';
import 'package:mahatask/screens/auth/register_screen.dart';
import 'package:mahatask/screens/onboarding/landing_page_one_screen.dart';
import 'package:mahatask/screens/onboarding/landing_page_three_screen.dart';
import 'package:mahatask/screens/onboarding/landing_page_two_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const int _pageCount = 3;

  final PageController _controller = PageController();
  int _page = 0;
  int _burstTrigger = 0;
  bool _scrollLocked = false;
  bool _assetsCached = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsCached) return;
    _assetsCached = true;
    for (final asset in _precacheAssets.entries) {
      precacheImage(
        ResizeImage(AssetImage(asset.key), width: asset.value),
        context,
      );
    }
  }

  static const Map<String, int> _precacheAssets = {
    'assets/img/LandingPage1_1.png': 380,
    'assets/img/LandingPage1_2.png': 298,
    'assets/img/LandingPage1_icon.png': 786,
    'assets/img/LandingPage2_1.png': 422,
    'assets/img/LandingPage2_icon.png': 684,
    'assets/img/LandingPage3_1.png': 442,
    'assets/img/LandingPage3_2.png': 228,
    'assets/img/LandingPage3_icon.png': 602,
  };

  void _goNext() {
    HapticFeedback.lightImpact();
    _triggerBurst();
    Future<void>.delayed(const Duration(milliseconds: 70), () {
      if (!mounted) return;

      if (_page == _pageCount - 1) {
        _openRegister();
        return;
      }

      _snapTo(_page + 1);
    });
  }

  void _snapTo(int page) {
    final target = page.clamp(0, _pageCount - 1);
    if (target == _page || !_controller.hasClients) return;

    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 430),
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
      if (!mounted) return;
      _scrollLocked = false;
    });
  }

  void _triggerBurst() {
    setState(() => _burstTrigger++);
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
      body: Stack(
        children: [
          Listener(
            onPointerSignal: _handlePointerSignal,
            child: PageView.builder(
              controller: _controller,
              physics: const PageScrollPhysics(),
              pageSnapping: true,
              onPageChanged: (index) {
                setState(() => _page = index);
              },
              itemCount: _pageCount,
              itemBuilder: (context, index) => _buildPage(index),
            ),
          ),
          Positioned.fill(
            child: OnboardingBurstOverlay(trigger: _burstTrigger),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final page = switch (index) {
      0 => LandingPageOneScreen(
        pageCount: _pageCount,
        onNext: _goNext,
        onSkip: _openLogin,
      ),
      1 => LandingPageTwoScreen(
        pageCount: _pageCount,
        onNext: _goNext,
        onSkip: _openLogin,
      ),
      _ => LandingPageThreeScreen(
        pageCount: _pageCount,
        onNext: _goNext,
        onSkip: _openLogin,
      ),
    };
    return RepaintBoundary(child: page);
  }
}

