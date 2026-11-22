/// Form checks. Each returns a message, or null when the value is fine.
/// The database checks the same rules again.
class Validators {
  const Validators._();

  static String? required(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email, such as you@example.com';
    }
    return null;
  }

  /// Supabase's default minimum is 6 characters.
  static String? newPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter a password';
    if (value!.length < 6) return 'Use at least 6 characters';
    return null;
  }

  /// A number of zero or more, with at most 2 decimals.
  static String? price(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a price';
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(text)) {
      return 'Enter a number, such as 49.99';
    }
    final price = double.parse(text);
    if (price < 0) return 'The price must be 0 or more';
    if (price > 99999999.99) return 'That price is too high';
    if (RegExp(r'\.\d{3,}$').hasMatch(text)) return 'Use at most 2 decimals';
    return null;
  }

  /// A whole number of zero or more.
  static String? stock(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter the stock';
    final stock = RegExp(r'^-?\d+$').hasMatch(text) ? int.tryParse(text) : null;
    if (stock == null) return 'Enter a whole number, such as 10';
    if (stock < 0) return 'The stock must be 0 or more';
    if (stock > 1000000) return 'That stock is too high';
    return null;
  }
}
