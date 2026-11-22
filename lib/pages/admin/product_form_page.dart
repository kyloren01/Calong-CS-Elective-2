import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_exception.dart';
import '../../models/category.dart';
import '../../models/picked_image.dart';
import '../../models/product.dart';
import '../../providers/admin_providers.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/session_providers.dart';
import '../../utils/validators.dart';
import '../../widgets/async_view.dart';
import '../../widgets/auth_form.dart' show ButtonSpinner;
import '../../widgets/message_view.dart';
import '../../widgets/product_image.dart';

/// Adds a product, or edits [product] with its current values filled in.
/// Closes with `true` after saving.
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _description = TextEditingController(
    text: widget.product?.description,
  );
  late final _price = TextEditingController(
    text: widget.product?.price.toStringAsFixed(2),
  );
  late final _stock = TextEditingController(
    text: widget.product?.stock.toString(),
  );
  late int? _categoryId = widget.product?.categoryId;

  PickedImage? _newImage;
  bool _removeImage = false;
  String? _imageProblem;

  bool get _isEditing => widget.product != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    setState(() => _imageProblem = null);
    try {
      final image = await ref.read(imagePickerServiceProvider).pick();
      if (image == null || !mounted) return;
      setState(() {
        _newImage = image;
        _removeImage = false;
      });
    } catch (error) {
      if (mounted) setState(() => _imageProblem = messageFor(error));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref
        .read(productSaveProvider.notifier)
        .save(
          ProductDraft(
            name: _name.text.trim(),
            description: _description.text.trim(),
            price: double.parse(_price.text.trim()),
            stock: int.parse(_stock.text.trim()),
            categoryId: _categoryId!,
          ),
          existing: widget.product,
          newImage: _newImage,
          removeImage: _removeImage,
        );
    if (error == null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(_isEditing ? 'Edit product' : 'Add product');
    // RLS would refuse the save anyway; this keeps customers out of the form.
    if (!ref.watch(isAdminProvider)) {
      return Scaffold(
        appBar: AppBar(title: title),
        body: const PermissionDeniedView(),
      );
    }

    final saving = ref.watch(productSaveProvider);
    final enabled = !saving.isLoading;
    return Scaffold(
      appBar: AppBar(title: title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImageField(
                    product: widget.product,
                    newImage: _newImage,
                    removed: _removeImage,
                    problem: _imageProblem,
                    onChoose: enabled ? _chooseImage : null,
                    onRemove: enabled
                        ? () => setState(() {
                            _newImage = null;
                            _removeImage = true;
                          })
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    enabled: enabled,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                        Validators.required(value, 'Enter a name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    enabled: enabled,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          enabled: enabled,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixText: '\$ ',
                            errorMaxLines: 2,
                          ),
                          validator: Validators.price,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stock,
                          enabled: enabled,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Stock quantity',
                            errorMaxLines: 2,
                          ),
                          validator: Validators.stock,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InlineAsyncView(
                    value: ref.watch(categoriesProvider),
                    onRetry: () => ref.invalidate(categoriesProvider),
                    data: (categories) => _CategoryField(
                      categories: categories,
                      selectedId: _categoryId,
                      onChanged: enabled
                          ? (id) => setState(() => _categoryId = id)
                          : null,
                    ),
                  ),
                  if (saving.error case final error? when enabled) ...[
                    const SizedBox(height: 16),
                    Notice(messageFor(error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: enabled ? _save : null,
                    child: enabled
                        ? Text(_isEditing ? 'Save changes' : 'Add product')
                        : const ButtonSpinner(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Notice(
        'There are no categories yet. Add one on the Categories tab first.',
      );
    }
    // The category may have been deleted while this form was open.
    final known = categories.any((category) => category.id == selectedId);
    return DropdownButtonFormField<int>(
      initialValue: known ? selectedId : null,
      decoration: const InputDecoration(labelText: 'Category'),
      isExpanded: true,
      items: [
        for (final category in categories)
          DropdownMenuItem(value: category.id, child: Text(category.name)),
      ],
      onChanged: onChanged,
      validator: (value) => value == null ? 'Choose a category' : null,
    );
  }
}

class _ImageField extends StatelessWidget {
  const _ImageField({
    required this.product,
    required this.newImage,
    required this.removed,
    required this.problem,
    required this.onChoose,
    required this.onRemove,
  });

  final Product? product;
  final PickedImage? newImage;
  final bool removed;
  final String? problem;
  final VoidCallback? onChoose;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = product;
    final hasCurrent = current?.imageUrl != null && !removed;
    final hasImage = newImage != null || hasCurrent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: newImage != null
                ? Image.memory(
                    newImage!.bytes,
                    fit: BoxFit.cover,
                    semanticLabel: 'The chosen picture',
                    errorBuilder: (_, _, _) => const _NoPicture(
                      icon: Icons.broken_image_outlined,
                      text: 'This picture can’t be shown',
                    ),
                  )
                : hasCurrent
                ? ProductImage(product: current!, radius: 16)
                : const _NoPicture(
                    icon: Icons.image_outlined,
                    text: 'No picture yet',
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onChoose,
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: Text(hasImage ? 'Change picture' : 'Choose picture'),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Remove picture'),
              ),
          ],
        ),
        if (problem case final problem?) ...[
          const SizedBox(height: 8),
          Notice(problem),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            'JPG, PNG, WebP, or GIF, up to 5 MB.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _NoPicture extends StatelessWidget {
  const _NoPicture({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
