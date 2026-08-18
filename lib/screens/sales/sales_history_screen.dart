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
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SalesProvider sales = context.watch<SalesProvider>();
    final String currency = context.watch<SettingsProvider>().currencySymbol;
    final int returnCount = sales.sales
        .where((SaleModel sale) => sale.saleType == 'return')
        .length;
    final double visibleAmount = sales.sales.fold<double>(0, (
      double sum,
      SaleModel sale,
    ) {
      if (sale.saleType == 'return') return sum - sale.finalTotal;
      final double outstanding = (sale.finalTotal - sale.paidAmount).clamp(
        0,
        double.infinity,
      );
      return sum + outstanding;
    });

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
                const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.white,
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sales History',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Date, customer and sale amount are shown first for quick checking.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                _HeroStat(label: 'Entries', value: '${sales.sales.length}'),
                const SizedBox(width: 10),
                _HeroStat(label: 'Returns', value: '$returnCount'),
                const SizedBox(width: 10),
                _HeroStat(
                  label: 'Unpaid Amount',
                  value: Formatters.money(visibleAmount, symbol: currency),
                  wide: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onSubmitted: (_) => _runSearch(sales),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search invoice, customer or date',
                        hintText: 'Example: INV-..., Customer Name, 2026-06-19',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => _runSearch(sales),
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      _search.clear();
                      sales.load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Show All'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _ColumnHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: sales.loading
                ? const Center(child: CircularProgressIndicator())
                : sales.sales.isEmpty
                ? const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    text: 'No sales found.',
                  )
                : ListView.separated(
                    itemCount: sales.sales.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int index) {
                      final SaleModel sale = sales.sales[index];
                      return _SaleHistoryCard(
                        sale: sale,
                        currency: currency,
                        onEditStatus: () => _editSettlementStatus(sale),
                        onView: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SaleDetailScreen(saleId: sale.id!),
                          ),
                        ),
                        onDelete: sale.saleType == 'sale'
                            ? () => _delete(sale.id!)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _runSearch(SalesProvider sales) {
    sales.load(invoiceQuery: _search.text);
  }

  Future<void> _delete(int saleId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Sale'),
        content: const Text(
          'Delete this sale and put all sold quantities back into stock?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SalesProvider>().deleteSale(saleId);
    }
  }

  Future<void> _editSettlementStatus(SaleModel sale) async {
    final bool? paid = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Update ${sale.invoiceNo} status'),
        content: const Text('Choose whether this transaction is settled.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Mark Unpaid'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
    if (paid != null && mounted) {
      await context.read<SalesProvider>().updateSettlementStatus(
        saleId: sale.id!,
        paid: paid,
      );
    }
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w900,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(width: 190, child: Text('DATE', style: style)),
          Expanded(flex: 3, child: Text('CUSTOMER', style: style)),
          Expanded(flex: 1, child: Text('STATUS', style: style)),
          Expanded(flex: 2, child: Text('AMOUNT', style: style)),
          const SizedBox(width: 210, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _SaleHistoryCard extends StatelessWidget {
  const _SaleHistoryCard({
    required this.sale,
    required this.currency,
    required this.onView,
    required this.onEditStatus,
    required this.onDelete,
  });

  final SaleModel sale;
  final String currency;
  final VoidCallback onView;
  final VoidCallback onEditStatus;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isReturn = sale.saleType == 'return';
    final String customer = (sale.customerName ?? '').trim().isEmpty
        ? 'Walk-in Customer'
        : sale.customerName!.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _datePart(sale.saleDate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timePart(sale.saleDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            customer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${sale.invoiceNo}  •  ${_customerTypeLabel(sale.customerType)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PaymentBadge(method: sale.paymentMethod),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: isReturn
                    ? const _ChipBadge(
                        text: 'RETURN',
                        background: Color(0xFFFFE0E0),
                        foreground: Color(0xFF9B1C1C),
                      )
                    : _SettlementBadge(
                        paid: sale.paidAmount >= sale.finalTotal,
                        onTap: onEditStatus,
                      ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (isReturn)
                      _AmountText(
                        amount: sale.finalTotal,
                        currency: currency,
                        label: 'Returned amount',
                        color: Theme.of(context).colorScheme.error,
                      )
                    else if (sale.paidAmount >= sale.finalTotal)
                      Text(
                        '—',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      )
                    else
                      _AmountText(
                        amount: (sale.finalTotal - sale.paidAmount)
                            .clamp(0, double.infinity)
                            .toDouble(),
                        currency: currency,
                        label: 'Outstanding balance',
                        color: Theme.of(context).colorScheme.error,
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 210,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View Voucher'),
                    ),
                    if (onDelete != null) ...<Widget>[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Delete sale',
                        onPressed: onDelete,
                        color: Theme.of(context).colorScheme.error,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _datePart(String raw) {
    final DateTime? value = DateTime.tryParse(raw);
    if (value == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String _timePart(String raw) {
    final DateTime? value = DateTime.tryParse(raw);
    if (value == null) return '';
    final int hour = value.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${displayHour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')} $period';
  }

  static String _customerTypeLabel(String type) {
    switch (type) {
      case 'office':
        return 'Office';
      case 'doctor':
        return 'Doctor';
      default:
        return 'Regular';
    }
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final bool isCredit = method == 'Credit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isCredit
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        method,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: isCredit
              ? Theme.of(context).colorScheme.onErrorContainer
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _SettlementBadge extends StatelessWidget {
  const _SettlementBadge({required this.paid, required this.onTap});

  final bool paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = paid
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEE2E2);
    final Color foreground = paid
        ? const Color(0xFF047857)
        : const Color(0xFFB91C1C);
    return Tooltip(
      message: 'Click to change status',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            paid ? 'PAID' : 'UNPAID',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({
    required this.amount,
    required this.currency,
    required this.label,
    required this.color,
  });

  final double amount;
  final String currency;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Formatters.money(amount, symbol: currency),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: wide ? 170 : 82),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
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
          fontWeight: FontWeight.w800,
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
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 52),
              const SizedBox(height: 12),
              Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
