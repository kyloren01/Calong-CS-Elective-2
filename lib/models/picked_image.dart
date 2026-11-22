import 'dart:typed_data';

/// A picture chosen on this device, ready to upload.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.extension,
    required this.contentType,
  });

  final Uint8List bytes;

  /// Without the dot, such as `png`.
  final String extension;

  /// Such as `image/png`.
  final String contentType;
}
