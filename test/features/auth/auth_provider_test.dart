import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:post_manager/core/storage/app_database.dart';
import 'package:post_manager/features/auth/application/auth_provider.dart';
import 'package:post_manager/features/auth/data/models/auth_account_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('post-manager-auth-');
    await AppDatabase.initialize(directory: directory.path);
  });

  setUp(() async {
    await AppDatabase.accounts.clear();
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('registers unique salted hashes and rejects duplicate email', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier);

    await expectLater(
      auth.register(name: '', email: 'invalid', password: 'short'),
      throwsStateError,
    );
    await auth.register(
      name: 'Local User',
      email: 'User@example.com',
      password: 'a strong password',
    );
    await expectLater(
      auth.register(
        name: 'Duplicate',
        email: 'user@example.com',
        password: 'another password',
      ),
      throwsStateError,
    );

    final stored = AppDatabase.accounts.get('user@example.com')!;
    expect(stored.passwordHash, isNot('a strong password'));
    expect(stored.salt, isNotEmpty);
    expect(stored.name, 'Local User');
    expect(stored, isA<AuthAccountModel>());
  });

  test('restores a logged-in session from local storage', () async {
    final firstContainer = ProviderContainer();
    final firstAuth = firstContainer.read(authProvider.notifier);
    await firstAuth.register(
      name: 'Persistent User',
      email: 'persistent@example.com',
      password: 'persistent-password',
    );
    await firstAuth.login(
      email: 'persistent@example.com',
      password: 'persistent-password',
    );
    firstContainer.dispose();

    await Hive.close();
    await AppDatabase.initialize(directory: directory.path);

    final restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);
    final ready = Completer<void>();
    final subscription = restoredContainer.listen(authProvider, (_, next) {
      if (next.isReady && !ready.isCompleted) {
        ready.complete();
      }
    }, fireImmediately: true);
    await ready.future;
    subscription.close();

    expect(restoredContainer.read(authProvider).isAuthenticated, isTrue);
    expect(
      restoredContainer.read(authProvider).email,
      'persistent@example.com',
    );
  });

  test('migrates existing SharedPreferences accounts into Hive', () async {
    SharedPreferences.setMockInitialValues({
      'post_manager_accounts': jsonEncode([
        {
          'email': 'legacy@example.com',
          'name': 'Legacy User',
          'salt': 'legacy-salt',
          'passwordHash': 'legacy-hash',
        },
      ]),
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ready = Completer<void>();
    final subscription = container.listen(authProvider, (_, next) {
      if (next.isReady && !ready.isCompleted) {
        ready.complete();
      }
    }, fireImmediately: true);
    await ready.future;
    subscription.close();

    expect(AppDatabase.accounts.get('legacy@example.com')?.name, 'Legacy User');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('post_manager_accounts'), isNull);
  });
}
