import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_header_bar.dart';

import '../../navigation/presentation/home_screen.dart';
import '../application/auth_provider.dart';
import 'auth_form.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _redirectScheduled = false;

  void _redirectHome(BuildContext context) {
    if (_redirectScheduled) {
      return;
    }
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.isReady && auth.isAuthenticated) {
      _redirectHome(context);
    }

    return Scaffold(
      appBar: const AppHeaderBar(
        title: 'Log in or register',
        icon: Icons.login,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: !auth.isReady
                ? const Center(child: CircularProgressIndicator())
                : auth.error != null
                ? Text(
                    auth.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : AuthForm(
                    onLoginSuccess: () => _redirectHome(context),
                    onSubmit:
                        ({
                          required registering,
                          required name,
                          required email,
                          required password,
                        }) async {
                          final controller = ref.read(authProvider.notifier);
                          if (registering) {
                            await controller.register(
                              name: name,
                              email: email,
                              password: password,
                            );
                          } else {
                            await controller.login(
                              email: email,
                              password: password,
                            );
                          }
                        },
                  ),
          ),
        ),
      ),
    );
  }
}
