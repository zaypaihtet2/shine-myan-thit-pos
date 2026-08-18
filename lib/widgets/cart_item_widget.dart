import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/formatters.dart';
import '../providers/pos_provider.dart';
import '../providers/settings_provider.dart';

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
    final String currency = context.watch<SettingsProvider>().currencySymbol;
    final double unitPrice = pos.lineUnitPrice(line);
    final double lineTotal = pos.lineSubtotal(line);
    final int focQty = pos.lineFocQty(line);
    final int stockOutQty = pos.lineStockOutQty(line);
    final double doctorCashback = pos.lineDoctorCashback(line);
    final double effectiveCost = pos.lineEffectiveCost(line);
    final double estimatedProfit = pos.lineEstimatedProfit(line);
    final bool isNetPrice = line.pricingMode == SalePricingMode.netPrice;

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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.qty} x ${Formatters.money(unitPrice, symbol: currency)}'
                    '${line.cd2Enabled ? ' (-2%)' : ''}'
                    ' = ${Formatters.money(lineTotal, symbol: currency)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Effective Cost / Unit: ${Formatters.money(effectiveCost, symbol: currency)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isNetPrice) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Net Price Sale: No customer FOC | Stock Out: $stockOutQty',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ] else if (focQty > 0) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'FOC: $focQty | Total Stock Out: $stockOutQty',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  if (doctorCashback > 0) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Doctor Cashback: ${Formatters.money(doctorCashback, symbol: currency)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Estimated Profit: ${Formatters.money(estimatedProfit, symbol: currency)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: estimatedProfit < 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      DropdownButton<SalePricingMode>(
                        value: line.pricingMode,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: SalePricingMode.values
                            .where(
                              (SalePricingMode mode) =>
                                  mode != SalePricingMode.cd2,
                            )
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
                          final SalePricingMode previousMode = line.pricingMode;
                          onModeChanged(mode);
                          if (!context.mounted) return;
                          if (mode == SalePricingMode.netPrice) {
                            final bool applied = await _showNetPriceDialog(
                              context,
                            );
                            if (!applied && context.mounted) {
                              onModeChanged(previousMode);
                            }
                          } else if (mode == SalePricingMode.drCashback) {
                            final bool applied =
                                await _showDoctorCashbackDialog(context);
                            if (!applied && context.mounted) {
                              onModeChanged(previousMode);
                            }
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('CD 2%'),
                        selected: line.cd2Enabled,
                        onSelected: (bool enabled) => context
                            .read<PosProvider>()
                            .setLineCd2(line, enabled),
                      ),
                      if (line.pricingMode == SalePricingMode.netPrice)
                        TextButton.icon(
                          onPressed: () => _showNetPriceDialog(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Adjust Net Price'),
                        ),
                      if (line.pricingMode == SalePricingMode.drCashback)
                        TextButton.icon(
                          onPressed: () => _showDoctorCashbackDialog(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Adjust Cashback'),
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
                    SizedBox(
                      width: 52,
                      child: TextFormField(
                        key: ValueKey<int>(line.qty),
                        initialValue: '${line.qty}',
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                        onFieldSubmitted: (String value) =>
                            _applyTypedQty(context, value),
                      ),
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

  void _applyTypedQty(BuildContext context, String value) {
    final int? qty = int.tryParse(value.trim());
    if (qty == null) return;
    try {
      context.read<PosProvider>().setQty(line, qty);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<bool> _showNetPriceDialog(BuildContext context) async {
    final PosProvider pos = context.read<PosProvider>();
    final String currency = context.read<SettingsProvider>().currencySymbol;
    final double suggested = pos.lineSuggestedNetPrice(line);
    final TextEditingController salePrice = TextEditingController(
      text: pos.lineUnitPrice(line).toStringAsFixed(2),
    );

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Adjust Net Price Sale'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Normal Product Price: ${Formatters.money(line.product.sellingPrice, symbol: currency)}',
              ),
              if (line.product.focEnabled)
                Text(
                  'Supplier / Normal FOC Rule: Buy ${line.product.focBuyQty}, FOC ${line.product.focFreeQty}',
                ),
              Text(
                'Calculated Net Cost / Unit: ${Formatters.money(suggested, symbol: currency)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Net Price mode does not give customer FOC. Only the sold quantity is deducted from stock.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: salePrice,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Net Sale Price Per Unit',
                  helperText:
                      'Suggested ${Formatters.money(suggested, symbol: currency)}. You can enter 35,000 or another price.',
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
      if (price == null || price <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid net sale price')),
          );
        }
        salePrice.dispose();
        return false;
      } else {
        try {
          pos.setLineUnitPrice(line, price);
          salePrice.dispose();
          return true;
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$error')));
          }
        }
      }
    }

    salePrice.dispose();
    return false;
  }

  Future<bool> _showDoctorCashbackDialog(BuildContext context) async {
    final PosProvider pos = context.read<PosProvider>();
    final TextEditingController salePrice = TextEditingController(
      text: pos.lineUnitPrice(line).toStringAsFixed(2),
    );
    final TextEditingController cashback = TextEditingController(
      text: pos.lineDoctorCashback(line).toStringAsFixed(2),
    );
    final TextEditingController focQty = TextEditingController(
      text: pos.lineFocQty(line).toString(),
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
              const SizedBox(height: 12),
              TextField(
                controller: focQty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'FOC Quantity',
                  helperText: 'Enter the FOC quantity for this cart line',
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
      final int? foc = int.tryParse(focQty.text.replaceAll(',', '').trim());
      if (price == null || amount == null || foc == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter valid price, cashback and FOC'),
            ),
          );
        }
        salePrice.dispose();
        cashback.dispose();
        focQty.dispose();
        return false;
      } else {
        try {
          pos.setLineUnitPrice(line, price);
          pos.setLineDoctorCashbackAmount(line, amount);
          pos.setLineFocQty(line, foc);
          salePrice.dispose();
          cashback.dispose();
          focQty.dispose();
          return true;
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$error')));
          }
        }
      }
    }

    salePrice.dispose();
    cashback.dispose();
    focQty.dispose();
    return false;
  }
}
