import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sales_provider.dart';

class SaleReturnScreen extends StatefulWidget {
  const SaleReturnScreen({
    super.key,
    required this.saleId,
    required this.saleItems,
  });

  final int saleId;
  final List<Map<String, Object?>> saleItems;

  @override
  State<SaleReturnScreen> createState() => _SaleReturnScreenState();
}

class _SaleReturnScreenState extends State<SaleReturnScreen> {
  final TextEditingController _note = TextEditingController();
  final Map<int, TextEditingController> _qtyControllers =
      <int, TextEditingController>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final Map<String, Object?> item in widget.saleItems) {
      _qtyControllers[item['id'] as int] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _note.dispose();
    for (final TextEditingController c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Return')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: widget.saleItems.map((Map<String, Object?> item) {
                  final int itemId = item['id'] as int;
                  final int soldQty = item['quantity'] as int? ?? 0;
                  final int paidQty =
                      (item['paid_quantity'] as int?) ?? soldQty;
                  final int focQty = (item['foc_quantity'] as int?) ?? 0;
                  return Card(
                    child: ListTile(
                      title: Text('${item['product_name']}'),
                      subtitle: Text(
                        'Sold Qty: $soldQty (Paid: $paidQty, FOC: $focQty) | Unit: ${item['selling_price']}',
                      ),
                      trailing: SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _qtyControllers[itemId],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Return Qty',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Return Note (optional)',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.assignment_return_outlined),
                label: Text(_saving ? 'Processing...' : 'Process Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final List<Map<String, Object?>> lines = <Map<String, Object?>>[];
    for (final Map<String, Object?> item in widget.saleItems) {
      final int saleItemId = item['id'] as int;
      final int qty =
          int.tryParse(_qtyControllers[saleItemId]?.text ?? '0') ?? 0;
      if (qty > 0) {
        lines.add(<String, Object?>{
          'sale_item_id': saleItemId,
          'return_quantity': qty,
        });
      }
    }

    try {
      if (lines.isEmpty) {
        throw Exception('Please enter at least one return quantity');
      }
      await context.read<SalesProvider>().createReturn(
        saleId: widget.saleId,
        returnLines: lines,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
