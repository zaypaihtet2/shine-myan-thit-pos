import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/receipt_service.dart';
import '../../widgets/cart_item_widget.dart';
import '../../widgets/product_card.dart';
import '../sales/voucher_preview_screen.dart';

class PosSaleScreen extends StatefulWidget {
  const PosSaleScreen({super.key});

  static final FocusNode searchFocusNode = FocusNode();
  static VoidCallback? saveSaleGlobal;
  static VoidCallback? clearCartGlobal;
  static VoidCallback? printLastVoucherGlobal;

  @override
  State<PosSaleScreen> createState() => _PosSaleScreenState();
}

class _PosSaleScreenState extends State<PosSaleScreen> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _customer = TextEditingController();
  final TextEditingController _paid = TextEditingController(text: '0');
  int? _lastSaleId;

  @override
  void initState() {
    super.initState();
    PosSaleScreen.saveSaleGlobal = _saveSale;
    PosSaleScreen.clearCartGlobal = () {
      context.read<PosProvider>().clear();
      _paid.text = '0';
      _customer.clear();
    };
    PosSaleScreen.printLastVoucherGlobal = _printLast;
  }

  @override
  void dispose() {
    _search.dispose();
    _customer.dispose();
    _paid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProductProvider products = context.watch<ProductProvider>();
    final CustomerProvider customers = context.watch<CustomerProvider>();
    final PosProvider pos = context.watch<PosProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        const Color(0xFF0F5132),
                        const Color(0xFF1F7A4D),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF0F5132).withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'POS Sale',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Fast search, FOC stock deduction, credit sales, and adjustable doctor cashback.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'F1 POS | F2 Search | F4 Save | F5 Print | ESC Clear',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  focusNode: PosSaleScreen.searchFocusNode,
                  onChanged: products.setSearch,
                  decoration: const InputDecoration(
                    labelText: 'Search by name, barcode, SKU',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    itemCount: products.filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 1600
                          ? 5
                          : 3,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (_, int i) {
                      final ProductModel p = products.filtered[i];
                      return ProductCard(
                        product: p,
                        onTap: () {
                          try {
                            pos.addProduct(p);
                          } catch (e) {
                            _toast('$e');
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Cart',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${pos.cart.length} item(s)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: pos.cart.isEmpty
                          ? _EmptyCart(onClear: pos.clear)
                          : ListView.separated(
                              itemCount: pos.cart.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, int index) {
                                final CartLine line = pos.cart[index];
                                return CartItemWidget(
                                  line: line,
                                  onInc: () {
                                    try {
                                      pos.incQty(line);
                                    } catch (e) {
                                      _toast('$e');
                                    }
                                  },
                                  onDec: () => pos.decQty(line),
                                  onRemove: () => pos.remove(line),
                                  onModeChanged: (SalePricingMode mode) =>
                                      pos.setLinePricingMode(line, mode),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>('payment-${pos.paymentMethod}'),
                      initialValue: pos.paymentMethod,
                      items: AppConstants.paymentMethods
                          .map(
                            (String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (String? v) {
                        final String method = v ?? 'Cash';
                        pos.setPaymentMethod(method);
                        if (method == 'Credit') {
                          _paid.text = '0';
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      key: ValueKey<String>(
                        'customer-${pos.customerId ?? 'walkin'}',
                      ),
                      initialValue: pos.customerId,
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Walk-in Customer'),
                        ),
                        ...customers.customers.map(
                          (CustomerModel c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              '${c.name} (${c.type}) • Credit ${Formatters.money(c.creditBalance, symbol: settings.currencySymbol)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (int? value) {
                        if (value == null) {
                          pos.setCustomerProfile(
                            id: null,
                            name: _customer.text.trim(),
                            type: 'regular',
                            priceMode: 'normal',
                            pricePercent: 0,
                            rebatePercent: 0,
                            cashbackPercent: 0,
                          );
                          return;
                        }
                        final CustomerModel? selected = customers.customers
                            .where((CustomerModel c) => c.id == value)
                            .cast<CustomerModel?>()
                            .firstOrNull;
                        if (selected == null) return;
                        _customer.text = selected.name;
                        pos.setCustomerProfile(
                          id: selected.id,
                          name: selected.name,
                          type: selected.type,
                          priceMode: selected.priceMode,
                          pricePercent: selected.pricePercent,
                          rebatePercent: selected.rebatePercent,
                          cashbackPercent: selected.cashbackPercent,
                        );
                      },
                      decoration: InputDecoration(
                        labelText: 'Customer Profile',
                        helperText:
                            pos.isCreditSale || pos.paidAmount < pos.finalTotal
                            ? 'Enter a customer name or select a saved customer when payment is not complete'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customer,
                      enabled: !pos.isCreditSale,
                      onChanged: (String value) {
                        pos.setCustomerProfile(
                          id: null,
                          name: value,
                          type: pos.customerType,
                          priceMode: pos.customerPriceMode,
                          pricePercent: pos.customerPricePercent,
                          rebatePercent: pos.customerRebatePercent,
                          cashbackPercent: pos.customerCashbackPercent,
                        );
                      },
                      decoration: InputDecoration(
                        labelText: 'Customer Name (optional)',
                        helperText: pos.isCreditSale
                            ? 'Select the saved customer above'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!pos.isCreditSale)
                      TextField(
                        controller: _paid,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (String v) =>
                            pos.setPaidAmount(double.tryParse(v) ?? 0),
                        decoration: InputDecoration(
                          labelText: 'Paid Amount',
                          helperText: pos.paidAmount < pos.finalTotal
                              ? 'Remaining: ${Formatters.money(pos.creditDueAmount, symbol: settings.currencySymbol)}'
                              : null,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Credit sale: no Paid Amount is required. The full total will be added to the selected customer credit balance.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: <Widget>[
                          _line(
                            'Subtotal',
                            Formatters.money(
                              pos.subtotal,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          _line(
                            'Customer CD',
                            Formatters.money(
                              pos.customerCdAmount,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          _line(
                            'Customer Rebate',
                            Formatters.money(
                              pos.rebateAmount,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          _line(
                            'Doctor Cashback',
                            Formatters.money(
                              pos.customerCashbackAmount,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          _line(
                            'Owner Cashback',
                            Formatters.money(
                              pos.companyCashbackAmount,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          if (pos.totalFocQty > 0)
                            _line('FOC Qty', '${pos.totalFocQty}'),
                          _line(
                            'Payable To Office',
                            Formatters.money(
                              pos.officePayableAmount,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          _line(
                            'My Remaining Profit',
                            Formatters.money(
                              pos.ownerKeepProfit,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Included in profit',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                          const Divider(height: 20),
                          _line(
                            'Final Total',
                            Formatters.money(
                              pos.finalTotal,
                              symbol: settings.currencySymbol,
                            ),
                          ),
                          if (pos.isCreditSale || pos.creditDueAmount > 0)
                            _line(
                              pos.isCreditSale
                                  ? 'Amount on Credit'
                                  : 'Amount Due',
                              Formatters.money(
                                pos.creditDueAmount,
                                symbol: settings.currencySymbol,
                              ),
                            )
                          else
                            _line(
                              'Change',
                              Formatters.money(
                                pos.changeAmount,
                                symbol: settings.currencySymbol,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saveSale,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save Sale (F4)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              pos.clear();
                              _paid.text = '0';
                              _customer.clear();
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear (ESC)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _printLast,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Print Last Voucher (F5)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[Text(title), Text(value)],
      ),
    );
  }

  Future<void> _saveSale() async {
    final PosProvider pos = context.read<PosProvider>();
    final ProductProvider products = context.read<ProductProvider>();
    final SalesProvider sales = context.read<SalesProvider>();
    final CustomerProvider customers = context.read<CustomerProvider>();
    try {
      final int saleId = await pos.saveSale();
      if (!mounted) return;
      _lastSaleId = saleId;
      await products.load();
      await sales.load();
      await customers.load();
      if (!mounted) return;
      _paid.text = '0';
      _customer.clear();
      _toast('Sale saved: #$saleId');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VoucherPreviewScreen(saleId: saleId),
        ),
      );
    } catch (e) {
      if (mounted) {
        _toast('$e');
      }
    }
  }

  Future<void> _printLast() async {
    if (_lastSaleId == null) {
      _toast('No last sale to print');
      return;
    }
    final PosProvider pos = context.read<PosProvider>();
    final SettingsProvider settings = context.read<SettingsProvider>();
    final Map<String, Object?> detail = await pos.saleDetail(_lastSaleId!);
    if (!mounted) return;
    final Map<String, Object?> sale = detail['sale'] as Map<String, Object?>;
    final List<Map<String, Object?>> items = (detail['items'] as List)
        .cast<Map<String, Object?>>();

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
      sale: sale,
      items: items,
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.shopping_cart_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            'Cart is empty',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap products on the left to build a sale.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }
}
