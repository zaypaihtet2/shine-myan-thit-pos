import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  ProductModel? selected;
  final TextEditingController _qty = TextEditingController(text: '1');
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProductProvider provider = context.watch<ProductProvider>();
    final int lowStockCount = provider.products.where((ProductModel p) {
      return p.stockQuantity <= p.lowStockAlertQuantity;
    }).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  const Color(0xFF0F5132),
                  const Color(0xFF1F7A4D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
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
                        'Stock Management',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add stock in or out, and quickly spot low-stock items.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _HeroStat(
                  label: 'Products',
                  value: '${provider.products.length}',
                ),
                const SizedBox(width: 10),
                _HeroStat(label: 'Low Stock', value: '$lowStockCount'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          initialValue: selected?.id,
                          hint: const Text('Select Product'),
                          items: provider.products
                              .map(
                                (ProductModel p) => DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(
                                    '${p.productName}  •  Stock ${p.stockQuantity}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (int? id) => setState(() {
                            selected = id == null
                                ? null
                                : provider.products.firstWhere(
                                    (ProductModel p) => p.id == id,
                                  );
                          }),
                          decoration: const InputDecoration(
                            labelText: 'Product',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _qty,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Qty',
                            prefixIcon: Icon(
                              Icons.confirmation_number_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _note,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            prefixIcon: Icon(Icons.sticky_note_2_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: selected == null
                              ? null
                              : () => _submit(isIn: true),
                          icon: const Icon(Icons.add_box_outlined),
                          label: const Text('Stock In'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selected == null
                              ? null
                              : () => _submit(isIn: false),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Stock Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: provider.products.isEmpty
                ? _EmptyState(
                    text: 'No products yet.',
                    icon: Icons.inventory_2_outlined,
                  )
                : ListView.separated(
                    itemCount: provider.products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int i) {
                      final ProductModel p = provider.products[i];
                      final bool low =
                          p.stockQuantity <= p.lowStockAlertQuantity;
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            p.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: <Widget>[
                              _InfoPill('Stock ${p.stockQuantity}', low: low),
                              _InfoPill('Low alert ${p.lowStockAlertQuantity}'),
                              if (p.discountPercent > 0)
                                _InfoPill(
                                  '${p.discountPercent.toStringAsFixed(0)}% OFF',
                                ),
                            ],
                          ),
                          trailing: Text(
                            'Sell ${p.sellingPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
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

  Future<void> _submit({required bool isIn}) async {
    if (selected == null) return;
    try {
      await context.read<ProductProvider>().stockInOut(
        product: selected!,
        qty: int.tryParse(_qty.text) ?? 0,
        isStockIn: isIn,
        note: _note.text,
      );
      _note.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stock updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.text, {this.low = false});

  final String text;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final Color bg = low
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color fg = low
        ? Theme.of(context).colorScheme.onErrorContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 48),
              const SizedBox(height: 10),
              Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
