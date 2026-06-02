import 'package:flutter/material.dart';

import 'auth_layout.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({required this.scale, required this.children, super.key});

  final AuthScale scale;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(scale.font(20)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
            BoxShadow(
              color: Color(0x1AFFFFFF),
              blurRadius: 8,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -scale.x(28),
              top: -scale.y(28),
              width: scale.w(104),
              height: scale.h(104),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB25A).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -scale.x(24),
              bottom: -scale.y(34),
              width: scale.w(118),
              height: scale.h(118),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF22C1B8).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: scale.h(5),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF5D5D),
                      Color(0xFFFFB25A),
                      Color(0xFF22C1B8),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                scale.x(22),
                scale.y(28),
                scale.x(22),
                scale.y(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    required this.scale,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    super.key,
  });

  final AuthScale scale;
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.y(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF111111),
              fontSize: scale.font(14),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: scale.y(8)),
          TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: TextStyle(
              color: const Color(0xFF111111),
              fontSize: scale.font(14),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF8A8A8A),
                fontSize: scale.font(14),
              ),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              contentPadding: EdgeInsets.symmetric(
                horizontal: scale.x(10),
                vertical: scale.y(11),
              ),
              errorStyle: TextStyle(fontSize: scale.font(10), height: 1.1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(scale.font(6)),
                borderSide: const BorderSide(color: Color(0xFF222222)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(scale.font(6)),
                borderSide: const BorderSide(
                  color: Color(0xFFFF5D5D),
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(scale.font(6)),
                borderSide: const BorderSide(color: Color(0xFFFF5D5D)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(scale.font(6)),
                borderSide: const BorderSide(
                  color: Color(0xFFFF5D5D),
                  width: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.scale,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final AuthScale scale;
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: scale.h(36),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5D5D),
          disabledBackgroundColor: const Color(0xFFFF9A9A),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(scale.font(7)),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: scale.w(18),
                height: scale.h(18),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(13),
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
