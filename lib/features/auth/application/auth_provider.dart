// JSON (jsonEncode, jsonDecode) and converting strings to bytes (utf8.encode).
import 'dart:convert';
// used here for Random.secure() to generate cryptographic-strength random numbers.
import 'dart:math';

// utilizing sha256 for hashing passwords.
import 'package:crypto/crypto.dart';
//Flutter Riverpod state management primitives (NotifierProvider, Notifier).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/auth_account_local_data_source.dart';
import '../data/datasources/auth_session_local_data_source.dart';
import '../data/repositories/local_auth_repository.dart';
import '../domain/entities/auth_account.dart';
import '../domain/repositories/auth_repository.dart';

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final authAccountLocalDataSourceProvider = Provider<AuthAccountLocalDataSource>(
  (ref) => AuthAccountLocalDataSource(),
);

final authSessionLocalDataSourceProvider = Provider<AuthSessionLocalDataSource>(
  (ref) => AuthSessionLocalDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(
    accounts: ref.watch(authAccountLocalDataSourceProvider),
    session: ref.watch(authSessionLocalDataSourceProvider),
  ),
);

class AuthState {
  final bool isReady;
  final String? name;
  final String? email;
  final String? error;

  const AuthState({this.isReady = false, this.name, this.email, this.error});

  bool get isAuthenticated => email != null;
}

class AuthController extends Notifier<AuthState> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final Map<String, AuthAccount> _accounts = {};
  late AuthRepository _repository;
  // A future tracker ensuring async loading operations complete before actions like login or registration run.
  late Future<void> _initialization;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _initialization = _loadAccounts();
    return const AuthState();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _repository.loadAccounts(
        defaultAccount: AuthAccount(
          name: 'Demo User',
          salt: 'post-manager-demo-account-v1',
          passwordHash: _hashPassword(
            'post-manager-demo-account-v1',
            'password123',
          ),
        ),
      );
      _accounts.addAll(accounts);
      final currentEmail = await _repository.getCurrentEmail();
      final account = currentEmail == null ? null : _accounts[currentEmail];
      state = AuthState(
        isReady: true,
        name: account?.name,
        email: account == null ? null : currentEmail,
      );
    } catch (error) {
      state = AuthState(
        isReady: true,
        error: 'Could not load local accounts: $error',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Halts execution until _loadAccounts() completes successfully.
    await _ensureInitialized();
    if (name.trim().isEmpty) {
      throw StateError('Enter your name.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(normalizedEmail)) {
      throw StateError('Enter a valid email address.');
    }
    if (password.length < 6) {
      throw StateError('Use at least 6 characters.');
    }
    if (_accounts.containsKey(normalizedEmail)) {
      throw StateError('An account with this email already exists.');
    }

    final salt = _createSalt();
    _accounts[normalizedEmail] = AuthAccount(
      name: name.trim(),
      salt: salt,
      passwordHash: _hashPassword(salt, password),
    );

    try {
      await _repository.saveAccount(
        normalizedEmail,
        _accounts[normalizedEmail]!,
      );
      state = const AuthState(isReady: true);
    } catch (error) {
      _accounts.remove(normalizedEmail);
      throw StateError('Could not save the account locally: $error');
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _ensureInitialized();
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null ||
        account.passwordHash != _hashPassword(account.salt, password)) {
      throw StateError('Email or password is incorrect.');
    }

    await _repository.saveCurrentEmail(normalizedEmail);
    state = AuthState(
      isReady: true,
      name: account.name,
      email: normalizedEmail,
    );
  }

  Future<void> logout() async {
    await _ensureInitialized();
    await _repository.clearCurrentEmail();
    state = const AuthState(isReady: true);
  }

  Future<void> _ensureInitialized() async {
    await _initialization;
    if (state.error != null) {
      throw StateError(state.error!);
    }
  }

  String _createSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String salt, String password) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }
}
