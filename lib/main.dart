import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/application/theme_provider.dart';
import 'core/presentation/mobile_intro_loader.dart';
import 'core/routing/app_router.dart';
import 'features/auth/application/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router = createAppRouter(
    readAuthState: () => ref.read(authProvider),
  );
  late final ProviderSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual(authProvider, (previous, next) {
      _router.refresh();
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Post Manager',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: _router,
      builder: (context, child) =>
          MobileIntroLoader(child: child ?? const SizedBox.shrink()),
    );
  }

  @override
  void dispose() {
    _authSubscription.close();
    _router.dispose();
    super.dispose();
  }
}
