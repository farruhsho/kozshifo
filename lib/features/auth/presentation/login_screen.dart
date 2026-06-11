import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Pre-filled with the seeded director account for a one-click demo.
  final _email = TextEditingController(text: 'director@kozshifo.uz');
  final _password = TextEditingController(text: 'Director!2026');
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _password.text);
      // Router redirect handles navigation on success.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 48, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text("KO'Z SHIFO",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold, color: scheme.primary)),
                      const SizedBox(height: 4),
                      Text('Медицинская ERP платформа',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Введите email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                            labelText: 'Пароль', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Введите пароль' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: scheme.error)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Войти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
