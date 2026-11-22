import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_exception.dart';
import '../../models/product.dart';
import '../../providers/admin_providers.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/brand.dart';
import '../../widgets/catalog_view.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/message_view.dart';
import '../../widgets/product_card.dart';
import 'product_form_page.dart';

/// The admin's product list: the Add button opens the form, and every
/// product can be edited or deleted.
class AdminProductsPage extends ConsumerWidget {
  const AdminProductsPage({super.key});

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );
    if (saved ?? false) {
      showMessageOn(
        messenger,
        product == null ? 'Product added.' : 'Changes saved.',
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(productDeleteProvider.notifier);
    final sure = await confirm(
      context,
      title: 'Delete ${product.name}?',
      message:
          '"${product.name}" will be removed from the shop. Past orders keep '
          'its name and price.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!sure) return;
    final error = await notifier.delete(product);
    showMessageOn(
      messenger,
      error == null ? '${product.name} deleted.' : messageFor(error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleting = ref.watch(productDeleteProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(suffix: 'Admin'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => refreshCatalog(ref.invalidate),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-product',
        tooltip: 'Add product',
        // Just the + on phones, so it covers less of the products.
        isExtended: MediaQuery.sizeOf(context).width >= 600,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
      body: CatalogView(
        emptyMessage: 'Press "Add product" to create the first one.',
        bottomPadding: 96,
        cardBuilder: (context, product) => ProductCard(
          product: product,
          showExactStock: true,
          footer: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: deleting
                      ? null
                      : () => _openForm(context, product: product),
                  child: Tooltip(
                    message: 'Edit ${product.name}',
                    child: const Text('Edit'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Delete ${product.name}',
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.square(44),
                ),
                onPressed: deleting
                    ? null
                    : () => _delete(context, ref, product),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
