import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
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
  final TextEditingController _paid = TextEditingController(text: '0');
  int? _lastSaleId;

  @override
  void initState() {
    super.initState();
    PosSaleScreen.saveSaleGlobal = _saveSale;
    PosSaleScreen.clearCartGlobal = () => context.read<PosProvider>().clear();
    PosSaleScreen.printLastVoucherGlobal = _printLast;
  }

  @override
  void dispose() {
    _search.dispose();
    _paid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProductProvider products = context.watch<ProductProvider>();
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
                              'Fast search, tap-to-add products, and simple checkout.',
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
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: pos.paymentMethod,
                      items: AppConstants.paymentMethods
                          .map(
                            (String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (String? v) =>
                          pos.setPaymentMethod(v ?? 'Cash'),
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _paid,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (String v) =>
                          pos.setPaidAmount(double.tryParse(v) ?? 0),
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
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
                            'Owner Cashback',
                            Formatters.money(
                              pos.companyCashbackAmount,
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
                            onPressed: pos.clear,
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
    try {
      final int saleId = await pos.saveSale();
      if (!mounted) return;
      _lastSaleId = saleId;
      await products.load();
      await sales.load();
      if (!mounted) return;
      _paid.text = '0';
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
