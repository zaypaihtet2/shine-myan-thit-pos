import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/company_model.dart';
import '../../models/product_model.dart';
import '../../providers/company_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/settings_provider.dart';

class PurchaseEntryFormScreen extends StatefulWidget {
  const PurchaseEntryFormScreen({super.key});

  @override
  State<PurchaseEntryFormScreen> createState() =>
      _PurchaseEntryFormScreenState();
}

class _PurchaseEntryFormScreenState extends State<PurchaseEntryFormScreen> {
  final TextEditingController _supplier = TextEditingController();
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final List<_PurchaseLineDraft> _lines = <_PurchaseLineDraft>[];

  int? _supplierCompanyId;
  DateTime _purchaseDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addLine();
  }

  @override
  void dispose() {
    _supplier.dispose();
    _reference.dispose();
    _note.dispose();
    for (final _PurchaseLineDraft line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<CompanyModel> companies =
        context.watch<CompanyProvider>().companies;
    final List<ProductModel> products =
        context.watch<ProductProvider>().products;
    final String currency = context.watch<SettingsProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  _buildHeader(context),
                  const SizedBox(height: 14),
                  _buildSupplierCard(companies),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Purchased Products',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product Row'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (products.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No products found. Create products before recording a purchase.',
                        ),
                      ),
                    )
                  else
                    ..._lines.asMap().entries.map(
                      (MapEntry<int, _PurchaseLineDraft> entry) =>
                          _buildLineCard(
                        index: entry.key,
                        line: entry.value,
                        products: products,
                        currency: currency,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.calculate_outlined, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Total Purchase Value',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            Formatters.money(_grandTotal, symbol: currency),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving || products.isEmpty ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Purchase & Add Stock',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F5132), Color(0xFF1F7A4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.local_shipping_outlined,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Purchase Entry',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saving this entry automatically adds every quantity to product stock.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(List<CompanyModel> companies) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Supplier & Purchase Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey<String>(
                      'supplier-${_supplierCompanyId ?? 'manual'}',
                    ),
                    initialValue: _supplierCompanyId,
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Manual Supplier Name'),
                      ),
                      ...companies.map(
                        (CompanyModel company) => DropdownMenuItem<int?>(
                          value: company.id,
                          child: Text(company.name),
                        ),
                      ),
                    ],
                    onChanged: (int? value) {
                      setState(() {
                        _supplierCompanyId = value;
                        if (value != null) {
                          final CompanyModel selected = companies.firstWhere(
                            (CompanyModel company) => company.id == value,
                          );
                          _supplier.text = selected.name;
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Company / Supplier',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _supplier,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Name',
                      hintText: 'Required',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: TextField(
                    controller: _reference,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Invoice / Reference',
                      hintText: 'Optional',
                      prefixIcon: Icon(Icons.receipt_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Purchase Date',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(_dateText(_purchaseDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional purchase note',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineCard({
    required int index,
    required _PurchaseLineDraft line,
    required List<ProductModel> products,
    required String currency,
  }) {
    final ProductModel? selected = _selectedProduct(products, line.productId);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                CircleAvatar(child: Text('${index + 1}')),
                SizedBox(
                  width: 390,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey<String>(
                      'purchase-line-$index-${line.productId}',
                    ),
                    initialValue: line.productId,
                    isExpanded: true,
                    hint: const Text('Select Product'),
                    items: products
                        .map(
                          (ProductModel product) => DropdownMenuItem<int>(
                            value: product.id,
                            child: Text(
                              '${product.productName} • Stock ${product.stockQuantity}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (int? productId) {
                      setState(() {
                        line.productId = productId;
                        final ProductModel? product =
                            _selectedProduct(products, productId);
                        if (product != null && line.cost == 0) {
                          final double suggested = product.buyingPrice > 0
                              ? product.buyingPrice
                              : product.sellingPrice;
                          line.unitCost.text = suggested.toStringAsFixed(2);
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: line.quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                    ),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: TextField(
                    controller: line.unitCost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Purchase Price / Unit',
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Line Total'),
                    child: Text(
                      Formatters.money(line.total, symbol: currency),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove row',
                  onPressed:
                      _lines.length == 1 ? null : () => _removeLine(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (selected != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Current Stock: ${selected.stockQuantity}  →  '
                'After Purchase: ${selected.stockQuantity + line.qty}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ProductModel? _selectedProduct(
    List<ProductModel> products,
    int? productId,
  ) {
    if (productId == null) return null;
    for (final ProductModel product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  double get _grandTotal => _lines.fold<double>(
        0,
        (double total, _PurchaseLineDraft line) => total + line.total,
      );

  void _addLine() {
    final _PurchaseLineDraft line = _PurchaseLineDraft();
    line.quantity.addListener(_refreshTotals);
    line.unitCost.addListener(_refreshTotals);
    setState(() => _lines.add(line));
  }

  void _removeLine(int index) {
    final _PurchaseLineDraft line = _lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  void _refreshTotals() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Purchase Date',
    );
    if (!mounted || picked == null) return;
    setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (_supplier.text.trim().isEmpty) {
      _showMessage('Supplier or company name is required');
      return;
    }

    final List<Map<String, Object?>> items = <Map<String, Object?>>[];
    final Set<int> productIds = <int>{};

    for (int index = 0; index < _lines.length; index++) {
      final _PurchaseLineDraft line = _lines[index];
      if (line.productId == null) {
        _showMessage('Select a product on row ${index + 1}');
        return;
      }
      if (!productIds.add(line.productId!)) {
        _showMessage('The same product is selected more than once');
        return;
      }
      if (line.qty <= 0) {
        _showMessage('Quantity must be greater than zero on row ${index + 1}');
        return;
      }
      if (line.cost < 0) {
        _showMessage('Purchase price cannot be negative');
        return;
      }
      items.add(<String, Object?>{
        'product_id': line.productId,
        'quantity': line.qty,
        'unit_cost': line.cost,
      });
    }

    final PurchaseProvider purchaseProvider =
        context.read<PurchaseProvider>();
    final ProductProvider productProvider = context.read<ProductProvider>();

    setState(() => _saving = true);
    try {
      await purchaseProvider.createPurchase(
        supplierCompanyId: _supplierCompanyId,
        supplierName: _supplier.text,
        purchaseDate: _dateText(_purchaseDate),
        referenceNo: _reference.text,
        note: _note.text,
        items: items,
      );
      await productProvider.load();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('$error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _dateText(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _PurchaseLineDraft {
  int? productId;
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController unitCost = TextEditingController(text: '0');

  int get qty => int.tryParse(quantity.text.replaceAll(',', '')) ?? 0;
  double get cost =>
      double.tryParse(unitCost.text.replaceAll(',', '')) ?? 0;
  double get total => qty * cost;

  void dispose() {
    quantity.dispose();
    unitCost.dispose();
  }
}
