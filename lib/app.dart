import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/login_page.dart';
import 'views/auth/new_password_page.dart';
import 'views/home/home_page.dart';

class JulidlineApp extends StatelessWidget {
  const JulidlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Julidline',
      theme: AppTheme.theme,
      home: const _AuthGate(),
    );
  }
}

/// Menentukan halaman awal berdasarkan status autentikasi Supabase.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // User baru saja membuka link reset password dari email.
    if (auth.recoveryMode) return const NewPasswordPage();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const HomePage();
      case AuthStatus.unauthenticated:
        return const LoginPage();
    }
  }
}
