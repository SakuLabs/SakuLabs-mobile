import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/navigation_provider.dart';
import '../widgets/auth/auth_card.dart';
import '../widgets/auth/auth_layout.dart';
import '../widgets/auth/auth_validators.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<AuthProvider>().register(
      name: _nameController.text.trim(),
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

  void _openLogin() {
    context.read<AuthProvider>().clearError();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthFrame(
      child: (context, scale) {
        return Stack(
          children: [
            AuthBackgroundDecor(scale: scale),
            Positioned(
              left: scale.x(38),
              right: scale.x(38),
              top: scale.y(98),
              child: Column(
                children: [
                  Text(
                    'Create an account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale.font(23),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: scale.y(12)),
                  Text(
                    'Enter your email below to create your\naccount',
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
              left: scale.x(128),
              top: scale.y(184),
              width: scale.w(128),
              height: scale.h(106),
              child: Image.asset(
                'assets/img/login_icon.png',
                fit: BoxFit.contain,
                cacheWidth: 256,
              ),
            ),
            Positioned(
              left: scale.x(35),
              top: scale.y(266),
              width: scale.w(305),
              height: scale.h(420),
              child: Form(
                key: _formKey,
                child: AuthCard(
                  scale: scale,
                  children: [
                    AuthInputField(
                      scale: scale,
                      label: 'Name',
                      hint: 'John Doe',
                      controller: _nameController,
                      validator: AuthValidators.name,
                      enabled: !auth.isLoading,
                    ),
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
                    if (auth.error != null) ...[
                      Text(
                        auth.error!,
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
                      text: 'Create account',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    SizedBox(height: scale.y(12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: const Color(0xFF8F8F96),
                            fontSize: scale.font(12),
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isLoading ? null : _openLogin,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign in',
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
