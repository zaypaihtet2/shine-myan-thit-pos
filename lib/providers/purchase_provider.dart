import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';

class PurchaseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Map<String, Object?>> purchases = <Map<String, Object?>>[];
  bool loading = false;

  double get totalPurchaseValue => purchases.fold<double>(
        0,
        (double sum, Map<String, Object?> row) =>
            sum + (row['total_amount'] as num? ?? 0).toDouble(),
      );

  int get totalPurchasedQuantity => purchases.fold<int>(
        0,
        (int sum, Map<String, Object?> row) =>
            sum + (row['total_quantity'] as num? ?? 0).toInt(),
      );

  Future<void> ensureTables() async {
    final Database db = await _db.database;
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS ${DatabaseTables.purchases} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_no TEXT NOT NULL UNIQUE,
        supplier_company_id INTEGER,
        supplier_name TEXT NOT NULL,
        reference_no TEXT,
        purchase_date TEXT NOT NULL,
        total_amount REAL NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT,
        updated_at TEXT
      )''',
    );
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS ${DatabaseTables.purchaseItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_entry_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_cost REAL NOT NULL DEFAULT 0,
        line_total REAL NOT NULL DEFAULT 0,
        old_stock INTEGER NOT NULL DEFAULT 0,
        new_stock INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )''',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchase_items_entry '
      'ON ${DatabaseTables.purchaseItems}(purchase_entry_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchase_items_product '
      'ON ${DatabaseTables.purchaseItems}(product_id)',
    );
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    await ensureTables();
    purchases = await _db.rawQuery(
      '''SELECT p.*,
        COUNT(i.id) AS item_count,
        COALESCE(SUM(i.quantity), 0) AS total_quantity
      FROM ${DatabaseTables.purchases} p
      LEFT JOIN ${DatabaseTables.purchaseItems} i
        ON i.purchase_entry_id = p.id
      GROUP BY p.id
      ORDER BY p.purchase_date DESC, p.id DESC''',
    );
    loading = false;
    notifyListeners();
  }

  Future<int> createPurchase({
    required int? supplierCompanyId,
    required String supplierName,
    required String purchaseDate,
    required String referenceNo,
    required String note,
    required List<Map<String, Object?>> items,
  }) async {
    final String cleanSupplier = supplierName.trim();
    if (cleanSupplier.isEmpty) {
      throw Exception('Supplier or company name is required');
    }
    if (items.isEmpty) {
      throw Exception('Add at least one product');
    }

    await ensureTables();
    final Database db = await _db.database;
    final String now = DateTime.now().toIso8601String();

    final int purchaseId = await db.transaction<int>((Transaction txn) async {
      final String purchaseNo = await _nextPurchaseNo(txn, purchaseDate);
      double totalAmount = 0;

      final int entryId = await txn.insert(
        DatabaseTables.purchases,
        <String, Object?>{
          'purchase_no': purchaseNo,
          'supplier_company_id': supplierCompanyId,
          'supplier_name': cleanSupplier,
          'reference_no': referenceNo.trim().isEmpty ? null : referenceNo.trim(),
          'purchase_date': purchaseDate,
          'total_amount': 0,
          'note': note.trim().isEmpty ? null : note.trim(),
          'created_at': now,
          'updated_at': now,
        },
      );

      final Set<int> usedProducts = <int>{};
      for (final Map<String, Object?> item in items) {
        final int productId = (item['product_id'] as num).toInt();
        final int quantity = (item['quantity'] as num).toInt();
        final double unitCost = (item['unit_cost'] as num).toDouble();

        if (!usedProducts.add(productId)) {
          throw Exception('The same product cannot be added twice');
        }
        if (quantity <= 0) {
          throw Exception('Purchase quantity must be greater than zero');
        }
        if (unitCost < 0) {
          throw Exception('Purchase price cannot be negative');
        }

        final List<Map<String, Object?>> productRows = await txn.query(
          DatabaseTables.products,
          where: 'id = ?',
          whereArgs: <Object?>[productId],
          limit: 1,
        );
        if (productRows.isEmpty) {
          throw Exception('Product not found: $productId');
        }

        final Map<String, Object?> product = productRows.first;
        final String productName = '${product['product_name'] ?? ''}';
        final int oldStock = (product['stock_quantity'] as num? ?? 0).toInt();
        final int newStock = oldStock + quantity;
        final double lineTotal = quantity * unitCost;
        totalAmount += lineTotal;

        await txn.insert(
          DatabaseTables.purchaseItems,
          <String, Object?>{
            'purchase_entry_id': entryId,
            'product_id': productId,
            'product_name': productName,
            'quantity': quantity,
            'unit_cost': unitCost,
            'line_total': lineTotal,
            'old_stock': oldStock,
            'new_stock': newStock,
            'created_at': now,
            'updated_at': now,
          },
        );

        await txn.update(
          DatabaseTables.products,
          <String, Object?>{
            'stock_quantity': newStock,
            'buying_price': unitCost,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: <Object?>[productId],
        );

        await txn.insert(
          DatabaseTables.stockHistories,
          <String, Object?>{
            'product_id': productId,
            'type': 'purchase',
            'quantity': quantity,
            'old_stock': oldStock,
            'new_stock': newStock,
            'note': 'Purchase $purchaseNo from $cleanSupplier',
            'created_at': now,
          },
        );
      }

      await txn.update(
        DatabaseTables.purchases,
        <String, Object?>{
          'total_amount': totalAmount,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: <Object?>[entryId],
      );

      return entryId;
    });

    await load();
    return purchaseId;
  }

  Future<Map<String, Object?>> detail(int purchaseId) async {
    await ensureTables();
    final List<Map<String, Object?>> entries = await _db.query(
      DatabaseTables.purchases,
      where: 'id = ?',
      whereArgs: <Object?>[purchaseId],
    );
    if (entries.isEmpty) {
      throw Exception('Purchase entry not found');
    }
    final List<Map<String, Object?>> items = await _db.query(
      DatabaseTables.purchaseItems,
      where: 'purchase_entry_id = ?',
      whereArgs: <Object?>[purchaseId],
      orderBy: 'id ASC',
    );
    return <String, Object?>{
      'purchase': entries.first,
      'items': items,
    };
  }

  Future<String> _nextPurchaseNo(
    Transaction txn,
    String purchaseDate,
  ) async {
    final DateTime parsed = DateTime.tryParse(purchaseDate) ?? DateTime.now();
    final String prefix =
        '${parsed.year.toString().padLeft(4, '0')}'
        '${parsed.month.toString().padLeft(2, '0')}'
        '${parsed.day.toString().padLeft(2, '0')}';
    final List<Map<String, Object?>> rows = await txn.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseTables.purchases} '
      'WHERE purchase_no LIKE ?',
      <Object?>['PUR-$prefix-%'],
    );
    final int count = (rows.first['c'] as num? ?? 0).toInt() + 1;
    return 'PUR-$prefix-${count.toString().padLeft(3, '0')}';
  }
}
