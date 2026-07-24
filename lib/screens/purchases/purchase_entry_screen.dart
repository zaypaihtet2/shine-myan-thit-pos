import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';
import 'purchase_entry_form_screen.dart';

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final PurchaseProvider provider = context.watch<PurchaseProvider>();
    final String currency = context.watch<SettingsProvider>().currencySymbol;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF0F5132), Color(0xFF1F7A4D)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Purchase Entries',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Record supplier purchases and update product stock automatically.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('New Purchase'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  title: 'Entries',
                  value: '${provider.purchases.length}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Purchased Qty',
                  value: '${provider.totalPurchasedQuantity}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Purchase Value',
                  value: Formatters.money(
                    provider.totalPurchaseValue,
                    symbol: currency,
                  ),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMonthlyCashback(context, provider, currency),
          const SizedBox(height: 14),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.purchases.isEmpty
                ? Center(
                    child: FilledButton.icon(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Purchase'),
                    ),
                  )
                : ListView.separated(
                    itemCount: provider.purchases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int index) {
                      final Map<String, Object?> row =
                          provider.purchases[index];
                      final int purchaseId = (row['id'] as num).toInt();
                      final String reference = '${row['reference_no'] ?? ''}'
                          .trim();
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.move_to_inbox_outlined),
                          ),
                          title: Text(
                            '${row['purchase_no']} - ${row['supplier_name']}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${row['purchase_date']} | '
                            '${(row['item_count'] as num? ?? 0).toInt()} products | '
                            '${(row['total_quantity'] as num? ?? 0).toInt()} qty'
                            '${reference.isEmpty ? '' : ' | Ref: $reference'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                Formatters.money(
                                  row['total_amount'] as num? ?? 0,
                                  symbol: currency,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Delete purchase and reduce stock',
                                onPressed: () => _deletePurchase(
                                  context,
                                  purchaseId,
                                  '${row['purchase_no']}',
                                ),
                                color: Theme.of(context).colorScheme.error,
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          onTap: () =>
                              _showDetail(context, purchaseId, currency),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCashback(
    BuildContext context,
    PurchaseProvider provider,
    String currency,
  ) {
    final Map<String, double> cashbackByCompany = <String, double>{};
    for (final Map<String, Object?> row in provider.purchases) {
      final DateTime? date = DateTime.tryParse('${row['purchase_date'] ?? ''}');
      if (date == null ||
          date.year != _selectedMonth.year ||
          date.month != _selectedMonth.month) {
        continue;
      }
      final String company = '${row['supplier_name'] ?? ''}'.trim();
      if (company.isEmpty) continue;
      final double amount = (row['cashback_amount'] as num? ?? 0).toDouble();
      cashbackByCompany[company] = (cashbackByCompany[company] ?? 0) + amount;
    }
    final List<MapEntry<String, double>> entries =
        cashbackByCompany.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
            return b.value.compareTo(a.value);
          });
    final double total = entries.fold<double>(
      0,
      (double sum, MapEntry<String, double> entry) => sum + entry.value,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.savings_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monthly Company Cashback',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  }),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  _monthLabel(_selectedMonth),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () => setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  }),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const Divider(height: 18),
            if (entries.isEmpty)
              Text(
                'No company cashback recorded for this month.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...<Widget>[
              ...entries.map(
                (MapEntry<String, double> entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(entry.key)),
                      Text(
                        Formatters.money(entry.value, symbol: currency),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const Text(
                    'Total Cashback: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    Formatters.money(total, symbol: currency),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthLabel(DateTime month) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  Future<void> _deletePurchase(
    BuildContext context,
    int purchaseId,
    String purchaseNo,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete $purchaseNo?'),
        content: const Text(
          'This will delete the purchase and reduce the purchased quantities from stock. Continue?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<PurchaseProvider>().deletePurchase(purchaseId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase deleted and stock reduced')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _openForm(BuildContext context) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PurchaseEntryFormScreen()),
    );
    if (saved == true && context.mounted) {
      await context.read<PurchaseProvider>().load();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase saved and stock updated')),
      );
    }
  }

  Future<void> _showDetail(
    BuildContext context,
    int purchaseId,
    String currency,
  ) async {
    try {
      final Map<String, Object?> result = await context
          .read<PurchaseProvider>()
          .detail(purchaseId);
      if (!context.mounted) return;
      final Map<String, Object?> purchase =
          result['purchase'] as Map<String, Object?>;
      final List<Map<String, Object?>> items = (result['items'] as List)
          .cast<Map<String, Object?>>();

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text('${purchase['purchase_no']} Details'),
          content: SizedBox(
            width: 650,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Text('Supplier: ${purchase['supplier_name']}'),
                Text('Date: ${purchase['purchase_date']}'),
                if ('${purchase['reference_no'] ?? ''}'.trim().isNotEmpty)
                  Text('Reference: ${purchase['reference_no']}'),
                if ('${purchase['note'] ?? ''}'.trim().isNotEmpty)
                  Text('Note: ${purchase['note']}'),
                const Divider(height: 24),
                ...items.map(
                  (Map<String, Object?> item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['product_name']}'),
                    subtitle: Text(
                      'Paid ${item['quantity']} + FOC ${item['foc_quantity'] ?? 0} x '
                      '${Formatters.money(item['unit_cost'] as num? ?? 0, symbol: currency)}'
                      ' | Stock ${item['old_stock']} to ${item['new_stock']}',
                    ),
                    trailing: Text(
                      Formatters.money(
                        item['line_total'] as num? ?? 0,
                        symbol: currency,
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Subtotal: ${Formatters.money(purchase['subtotal_amount'] as num? ?? purchase['total_amount'] as num? ?? 0, symbol: currency)}',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Company Cashback ${purchase['cashback_percent'] ?? 0}%: '
                    '${Formatters.money(purchase['cashback_amount'] as num? ?? 0, symbol: currency)}',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Final Total: ${Formatters.money(purchase['final_total'] as num? ?? purchase['total_amount'] as num? ?? 0, symbol: currency)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
