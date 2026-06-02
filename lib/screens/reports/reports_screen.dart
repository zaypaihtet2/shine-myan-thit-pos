import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/database/database_tables.dart';
import '../../core/utils/formatters.dart';
import '../../providers/settings_provider.dart';
import '../../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  DateTime from = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime to = DateTime.now();
  List<Map<String, Object?>> rows = <Map<String, Object?>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final String currency = context.watch<SettingsProvider>().currencySymbol;

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
                        'Reports',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quick day range summary, profit view, and export tools.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _HeroStat(label: 'Rows', value: '${rows.length}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton(
                    onPressed: _setToday,
                    child: const Text('Today'),
                  ),
                  OutlinedButton(
                    onPressed: _setYesterday,
                    child: const Text('Yesterday'),
                  ),
                  OutlinedButton(
                    onPressed: _setThisWeek,
                    child: const Text('This Week'),
                  ),
                  OutlinedButton(
                    onPressed: _setThisMonth,
                    child: const Text('This Month'),
                  ),
                  FilledButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range),
                    label: const Text('Custom Date'),
                  ),
                  FilledButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'From: ${Formatters.date(from)}  To: ${Formatters.date(to)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: rows.isEmpty
                ? _EmptyState(
                    icon: Icons.analytics_outlined,
                    text: 'No report rows in this date range.',
                  )
                : ListView(
                    children: <Widget>[
                      _summaryCard(currency),
                      const SizedBox(height: 12),
                      Text(
                        'Sales List',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...rows.map(
                        (Map<String, Object?> r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                '${r['invoice_no']} - ${r['payment_method']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text('${r['sale_date']}'),
                              trailing: Text(
                                Formatters.money(
                                  (r['final_total'] as num? ?? 0),
                                  symbol: currency,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String currency) {
    final double totalSales = rows.fold<double>(
      0,
      (double a, Map<String, Object?> b) =>
          a + ((b['final_total'] as num? ?? 0).toDouble()),
    );
    final double totalProfit = rows.fold<double>(
      0,
      (double a, Map<String, Object?> b) =>
          a + ((b['profit_amount'] as num? ?? 0).toDouble()),
    );
    final double totalCd = rows.fold<double>(
      0,
      (double a, Map<String, Object?> b) =>
          a + ((b['customer_cd_amount'] as num? ?? 0).toDouble()),
    );
    final double totalCashback = rows.fold<double>(
      0,
      (double a, Map<String, Object?> b) =>
          a + ((b['company_cashback_amount'] as num? ?? 0).toDouble()),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Daily / Monthly / Profit / CD / Owner Cashback / Payment Report',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _MetricBox(
                  'Sales',
                  Formatters.money(totalSales, symbol: currency),
                  Icons.payments_outlined,
                ),
                _MetricBox(
                  'Profit',
                  Formatters.money(totalProfit, symbol: currency),
                  Icons.trending_up,
                ),
                _MetricBox(
                  'Customer CD',
                  Formatters.money(totalCd, symbol: currency),
                  Icons.percent,
                ),
                _MetricBox(
                  'Owner Cashback',
                  Formatters.money(totalCashback, symbol: currency),
                  Icons.redeem_outlined,
                ),
                _MetricBox(
                  'Total Invoices',
                  '${rows.length}',
                  Icons.receipt_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Owner cashback is already included in profit.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    rows = await _db.rawQuery(
      'SELECT * FROM ${DatabaseTables.sales} WHERE sale_date >= ? AND sale_date <= ? ORDER BY id DESC',
      <Object?>[from.toIso8601String(), to.toIso8601String()],
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: from, end: to),
    );
    if (range == null) return;
    from = DateTime(range.start.year, range.start.month, range.start.day);
    to = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    await _load();
  }

  Future<void> _exportCsv() async {
    final List<List<Object?>> csvRows = <List<Object?>>[
      <Object?>[
        'Invoice',
        'Subtotal',
        'Discount',
        'Customer CD %',
        'Customer CD Amount',
        'Owner Cashback',
        'Final Total',
        'Profit',
        'Payment',
        'Date',
      ],
      ...rows.map(
        (Map<String, Object?> e) => <Object?>[
          e['invoice_no'],
          e['subtotal'],
          e['discount_amount'],
          e['customer_cd_percent'],
          e['customer_cd_amount'],
          e['company_cashback_amount'],
          e['final_total'],
          e['profit_amount'],
          e['payment_method'],
          e['sale_date'],
        ],
      ),
    ];
    final String? file = await ReportService().exportCsv(
      fileName: 'sales_report',
      rows: csvRows,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(file == null ? 'Canceled' : 'Exported: $file')),
    );
  }

  Future<void> _setToday() async {
    final DateTime now = DateTime.now();
    from = DateTime(now.year, now.month, now.day);
    to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    await _load();
  }

  Future<void> _setYesterday() async {
    final DateTime y = DateTime.now().subtract(const Duration(days: 1));
    from = DateTime(y.year, y.month, y.day);
    to = DateTime(y.year, y.month, y.day, 23, 59, 59);
    await _load();
  }

  Future<void> _setThisWeek() async {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: now.weekday - 1));
    from = DateTime(start.year, start.month, start.day);
    to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    await _load();
  }

  Future<void> _setThisMonth() async {
    final DateTime now = DateTime.now();
    from = DateTime(now.year, now.month, 1);
    to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    await _load();
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

class _MetricBox extends StatelessWidget {
  const _MetricBox(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
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
