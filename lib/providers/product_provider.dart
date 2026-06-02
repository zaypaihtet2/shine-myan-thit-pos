import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<ProductModel> products = <ProductModel>[];
  List<ProductModel> filtered = <ProductModel>[];
  bool loading = false;
  String query = '';
  int? categoryFilter;
  int? companyFilter;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final List<Map<String, Object?>> rows = await _db.query(DatabaseTables.products, orderBy: 'product_name ASC');
    products = rows.map(ProductModel.fromMap).toList();
    _applyFilter();
    loading = false;
    notifyListeners();
  }

  void setSearch(String value) {
    query = value.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void setCategoryFilter(int? value) {
    categoryFilter = value;
    _applyFilter();
    notifyListeners();
  }

  void setCompanyFilter(int? value) {
    companyFilter = value;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    filtered = products.where((ProductModel p) {
      final bool byQuery = query.isEmpty ||
          p.productName.toLowerCase().contains(query) ||
          (p.sku ?? '').toLowerCase().contains(query) ||
          (p.barcode ?? '').toLowerCase().contains(query);
      final bool byCategory = categoryFilter == null || p.categoryId == categoryFilter;
      final bool byCompany = companyFilter == null || p.companyId == companyFilter;
      return byQuery && byCategory && byCompany;
    }).toList();
  }

  Future<String?> copyImageToAppStorage(String sourcePath) async {
    final File source = File(sourcePath);
    if (!await source.exists()) return null;

    final Directory appDir = await getApplicationSupportDirectory();
    final Directory imageDir = Directory(p.join(appDir.path, 'product_images'));
    await imageDir.create(recursive: true);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
    final String targetPath = p.join(imageDir.path, fileName);
    await source.copy(targetPath);
    return targetPath;
  }

  Future<void> save(ProductModel model) async {
    final String now = DateTime.now().toIso8601String();
    final Map<String, Object?> map = model.toMap()
      ..['updated_at'] = now
      ..['created_at'] = model.createdAt ?? now;

    if (model.id == null) {
      await _db.insert(DatabaseTables.products, map..remove('id'));
    } else {
      await _db.update(DatabaseTables.products, map, 'id = ?', <Object?>[model.id!]);
    }
    await load();
  }

  Future<void> delete(int id) async {
    await _db.delete(DatabaseTables.products, 'id = ?', <Object?>[id]);
    await load();
  }

  List<ProductModel> lowStockProducts() {
    return products
        .where((ProductModel p) => p.stockQuantity <= p.lowStockAlertQuantity)
        .toList();
  }

  Future<void> stockInOut({
    required ProductModel product,
    required int qty,
    required bool isStockIn,
    required String note,
  }) async {
    final int newStock = isStockIn ? product.stockQuantity + qty : product.stockQuantity - qty;
    if (newStock < 0) {
      throw Exception('Cannot stock out below zero');
    }

    final String now = DateTime.now().toIso8601String();
    await _db.update(
      DatabaseTables.products,
      <String, Object?>{'stock_quantity': newStock, 'updated_at': now},
      'id = ?',
      <Object?>[product.id!],
    );

    await _db.insert(DatabaseTables.stockHistories, <String, Object?>{
      'product_id': product.id,
      'type': isStockIn ? 'stock_in' : 'stock_out',
      'quantity': qty,
      'old_stock': product.stockQuantity,
      'new_stock': newStock,
      'note': note,
      'created_at': now,
    });

    await load();
  }
}
