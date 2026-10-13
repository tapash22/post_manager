import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
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
  static const _accountsKey = 'post_manager_accounts';
  static const _currentEmailKey = 'post_manager_current_email';

  final Map<String, _LocalAccount> _accounts = {};
  late Future<void> _initialization;

  @override
  AuthState build() {
    _initialization = _loadAccounts();
    return const AuthState();
  }

  Future<void> _loadAccounts() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedAccounts = preferences.getString(_accountsKey);

      if (storedAccounts == null) {
        _accounts['demo@example.com'] = _LocalAccount(
          name: 'Demo User',
          salt: 'post-manager-demo-account-v1',
          passwordHash: _hashPassword(
            'post-manager-demo-account-v1',
            'password123',
          ),
        );
        await _saveAccounts(preferences);
      } else {
        final decoded = jsonDecode(storedAccounts);
        if (decoded is! List<dynamic>) {
          throw const FormatException('Stored accounts must be a list.');
        }
        for (final item in decoded) {
          if (item is! Map<String, dynamic> ||
              item['email'] is! String ||
              item['name'] is! String ||
              item['salt'] is! String ||
              item['passwordHash'] is! String) {
            throw const FormatException('Stored account data is invalid.');
          }
          _accounts[item['email'] as String] = _LocalAccount(
            name: item['name'] as String,
            salt: item['salt'] as String,
            passwordHash: item['passwordHash'] as String,
          );
        }
      }

      final currentEmail = preferences.getString(_currentEmailKey);
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
    await _ensureInitialized();
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      throw StateError('An account with this email already exists.');
    }

    final salt = _createSalt();
    _accounts[normalizedEmail] = _LocalAccount(
      name: name.trim(),
      salt: salt,
      passwordHash: _hashPassword(salt, password),
    );

    try {
      final preferences = await SharedPreferences.getInstance();
      await _saveAccounts(preferences);
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

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _currentEmailKey,
      normalizedEmail,
    );
    if (!saved) {
      throw StateError('Could not save the local login session.');
    }
    state = AuthState(
      isReady: true,
      name: account.name,
      email: normalizedEmail,
    );
  }

  Future<void> logout() async {
    await _ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_currentEmailKey);
    if (!removed) {
      throw StateError('Could not clear the local login session.');
    }
    state = const AuthState(isReady: true);
  }

  Future<void> _ensureInitialized() async {
    await _initialization;
    if (state.error != null) {
      throw StateError(state.error!);
    }
  }

  Future<void> _saveAccounts(SharedPreferences preferences) {
    final accounts = [
      for (final entry in _accounts.entries)
        {
          'email': entry.key,
          'name': entry.value.name,
          'salt': entry.value.salt,
          'passwordHash': entry.value.passwordHash,
        },
    ];
    return preferences.setString(_accountsKey, jsonEncode(accounts)).then((
      saved,
    ) {
      if (!saved) {
        throw StateError('The local account data could not be saved.');
      }
    });
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

class _LocalAccount {
  final String name;
  final String salt;
  final String passwordHash;

  const _LocalAccount({
    required this.name,
    required this.salt,
    required this.passwordHash,
  });
}
