import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_exception.dart';
import '../models/profile.dart';
import 'supabase_guard.dart';

/// Reads and edits the `profiles` table.
class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  /// The profile and its role, or null when the account has no profile.
  Future<Profile?> fetchProfile(String userId) => guard(() async {
    final row = await _client
        .from('profiles')
        .select('id, email, firstname, lastname, roles(role)')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  });

  Future<void> updateName(
    String userId, {
    required String firstName,
    required String lastName,
  }) => guard(() async {
    final rows = await _client
        .from('profiles')
        .update({'firstname': firstName, 'lastname': lastName})
        .eq('id', userId)
        .select('id');
    // RLS doesn't raise an error for a row it hides: it changes 0 rows.
    if (rows.isEmpty) {
      throw const AppException(
        "Your account doesn't have permission to change this profile.",
        kind: AppErrorKind.permissionDenied,
      );
    }
  });
}
