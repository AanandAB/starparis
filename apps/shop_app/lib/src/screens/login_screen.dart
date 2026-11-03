import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../auth/auth_repository.dart';
import '../providers.dart';

/// Sign-in. Online only, once per device — after that the PIN unlocks the app
/// with no connection at all.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phone = TextEditingController(
    text: '+97150000000',
  );
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = await bootstrap.auth.login(
        phone: _phone.text.trim(),
        password: _password.text,
        deviceName: 'Counter PC',
      );
      await bootstrap.startSync();
      ref.read(sessionProvider.notifier).signedIn(session);
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'Could not sign in: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(StarSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: StarColors.petrol,
                      borderRadius: BorderRadius.circular(StarRadius.card),
                    ),
                    child: const Icon(
                      Icons.local_print_shop_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: StarSpace.lg),
                Text('Star Paris', style: theme.textTheme.headlineSmall),
                const SizedBox(height: StarSpace.xs),
                Text(
                  'Sign in once on this device. After that, the shop works offline.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: StarSpace.xl),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const <String>[AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: StarSpace.md),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _busy ? null : _signIn(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: StarSpace.md),
                  Container(
                    padding: const EdgeInsets.all(StarSpace.md),
                    decoration: BoxDecoration(
                      color: StarColors.statusProblem.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(StarRadius.field),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          color: StarColors.statusProblem,
                          size: 18,
                        ),
                        const SizedBox(width: StarSpace.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: StarColors.statusProblem,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: StarSpace.lg),
                FilledButton(
                  onPressed: _busy ? null : _signIn,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
