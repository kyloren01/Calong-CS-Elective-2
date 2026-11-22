enum UserRole { customer, admin }

/// One row of the `profiles` table, with the name of its role.
class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.email,
    this.firstName = '',
    this.lastName = '',
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final role = (json['roles'] as Map<String, dynamic>?)?['role'];
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['firstname'] as String? ?? '',
      lastName: json['lastname'] as String? ?? '',
      // Anything unexpected gets the fewest rights.
      role: role == 'admin' ? UserRole.admin : UserRole.customer,
    );
  }

  final String id;
  final UserRole role;
  final String? email;
  final String firstName;
  final String lastName;

  bool get isAdmin => role == UserRole.admin;

  String get fullName => '$firstName $lastName'.trim();

  String get displayName =>
      fullName.isNotEmpty ? fullName : email ?? 'Customer';
}
