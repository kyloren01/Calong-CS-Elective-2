/// One row of the `products` table, with its category's name and the link
/// to its picture.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    this.description = '',
    this.imagePath,
    this.imageUrl,
  });

  factory Product.fromJson(
    Map<String, dynamic> json, {
    required String Function(String path) imageUrlFor,
  }) {
    final imagePath = json['image_path'] as String?;
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      // Supabase sends numeric columns as JSON numbers, such as 129 or 12.5.
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      categoryName:
          (json['categories'] as Map<String, dynamic>?)?['name'] as String? ??
          'General',
      imagePath: imagePath,
      imageUrl: imagePath == null ? null : imageUrlFor(imagePath),
    );
  }

  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final String categoryName;

  /// Where the picture is in the Storage bucket, or null without one.
  final String? imagePath;
  final String? imageUrl;

  bool get isOutOfStock => stock <= 0;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.price == price &&
      other.stock == stock &&
      other.categoryId == categoryId &&
      other.categoryName == categoryName &&
      other.imagePath == imagePath;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    price,
    stock,
    categoryId,
    categoryName,
    imagePath,
  );

  @override
  String toString() => 'Product($id, $name, $price, stock $stock)';
}

/// The fields an admin fills in on the product form.
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imagePath,
  });

  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final String? imagePath;

  ProductDraft withImage(String? path) => ProductDraft(
    name: name,
    description: description,
    price: price,
    stock: stock,
    categoryId: categoryId,
    imagePath: path,
  );

  /// The column values sent to Supabase.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'category_id': categoryId,
    'image_path': imagePath,
  };
}
