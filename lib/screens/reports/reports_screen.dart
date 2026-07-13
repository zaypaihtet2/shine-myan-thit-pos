import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/database/database_tables.dart';
import '../../core/utils/formatters.dart';
import '../../providers/settings_provider.dart';
import '../../services/report_service.dart';
import '../sales/sale_detail_screen.dart';

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
  DateTime to = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    23,
    59,
    59,
  );

  List<Map<String, Object?>> rows = <Map<String, Object?>>[];
  Map<String, double> companyCashback = <String, double>{};
  bool loading = false;
  String selectedRange = 'Today';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final String currency = context.watch<SettingsProvider>().currencySymbol;
    final _ReportTotals totals = _calculateTotals();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHero(context, currency, totals),
          const SizedBox(height: 14),
          _buildFilters(context),
          const SizedBox(height: 14),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                ? const _EmptyState(
                    icon: Icons.analytics_outlined,
                    text: 'No report records in this date range.',
                  )
                : ListView(
                    children: <Widget>[
                      _buildMetricGrid(context, currency, totals),
                      const SizedBox(height: 18),
                      _buildDoctorCashbackBreakdown(context, currency),
                      const SizedBox(height: 18),
                      _buildCompanyCashbackBreakdown(context, currency),
                      const SizedBox(height: 18),
                      _buildSalesHeader(context),
                      const SizedBox(height: 10),
                      ...rows.map(
                        (Map<String, Object?> row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReportSaleCard(
                            row: row,
                            currency: currency,
                            onView: _isNormalSale(row)
                                ? () => _openVoucher(row)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    String currency,
    _ReportTotals totals,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0B5D3B), Color(0xFF1B8A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0B5D3B).withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Sales Reports',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$selectedRange  •  ${Formatters.date(from)} to ${Formatters.date(to)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _HeroValue(label: 'Invoices', value: '${totals.invoiceCount}'),
          const SizedBox(width: 10),
          _HeroValue(
            label: 'Net Sales',
            value: Formatters.money(totals.netSales, symbol: currency),
            wide: true,
          ),
          const SizedBox(width: 10),
          _HeroValue(
            label: 'Net Profit',
            value: Formatters.money(totals.remainingProfit, symbol: currency),
            wide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _RangeButton(
                    label: 'Today',
                    selected: selectedRange == 'Today',
                    onPressed: _setToday,
                  ),
                  _RangeButton(
                    label: 'Yesterday',
                    selected: selectedRange == 'Yesterday',
                    onPressed: _setYesterday,
                  ),
                  _RangeButton(
                    label: 'This Week',
                    selected: selectedRange == 'This Week',
                    onPressed: _setThisWeek,
                  ),
                  _RangeButton(
                    label: 'This Month',
                    selected: selectedRange == 'This Month',
                    onPressed: _setThisMonth,
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: const Text('Custom Date'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export CSV'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(
    BuildContext context,
    String currency,
    _ReportTotals totals,
  ) {
    final List<_MetricData> metrics = <_MetricData>[
      _MetricData(
        title: 'Net Sales',
        value: Formatters.money(totals.netSales, symbol: currency),
        subtitle: 'Sales after returns',
        icon: Icons.payments_outlined,
        colors: const <Color>[Color(0xFF176B45), Color(0xFF2B9B67)],
      ),
      _MetricData(
        title: 'My Remaining Profit',
        value: Formatters.money(totals.remainingProfit, symbol: currency),
        subtitle: 'Profit after cashback and cost',
        icon: Icons.savings_outlined,
        colors: const <Color>[Color(0xFF075985), Color(0xFF0EA5E9)],
      ),
      _MetricData(
        title: 'Payable To Office',
        value: Formatters.money(totals.officePayable, symbol: currency),
        subtitle: 'Amount payable after owner cashback',
        icon: Icons.account_balance_outlined,
        colors: const <Color>[Color(0xFF5B21B6), Color(0xFF8B5CF6)],
      ),
      _MetricData(
        title: 'Owner Cashback',
        value: Formatters.money(totals.ownerCashback, symbol: currency),
        subtitle: 'Cashback received from companies',
        icon: Icons.redeem_outlined,
        colors: const <Color>[Color(0xFF9A3412), Color(0xFFF97316)],
      ),
      _MetricData(
        title: 'Doctor Cashback',
        value: Formatters.money(totals.doctorCashback, symbol: currency),
        subtitle: 'Cashback paid to doctors',
        icon: Icons.local_hospital_outlined,
        colors: const <Color>[Color(0xFF9F1239), Color(0xFFE11D48)],
      ),
      _MetricData(
        title: 'Customer CD',
        value: Formatters.money(totals.customerCd, symbol: currency),
        subtitle: 'CD discount total',
        icon: Icons.percent_outlined,
        colors: const <Color>[Color(0xFF854D0E), Color(0xFFEAB308)],
      ),
      _MetricData(
        title: 'Rebate',
        value: Formatters.money(totals.rebate, symbol: currency),
        subtitle: 'Customer rebate total',
        icon: Icons.discount_outlined,
        colors: const <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)],
      ),
      _MetricData(
        title: 'Returns',
        value: Formatters.money(totals.returnAmount.abs(), symbol: currency),
        subtitle: '${totals.returnCount} return record(s)',
        icon: Icons.assignment_return_outlined,
        colors: const <Color>[Color(0xFF7F1D1D), Color(0xFFDC2626)],
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 1250
            ? 4
            : width >= 850
            ? 3
            : 2;
        final double cardWidth = (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (_MetricData metric) => SizedBox(
                  width: cardWidth,
                  child: _ColorMetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSalesHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Sales Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${rows.length} record(s)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 180,
                child: Text('DATE', style: _columnStyle(context)),
              ),
              Expanded(
                flex: 4,
                child: Text('CUSTOMER', style: _columnStyle(context)),
              ),
              Expanded(
                flex: 2,
                child: Text('AMOUNT', style: _columnStyle(context)),
              ),
              Expanded(
                flex: 2,
                child: Text('PROFIT / OFFICE', style: _columnStyle(context)),
              ),
              const SizedBox(width: 150),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCashbackBreakdown(BuildContext context, String currency) {
    final Map<String, double> byDoctor = <String, double>{};
    for (final Map<String, Object?> row in rows) {
      final double cashback = _number(row['customer_cashback_amount']);
      if (cashback == 0) continue;
      final String name = '${row['customer_name'] ?? ''}'.trim();
      final String doctor = name.isEmpty ? 'Unknown Doctor' : name;
      byDoctor[doctor] = (byDoctor[doctor] ?? 0) + cashback;
    }
    if (byDoctor.isEmpty) return const SizedBox.shrink();

    final List<MapEntry<String, double>> entries = byDoctor.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
        return b.value.compareTo(a.value);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Doctor Cashback by Doctor',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...entries.map(
              (MapEntry<String, double> entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.local_hospital_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.key)),
                    Text(
                      Formatters.money(entry.value, symbol: currency),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCashbackBreakdown(BuildContext context, String currency) {
    if (companyCashback.isEmpty) return const SizedBox.shrink();
    final List<MapEntry<String, double>> entries =
        companyCashback.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
            return b.value.compareTo(a.value);
          });
    final double total = entries.fold<double>(
      0,
      (double sum, MapEntry<String, double> entry) => sum + entry.value,
    );
    const List<List<Color>> palettes = <List<Color>>[
      <Color>[Color(0xFF0E7490), Color(0xFF06B6D4)],
      <Color>[Color(0xFF6D28D9), Color(0xFF8B5CF6)],
      <Color>[Color(0xFFB45309), Color(0xFFF59E0B)],
      <Color>[Color(0xFF047857), Color(0xFF10B981)],
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.apartment_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Company Cashback',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Cashback earned from each company',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.money(total, symbol: currency),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                const double gap = 10;
                final double width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: entries.asMap().entries.map((
                    MapEntry<int, MapEntry<String, double>> item,
                  ) {
                    final MapEntry<String, double> entry = item.value;
                    final double percent = total == 0
                        ? 0
                        : entry.value * 100 / total;
                    final List<Color> colors =
                        palettes[item.key % palettes.length];
                    return SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.business_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Formatters.money(entry.value, symbol: currency),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${percent.toStringAsFixed(1)}% of total cashback',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _columnStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.6,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  _ReportTotals _calculateTotals() {
    double netSales = 0;
    double profit = 0;
    double customerCd = 0;
    double rebate = 0;
    double doctorCashback = 0;
    double ownerCashback = 0;
    double officePayable = 0;
    double remainingProfit = 0;
    double returnAmount = 0;
    int invoiceCount = 0;
    int returnCount = 0;

    for (final Map<String, Object?> row in rows) {
      final bool isReturn = '${row['sale_type'] ?? 'sale'}' == 'return';
      final double finalTotal = _number(row['final_total']);
      final double companyCashback = _number(row['company_cashback_amount']);
      final double rowProfit = _number(row['profit_amount']);

      netSales += finalTotal;
      profit += rowProfit;
      customerCd += _number(row['customer_cd_amount']);
      rebate += _number(row['rebate_amount']);
      doctorCashback += _number(row['customer_cashback_amount']);
      ownerCashback += companyCashback;
      officePayable += _numberOrFallback(
        row['office_payable_amount'],
        finalTotal - companyCashback,
      );
      remainingProfit += _numberOrFallback(row['owner_keep_profit'], rowProfit);

      if (isReturn) {
        returnCount += 1;
        returnAmount += finalTotal;
      } else {
        invoiceCount += 1;
      }
    }

    return _ReportTotals(
      netSales: netSales,
      profit: profit,
      customerCd: customerCd,
      rebate: rebate,
      doctorCashback: doctorCashback,
      ownerCashback: ownerCashback,
      officePayable: officePayable,
      remainingProfit: remainingProfit,
      returnAmount: returnAmount,
      invoiceCount: invoiceCount,
      returnCount: returnCount,
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => loading = true);
    }
    rows = await _db.rawQuery(
      'SELECT * FROM ${DatabaseTables.sales} '
      'WHERE sale_date >= ? AND sale_date <= ? '
      'ORDER BY sale_date DESC, id DESC',
      <Object?>[from.toIso8601String(), to.toIso8601String()],
    );
    final List<Map<String, Object?>> companyRows = await _db.rawQuery(
      '''SELECT COALESCE(c.name, 'Unknown Company') AS company_name,
        COALESCE(SUM(i.company_cashback_amount), 0) AS cashback
      FROM ${DatabaseTables.saleItems} i
      INNER JOIN ${DatabaseTables.sales} s ON s.id = i.sale_id
      LEFT JOIN ${DatabaseTables.companies} c ON c.id = i.company_id
      WHERE s.sale_date >= ? AND s.sale_date <= ?
      GROUP BY company_name
      ORDER BY cashback DESC''',
      <Object?>[from.toIso8601String(), to.toIso8601String()],
    );
    companyCashback = <String, double>{
      for (final Map<String, Object?> row in companyRows)
        '${row['company_name']}': _number(row['cashback']),
    };
    if (mounted) {
      setState(() => loading = false);
    }
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
    selectedRange = 'Custom Date';
    await _load();
  }

  Future<void> _exportCsv() async {
    final List<List<Object?>> csvRows = <List<Object?>>[
      <Object?>[
        'Invoice',
        'Customer Name',
        'Customer Type',
        'Subtotal',
        'Discount',
        'Customer CD %',
        'Customer CD Amount',
        'Rebate Amount',
        'Doctor Cashback',
        'Owner Cashback',
        'Payable To Office',
        'Final Total',
        'Profit',
        'My Remaining Profit',
        'Payment',
        'Date',
      ],
      ...rows.map(
        (Map<String, Object?> row) => <Object?>[
          row['invoice_no'],
          row['customer_name'],
          row['customer_type'],
          row['subtotal'],
          row['discount_amount'],
          row['customer_cd_percent'],
          row['customer_cd_amount'],
          row['rebate_amount'],
          row['customer_cashback_amount'],
          row['company_cashback_amount'],
          row['office_payable_amount'] ??
              (_number(row['final_total']) -
                  _number(row['company_cashback_amount'])),
          row['final_total'],
          row['profit_amount'],
          row['owner_keep_profit'] ?? row['profit_amount'],
          row['payment_method'],
          row['sale_date'],
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
    selectedRange = 'Today';
    await _load();
  }

  Future<void> _setYesterday() async {
    final DateTime day = DateTime.now().subtract(const Duration(days: 1));
    from = DateTime(day.year, day.month, day.day);
    to = DateTime(day.year, day.month, day.day, 23, 59, 59);
    selectedRange = 'Yesterday';
    await _load();
  }

  Future<void> _setThisWeek() async {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: now.weekday - 1));
    from = DateTime(start.year, start.month, start.day);
    to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    selectedRange = 'This Week';
    await _load();
  }

  Future<void> _setThisMonth() async {
    final DateTime now = DateTime.now();
    from = DateTime(now.year, now.month, 1);
    to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    selectedRange = 'This Month';
    await _load();
  }

  void _openVoucher(Map<String, Object?> row) {
    final int? saleId = (row['id'] as num?)?.toInt();
    if (saleId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SaleDetailScreen(saleId: saleId)),
    );
  }

  bool _isNormalSale(Map<String, Object?> row) {
    return '${row['sale_type'] ?? 'sale'}' == 'sale';
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static double _numberOrFallback(Object? value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }
}

class _ReportSaleCard extends StatelessWidget {
  const _ReportSaleCard({
    required this.row,
    required this.currency,
    required this.onView,
  });

  final Map<String, Object?> row;
  final String currency;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final bool isReturn = '${row['sale_type'] ?? 'sale'}' == 'return';
    final String customer = '${row['customer_name'] ?? ''}'.trim().isEmpty
        ? 'Walk-in Customer'
        : '${row['customer_name']}';
    final double amount = _number(row['final_total']);
    final double profit = _numberOrFallback(
      row['owner_keep_profit'],
      _number(row['profit_amount']),
    );
    final double officePayable = _numberOrFallback(
      row['office_payable_amount'],
      amount - _number(row['company_cashback_amount']),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 6,
                color: isReturn
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16804F),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _datePart('${row['sale_date'] ?? ''}'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _timePart('${row['sale_date'] ?? ''}'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
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
                        if (isReturn) ...<Widget>[
                          const SizedBox(width: 8),
                          const _SmallBadge(
                            text: 'RETURN',
                            background: Color(0xFFFFE0E0),
                            foreground: Color(0xFF991B1B),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${row['invoice_no'] ?? ''}  •  ${_customerType('${row['customer_type'] ?? 'regular'}')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _PaymentBadge(method: '${row['payment_method'] ?? ''}'),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      Formatters.money(amount, symbol: currency),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isReturn
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      isReturn ? 'Returned amount' : 'Sale amount',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Profit: ${Formatters.money(profit, symbol: currency)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: profit < 0
                            ? Theme.of(context).colorScheme.error
                            : const Color(0xFF16804F),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Office: ${Formatters.money(officePayable, symbol: currency)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: onView == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: onView,
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Voucher'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _datePart(String raw) {
    final DateTime? date = DateTime.tryParse(raw);
    if (date == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _timePart(String raw) {
    final DateTime? date = DateTime.tryParse(raw);
    if (date == null) return '';
    final String period = date.hour >= 12 ? 'PM' : 'AM';
    final int hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '${hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')} $period';
  }

  static String _customerType(String value) {
    switch (value) {
      case 'office':
        return 'Office';
      case 'doctor':
        return 'Doctor';
      default:
        return 'Regular';
    }
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static double _numberOrFallback(Object? value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }
}

class _ColorMetricCard extends StatelessWidget {
  const _ColorMetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: metric.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: metric.colors.first.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(metric.icon, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Text(
                metric.title,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final bool credit = method == 'Credit';
    final bool returned = method == 'RETURN';
    final Color background = returned
        ? const Color(0xFFFFE0E0)
        : credit
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFDCFCE7);
    final Color foreground = returned
        ? const Color(0xFF991B1B)
        : credit
        ? const Color(0xFF9A3412)
        : const Color(0xFF166534);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        method.isEmpty ? 'Unknown' : method,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({
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
      constraints: BoxConstraints(minWidth: wide ? 170 : 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
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
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 58,
                color: Theme.of(context).colorScheme.primary,
              ),
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

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

class _ReportTotals {
  const _ReportTotals({
    required this.netSales,
    required this.profit,
    required this.customerCd,
    required this.rebate,
    required this.doctorCashback,
    required this.ownerCashback,
    required this.officePayable,
    required this.remainingProfit,
    required this.returnAmount,
    required this.invoiceCount,
    required this.returnCount,
  });

  final double netSales;
  final double profit;
  final double customerCd;
  final double rebate;
  final double doctorCashback;
  final double ownerCashback;
  final double officePayable;
  final double remainingProfit;
  final double returnAmount;
  final int invoiceCount;
  final int returnCount;
}
