import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_exception.dart';
import '../models/category.dart';
import 'supabase_guard.dart';

/// Reads and edits the `categories` table. RLS lets only admins edit it.
class CategoryService {
  CategoryService(this._client);

  final SupabaseClient _client;

  static const _table = 'categories';

  Future<List<Category>> fetchAll() => guard(() async {
    final rows = await _client
        .from(_table)
        .select('id, name')
        .order('name', ascending: true);
    return rows.map(Category.fromJson).toList();
  });

  Future<void> add(String name) =>
      guard(() => _client.from(_table).insert({'name': name}));

  Future<void> rename(int id, String name) => guard(() async {
    final rows = await _client
        .from(_table)
        .update({'name': name})
        .eq('id', id)
        .select('id');
    _expectChange(rows);
  });

  Future<void> delete(int id) => guard(() async {
    try {
      final rows = await _client
          .from(_table)
          .delete()
          .eq('id', id)
          .select('id');
      _expectChange(rows);
    } on PostgrestException catch (error) {
      if (error.code != '23503') rethrow;
      throw const AppException(
        'This category still has products. Move or delete them first.',
        kind: AppErrorKind.rejected,
      );
    }
  });

  // RLS doesn't raise an error when it blocks an edit: it changes 0 rows.
  static void _expectChange(List<Object?> rows) {
    if (rows.isNotEmpty) return;
    throw const AppException(
      'Nothing was changed. The category may be gone, or your account is not '
      'allowed to change it.',
      kind: AppErrorKind.permissionDenied,
    );
  }
}
