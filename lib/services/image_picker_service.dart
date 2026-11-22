import 'package:image_picker/image_picker.dart';

import '../models/app_exception.dart';
import '../models/picked_image.dart';

/// Lets an admin choose a product picture from this device.
class ImagePickerService {
  static const maxBytes = 5 * 1024 * 1024;

  static const _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  /// The chosen picture, or null when the person cancelled.
  Future<PickedImage?> pick() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );
    } catch (_) {
      throw const AppException('This device could not open its pictures.');
    }
    if (file == null) return null;
    return check(
      PickedImage(
        bytes: await file.readAsBytes(),
        extension: file.name.split('.').last.toLowerCase(),
        contentType: file.mimeType ?? '',
      ),
    );
  }

  /// Refuses files that Storage would refuse anyway, before uploading them.
  static PickedImage check(PickedImage image) {
    // Phones don't always report a type, so fall back on the file name.
    final contentType = _contentTypes.containsValue(image.contentType)
        ? image.contentType
        : _contentTypes[image.extension];
    if (contentType == null) {
      throw const AppException(
        'Use a JPG, PNG, WebP, or GIF picture.',
        kind: AppErrorKind.rejected,
      );
    }
    if (image.bytes.length > maxBytes) {
      throw const AppException(
        'That picture is too large. Use one under 5 MB.',
        kind: AppErrorKind.rejected,
      );
    }
    return PickedImage(
      bytes: image.bytes,
      extension: contentType.split('/').last,
      contentType: contentType,
    );
  }
}
