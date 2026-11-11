import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/app_database.dart';
import '../models/auth_account_model.dart';

class AuthAccountLocalDataSource {
  static const _legacyAccountsKey = 'post_manager_accounts';

  Future<Map<String, AuthAccountModel>> getAccounts() async {
    final storedAccounts = AppDatabase.accounts
        .toMap()
        .cast<String, AuthAccountModel>();
    if (storedAccounts.isNotEmpty) {
      return storedAccounts;
    }

    final preferences = await SharedPreferences.getInstance();
    final legacyData = preferences.getString(_legacyAccountsKey);
    if (legacyData == null) {
      return storedAccounts;
    }

    final decoded = jsonDecode(legacyData);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Stored accounts must be a list.');
    }
    final migratedAccounts = <String, AuthAccountModel>{};
    for (final item in decoded) {
      if (item is! Map<String, dynamic> ||
          item['email'] is! String ||
          item['name'] is! String ||
          item['salt'] is! String ||
          item['passwordHash'] is! String) {
        throw const FormatException('Stored account data is invalid.');
      }
      migratedAccounts[item['email'] as String] = AuthAccountModel(
        name: item['name'] as String,
        salt: item['salt'] as String,
        passwordHash: item['passwordHash'] as String,
      );
    }

    await AppDatabase.accounts.putAll(migratedAccounts);
    final removed = await preferences.remove(_legacyAccountsKey);
    if (!removed) {
      throw StateError('Could not complete local account migration.');
    }
    return migratedAccounts;
  }

  Future<void> saveAccount(String email, AuthAccountModel account) =>
      AppDatabase.accounts.put(email, account);
}
