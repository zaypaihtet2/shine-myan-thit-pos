import 'package:flutter/material.dart';

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
    return Card(
      child: ListTile(
        title: Text(line.product.productName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${line.qty} x ${line.product.sellingPrice.toStringAsFixed(2)}'
              '${line.discountPercent > 0 ? ' (-${line.discountPercent.toStringAsFixed(0)}%)' : ''}'
              ' = ${line.subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            DropdownButton<SalePricingMode>(
              value: line.pricingMode,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: SalePricingMode.values
                  .map(
                    (SalePricingMode mode) => DropdownMenuItem<SalePricingMode>(
                      value: mode,
                      child: Text(mode.label),
                    ),
                  )
                  .toList(),
              onChanged: (SalePricingMode? mode) {
                if (mode != null) {
                  onModeChanged(mode);
                }
              },
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: <Widget>[
            IconButton(
              onPressed: onDec,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              onPressed: onInc,
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
