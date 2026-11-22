import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/picked_image.dart';
import 'supabase_guard.dart';

/// Product pictures in Supabase Storage. Anyone can view a picture by its
/// link; the bucket's policies let only admins upload or delete.
class ImageService {
  ImageService(this._client);

  final SupabaseClient _client;

  static const bucket = 'product-images';
  static final _random = Random();

  /// Uploads [image] and returns its path in the bucket. Every upload gets a
  /// new name, so a replaced picture is never shown from an old cache.
  Future<String> upload(PickedImage image) => guard(() async {
    final path =
        '${DateTime.now().millisecondsSinceEpoch}'
        '-${_random.nextInt(0xFFFFFF)}.${image.extension}';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(contentType: image.contentType),
        );
    return path;
  });

  Future<void> delete(String path) =>
      guard(() => _client.storage.from(bucket).remove([path]));
}
