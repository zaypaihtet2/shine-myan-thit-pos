import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pos_provider.dart';

class CartItemWidget extends StatelessWidget {
  const CartItemWidget({
    super.key,
    required this.line,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
    required this.onModeChanged,
  });

  final CartLine line;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;
  final ValueChanged<SalePricingMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final PosProvider pos = context.watch<PosProvider>();
    final double unitPrice = pos.lineUnitPrice(line);
    final double lineTotal = pos.lineSubtotal(line);
    final int focQty = pos.lineFocQty(line);
    final int stockOutQty = pos.lineStockOutQty(line);
    final double doctorCashback = pos.lineDoctorCashback(line);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    line.product.productName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.qty} x ${unitPrice.toStringAsFixed(2)}'
                    '${line.pricingMode.discountPercent > 0 ? ' (-${line.pricingMode.discountPercent.toStringAsFixed(0)}%)' : ''}'
                    ' = ${lineTotal.toStringAsFixed(2)}',
                  ),
                  if (focQty > 0) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'FOC: $focQty | Total Stock Out: $stockOutQty',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  if (doctorCashback > 0) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Doctor Cashback: ${doctorCashback.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      DropdownButton<SalePricingMode>(
                        value: line.pricingMode,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: SalePricingMode.values
                            .map(
                              (SalePricingMode mode) =>
                                  DropdownMenuItem<SalePricingMode>(
                                    value: mode,
                                    child: Text(mode.label),
                                  ),
                            )
                            .toList(),
                        onChanged: (SalePricingMode? mode) async {
                          if (mode == null) return;
                          onModeChanged(mode);
                          if (mode == SalePricingMode.drCashback &&
                              context.mounted) {
                            await _showDoctorCashbackDialog(context);
                          }
                        },
                      ),
                      if (line.pricingMode == SalePricingMode.drCashback)
                        TextButton.icon(
                          onPressed: () => _showDoctorCashbackDialog(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Adjust'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Decrease quantity',
                      onPressed: onDec,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${line.qty}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: 'Increase quantity',
                      onPressed: onInc,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDoctorCashbackDialog(BuildContext context) async {
    final PosProvider pos = context.read<PosProvider>();
    final TextEditingController salePrice = TextEditingController(
      text: pos.lineUnitPrice(line).toStringAsFixed(2),
    );
    final TextEditingController cashback = TextEditingController(
      text: pos.lineDoctorCashback(line).toStringAsFixed(2),
    );

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Adjust Doctor Cashback Sale'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: salePrice,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Sale Price Per Unit',
                  helperText: 'Example: change 53,000 to 60,000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cashback,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Doctor Cashback Amount',
                  helperText: 'Enter the total cashback for this cart line',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (save == true) {
      final double? price = double.tryParse(salePrice.text.replaceAll(',', ''));
      final double? amount = double.tryParse(cashback.text.replaceAll(',', ''));
      if (price == null || amount == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter valid sale price and cashback')),
          );
        }
      } else {
        try {
          pos.setLineUnitPrice(line, price);
          pos.setLineDoctorCashbackAmount(line, amount);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
      }
    }

    salePrice.dispose();
    cashback.dispose();
  }
}
