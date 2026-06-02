import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/sale_model.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import 'sale_detail_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _invoiceSearch = TextEditingController();

  @override
  void dispose() {
    _invoiceSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SalesProvider sales = context.watch<SalesProvider>();
    final String currency = context.watch<SettingsProvider>().currencySymbol;
    final int returnCount = sales.sales.where((SaleModel s) {
      return s.saleType == 'return';
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
                        'Sales History',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Search invoices, inspect totals, and open detailed receipts.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _HeroStat(label: 'Sales', value: '${sales.sales.length}'),
                const SizedBox(width: 10),
                _HeroStat(label: 'Returns', value: '$returnCount'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _invoiceSearch,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search invoice number',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () =>
                        sales.load(invoiceQuery: _invoiceSearch.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: sales.sales.isEmpty
                ? _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    text: 'No sales found.',
                  )
                : ListView.separated(
                    itemCount: sales.sales.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int i) {
                      final SaleModel s = sales.sales[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  s.saleType == 'return'
                                      ? Icons.assignment_return_outlined
                                      : Icons.receipt_long_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          s.invoiceNo,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (s.saleType == 'return')
                                          const _ChipBadge(
                                            text: 'RETURN',
                                            background: Color(0xFFFFE0E0),
                                            foreground: Color(0xFF9B1C1C),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Date: ${s.saleDate}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Payment: ${s.paymentMethod}  •  Profit: ${Formatters.money(s.profitAmount, symbol: currency)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    Formatters.money(
                                      s.finalTotal,
                                      symbol: currency,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      FilledButton.tonalIcon(
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    SaleDetailScreen(
                                                      saleId: s.id!,
                                                    ),
                                              ),
                                            ),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        label: const Text('View'),
                                      ),
                                      if (s.saleType == 'sale') ...<Widget>[
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () => _delete(s.id!),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Delete'),
                                        ),
                                      ],
                                    ],
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

  Future<void> _delete(int saleId) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sale'),
        content: const Text('Delete this sale and revert stock?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (!mounted) return;
      await context.read<SalesProvider>().deleteSale(saleId);
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

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
