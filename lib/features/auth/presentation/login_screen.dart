import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/ui_prefs.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _remember = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillRememberedEmail();
  }

  /// Restores the last remembered email (if «Запомнить логин» was on) and
  /// jumps the cursor straight to the password — one field away from working.
  Future<void> _prefillRememberedEmail() async {
    final saved = await ref.read(uiPrefsProvider).readRememberedEmail();
    if (!mounted || saved == null || saved.isEmpty) return;
    if (_email.text.isNotEmpty) return; // user already started typing
    setState(() => _email.text = saved);
    _passwordFocus.requestFocus();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    // Captured before any await: on success the router disposes this screen.
    final prefs = ref.read(uiPrefsProvider);
    final auth = ref.read(authControllerProvider.notifier);
    final email = _email.text.trim();
    try {
      await auth.login(email, _password.text);
      // Persist (or clear) the remembered email only after a successful login.
      await prefs.writeRememberedEmail(_remember ? email : null);
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
                        focusNode: _emailFocus,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: const InputDecoration(
                            labelText: 'Email', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Введите email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Показать пароль' : 'Скрыть пароль',
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Введите пароль' : null,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _remember,
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _remember = v ?? true),
                        title: const Text('Запомнить логин'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: scheme.error)),
                      ],
                      const SizedBox(height: 16),
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
