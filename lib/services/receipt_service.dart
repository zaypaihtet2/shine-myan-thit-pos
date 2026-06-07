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
    final String logoPath = shop['logo_path'] ?? '';
    final pw.ImageProvider? logo = await _loadLogo(logoPath);

    final pw.Document doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: _paperFormat(paperMm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              if (logo != null)
                pw.Center(
                  child: pw.Image(
                    logo,
                    width: paperMm == 58 ? 90 : 130,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              if (logo != null) pw.SizedBox(height: 6),
              pw.Text(
                shop['name'] ?? '',
                style: pw.TextStyle(
                  fontSize: fontSize + 4,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                shop['phone'] ?? '',
                style: pw.TextStyle(fontSize: fontSize),
              ),
              pw.Text(
                shop['address'] ?? '',
                style: pw.TextStyle(fontSize: fontSize),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Invoice: ${sale['invoice_no']}',
                style: pw.TextStyle(fontSize: fontSize),
              ),
              pw.Text(
                'Date: ${sale['sale_date'] ?? ''}',
                style: pw.TextStyle(fontSize: fontSize),
              ),
              if ('${sale['customer_name'] ?? ''}'.trim().isNotEmpty)
                pw.Text(
                  'Customer: ${sale['customer_name']} (${sale['customer_type'] ?? 'regular'})',
                  style: pw.TextStyle(fontSize: fontSize),
                ),
              pw.Divider(),
              ...items.map(
                (Map<String, Object?> i) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: pw.Text(
                        '${i['product_name']} x ${((i['paid_quantity'] as num?) ?? (i['quantity'] as num?) ?? 0).toInt()}${((i['foc_quantity'] as num?) ?? 0) > 0 ? ' + FOC ${((i['foc_quantity'] as num?) ?? 0).toInt()}' : ''} [${_saleOptionLabel('${i['sale_option'] ?? 'normal'}')}]${((i['discount_percent'] as num?) ?? 0) > 0 ? ' (-${(i['discount_percent'] as num).toStringAsFixed(0)}%)' : ''}',
                        style: pw.TextStyle(fontSize: fontSize),
                      ),
                    ),
                    pw.Text(
                      (i['subtotal'] as num).toStringAsFixed(2),
                      style: pw.TextStyle(fontSize: fontSize),
                    ),
                  ],
                ),
              ),
              pw.Divider(),
              _line('Subtotal', sale['subtotal'], fontSize),
              _line(
                'Discount',
                (sale['discount_amount'] as num? ?? 0) != 0
                    ? sale['discount_amount']
                    : items.fold<double>(
                        0,
                        (double total, Map<String, Object?> item) =>
                            total +
                            (item['discount_amount'] as num? ?? 0).toDouble(),
                      ),
                fontSize,
              ),
              _line('Customer CD %', sale['customer_cd_percent'], fontSize),
              _line('Customer CD', sale['customer_cd_amount'], fontSize),
              _line('Rebate', sale['rebate_amount'], fontSize),
              _line(
                'Doctor Cashback',
                sale['customer_cashback_amount'],
                fontSize,
              ),
              _line(
                'Owner Cashback',
                sale['company_cashback_amount'],
                fontSize,
              ),
              _line(
                'Payable To Office',
                sale['office_payable_amount'],
                fontSize,
              ),
              pw.Text(
                'Included in profit',
                style: pw.TextStyle(fontSize: fontSize - 1),
              ),
              _line('Final Total', sale['final_total'], fontSize),
              _line('Paid', sale['paid_amount'], fontSize),
              _line('Change', sale['change_amount'], fontSize),
              _line('Payment', sale['payment_method'], fontSize),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  shop['footer'] ?? 'Thank you',
                  style: pw.TextStyle(fontSize: fontSize),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _line(String label, Object? value, double fontSize) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize)),
        pw.Text('${value ?? ''}', style: pw.TextStyle(fontSize: fontSize)),
      ],
    );
  }

  String _saleOptionLabel(String code) {
    switch (code) {
      case 'office_rule':
        return 'Office Rule';
      case 'doctor_rule':
        return 'Doctor Rule';
      case 'cd2':
        return 'CD 2%';
      case 'dr_cashback':
        return 'DR Cashback';
      default:
        return 'Normal';
    }
  }

  PdfPageFormat _paperFormat(int mm) {
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
      marginAll: 6 * PdfPageFormat.mm,
    );
  }

  Future<pw.ImageProvider?> _loadLogo(String path) async {
    if (path.isEmpty) return null;
    final File file = File(path);
    if (!await file.exists()) return null;
    final Uint8List bytes = await file.readAsBytes();
    return pw.MemoryImage(bytes);
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
