import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../auth/auth_repository.dart';
import '../auth/session.dart';
import '../providers.dart';

/// Offline unlock.
///
/// On a fresh device the first sign-in also sets the PIN. After that the PIN is
/// checked entirely locally: no network, no server round trip, and a lockout
/// that grows with each wrong attempt.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({required this.session, required this.onUnlocked, super.key});

  final Session session;
  final VoidCallback onUnlocked;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final TextEditingController _pin = TextEditingController();
  bool? _creating;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPin = await ref.read(bootstrapProvider).auth.hasPin();
      if (mounted) setState(() => _creating = !hasPin);
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pin.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'The PIN is at least 4 digits.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = ref.read(bootstrapProvider).auth;
    if (_creating ?? false) {
      await auth.setPin(pin);
      if (mounted) widget.onUnlocked();
      return;
    }

    final result = await auth.checkPin(pin);
    if (!mounted) return;
    switch (result) {
      case PinCheck.ok:
        widget.onUnlocked();
      case PinCheck.locked:
        setState(
          () => _error = 'Too many attempts. Wait a minute and try again.',
        );
      case PinCheck.wrong:
        final failures = await auth.pinFailures();
        if (mounted) {
          setState(
            () => _error = 'That PIN is not right. Attempt $failures of 5.',
          );
        }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creating = _creating ?? false;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(StarSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: StarSpace.md),
                Text(
                  creating
                      ? 'Choose a PIN'
                      : 'Welcome back, ${widget.session.name}',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StarSpace.xs),
                Text(
                  creating
                      ? 'Four to six digits. This unlocks the app with no internet.'
                      : 'Enter your PIN to open the shop.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StarSpace.xl),
                TextField(
                  controller: _pin,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 12,
                  ),
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••',
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: StarSpace.sm),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: StarColors.statusProblem,
                    ),
                  ),
                ],
                const SizedBox(height: StarSpace.lg),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(creating ? 'Set PIN' : 'Unlock'),
                ),
                const SizedBox(height: StarSpace.sm),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => ref.read(sessionProvider.notifier).signOut(),
                  child: const Text('Sign out instead'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
