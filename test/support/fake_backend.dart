import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:my_first_flutter_ui/models/app_exception.dart';
import 'package:my_first_flutter_ui/models/cart.dart';
import 'package:my_first_flutter_ui/models/catalog.dart';
import 'package:my_first_flutter_ui/models/category.dart';
import 'package:my_first_flutter_ui/models/order.dart';
import 'package:my_first_flutter_ui/models/picked_image.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/models/profile.dart';
import 'package:my_first_flutter_ui/models/session_user.dart';
import 'package:my_first_flutter_ui/providers/service_providers.dart';
import 'package:my_first_flutter_ui/services/auth_service.dart';
import 'package:my_first_flutter_ui/services/category_service.dart';
import 'package:my_first_flutter_ui/services/image_picker_service.dart';
import 'package:my_first_flutter_ui/services/image_service.dart';
import 'package:my_first_flutter_ui/services/order_service.dart';
import 'package:my_first_flutter_ui/services/product_service.dart';
import 'package:my_first_flutter_ui/services/profile_service.dart';

const permissionDenied = AppException(
  "Your account doesn't have permission to do that.",
  kind: AppErrorKind.permissionDenied,
);
const offline = AppException(
  'Could not reach Supabase.',
  kind: AppErrorKind.network,
);

const ana = Profile(
  id: 'ana',
  role: UserRole.customer,
  email: 'ana@example.com',
  firstName: 'Ana',
  lastName: 'Cruz',
);
const ben = Profile(
  id: 'ben',
  role: UserRole.customer,
  email: 'ben@example.com',
  firstName: 'Ben',
  lastName: 'Reyes',
);
const boss = Profile(
  id: 'boss',
  role: UserRole.admin,
  email: 'boss@example.com',
  firstName: 'Bea',
  lastName: 'Boss',
);

/// Everyone's password.
const password = 'secret123';

const _seed = [
  ('Aurora Headphones', 'Audio', 129.0, 12),
  ('Echo Mini Speaker', 'Audio', 59.0, 25),
  ('Pulse Earbuds', 'Audio', 89.0, 18),
  ('Studio Mic', 'Audio', 149.0, 2),
  ('Urban Backpack', 'Bags', 74.0, 15),
  ('Transit Sling', 'Bags', 39.0, 30),
  ('Weekender Duffel', 'Bags', 119.0, 8),
  ('Laptop Sleeve', 'Bags', 29.0, 22),
  ('Pulse Watch', 'Wearables', 199.0, 10),
  ('Fit Band', 'Wearables', 49.0, 27),
  ('Trail Watch', 'Wearables', 249.0, 0),
  ('Glow Desk Lamp', 'Home', 48.0, 14),
  ('Aroma Diffuser', 'Home', 42.0, 16),
  ('Cloud Pillow', 'Home', 35.0, 40),
  ('Sprint Sneakers', 'Footwear', 96.0, 11),
  ('Trail Runners', 'Footwear', 135.0, 6),
  ('Slide Sandals', 'Footwear', 25.0, 33),
  ('Brew Kit', 'Kitchen', 58.0, 9),
  ('Steel Tumbler', 'Kitchen', 22.0, 45),
  ('Chef Knife', 'Kitchen', 64.0, 13),
  ('Bento Box', 'Kitchen', 18.0, 1),
  ('Power Bank', 'Tech', 45.0, 20),
  ('Wireless Charger', 'Tech', 32.0, 24),
  ('Mechanical Keyboard', 'Tech', 110.0, 7),
];

class SavedOrder {
  SavedOrder({required this.userId, required this.order});

  final String userId;
  Order order;
}

/// An in-memory Supabase that follows the same role rules as
/// supabase/final_exam.sql, so a customer's forbidden request really fails.
class FakeBackend {
  FakeBackend({Profile? signedInAs, List<Profile>? people})
    : profiles = {
        for (final person in people ?? const [ana, ben, boss])
          person.id: person,
      } {
    if (signedInAs != null) _session = _sessionOf(signedInAs);
    const names = [
      'Audio',
      'Bags',
      'Footwear',
      'Home',
      'Kitchen',
      'Tech',
      'Wearables',
    ];
    for (final (index, name) in names.indexed) {
      categories.add(Category(id: index + 1, name: name));
    }
    for (final (index, (name, category, price, stock)) in _seed.indexed) {
      products.add(
        Product(
          id: index + 1,
          name: name,
          description: 'About the $name.',
          price: price,
          stock: stock,
          categoryId: names.indexOf(category) + 1,
          categoryName: category,
        ),
      );
    }
  }

