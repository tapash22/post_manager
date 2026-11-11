import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionLocalDataSource {
  static const _currentEmailKey = 'post_manager_current_email';

  Future<String?> getCurrentEmail() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_currentEmailKey);
  }

  Future<void> saveCurrentEmail(String email) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_currentEmailKey, email);
    if (!saved) {
      throw StateError('Could not save the local login session.');
    }
  }

  Future<void> clearCurrentEmail() async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_currentEmailKey);
    if (!removed) {
      throw StateError('Could not clear the local login session.');
    }
  }
}
