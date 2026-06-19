import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';
import 'purchase_entry_form_screen.dart';

class PurchaseEntryScreen extends StatelessWidget {
  const PurchaseEntryScreen({super.key});

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
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, int index) {
                          final Map<String, Object?> row =
                              provider.purchases[index];
                          final int purchaseId = (row['id'] as num).toInt();
                          final String reference =
                              '${row['reference_no'] ?? ''}'.trim();
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${row['purchase_date']} | '
                                '${(row['item_count'] as num? ?? 0).toInt()} products | '
                                '${(row['total_quantity'] as num? ?? 0).toInt()} qty'
                                '${reference.isEmpty ? '' : ' | Ref: $reference'}',
                              ),
                              trailing: Text(
                                Formatters.money(
                                  row['total_amount'] as num? ?? 0,
                                  symbol: currency,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              onTap: () => _showDetail(
                                context,
                                purchaseId,
                                currency,
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

  Future<void> _openForm(BuildContext context) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const PurchaseEntryFormScreen(),
      ),
    );
    if (saved == true && context.mounted) {
      await context.read<PurchaseProvider>().load();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase saved and stock updated'),
        ),
      );
    }
  }

  Future<void> _showDetail(
    BuildContext context,
    int purchaseId,
    String currency,
  ) async {
    try {
      final Map<String, Object?> result =
          await context.read<PurchaseProvider>().detail(purchaseId);
      if (!context.mounted) return;
      final Map<String, Object?> purchase =
          result['purchase'] as Map<String, Object?>;
      final List<Map<String, Object?>> items =
          (result['items'] as List).cast<Map<String, Object?>>();

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
                      'Qty ${item['quantity']} x '
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
                    'Total: ${Formatters.money(purchase['total_amount'] as num? ?? 0, symbol: currency)}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
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
