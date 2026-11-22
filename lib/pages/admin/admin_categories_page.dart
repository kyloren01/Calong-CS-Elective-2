import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_exception.dart';
import '../../models/category.dart';
import '../../providers/admin_providers.dart';
import '../../providers/catalog_providers.dart';
import '../../utils/validators.dart';
import '../../widgets/async_view.dart';
import '../../widgets/auth_form.dart' show ButtonSpinner;
import '../../widgets/confirm_dialog.dart';
import '../../widgets/message_view.dart';
import '../../widgets/product_image.dart';

/// Add, rename, and delete categories.
class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  Future<void> _openForm(BuildContext context, {Category? category}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
    if (saved ?? false) {
      showMessageOn(
        messenger,
        category == null ? 'Category added.' : 'Category renamed.',
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(categoryDeleteProvider.notifier);
    final sure = await confirm(
      context,
      title: 'Delete ${category.name}?',
      message: 'Only a category without products can be deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!sure) return;
    final error = await notifier.delete(category);
    showMessageOn(
      messenger,
      error == null ? '${category.name} deleted.' : messageFor(error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deleting = ref.watch(categoryDeleteProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-category',
        tooltip: 'Add category',
        isExtended: MediaQuery.sizeOf(context).width >= 600,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add category'),
      ),
      body: AsyncView(
        value: ref.watch(categoriesProvider),
        onRetry: () => ref.invalidate(categoriesProvider),
        data: (categories) => categories.isEmpty
            ? const MessageView(
                icon: Icons.category_outlined,
                title: 'No categories yet',
                message: 'Products need a category, so add one first.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Material(
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          leading: SizedBox.square(
                            dimension: 40,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CategoryArtwork(category: category.name),
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: theme.textTheme.titleSmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Rename ${category.name}',
                                onPressed: deleting
                                    ? null
                                    : () => _openForm(
                                        context,
                                        category: category,
                                      ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete ${category.name}',
                                color: theme.colorScheme.error,
                                onPressed: deleting
                                    ? null
                                    : () => _delete(context, ref, category),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({this.category});

  final Category? category;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref
        .read(categorySaveProvider.notifier)
        .save(_name.text.trim(), existing: widget.category);
    if (error == null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(categorySaveProvider);
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Rename category'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                enabled: !saving.isLoading,
                textCapitalization: TextCapitalization.words,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Category name'),
                validator: (value) =>
                    Validators.required(value, 'Enter a name'),
              ),
              if (saving.error case final error?) ...[
                const SizedBox(height: 12),
                Notice(messageFor(error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving.isLoading ? null : _save,
          child: saving.isLoading ? const ButtonSpinner() : const Text('Save'),
        ),
      ],
    );
  }
}
