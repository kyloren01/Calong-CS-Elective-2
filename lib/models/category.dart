/// One row of the `categories` table.
class Category {
  const Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: (json['id'] as num).toInt(), name: json['name'] as String);

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
