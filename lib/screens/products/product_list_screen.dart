import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../models/company_model.dart';
import '../../models/product_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/product_provider.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductProvider products = context.watch<ProductProvider>();
    final List<CategoryModel> categories =
        context.watch<CategoryProvider>().categories;
    final List<CompanyModel> companies =
        context.watch<CompanyProvider>().companies;
    final List<ProductModel> filtered = products.filtered;
    final int lowStockCount = filtered
        .where(
          (ProductModel p) =>
              p.stockQuantity <= p.lowStockAlertQuantity,
        )
        .length;
    final int expiredCount =
        filtered.where((ProductModel p) => p.isExpired).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF0F5132), Color(0xFF1F7A4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Products',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage stock, expiry dates, pricing, FOC, and optional internal product codes.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProductFormScreen(),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              SizedBox(
                width: 420,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search product name, SKU, or expiry date',
                  ),
                  onChanged: products.setSearch,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  initialValue: products.categoryFilter,
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map(
                      (CategoryModel category) => DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: products.setCategoryFilter,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  initialValue: products.companyFilter,
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Companies'),
                    ),
                    ...companies.map(
                      (CompanyModel company) => DropdownMenuItem<int?>(
                        value: company.id,
                        child: Text(company.name),
                      ),
                    ),
                  ],
                  onChanged: products.setCompanyFilter,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  title: 'Visible',
                  value: '${filtered.length}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Low Stock',
                  value: '$lowStockCount',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Expired',
                  value: '$expiredCount',
                  icon: Icons.event_busy_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Companies',
                  value: '${companies.length}',
                  icon: Icons.apartment_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(
                    onClearFilters: () {
                      products.setSearch('');
                      products.setCategoryFilter(null);
                      products.setCompanyFilter(null);
                    },
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int index) {
                      final ProductModel product = filtered[index];
                      final bool lowStock = product.stockQuantity <=
                          product.lowStockAlertQuantity;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _ProductThumb(product: product),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            product.productName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        if (product.discountPercent > 0)
                                          _Badge(
                                            label:
                                                '${product.discountPercent.toStringAsFixed(0)}% DISCOUNT',
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                          ),
                                        if (product.isExpired) ...<Widget>[
                                          const SizedBox(width: 8),
                                          const _Badge(
                                            label: 'EXPIRED',
                                            color: Color(0xFFFFCDD2),
                                            foreground: Color(0xFF8B0000),
                                          ),
                                        ],
                                        if (lowStock) ...<Widget>[
                                          const SizedBox(width: 8),
                                          const _Badge(
                                            label: 'LOW STOCK',
                                            color: Color(0xFFFFE0B2),
                                            foreground: Color(0xFF8A4B00),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        _InfoChip(
                                          icon: Icons.sell_outlined,
                                          label:
                                              'Price ${product.sellingPrice.toStringAsFixed(2)}',
                                        ),
                                        _InfoChip(
                                          icon: Icons.inventory_2_outlined,
                                          label: 'Stock ${product.stockQuantity}',
                                          emphasized: lowStock,
                                        ),
                                        _InfoChip(
                                          icon: Icons.tag_outlined,
                                          label: product.sku?.trim().isNotEmpty ==
                                                  true
                                              ? 'SKU ${product.sku}'
                                              : 'No internal code',
                                        ),
                                        _InfoChip(
                                          icon: product.isExpired
                                              ? Icons.event_busy_outlined
                                              : Icons.event_outlined,
                                          label: product.expiryDate == null
                                              ? 'No expiry date'
                                              : 'Expiry ${product.expiryDate}',
                                          emphasized: product.isExpired,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Category: ${_nameForCategory(categories, product.categoryId)} | '
                                      'Company: ${_nameForCompany(companies, product.companyId)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  FilledButton.tonalIcon(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductFormScreen(
                                          product: product,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, product),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _nameForCategory(
    List<CategoryModel> categories,
    int? categoryId,
  ) {
    for (final CategoryModel category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'No Category';
  }

  String _nameForCompany(List<CompanyModel> companies, int? companyId) {
    for (final CompanyModel company in companies) {
      if (company.id == companyId) return company.name;
    }
    return 'No Company';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductModel product,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'This will remove ${product.productName} from the product list.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<ProductProvider>().delete(product.id!);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.foreground,
  });

  final String label;
  final Color color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: foreground ??
              Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Color background = emphasized
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color foreground = emphasized
        ? Theme.of(context).colorScheme.onErrorContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 84,
        height: 84,
        child: product.imagePath != null &&
                File(product.imagePath!).existsSync()
            ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.medication_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 34,
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.inventory_2_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No products found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try changing the search or filters, or add a new product.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
