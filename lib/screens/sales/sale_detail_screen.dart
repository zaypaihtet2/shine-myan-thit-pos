import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/pos_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/receipt_service.dart';
import 'sale_return_screen.dart';
import 'voucher_preview_screen.dart';

class SaleDetailScreen extends StatefulWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Map<String, Object?>? sale;
  List<Map<String, Object?>> items = <Map<String, Object?>>[];
  List<Map<String, Object?>> returns = <Map<String, Object?>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, Object?> detail = await context
        .read<PosProvider>()
        .saleDetail(widget.saleId);
    if (!mounted) return;
    final List<Map<String, Object?>> returnRows = await context
        .read<SalesProvider>()
        .saleReturnsBySaleId(widget.saleId);
    if (!mounted) return;
    setState(() {
      sale = detail['sale'] as Map<String, Object?>;
      items = (detail['items'] as List).cast<Map<String, Object?>>();
      returns = returnRows;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final String currency = settings.currencySymbol;
    if (sale == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isCredit = '${sale!['payment_method'] ?? ''}' == 'Credit';
    final bool isSale = '${sale!['sale_type'] ?? 'sale'}' == 'sale';
    final double finalTotal = _number(sale!['final_total']);
    final double paidAmount = _number(sale!['paid_amount']);
    final double balance = isCredit
        ? (finalTotal - paidAmount).clamp(0, double.infinity).toDouble()
        : 0;
    final int totalFoc = items.fold<int>(
      0,
      (int total, Map<String, Object?> item) =>
          total + _integer(item['foc_quantity']),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Voucher ${sale!['invoice_no']}'),
        actions: <Widget>[
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VoucherPreviewScreen(saleId: widget.saleId),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF Preview'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _print,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          if (isSale) ...<Widget>[
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _openReturn,
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Return'),
            ),
          ],
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFB3261E),
                        width: 1.4,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _VoucherHeader(
                          shopName: settings.shopName,
                          phone: settings.shopPhone,
                          address: settings.shopAddress,
                          invoiceNo: '${sale!['invoice_no'] ?? ''}',
                          saleDate: _displayDate('${sale!['sale_date'] ?? ''}'),
                          customerName:
                              '${sale!['customer_name'] ?? ''}'.trim().isEmpty
                                  ? 'Walk-in Customer'
                                  : '${sale!['customer_name']}',
                          customerType: _customerTypeLabel(
                            '${sale!['customer_type'] ?? 'regular'}',
                          ),
                          paymentMethod: '${sale!['payment_method'] ?? ''}',
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1040,
                            child: _buildItemsTable(currency),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: _NotesPanel(
                                paymentMethod:
                                    '${sale!['payment_method'] ?? ''}',
                                totalFoc: totalFoc,
                                returnCount: returns.length,
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 390,
                              child: _SummaryPanel(
                                currency: currency,
                                subtotal: _number(sale!['subtotal']),
                                discount: _number(sale!['discount_amount']),
                                rebate: _number(sale!['rebate_amount']),
                                doctorCashback:
                                    _number(sale!['customer_cashback_amount']),
                                ownerCashback:
                                    _number(sale!['company_cashback_amount']),
                                officePayable:
                                    _number(sale!['office_payable_amount']),
                                total: finalTotal,
                                paid: paidAmount,
                                change: _number(sale!['change_amount']),
                                balance: balance,
                                isCredit: isCredit,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 54),
                        const _SignatureRow(),
                        const SizedBox(height: 24),
                        Text(
                          settings.voucherFooter,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (returns.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Return History',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          ...returns.map(
                            (Map<String, Object?> row) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.assignment_return_outlined),
                              ),
                              title: Text(
                                '${row['return_no']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text('${row['created_at']}'),
                              trailing: Text(
                                Formatters.money(
                                  _number(row['total_return_amount']),
                                  symbol: currency,
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsTable(String currency) {
    const Color lineColor = Color(0xFFB3261E);
    const Color headerColor = Color(0xFFFFE9E7);
    const TextStyle headerStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
    );

    return Table(
      border: TableBorder.all(color: lineColor, width: 1.2),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(54),
        1: FlexColumnWidth(4.2),
        2: FixedColumnWidth(82),
        3: FixedColumnWidth(82),
        4: FlexColumnWidth(1.7),
        5: FlexColumnWidth(1.8),
      },
      children: <TableRow>[
        const TableRow(
          decoration: BoxDecoration(color: headerColor),
          children: <Widget>[
            _VoucherCell('No', style: headerStyle, center: true),
            _VoucherCell('Description', style: headerStyle),
            _VoucherCell('Qty', style: headerStyle, center: true),
            _VoucherCell('FOC', style: headerStyle, center: true),
            _VoucherCell('Unit Price', style: headerStyle, right: true),
            _VoucherCell('Amount', style: headerStyle, right: true),
          ],
        ),
        ...items.asMap().entries.map(
          (MapEntry<int, Map<String, Object?>> entry) {
            final Map<String, Object?> item = entry.value;
            final int paidQty = _integer(
              item['paid_quantity'] ?? item['quantity'],
            );
            final int focQty = _integer(item['foc_quantity']);
            final double appliedPrice = _number(item['unit_price_applied']);
            final double unitPrice = appliedPrice != 0
                ? appliedPrice
                : _number(item['selling_price']);
            final double amount = _number(item['subtotal']);
            final double doctorCashback =
                _number(item['customer_cashback_amount']);
            final String option = _saleOptionLabel(
              '${item['sale_option'] ?? 'normal'}',
            );

            return TableRow(
              children: <Widget>[
                _VoucherCell('${entry.key + 1}', center: true),
                _VoucherCell(
                  '${item['product_name'] ?? ''}',
                  secondary: <String>[
                    if (option != 'Normal') option,
                    if (doctorCashback > 0)
                      'Doctor Cashback: ${Formatters.money(doctorCashback, symbol: currency)}',
                  ].join('  •  '),
                ),
                _VoucherCell('$paidQty', center: true),
                _VoucherCell(focQty == 0 ? '-' : '$focQty', center: true),
                _VoucherCell(
                  Formatters.money(unitPrice, symbol: currency),
                  right: true,
                ),
                _VoucherCell(
                  Formatters.money(amount, symbol: currency),
                  right: true,
                  bold: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _print() async {
    final SettingsProvider settings = context.read<SettingsProvider>();
    await ReceiptService().printReceipt(
      shop: <String, String>{
        'name': settings.shopName,
        'phone': settings.shopPhone,
        'address': settings.shopAddress,
        'footer': settings.voucherFooter,
        'logo_path': settings.voucherLogoPath,
        'paper_mm': '${settings.voucherPaperSizeMm}',
        'font_size': '${settings.voucherFontSize}',
        'currency': settings.currencySymbol,
      },
      sale: sale!,
      items: items,
    );
  }

  Future<void> _openReturn() async {
    final bool? done = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            SaleReturnScreen(saleId: widget.saleId, saleItems: items),
      ),
    );
    if (done == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return processed and stock restored')),
      );
    }
  }

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static String _displayDate(String raw) {
    final DateTime? date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final int hour = date.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}  '
        '${displayHour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')} $period';
  }

  static String _saleOptionLabel(String code) {
    switch (code) {
      case 'office_rule':
        return 'Office FOC';
      case 'doctor_rule':
      case 'dr_cashback':
        return 'Doctor Cashback';
      case 'cd2':
        return 'CD 2%';
      default:
        return 'Normal';
    }
  }

  static String _customerTypeLabel(String code) {
    switch (code) {
      case 'office':
        return 'Office';
      case 'doctor':
        return 'Doctor';
      default:
        return 'Regular';
    }
  }
}

class _VoucherHeader extends StatelessWidget {
  const _VoucherHeader({
    required this.shopName,
    required this.phone,
    required this.address,
    required this.invoiceNo,
    required this.saleDate,
    required this.customerName,
    required this.customerType,
    required this.paymentMethod,
  });

  final String shopName;
  final String phone;
  final String address;
  final String invoiceNo;
  final String saleDate;
  final String customerName;
  final String customerType;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          shopName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
        ),
        if (phone.trim().isNotEmpty)
          Text(
            phone,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        if (address.trim().isNotEmpty)
          Text(
            address,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: _HeaderValue(
                label: 'CUSTOMER',
                value: customerName,
                secondary: customerType,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _HeaderValue(
                label: 'DATE',
                value: saleDate,
                secondary: paymentMethod,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _HeaderValue(
                label: 'INVOICE NO.',
                value: invoiceNo,
                secondary: 'Sales Voucher',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderValue extends StatelessWidget {
  const _HeaderValue({
    required this.label,
    required this.value,
    required this.secondary,
  });

  final String label;
  final String value;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 3),
          Text(secondary, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _VoucherCell extends StatelessWidget {
  const _VoucherCell(
    this.text, {
    this.secondary = '',
    this.style,
    this.center = false,
    this.right = false,
    this.bold = false,
  });

  final String text;
  final String secondary;
  final TextStyle? style;
  final bool center;
  final bool right;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final TextAlign align = center
        ? TextAlign.center
        : right
            ? TextAlign.right
            : TextAlign.left;
    final CrossAxisAlignment cross = center
        ? CrossAxisAlignment.center
        : right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Column(
        crossAxisAlignment: cross,
        children: <Widget>[
          Text(
            text,
            textAlign: align,
            style: style ??
                TextStyle(
                  fontSize: 16,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                ),
          ),
          if (secondary.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              secondary,
              textAlign: align,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({
    required this.paymentMethod,
    required this.totalFoc,
    required this.returnCount,
  });

  final String paymentMethod;
  final int totalFoc;
  final int returnCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Voucher Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text('Payment Method: $paymentMethod'),
          Text('Total FOC Quantity: $totalFoc'),
          Text('Return Records: $returnCount'),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.currency,
    required this.subtotal,
    required this.discount,
    required this.rebate,
    required this.doctorCashback,
    required this.ownerCashback,
    required this.officePayable,
    required this.total,
    required this.paid,
    required this.change,
    required this.balance,
    required this.isCredit,
  });

  final String currency;
  final double subtotal;
  final double discount;
  final double rebate;
  final double doctorCashback;
  final double ownerCashback;
  final double officePayable;
  final double total;
  final double paid;
  final double change;
  final double balance;
  final bool isCredit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB3261E), width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          _SummaryLine('Subtotal', subtotal, currency),
          if (discount > 0) _SummaryLine('Discount / CD', discount, currency),
          if (rebate > 0) _SummaryLine('Rebate', rebate, currency),
          if (doctorCashback > 0)
            _SummaryLine('Doctor Cashback', doctorCashback, currency),
          if (ownerCashback > 0)
            _SummaryLine('Owner Cashback', ownerCashback, currency),
          if (officePayable > 0 && officePayable != total)
            _SummaryLine('Payable To Office', officePayable, currency),
          const Divider(height: 22),
          _SummaryLine('TOTAL', total, currency, important: true),
          _SummaryLine('Paid', paid, currency),
          if (isCredit)
            _SummaryLine('BALANCE', balance, currency, important: true)
          else
            _SummaryLine('Change', change.abs(), currency),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(
    this.label,
    this.value,
    this.currency, {
    this.important = false,
  });

  final String label;
  final double value;
  final String currency;
  final bool important;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: important ? 19 : 16,
              fontWeight: important ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            Formatters.money(value, symbol: currency),
            style: TextStyle(
              fontSize: important ? 20 : 16,
              fontWeight: important ? FontWeight.w900 : FontWeight.w700,
              color: important
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureRow extends StatelessWidget {
  const _SignatureRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _Signature(label: 'Customer Signature'),
        _Signature(label: 'Authorized Signature'),
      ],
    );
  }
}

class _Signature extends StatelessWidget {
  const _Signature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        children: <Widget>[
          const Divider(thickness: 1.2),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
