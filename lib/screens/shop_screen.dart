import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/product.dart';
import '../state/shop_cubit.dart';
import '../state/shop_state.dart';
import '../theme/app_theme.dart';
import '../widgets/category_filter.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/price_filter.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form_dialog.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, state) {
        final cubit = context.read<ShopCubit>();
        final showContent = state.status != ShopStatus.failure;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: const Text(
              'Shopping',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: state.isLoading ? null : cubit.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: state.isLoading
                  ? const LinearProgressIndicator(minHeight: 3)
                  : const SizedBox(height: 3),
            ),
          ),
          floatingActionButton: showContent && state.status != ShopStatus.initial
              ? FloatingActionButton.extended(
                  tooltip: 'Add product',
                  onPressed: () => _openForm(context),
                  // Just the + on phones, so it covers less of the grid.
                  isExtended: MediaQuery.sizeOf(context).width >= 600,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add product'),
                )
              : null,
          bottomNavigationBar: showContent && state.totalCount > 0
              ? PaginationBar(
                  page: state.page,
                  totalPages: state.totalPages,
                  onPageSelected: cubit.goToPage,
                )
              : null,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ShopState state) {
    final cubit = context.read<ShopCubit>();
    if (state.status == ShopStatus.failure) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load products',
        message: state.errorMessage ?? 'Please try again.',
        action: FilledButton.icon(
          onPressed: cubit.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (state.status == ShopStatus.initial ||
        (state.isLoading && state.products.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the content at most 1200 px wide, centred on large screens.
        final gutter = math.max(16.0, (constraints.maxWidth - 1200) / 2);
        final width = constraints.maxWidth - gutter * 2;
        // 6 products per page fit evenly as 2x3, 3x2, or 6x1.
        final columns = width >= 1100 ? 6 : (width >= 600 ? 3 : 2);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
              sliver: SliverToBoxAdapter(child: _FilterPanel(state: state)),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
              sliver: SliverToBoxAdapter(child: _ResultSummary(state: state)),
            ),
            if (state.products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: state.hasFilters
                    ? _Message(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No products match',
                        message: 'Try a wider price range or another category.',
                        action: TextButton(
                          onPressed: cubit.clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      )
                    : _Message(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products yet',
                        message: 'Products you add are saved to Supabase.',
                        action: FilledButton.icon(
                          onPressed: () => _openForm(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add a product'),
                        ),
                      ),
              )
            else
              SliverPadding(
                // Extra bottom space keeps the last row clear of the button.
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 96),
                sliver: SliverIgnorePointer(
                  // Old cards fade and can't be tapped while a page loads.
                  ignoring: state.isLoading,
                  sliver: SliverAnimatedOpacity(
                    opacity: state.isLoading ? 0.45 : 1,
                    duration: const Duration(milliseconds: 150),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 250,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = state.products[index];
                          return ProductCard(
                            key: ValueKey(product.id),
                            product: product,
                            onEdit: () => _openForm(context, product: product),
                            onDelete: () => _confirmDelete(context, product),
                          );
                        },
                        childCount: state.products.length,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _openForm(BuildContext context, {Product? product}) async {
  final cubit = context.read<ShopCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => ProductFormDialog(
      product: product,
      categories: cubit.state.categories,
      onSubmit: (draft) => product == null
          ? cubit.addProduct(draft)
          : cubit.updateProduct(product, draft),
    ),
  );
  if (saved ?? false) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(product == null ? 'Product added.' : 'Changes saved.'),
        ),
      );
  }
}

Future<void> _confirmDelete(BuildContext context, Product product) async {
  final cubit = context.read<ShopCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete ${product.name}?'),
      content: const Text(
        'This permanently removes it from the products table in Supabase.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final error = await cubit.deleteProduct(product);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(error ?? '${product.name} deleted.')));
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.state});

  final ShopState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<ShopCubit>();
    final bounds = state.priceBounds;
    final selected = state.selectedPrice;
    final categories = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        CategoryFilter(
          categories: state.categories,
          selected: state.selectedCategory,
          onSelected: cubit.selectCategory,
        ),
      ],
    );
    final price = bounds == null || selected == null
        ? null
        : PriceFilter(
            bounds: bounds,
            selected: selected,
            onChanged: cubit.setPriceRange,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (price != null && constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: categories),
                const SizedBox(width: 32),
                SizedBox(width: 340, child: price),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              categories,
              if (price != null) ...[const SizedBox(height: 16), price],
            ],
          );
        },
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.state});

  final ShopState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = state.firstShown == state.lastShown
        ? '${state.firstShown}'
        : '${state.firstShown}–${state.lastShown}';
    final summary = state.totalCount == 0
        ? 'No products found'
        : 'Showing $shown of ${state.totalCount} products · '
              'Page ${state.page} of ${state.totalPages}';
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (state.hasFilters)
          TextButton.icon(
            onPressed: context.read<ShopCubit>().clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Clear filters'),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.orange),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          action,
        ],
      ),
    ),
  );
}
