import '../../domain/entities/auth_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_account_local_data_source.dart';
import '../datasources/auth_session_local_data_source.dart';
import '../models/auth_account_model.dart';

class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository({required this._accounts, required this._session});

  final AuthAccountLocalDataSource _accounts;
  final AuthSessionLocalDataSource _session;

  @override
  Future<Map<String, AuthAccount>> loadAccounts({
    required AuthAccount defaultAccount,
  }) async {
    var storedAccounts = await _accounts.getAccounts();
    if (storedAccounts.isEmpty) {
      await saveAccount('demo@example.com', defaultAccount);
      storedAccounts = await _accounts.getAccounts();
    }
    return {
      for (final entry in storedAccounts.entries)
        entry.key: AuthAccount(
          name: entry.value.name,
          salt: entry.value.salt,
          passwordHash: entry.value.passwordHash,
        ),
    };
  }

  @override
  Future<void> saveAccount(String email, AuthAccount account) =>
      _accounts.saveAccount(
        email,
        AuthAccountModel(
          name: account.name,
          salt: account.salt,
          passwordHash: account.passwordHash,
        ),
      );

  @override
  Future<String?> getCurrentEmail() => _session.getCurrentEmail();

  @override
  Future<void> saveCurrentEmail(String email) =>
      _session.saveCurrentEmail(email);

  @override
  Future<void> clearCurrentEmail() => _session.clearCurrentEmail();
}
