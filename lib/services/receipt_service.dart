import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptService {
  Future<Uint8List> buildReceiptPdf({
    required Map<String, String> shop,
    required Map<String, Object?> sale,
    required List<Map<String, Object?>> items,
  }) async {
    final int paperMm = int.tryParse(shop['paper_mm'] ?? '80') ?? 80;
    final double fontSize = double.tryParse(shop['font_size'] ?? '10') ?? 10;
    final String currency = shop['currency'] ?? 'Ks';
    final pw.ImageProvider? logo = await _loadLogo(shop['logo_path'] ?? '');
    final bool invoiceStyle = paperMm >= 100;

    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: _paperFormat(paperMm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            _header(shop, sale, logo, fontSize, paperMm),
            pw.SizedBox(height: 8),
            _itemsTable(items, fontSize, currency, invoiceStyle),
            pw.SizedBox(height: 8),
            _summary(sale, items, fontSize, currency, invoiceStyle),
            pw.SizedBox(height: 16),
            if (invoiceStyle) _signatureRow(fontSize),
            if (!invoiceStyle) pw.Divider(),
            pw.Center(
              child: pw.Text(
                shop['footer'] ?? 'Thank you',
                style: pw.TextStyle(fontSize: fontSize),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  pw.Widget _header(
    Map<String, String> shop,
    Map<String, Object?> sale,
    pw.ImageProvider? logo,
    double fontSize,
    int paperMm,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        if (logo != null)
          pw.Center(
            child: pw.Image(
              logo,
              width: paperMm <= 58 ? 90 : 130,
              fit: pw.BoxFit.contain,
            ),
          ),
        if (logo != null) pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            shop['name'] ?? '',
            style: pw.TextStyle(
              fontSize: fontSize + 5,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        if ((shop['phone'] ?? '').trim().isNotEmpty)
          pw.Center(
            child: pw.Text(
              shop['phone'] ?? '',
              style: pw.TextStyle(fontSize: fontSize),
            ),
          ),
        if ((shop['address'] ?? '').trim().isNotEmpty)
          pw.Center(
            child: pw.Text(
              shop['address'] ?? '',
              style: pw.TextStyle(fontSize: fontSize),
              textAlign: pw.TextAlign.center,
            ),
          ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              'Invoice: ${sale['invoice_no'] ?? ''}',
              style: pw.TextStyle(fontSize: fontSize),
            ),
            pw.Text(
              'Date: ${_shortDate(sale['sale_date'])}',
              style: pw.TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        if ('${sale['customer_name'] ?? ''}'.trim().isNotEmpty)
          pw.Text(
            'Customer: ${sale['customer_name']} (${_customerTypeLabel('${sale['customer_type'] ?? 'regular'}')})',
            style: pw.TextStyle(fontSize: fontSize),
          ),
      ],
    );
  }

  pw.Widget _itemsTable(
    List<Map<String, Object?>> items,
    double fontSize,
    String currency,
    bool invoiceStyle,
  ) {
    final double tableFont = invoiceStyle ? fontSize : fontSize - 1;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FixedColumnWidth(18),
        1: const pw.FlexColumnWidth(3.6),
        2: const pw.FixedColumnWidth(28),
        3: const pw.FixedColumnWidth(28),
        4: const pw.FlexColumnWidth(1.7),
        5: const pw.FlexColumnWidth(1.8),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: <pw.Widget>[
            _cell('No', tableFont, header: true, align: pw.TextAlign.center),
            _cell('Description', tableFont, header: true),
            _cell('Qty', tableFont, header: true, align: pw.TextAlign.center),
            _cell('FOC', tableFont, header: true, align: pw.TextAlign.center),
            _cell('Unit Price', tableFont, header: true, align: pw.TextAlign.right),
            _cell('Amount', tableFont, header: true, align: pw.TextAlign.right),
          ],
        ),
        ...items.asMap().entries.map((MapEntry<int, Map<String, Object?>> row) {
          final Map<String, Object?> item = row.value;
          final int paidQty = _intValue(
            item['paid_quantity'] ?? item['quantity'],
          );
          final int focQty = _intValue(item['foc_quantity']);
          final double appliedPrice = _numberValue(item['unit_price_applied']);
          final double unitPrice = appliedPrice != 0
              ? appliedPrice
              : _numberValue(item['selling_price']);
          final double amount = _numberValue(item['subtotal']);
          final String remarks = _itemRemarks(item, currency);
          return pw.TableRow(
            children: <pw.Widget>[
              _cell('${row.key + 1}', tableFont, align: pw.TextAlign.center),
              _cell(
                remarks.isEmpty
                    ? '${item['product_name'] ?? ''}'
                    : '${item['product_name'] ?? ''}\n$remarks',
                tableFont,
              ),
              _cell('$paidQty', tableFont, align: pw.TextAlign.center),
              _cell(
                focQty == 0 ? '-' : '$focQty',
                tableFont,
                align: pw.TextAlign.center,
              ),
              _cell(
                _money(unitPrice, currency, showCurrency: false),
                tableFont,
                align: pw.TextAlign.right,
              ),
              _cell(
                _money(amount, currency, showCurrency: false),
                tableFont,
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _summary(
    Map<String, Object?> sale,
    List<Map<String, Object?>> items,
    double fontSize,
    String currency,
    bool invoiceStyle,
  ) {
    final double discount = _numberValue(sale['discount_amount']);
    final double rebate = _numberValue(sale['rebate_amount']);
    final double doctorCashback = _numberValue(sale['customer_cashback_amount']);
    final double ownerCashback = _numberValue(sale['company_cashback_amount']);
    final double officePayable = _numberValue(sale['office_payable_amount']);
    final double total = _numberValue(sale['final_total']);
    final double paid = _numberValue(sale['paid_amount']);
    final double change = _numberValue(sale['change_amount']);
    final bool isCredit = '${sale['payment_method'] ?? ''}' == 'Credit';
    final double balance = isCredit
        ? (total - paid).clamp(0, double.infinity).toDouble()
        : 0;
    final int totalFoc = items.fold<int>(
      0,
      (int sum, Map<String, Object?> item) =>
          sum + _intValue(item['foc_quantity']),
    );

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: invoiceStyle ? 230 : double.infinity,
        child: pw.Column(
          children: <pw.Widget>[
            _moneyLine('Subtotal', sale['subtotal'], fontSize, currency),
            if (totalFoc > 0) _textLine('Total FOC', '$totalFoc', fontSize),
            if (discount > 0)
              _moneyLine('Discount / CD', discount, fontSize, currency),
            if (rebate > 0)
              _moneyLine('Rebate', rebate, fontSize, currency),
            if (doctorCashback > 0)
              _moneyLine(
                'Doctor Cashback',
                doctorCashback,
                fontSize,
                currency,
              ),
            if (ownerCashback > 0)
              _moneyLine(
                'Owner Cashback',
                ownerCashback,
                fontSize,
                currency,
              ),
            if (officePayable > 0 && officePayable != total)
              _moneyLine(
                'Payable To Office',
                officePayable,
                fontSize,
                currency,
              ),
            pw.Divider(height: 10),
            _moneyLine('TOTAL', total, fontSize + 1, currency, bold: true),
            _moneyLine('Paid', paid, fontSize, currency),
            if (isCredit)
              _moneyLine(
                'BALANCE',
                balance,
                fontSize + 1,
                currency,
                bold: true,
              )
            else
              _moneyLine(
                change < 0 ? 'BALANCE' : 'Change',
                change.abs(),
                fontSize,
                currency,
              ),
            _textLine('Payment', '${sale['payment_method'] ?? ''}', fontSize),
          ],
        ),
      ),
    );
  }

  pw.Widget _signatureRow(double fontSize) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        _signature('Customer Signature', fontSize),
        _signature('Signature', fontSize),
      ],
    );
  }

  pw.Widget _signature(String label, double fontSize) {
    return pw.Column(
      children: <pw.Widget>[
        pw.Container(width: 130, height: 1, color: PdfColors.grey600),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize)),
      ],
    );
  }

  pw.Widget _cell(
    String text,
    double fontSize, {
    bool header = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _moneyLine(
    String label,
    Object? value,
    double fontSize,
    String currency, {
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          _money(_numberValue(value), currency),
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _textLine(String label, String value, double fontSize) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize)),
        pw.Text(value, style: pw.TextStyle(fontSize: fontSize)),
      ],
    );
  }

  String _itemRemarks(Map<String, Object?> item, String currency) {
    final List<String> remarks = <String>[];
    final String option = _saleOptionLabel('${item['sale_option'] ?? 'normal'}');
    if (option != 'Normal') remarks.add(option);

    final double discountPercent = _numberValue(item['discount_percent']);
    if (discountPercent > 0) {
      remarks.add('CD ${_percent(discountPercent)}');
    }

    final double rebatePercent = _numberValue(item['rebate_percent']);
    if (rebatePercent > 0) {
      remarks.add('Rebate ${_percent(rebatePercent)}');
    }

    final double doctorCashback =
        _numberValue(item['customer_cashback_amount']);
    if (doctorCashback > 0) {
      remarks.add('Doctor Cashback ${_money(doctorCashback, currency)}');
    }
    return remarks.join(' | ');
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

  String _customerTypeLabel(String code) {
    switch (code) {
      case 'office':
        return 'Office';
      case 'doctor':
        return 'Doctor';
      default:
        return 'Regular';
    }
  }

  PdfPageFormat _paperFormat(int mm) {
    if (mm >= 100) {
      return PdfPageFormat(
        148 * PdfPageFormat.mm,
        210 * PdfPageFormat.mm,
        marginAll: 8 * PdfPageFormat.mm,
      );
    }
    if (mm <= 58) {
      return PdfPageFormat(
        58 * PdfPageFormat.mm,
        double.infinity,
        marginAll: 4 * PdfPageFormat.mm,
      );
    }
    return PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 5 * PdfPageFormat.mm,
    );
  }

  Future<pw.ImageProvider?> _loadLogo(String path) async {
    if (path.isEmpty) return null;
    final File file = File(path);
    if (!await file.exists()) return null;
    return pw.MemoryImage(await file.readAsBytes());
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _money(num value, String currency, {bool showCurrency = true}) {
    final String number = _formatNumber(value);
    if (!showCurrency || currency.trim().isEmpty) return number;
    return '$number $currency';
  }

  String _formatNumber(num value) {
    final bool whole = value % 1 == 0;
    final String raw = whole
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final List<String> parts = raw.split('.');
    final String integer = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return parts.length == 1 ? integer : '$integer.${parts.last}';
  }

  String _percent(num value) {
    return value % 1 == 0
        ? '${value.toStringAsFixed(0)}%'
        : '${value.toStringAsFixed(2)}%';
  }

  String _shortDate(Object? value) {
    final String raw = '${value ?? ''}';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Future<void> printReceipt({
    required Map<String, String> shop,
    required Map<String, Object?> sale,
    required List<Map<String, Object?>> items,
  }) async {
    final Uint8List data = await buildReceiptPdf(
      shop: shop,
      sale: sale,
      items: items,
    );
    await Printing.layoutPdf(onLayout: (_) async => data);
  }
}
