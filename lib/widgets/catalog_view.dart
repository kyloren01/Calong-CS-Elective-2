import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../models/product.dart';
import '../providers/catalog_providers.dart';
import 'async_view.dart';
import 'category_filter.dart';
import 'message_view.dart';
import 'pagination_bar.dart';
import 'price_filter.dart';
import 'search_field.dart';

/// Search, filters, the product grid, and page numbers. Customers and admins
/// share it; [cardBuilder] decides which buttons a product gets.
class CatalogView extends ConsumerStatefulWidget {
  const CatalogView({
    super.key,
    required this.cardBuilder,
    required this.emptyMessage,
    this.bottomPadding = 24,
  });

  final Widget Function(BuildContext context, Product product) cardBuilder;

  /// Shown when the shop has no products at all.
  final String emptyMessage;

  /// Room for a floating button.
  final double bottomPadding;

  @override
  ConsumerState<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<CatalogView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    refreshCatalog(ref.invalidate);
    try {
      await ref.read(productPageProvider.future);
    } catch (_) {
      // The page itself shows the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    // A new page starts at the top.
    ref.listen(catalogFiltersProvider.select((filters) => filters.page), (
      _,
      _,
    ) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });

    final page = ref.watch(productPageProvider);
    final filters = ref.watch(catalogFiltersProvider);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // At most 1240 px wide, centred on large screens.
              final gutter = math.max(16.0, (constraints.maxWidth - 1240) / 2);
              final width = constraints.maxWidth - gutter * 2;
              // 6 products fill 2x3, 3x2, or 6x1 evenly.
              final columns = width >= 1100 ? 6 : (width >= 560 ? 3 : 2);
              return CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                    sliver: const SliverToBoxAdapter(child: _FilterPanel()),
                  ),
                  ..._results(context, page, filters, gutter, columns),
                ],
              );
            },
          ),
        ),
        if (page.isLoading && page.hasValue)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }

  List<Widget> _results(
    BuildContext context,
    AsyncValue<ProductPage> value,
    CatalogFilters filters,
    double gutter,
    int columns,
  ) {
    final page = value.value;
    if (value.hasError || page == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AsyncView(
            value: value,
            onRetry: () => refreshCatalog(ref.invalidate),
            data: (_) => const SizedBox.shrink(),
          ),
        ),
      ];
    }

    final notifier = ref.read(catalogFiltersProvider.notifier);
    if (page.products.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: filters.isFiltering
              ? MessageView(
                  icon: Icons.search_off_rounded,
                  title: 'No products match',
                  message:
                      'Try another search, category, or a wider price range.',
                  action: OutlinedButton(
                    onPressed: notifier.clear,
                    child: const Text('Clear filters'),
                  ),
                )
              : MessageView(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products yet',
                  message: widget.emptyMessage,
                ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 14),
        sliver: SliverToBoxAdapter(
          child: _ResultSummary(page: page, filters: filters),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        sliver: SliverIgnorePointer(
          // Old cards fade and can't be tapped while a new page loads.
          ignoring: value.isLoading,
          sliver: SliverAnimatedOpacity(
            opacity: value.isLoading ? 0.5 : 1,
            duration: const Duration(milliseconds: 150),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 316,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => KeyedSubtree(
                  key: ValueKey(page.products[index].id),
                  child: widget.cardBuilder(context, page.products[index]),
                ),
                childCount: page.products.length,
              ),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 16, gutter, widget.bottomPadding),
        sliver: SliverToBoxAdapter(
          child: PaginationBar(
            page: page.page,
            totalPages: page.totalPages,
            onPageSelected: (number) {
              if (number != page.page) notifier.goToPage(number);
            },
          ),
        ),
      ),
    ];
  }
}

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filters = ref.watch(catalogFiltersProvider);
    final notifier = ref.read(catalogFiltersProvider.notifier);

    final categories = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        InlineAsyncView(
          value: ref.watch(categoriesProvider),
          onRetry: () => ref.invalidate(categoriesProvider),
          data: (categories) => CategoryFilter(
            categories: categories,
            selectedId: filters.categoryId,
            onSelected: notifier.selectCategory,
          ),
        ),
      ],
    );
    final price = InlineAsyncView(
      value: ref.watch(priceBoundsProvider),
      onRetry: () => ref.invalidate(priceBoundsProvider),
      data: (bounds) => bounds == null
          ? const SizedBox.shrink()
          : PriceFilter(
              bounds: bounds,
              selected: filters.price ?? bounds,
              onChanged: notifier.selectPrice,
            ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const SearchField(),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: categories),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                SizedBox(width: 320, child: price),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SearchField(),
              const SizedBox(height: 16),
              categories,
              const SizedBox(height: 16),
              price,
            ],
          );
        },
      ),
    );
  }
}

class _ResultSummary extends ConsumerWidget {
  const _ResultSummary({required this.page, required this.filters});

  final ProductPage page;
  final CatalogFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = page.firstShown == page.lastShown
        ? '${page.firstShown}'
        : '${page.firstShown}–${page.lastShown}';
    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $shown of ${page.totalCount} products · '
            'Page ${page.page} of ${page.totalPages}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        if (filters.isFiltering)
          TextButton.icon(
            onPressed: ref.read(catalogFiltersProvider.notifier).clear,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Clear filters'),
          ),
      ],
    );
  }
}
