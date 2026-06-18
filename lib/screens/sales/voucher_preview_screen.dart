import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/receipt_service.dart';

class VoucherPreviewScreen extends StatefulWidget {
  const VoucherPreviewScreen({super.key, required this.saleId});

  final int saleId;

  @override
  State<VoucherPreviewScreen> createState() => _VoucherPreviewScreenState();
}

class _VoucherPreviewScreenState extends State<VoucherPreviewScreen> {
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final settings = context.read<SettingsProvider>();
    final detail = await context.read<PosProvider>().saleDetail(widget.saleId);
    final sale = detail['sale'] as Map<String, Object?>;
    final items = (detail['items'] as List).cast<Map<String, Object?>>();

    final Uint8List pdf = await ReceiptService().buildReceiptPdf(
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
      sale: sale,
      items: items,
    );
    if (mounted) {
      setState(() => bytes = pdf);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher Preview')),
      body: PdfPreview(build: (_) async => bytes!),
    );
  }
}
