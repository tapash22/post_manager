import '../entities/auth_account.dart';

abstract interface class AuthRepository {
  Future<Map<String, AuthAccount>> loadAccounts({
    required AuthAccount defaultAccount,
  });

  Future<void> saveAccount(String email, AuthAccount account);

  Future<String?> getCurrentEmail();

  Future<void> saveCurrentEmail(String email);

  Future<void> clearCurrentEmail();
}
