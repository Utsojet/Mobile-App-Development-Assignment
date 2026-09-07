import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';
import 'login_screen.dart';

/// The root gatekeeper widget that routes to either [MainShell]
/// (if authenticated or in guest mode) or [LoginScreen] (if signed out).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // If user is authenticated (including anonymous guest), show MainShell
    if (authProvider.isAuthenticated) {
      return const MainShell();
    }

    // Otherwise show the login flow
    return const LoginScreen();
  }
}
