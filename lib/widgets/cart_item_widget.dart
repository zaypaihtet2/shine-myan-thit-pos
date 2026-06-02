import 'package:flutter/material.dart';

import '../providers/pos_provider.dart';

class CartItemWidget extends StatelessWidget {
  const CartItemWidget({
    super.key,
    required this.line,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(line.product.productName),
        subtitle: Text(
          '${line.qty} x ${line.product.sellingPrice.toStringAsFixed(2)}'
          '${line.product.discountPercent > 0 ? ' (-${line.product.discountPercent.toStringAsFixed(0)}%)' : ''}'
          ' = ${line.subtotal.toStringAsFixed(2)}',
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
