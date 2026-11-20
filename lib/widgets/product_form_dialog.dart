import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';

/// The add and edit form. It stays open while Supabase saves, and shows the
/// error if saving fails.
class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    this.product,
    required this.categories,
    required this.onSubmit,
  });

  /// The product to edit, or null to add a new one.
  final Product? product;

  /// Existing categories, offered as one-tap choices.
  final List<String> categories;

  /// Saves the draft and returns null, or returns an error message.
  final Future<String?> Function(ProductDraft draft) onSubmit;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _description = TextEditingController(
    text: widget.product?.description,
  );
  late final _price = TextEditingController(
    text: widget.product?.price.toStringAsFixed(2),
  );
  late final _category = TextEditingController(text: widget.product?.category);
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(
      ProductDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        category: _category.text.trim(),
        price: double.parse(_price.text),
      ),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  static String? _required(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  static String? _validatePrice(String? value) {
    final price = double.tryParse(value ?? '');
    if (price == null) return 'Enter a price, such as 49.99';
    if (price < 0) return 'The price cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEditing ? 'Edit product' : 'Add product'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => _required(value, 'Enter a name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // Up to 8 digits and 2 decimals, the size of numeric(10, 2).
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,8}(\.\d{0,2})?'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$ ',
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _category,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      _required(value, 'Enter or pick a category'),
                ),
                if (widget.categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final category in widget.categories)
                        ChoiceChip(
                          label: Text(category),
                          selected: _category.text.trim() == category,
                          onSelected: _saving
                              ? null
                              : (_) => setState(() => _category.text = category),
                        ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