  final Map<String, Profile> profiles;
  final List<Category> categories = [];
  final List<Product> products = [];
  final List<SavedOrder> orders = [];
  final Set<String> images = {};

  /// Every service call, such as `fetchPage`, in order.
  final List<String> calls = [];
  final List<CatalogFilters> pageRequests = [];

  /// Makes a call fail until removed, such as `errors['placeOrder'] = ...`.
  final Map<String, Object> errors = {};

  /// Makes a call wait until the completer completes.
  final Map<String, Completer<void>> gates = {};

  /// Supabase's "Confirm email" setting.
  bool confirmEmail = false;
  bool googleAvailable = true;
  PickedImage? nextPick;

  SessionUser? _session;
  final _changes = StreamController<SessionUser?>.broadcast();
  int _nextId = 1000;

  List<Override> get overrides => [
    authServiceProvider.overrideWithValue(FakeAuthService(this)),
    profileServiceProvider.overrideWithValue(FakeProfileService(this)),
    categoryServiceProvider.overrideWithValue(FakeCategoryService(this)),
    productServiceProvider.overrideWithValue(FakeProductService(this)),
    imageServiceProvider.overrideWithValue(FakeImageService(this)),
    imagePickerServiceProvider.overrideWithValue(FakeImagePickerService(this)),
    orderServiceProvider.overrideWithValue(FakeOrderService(this)),
  ];

  Stream<SessionUser?> get userChanges => Stream.multi((listener) {
    listener.add(_session);
    final subscription = _changes.stream.listen(
      listener.add,
      onError: listener.addError,
    );
    listener.onCancel = subscription.cancel;
  });

  void signIn(Profile person) => _emit(_sessionOf(person));
  void signOut() => _emit(null);

  /// Supabase reports the same person again when it refreshes a token.
  void refreshToken() => _changes.add(_session);

  /// Such as pressing Cancel on Google's page.
  void failSession(String message) => _changes.addError(AppException(message));

  void setRole(Profile person, UserRole role) => profiles[person.id] = Profile(
    id: person.id,
    role: role,
    email: person.email,
    firstName: person.firstName,
    lastName: person.lastName,
  );

  Product product(String name) =>
      products.firstWhere((product) => product.name == name);

  void change(
    String name, {
    double? price,
    int? stock,
    String? newName,
    String? imagePath,
  }) {
    final index = products.indexWhere((product) => product.name == name);
    final old = products[index];
    products[index] = Product(
      id: old.id,
      name: newName ?? old.name,
      description: old.description,
      price: price ?? old.price,
      stock: stock ?? old.stock,
      categoryId: old.categoryId,
      categoryName: old.categoryName,
      imagePath: imagePath ?? old.imagePath,
    );
  }

  void removeProduct(String name) =>
      products.removeWhere((product) => product.name == name);

  Profile? get _person => profiles[_session?.id];

  SessionUser _sessionOf(Profile person) =>
      SessionUser(id: person.id, email: person.email);

  void _emit(SessionUser? user) {
    _session = user;
    _changes.add(user);
  }

  Future<T> call<T>(String name, T Function() body) async {
    calls.add(name);
    await Future<void>.delayed(Duration.zero);
    await gates[name]?.future;
    if (errors[name] case final error?) throw error;
    return body();
  }

  // The same rules as the RLS policies.
  void requireSignedIn() {
    if (_person == null) throw permissionDenied;
  }

  void requireAdmin() {
    if (_person?.isAdmin != true) throw permissionDenied;
  }
}

class FakeAuthService implements AuthService {
  FakeAuthService(this.backend);

  final FakeBackend backend;

  @override
  Stream<SessionUser?> get userChanges => backend.userChanges;

  @override
  bool get googleAvailable => backend.googleAvailable;

  @override
  Future<void> signIn({required String email, required String password}) =>
      backend.call('signIn', () {
        final person = backend.profiles.values
            .where((profile) => profile.email == email)
            .firstOrNull;
        if (person == null || password != 'secret123') {
          throw const AppException('Wrong email or password.');
        }
        backend.signIn(person);
      });

  @override
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => backend.call('signUp', () {
    if (backend.profiles.values.any((profile) => profile.email == email)) {
      throw const AppException(
        'That email already has an account. Sign in instead.',
      );
    }
    final person = Profile(
      id: email,
      role: UserRole.customer,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
    backend.profiles[email] = person;
    if (!backend.confirmEmail) backend.signIn(person);
    return backend.confirmEmail;
  });

  @override
  Future<void> signInWithGoogle() => backend.call('signInWithGoogle', () {});

  @override
  Future<void> signOut() => backend.call('signOut', backend.signOut);
}

class FakeProfileService implements ProfileService {
  FakeProfileService(this.backend);

