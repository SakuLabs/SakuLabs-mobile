import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/services/auth_provider.dart';
import 'package:mahatask/services/navigation_provider.dart';
import 'package:mahatask/widgets/auth/auth_card.dart';
import 'package:mahatask/widgets/auth/auth_layout.dart';
import 'package:mahatask/widgets/auth/auth_validators.dart';
import 'package:mahatask/screens/dashboard/dashboard_screen.dart';
import 'package:mahatask/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<AuthProvider>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted || !ok) return;

    context.read<NavigationProvider>().setIndex(0);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  void _openRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasError = auth.error != null;

    return AuthFrame(
      child: (context, scale) {
        return Stack(
          children: [
            AuthBackgroundDecor(scale: scale),
            Positioned(
              left: scale.x(38),
              right: scale.x(38),
              top: scale.y(78),
              child: Column(
                children: [
                  Text(
                    'Welcome back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale.font(23),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: scale.y(14)),
                  Text(
                    'Enter your email to sign in to your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale.font(15),
                      height: 1.14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: scale.x(136),
              top: scale.y(183),
              width: scale.w(128),
              height: scale.h(98),
              child: Image.asset(
                'assets/img/login_icon.png',
                fit: BoxFit.contain,
                cacheWidth: 256,
              ),
            ),
            Positioned(
              left: scale.x(32),
              top: scale.y(hasError ? 224 : 255),
              width: scale.w(305),
              height: scale.h(hasError ? 430 : 340),
              child: Form(
                key: _formKey,
                child: AuthCard(
                  scale: scale,
                  children: [
                    AuthInputField(
                      scale: scale,
                      label: 'Email',
                      hint: 'name@example.com',
                      controller: _emailController,
                      validator: AuthValidators.email,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !auth.isLoading,
                    ),
                    AuthInputField(
                      scale: scale,
                      label: 'Password',
                      hint: '',
                      controller: _passwordController,
                      validator: AuthValidators.password,
                      obscureText: true,
                      enabled: !auth.isLoading,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 0, bottom: scale.y(26)),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: const Color(0xFF8F8F96),
                            fontSize: scale.font(11),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (auth.error != null) ...[
                      Text(
                        auth.error!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFFF5D5D),
                          fontSize: scale.font(11),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: scale.y(8)),
                    ],
                    AuthPrimaryButton(
                      scale: scale,
                      text: 'Sign In',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    SizedBox(height: scale.y(13)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: const Color(0xFF8F8F96),
                            fontSize: scale.font(12),
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isLoading ? null : _openRegister,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: scale.font(12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

