import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final ProductModel? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _sku;
  late final TextEditingController _selling;
  late final TextEditingController _discountPercent;
  late final TextEditingController _stock;
  late final TextEditingController _lowStock;
  late final TextEditingController _focBuyQty;
  late final TextEditingController _focFreeQty;
  bool _focEnabled = false;
  int? categoryId;
  int? companyId;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    final ProductModel? p = widget.product;
    _name = TextEditingController(text: p?.productName ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _selling = TextEditingController(text: (p?.sellingPrice ?? 0).toString());
    _focEnabled = p?.focEnabled ?? false;
    _discountPercent = TextEditingController(
      text: (p?.discountPercent ?? 0).toString(),
    );
    _stock = TextEditingController(text: (p?.stockQuantity ?? 0).toString());
    _lowStock = TextEditingController(
      text: (p?.lowStockAlertQuantity ?? 5).toString(),
    );
    _focBuyQty = TextEditingController(text: '${p?.focBuyQty ?? 10}');
    _focFreeQty = TextEditingController(text: '${p?.focFreeQty ?? 1}');
    categoryId = p?.categoryId;
    companyId = p?.companyId;
    imagePath = p?.imagePath;
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final companies = context.watch<CompanyProvider>().companies;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 130,
                  height: 130,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imagePath != null && File(imagePath!).existsSync()
                        ? Image.file(File(imagePath!), fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_outlined, size: 44),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose Image'),
                    ),
                    if (imagePath != null)
                      TextButton.icon(
                        onPressed: () => setState(() => imagePath = null),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _barcode,
                    decoration: const InputDecoration(labelText: 'Barcode'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _sku,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _discountPercent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Product Discount %',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: categoryId,
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No Category'),
                      ),
                      ...categories.map(
                        (e) => DropdownMenuItem<int?>(
                          value: e.id,
                          child: Text(e.name),
                        ),
                      ),
                    ],
                    onChanged: (int? value) =>
                        setState(() => categoryId = value),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: companyId,
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No Company'),
                      ),
                      ...companies.map(
                        (e) => DropdownMenuItem<int?>(
                          value: e.id,
                          child: Text(e.name),
                        ),
                      ),
                    ],
                    onChanged: (int? value) =>
                        setState(() => companyId = value),
                    decoration: const InputDecoration(
                      labelText: 'Company/Brand',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _selling,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Selling Price',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _focEnabled,
              onChanged: (bool value) {
                setState(() => _focEnabled = value);
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable FOC Rule'),
              subtitle: const Text('Example: buy 10, get 1 free'),
            ),
            if (_focEnabled)
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _focBuyQty,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Buy Qty'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _focFreeQty,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'FOC Qty'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lowStock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Low Stock Alert Qty',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _sku.dispose();
    _selling.dispose();
    _discountPercent.dispose();
    _stock.dispose();
    _lowStock.dispose();
    _focBuyQty.dispose();
    _focFreeQty.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final FilePickerResult? pick = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose product image',
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );

    if (!mounted) return;
    if (pick == null || pick.files.single.path == null) return;
    final ProductProvider provider = context.read<ProductProvider>();
    final String? copied = await provider.copyImageToAppStorage(
      pick.files.single.path!,
    );
    if (copied != null) {
      setState(() => imagePath = copied);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;

    final ProductProvider provider = context.read<ProductProvider>();
    await provider.save(
      ProductModel(
        id: widget.product?.id,
        productName: _name.text.trim(),
        categoryId: categoryId,
        companyId: companyId,
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        imagePath: imagePath,
        discountPercent: double.tryParse(_discountPercent.text) ?? 0,
        buyingPrice: double.tryParse(_selling.text) ?? 0,
        sellingPrice: double.tryParse(_selling.text) ?? 0,
        samePriceAsBuying: false,
        focEnabled: _focEnabled,
        focBuyQty: int.tryParse(_focBuyQty.text) ?? 10,
        focFreeQty: int.tryParse(_focFreeQty.text) ?? 1,
        stockQuantity: int.tryParse(_stock.text) ?? 0,
        lowStockAlertQuantity: int.tryParse(_lowStock.text) ?? 5,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
