import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_view_model.dart';

/// Decides which screen to show based on auth state:
/// - while the first auth state is loading → a small loader
/// - signed in (or demo mode) → the main app ([MainShell])
/// - otherwise → [LoginScreen]
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.initializing) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (auth.canEnter) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}
