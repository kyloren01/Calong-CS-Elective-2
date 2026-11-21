/// The signed-in person, with only the details the app shows.
class AppUser {
  const AppUser({
    required this.id,
    required this.provider,
    this.email,
    this.name,
    this.avatarUrl,
  });

  final String id;

  /// How the account was created: `email` or `github`.
  final String provider;

  final String? email;

  /// The GitHub name or username. Email accounts don't have one.
  final String? name;

  /// The GitHub profile picture.
  final String? avatarUrl;

  String get displayName => name ?? email ?? 'Shopper';

  /// "GitHub" or "email", for "Signed in with ...".
  String get providerLabel => switch (provider) {
    'github' => 'GitHub',
    'email' => 'email',
    _ => provider,
  };

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.provider == provider &&
      other.email == email &&
      other.name == name &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, provider, email, name, avatarUrl);

  @override
  String toString() => 'AppUser($id, $provider, $email)';
}
