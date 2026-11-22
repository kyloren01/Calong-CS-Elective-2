import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/order.dart';
import '../models/picked_image.dart';
import '../models/product.dart';
import '../services/image_service.dart';
import 'action_notifier.dart';
import 'catalog_providers.dart';
import 'service_providers.dart';
import 'session_providers.dart';

// What admins can change. These providers don't check the role themselves:
// Row Level Security refuses the request for anyone who isn't an admin.

/// Adds or edits a product, including its picture.
final productSaveProvider =
    NotifierProvider.autoDispose<ProductSaveNotifier, AsyncValue<void>>(
      ProductSaveNotifier.new,
    );

class ProductSaveNotifier extends ActionNotifier {
  /// Saves [draft] as a new product, or over [existing].
  Future<Object?> save(
    ProductDraft draft, {
    Product? existing,
    PickedImage? newImage,
    bool removeImage = false,
  }) => run(() async {
    final products = ref.read(productServiceProvider);
    final images = ref.read(imageServiceProvider);

    final oldPath = existing?.imagePath;
    final uploaded = newImage == null ? null : await images.upload(newImage);
    final path = uploaded ?? (removeImage ? null : oldPath);
    try {
      if (existing == null) {
        await products.create(draft.withImage(path));
      } else {
        await products.update(existing.id, draft.withImage(path));
      }
    } catch (_) {
      if (uploaded != null) await _deleteQuietly(images, uploaded);
      rethrow;
    }
    if (oldPath != null && oldPath != path) {
      await _deleteQuietly(images, oldPath);
    }
    if (ref.mounted) refreshCatalog(ref.invalidate);
  });
}

final productDeleteProvider =
    NotifierProvider<ProductDeleteNotifier, AsyncValue<void>>(
      ProductDeleteNotifier.new,
    );

class ProductDeleteNotifier extends ActionNotifier {
  Future<Object?> delete(Product product) => run(() async {
    final images = ref.read(imageServiceProvider);
    await ref.read(productServiceProvider).delete(product.id);
    final path = product.imagePath;
    if (path != null) await _deleteQuietly(images, path);
    if (ref.mounted) refreshCatalog(ref.invalidate);
  });
}

/// The product itself is already saved or deleted at this point, so a
/// picture that stays behind in Storage is not worth an error message.
Future<void> _deleteQuietly(ImageService images, String path) async {
  try {
    await images.delete(path);
  } catch (_) {}
}

/// Adds or renames a category.
final categorySaveProvider =
    NotifierProvider.autoDispose<CategorySaveNotifier, AsyncValue<void>>(
      CategorySaveNotifier.new,
    );

class CategorySaveNotifier extends ActionNotifier {
  Future<Object?> save(String name, {Category? existing}) => run(() async {
    final categories = ref.read(categoryServiceProvider);
    if (existing == null) {
      await categories.add(name);
    } else {
      await categories.rename(existing.id, name);
    }
    if (ref.mounted) refreshCatalog(ref.invalidate);
  });
}

final categoryDeleteProvider =
    NotifierProvider<CategoryDeleteNotifier, AsyncValue<void>>(
      CategoryDeleteNotifier.new,
    );

class CategoryDeleteNotifier extends ActionNotifier {
  Future<Object?> delete(Category category) => run(() async {
    await ref.read(categoryServiceProvider).delete(category.id);
    if (!ref.mounted) return;
    // Don't keep filtering by a category that no longer exists.
    if (ref.read(catalogFiltersProvider).categoryId == category.id) {
      ref.read(catalogFiltersProvider.notifier).selectCategory(null);
    }
    refreshCatalog(ref.invalidate);
  });
}

/// Every order, newest first.
final allOrdersProvider = FutureProvider<List<Order>>((ref) async {
  if (ref.watch(userIdProvider) == null) return const [];
  return ref.watch(orderServiceProvider).fetchAllOrders();
});

/// Changes order statuses. The state is the order being saved, if any.
final orderStatusProvider = NotifierProvider<OrderStatusNotifier, int?>(
  OrderStatusNotifier.new,
);

class OrderStatusNotifier extends Notifier<int?> {
  @override
  int? build() {
    ref.watch(userIdProvider);
    return null;
  }

  /// Returns null when it worked, or the error.
  Future<Object?> update(Order order, OrderStatus status) async {
    state = order.id;
    try {
      await ref.read(orderServiceProvider).updateStatus(order.id, status);
      if (ref.mounted) ref.invalidate(allOrdersProvider);
      return null;
    } catch (error) {
      return error;
    } finally {
      if (ref.mounted) state = null;
    }
  }
}
