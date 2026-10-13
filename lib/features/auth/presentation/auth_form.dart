import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final Future<void> Function({
    required bool registering,
    required String name,
    required String email,
    required String password,
  })
  onSubmit;
  final VoidCallback onLoginSuccess;

  const AuthForm({
    super.key,
    required this.onSubmit,
    required this.onLoginSuccess,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  bool _hasRegistered = false;
  String? _error;

  bool get _isValid {
    final nameIsValid =
        !_isRegistering || _nameController.text.trim().isNotEmpty;
    final email = _emailController.text.trim();
    final emailIsValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    final passwordIsValid = _passwordController.text.length >= 6;
    return nameIsValid && emailIsValid && passwordIsValid;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {
      _error = null;
      _hasRegistered = false;
    });
  }

  Future<void> _submit() async {
    if (!_isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        registering: _isRegistering,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      if (_isRegistering) {
        setState(() {
          _isRegistering = false;
          _hasRegistered = true;
          _isSubmitting = false;
          _formKey = GlobalKey<FormState>();
          _passwordController.clear();
        });
      } else {
        widget.onLoginSuccess();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isRegistering ? 'Join Post Manager' : 'Welcome back',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _isRegistering
                ? 'Create an account to manage posts.'
                : 'Log in to create, edit, and delete posts.',
          ),
          const SizedBox(height: 24),
          if (_isRegistering) ...[
            TextFormField(
              key: const ValueKey('auth-name'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: _onChanged,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const ValueKey('auth-email'),
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: _onChanged,
            validator: (value) {
              if (value == null ||
                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('auth-password'),
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onChanged: _onChanged,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) => value == null || value.length < 6
                ? 'Use at least 6 characters'
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_hasRegistered) ...[
            const SizedBox(height: 12),
            const Text('Account created. Log in to continue.'),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('auth-submit'),
            onPressed: _isValid && !_isSubmitting ? _submit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isRegistering ? 'Register' : 'Log in'),
          ),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => setState(() {
                    _isRegistering = !_isRegistering;
                    _error = null;
                    _hasRegistered = false;
                    _formKey = GlobalKey<FormState>();
                  }),
            child: Text(
              _isRegistering
                  ? 'Already have an account? Log in'
                  : 'New here? Create an account',
            ),
          ),
          if (!_isRegistering) ...[
            const SizedBox(height: 8),
            Text(
              'Demo account: demo@example.com / password123',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
