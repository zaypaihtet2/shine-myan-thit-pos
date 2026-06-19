import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/pos_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/receipt_service.dart';
import 'sale_return_screen.dart';

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
    final String currency = context.watch<SettingsProvider>().currencySymbol;
    if (sale == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isCredit = '${sale!['payment_method'] ?? ''}' == 'Credit';
    final double finalTotal = (sale!['final_total'] as num? ?? 0).toDouble();
    final double paidAmount = (sale!['paid_amount'] as num? ?? 0).toDouble();
    final double creditBalance = isCredit
        ? (finalTotal - paidAmount).clamp(0, double.infinity).toDouble()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sale Detail - ${sale!['invoice_no']}'),
        actions: <Widget>[
          if ('${sale!['sale_type'] ?? 'sale'}' == 'sale')
            IconButton(
              onPressed: _openReturn,
              icon: const Icon(Icons.assignment_return_outlined),
            ),
          IconButton(onPressed: _print, icon: const Icon(Icons.print_outlined)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Date: ${sale!['sale_date']}'),
            if ('${sale!['customer_name'] ?? ''}'.trim().isNotEmpty)
              Text(
                'Customer: ${sale!['customer_name']} (${sale!['customer_type'] ?? 'regular'})',
              ),
            Text('Payment: ${sale!['payment_method']}'),
            if (isCredit)
              Text(
                'Outstanding Credit: ${Formatters.money(creditBalance, symbol: currency)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: items
                    .map(
                      (Map<String, Object?> e) {
                        final int paidQty =
                            (e['paid_quantity'] as num? ??
                                    e['quantity'] as num? ??
                                    0)
                                .toInt();
                        final int focQty =
                            (e['foc_quantity'] as num? ?? 0).toInt();
                        final int totalQty = paidQty + focQty;
                        final double appliedPrice =
                            (e['unit_price_applied'] as num? ?? 0).toDouble();
                        final double unitPrice = appliedPrice != 0
                            ? appliedPrice
                            : (e['selling_price'] as num? ?? 0).toDouble();
                        final double amount =
                            (e['subtotal'] as num? ?? 0).toDouble();
                        final double doctorCashback =
                            (e['customer_cashback_amount'] as num? ?? 0)
                                .toDouble();
                        return ListTile(
                          title: Text(
                            '${e['product_name']} [${_saleOptionLabel('${e['sale_option'] ?? 'normal'}')}]'
                            '${(e['discount_percent'] as num? ?? 0) > 0 ? ' (-${(e['discount_percent'] as num).toStringAsFixed(0)}%)' : ''}',
                          ),
                          subtitle: Text(
                            'Qty: $paidQty | FOC: $focQty | Stock Out: $totalQty | Unit: ${Formatters.money(unitPrice, symbol: currency)}'
                            '${doctorCashback > 0 ? '\nDoctor Cashback: ${Formatters.money(doctorCashback, symbol: currency)}' : ''}',
                          ),
                          trailing: Text(
                            Formatters.money(
                              amount,
                              symbol: currency,
                            ),
                          ),
                        );
                      },
                    )
                    .toList(),
              ),
            ),
            const Divider(),
            Text(
              'Subtotal: ${Formatters.money((sale!['subtotal'] as num? ?? 0), symbol: currency)}',
            ),
            Text(
              'Discount: ${Formatters.money((sale!['discount_amount'] as num? ?? 0) != 0 ? (sale!['discount_amount'] as num? ?? 0) : items.fold<double>(0, (double total, Map<String, Object?> item) => total + (item['discount_amount'] as num? ?? 0).toDouble()), symbol: currency)}',
            ),
            Text(
              'Total FOC: ${items.fold<int>(0, (int total, Map<String, Object?> item) => total + (item['foc_quantity'] as num? ?? 0).toInt())}',
            ),
            Text(
              'Rebate: ${Formatters.money((sale!['rebate_amount'] as num? ?? 0), symbol: currency)}',
            ),
            Text(
              'Customer CD: ${Formatters.money((sale!['customer_cd_amount'] as num? ?? 0), symbol: currency)}',
            ),
            Text(
              'Doctor Cashback: ${Formatters.money((sale!['customer_cashback_amount'] as num? ?? 0), symbol: currency)}',
            ),
            Text(
              'Owner Cashback: ${Formatters.money((sale!['company_cashback_amount'] as num? ?? 0), symbol: currency)}',
            ),
            Text(
              'Payable To Office: ${Formatters.money((sale!['office_payable_amount'] as num? ?? 0), symbol: currency)}',
            ),
            Text(
              'Included in profit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Profit: ${Formatters.money((sale!['owner_keep_profit'] as num? ?? sale!['profit_amount'] as num? ?? 0), symbol: currency)}',
            ),
            Text(
              'Total: ${Formatters.money(finalTotal, symbol: currency)}',
            ),
            if (isCredit)
              Text(
                'Balance: ${Formatters.money(creditBalance, symbol: currency)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 8),
            if (returns.isNotEmpty) ...<Widget>[
              const Divider(),
              const Text(
                'Return History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...returns.map(
                (Map<String, Object?> row) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${row['return_no']}'),
                  subtitle: Text('${row['created_at']}'),
                  trailing: Text(
                    Formatters.money(
                      (row['total_return_amount'] as num? ?? 0),
                      symbol: currency,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _print() async {
    final settings = context.read<SettingsProvider>();
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

  String _saleOptionLabel(String code) {
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
}
