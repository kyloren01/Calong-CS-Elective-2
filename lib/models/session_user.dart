/// The signed-in account, as Supabase Auth knows it.
class SessionUser {
  const SessionUser({required this.id, this.email});

  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is SessionUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
