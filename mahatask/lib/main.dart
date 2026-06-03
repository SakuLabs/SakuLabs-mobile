import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/screens/dashboard/dashboard_screen.dart';
import 'package:mahatask/screens/onboarding/welcome_screen.dart';
import 'package:mahatask/services/auth_provider.dart';
import 'package:mahatask/services/navigation_provider.dart';
import 'package:mahatask/services/realtime_service.dart';
import 'package:mahatask/services/theme_provider.dart';
import 'package:mahatask/services/unread_provider.dart';
import 'package:mahatask/theme/app_theme.dart';

void main() {
  runApp(const MahaTaskApp());
}

class MahaTaskApp extends StatelessWidget {
  const MahaTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UnreadProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'MahaTask',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  @override
  Widget build(BuildContext context) {
    final authenticated = context.watch<AuthProvider>().isAuthenticated;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final unread = context.read<UnreadProvider>();
      if (authenticated) {
        unread.start();
        RealtimeService.instance.connect();
      } else {
        unread.stop();
        unread.clear();
        RealtimeService.instance.disconnect();
      }
    });
    return authenticated ? const DashboardScreen() : const WelcomeScreen();
  }
}
