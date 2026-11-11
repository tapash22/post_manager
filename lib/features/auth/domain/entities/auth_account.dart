class AuthAccount {
  final String name;
  final String salt;
  final String passwordHash;

  const AuthAccount({
    required this.name,
    required this.salt,
    required this.passwordHash,
  });
}
