import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/shell.dart';

/// Decides what the app shows: sign-in, PIN unlock, or the shop itself.
///
/// The unlocked user is tracked by id rather than a bool, so signing out and
/// signing back in always asks for the PIN again — a bool would let the next
/// person in behind the same unlocked screen.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _unlockedUserId;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    if (session == null) {
      return const LoginScreen();
    }
    if (_unlockedUserId != session.userId) {
      return PinScreen(
        session: session,
        onUnlocked: () => setState(() => _unlockedUserId = session.userId),
      );
    }
    return const AppShell();
  }
}