  final FakeBackend backend;

  @override
  Future<Profile?> fetchProfile(String userId) =>
      backend.call('fetchProfile', () => backend.profiles[userId]);

  @override
  Future<void> updateName(
    String userId, {
    required String firstName,
    required String lastName,
  }) => backend.call('updateName', () {
    final person = backend._person;
    if (person == null || person.isAdmin || person.id != userId) {
      throw permissionDenied;
    }
    backend.profiles[userId] = Profile(
      id: userId,
      role: person.role,
      email: person.email,
      firstName: firstName,
      lastName: lastName,
    );
  });
}

class FakeCategoryService implements CategoryService {
  FakeCategoryService(this.backend);

  final FakeBackend backend;

  @override
  Future<List<Category>> fetchAll() => backend.call('fetchCategories', () {
    backend.requireSignedIn();
    return [...backend.categories]..sort((a, b) => a.name.compareTo(b.name));
  });

  void _requireNewName(String name) {
    if (backend.categories.any((category) => category.name == name)) {
      throw const AppException(
        'That name is already in use.',
        kind: AppErrorKind.rejected,
      );
    }
  }

  @override
  Future<void> add(String name) => backend.call('addCategory', () {
    backend.requireAdmin();
    _requireNewName(name);
    backend.categories.add(Category(id: backend._nextId++, name: name));
  });

  @override
  Future<void> rename(int id, String name) =>
      backend.call('renameCategory', () {
        backend.requireAdmin();
        _requireNewName(name);
        final index = backend.categories.indexWhere((c) => c.id == id);
        backend.categories[index] = Category(id: id, name: name);
      });

  @override
  Future<void> delete(int id) => backend.call('deleteCategory', () {
    backend.requireAdmin();
    if (backend.products.any((product) => product.categoryId == id)) {
      throw const AppException(
        'This category still has products. Move or delete them first.',
        kind: AppErrorKind.rejected,
      );
    }
    backend.categories.removeWhere((category) => category.id == id);
  });
}

class FakeProductService implements ProductService {
  FakeProductService(this.backend);

  final FakeBackend backend;

  Product _withUrl(Product product) => Product(
    id: product.id,
    name: product.name,
    description: product.description,
    price: product.price,
    stock: product.stock,
    categoryId: product.categoryId,
    categoryName: backend.categories
        .firstWhere((category) => category.id == product.categoryId)
        .name,
    imagePath: product.imagePath,
  );

  @override
  Future<PriceRange?> fetchPriceBounds() =>
      backend.call('fetchPriceBounds', () {
        backend.requireSignedIn();
        final prices = [for (final p in backend.products) p.price]..sort();
        return prices.isEmpty ? null : PriceRange(prices.first, prices.last);
      });

  @override
  Future<ProductPage> fetchPage(CatalogFilters filters) {
    backend.pageRequests.add(filters);
    return backend.call('fetchPage', () {
      backend.requireSignedIn();
      final matches =
          backend.products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(
                      filters.search.toLowerCase(),
                    ) &&
                    (filters.categoryId == null ||
                        p.categoryId == filters.categoryId) &&
                    (filters.price == null ||
                        (p.price >= filters.price!.min &&
                            p.price <= filters.price!.max)),
              )
              .toList()
            ..sort(
              (a, b) => a.price != b.price
                  ? a.price.compareTo(b.price)
                  : a.id.compareTo(b.id),
            );
      final lastPage = ProductPage.pagesFor(matches.length);
      final page = filters.page > lastPage ? lastPage : filters.page;
      return ProductPage(
        products: [
          for (final product
              in matches
                  .skip((page - 1) * ProductPage.size)
                  .take(ProductPage.size))
            _withUrl(product),
        ],
        totalCount: matches.length,
        page: page,
      );
    });
  }

  @override
  Future<List<Product>> fetchByIds(List<int> ids) =>
      backend.call('fetchByIds', () {
        backend.requireSignedIn();
        return [
          for (final product in backend.products)
            if (ids.contains(product.id)) _withUrl(product),
        ];
      });

  Product _fromDraft(int id, ProductDraft draft) => Product(
    id: id,
    name: draft.name,
    description: draft.description,
    price: draft.price,
    stock: draft.stock,
    categoryId: draft.categoryId,
    categoryName: backend.categories
        .firstWhere((category) => category.id == draft.categoryId)
        .name,
    imagePath: draft.imagePath,
  );

  @override
  Future<void> create(ProductDraft draft) => backend.call('createProduct', () {
    backend.requireAdmin();
    backend.products.add(_fromDraft(backend._nextId++, draft));
  });

  @override
  Future<void> update(int id, ProductDraft draft) =>
      backend.call('updateProduct', () {
        backend.requireAdmin();
        final index = backend.products.indexWhere((p) => p.id == id);
        backend.products[index] = _fromDraft(id, draft);
      });

  @override
  Future<void> delete(int id) => backend.call('deleteProduct', () {
    backend.requireAdmin();
    backend.products.removeWhere((product) => product.id == id);
  });
}

class FakeImageService implements ImageService {
  FakeImageService(this.backend);

  final FakeBackend backend;

  @override
  Future<String> upload(PickedImage image) => backend.call('uploadImage', () {
    backend.requireAdmin();
    final path = 'image-${backend._nextId++}.${image.extension}';
    backend.images.add(path);
    return path;
  });

  @override
  Future<void> delete(String path) => backend.call('deleteImage', () {
    backend.requireAdmin();
    backend.images.remove(path);
  });
}

class FakeImagePickerService implements ImagePickerService {
  FakeImagePickerService(this.backend);

  final FakeBackend backend;

  @override
  Future<PickedImage?> pick() =>
      backend.call('pickImage', () => backend.nextPick);
}

class FakeOrderService implements OrderService {
  FakeOrderService(this.backend);

  final FakeBackend backend;

  /// Works like place_order(): everything is checked before anything is
  /// saved, and names and prices come from the backend.
  @override
  Future<Order> placeOrder(List<CartLine> lines) {
    final wanted = {for (final line in lines) line.product.id: line.quantity};
    return backend.call('placeOrder', () {
      final person = backend._person;
      if (person == null || person.isAdmin) throw permissionDenied;
      final items = <OrderItem>[];
      for (final MapEntry(key: id, value: quantity) in wanted.entries) {
        final product = backend.products
            .where((product) => product.id == id)
            .firstOrNull;
        if (product == null) {
          throw const AppException(
            'A product in your cart is no longer sold. Please review your '
            'cart.',
            kind: AppErrorKind.rejected,
          );
        }
        if (product.stock < quantity) {
          throw AppException(
            product.stock == 0
                ? '${product.name} is out of stock.'
                : 'Only ${product.stock} left of ${product.name}.',
            kind: AppErrorKind.rejected,
          );
        }
        items.add(
          OrderItem(
            productName: product.name,
            unitPrice: product.price,
            quantity: quantity,
          ),
        );
      }
      for (final MapEntry(key: id, value: quantity) in wanted.entries) {
        final product = backend.products.firstWhere((p) => p.id == id);
        backend.change(product.name, stock: product.stock - quantity);
      }
      final order = Order(
        id: backend.orders.length + 1,
        status: OrderStatus.done,
        total: items.fold(0, (sum, item) => sum + item.total),
        createdAt: DateTime(2026, 11, 22, 15, backend.orders.length),
        items: items,
      );
      backend.orders.add(SavedOrder(userId: person.id, order: order));
      return order;
    });
  }

  @override
  Future<List<Order>> fetchMyOrders(String userId) =>
      backend.call('fetchMyOrders', () {
        backend.requireSignedIn();
        return [
          for (final saved in backend.orders.reversed)
            if (saved.userId == userId && saved.userId == backend._person!.id)
              saved.order,
        ];
      });

  @override
  Future<List<Order>> fetchAllOrders() => backend.call('fetchAllOrders', () {
    backend.requireAdmin();
    return [
      for (final saved in backend.orders.reversed)
        Order(
          id: saved.order.id,
          status: saved.order.status,
          total: saved.order.total,
          createdAt: saved.order.createdAt,
          items: saved.order.items,
          customerName: backend.profiles[saved.userId]!.fullName,
          customerEmail: backend.profiles[saved.userId]!.email,
        ),
    ];
  });

  @override
  Future<void> updateStatus(int orderId, OrderStatus status) =>
      backend.call('updateStatus', () {
        backend.requireAdmin();
        final saved = backend.orders.firstWhere((s) => s.order.id == orderId);
        saved.order = Order(
          id: saved.order.id,
          status: status,
          total: saved.order.total,
          createdAt: saved.order.createdAt,
          items: saved.order.items,
        );
      });
}

/// A valid 1x1 PNG.
final tinyPng = PickedImage(
  bytes: Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
    0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
  extension: 'png',
  contentType: 'image/png',
);
