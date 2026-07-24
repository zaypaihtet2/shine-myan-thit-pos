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
    await db.execute('''CREATE TABLE IF NOT EXISTS ${DatabaseTables.purchases} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_no TEXT NOT NULL UNIQUE,
        supplier_company_id INTEGER,
        supplier_name TEXT NOT NULL,
        reference_no TEXT,
        purchase_date TEXT NOT NULL,
        total_amount REAL NOT NULL DEFAULT 0,
        subtotal_amount REAL NOT NULL DEFAULT 0,
        cashback_percent REAL NOT NULL DEFAULT 0,
        cashback_amount REAL NOT NULL DEFAULT 0,
        final_total REAL NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT,
        updated_at TEXT
      )''');
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS ${DatabaseTables.purchaseItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_entry_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        foc_quantity INTEGER NOT NULL DEFAULT 0,
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
    final List<Map<String, Object?>> purchaseColumns = await db.rawQuery(
      'PRAGMA table_info(${DatabaseTables.purchases})',
    );
    final Set<String> purchaseNames = purchaseColumns
        .map((Map<String, Object?> row) => '${row['name']}')
        .toSet();
    for (final Map<String, String> column in <Map<String, String>>[
      <String, String>{
        'name': 'subtotal_amount',
        'type': 'REAL NOT NULL DEFAULT 0',
      },
      <String, String>{
        'name': 'cashback_percent',
        'type': 'REAL NOT NULL DEFAULT 0',
      },
      <String, String>{
        'name': 'cashback_amount',
        'type': 'REAL NOT NULL DEFAULT 0',
      },
      <String, String>{
        'name': 'final_total',
        'type': 'REAL NOT NULL DEFAULT 0',
      },
    ]) {
      if (!purchaseNames.contains(column['name'])) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.purchases} ADD COLUMN ${column['name']} ${column['type']}',
        );
      }
    }
    await db.rawUpdate(
      'UPDATE ${DatabaseTables.purchases} '
      'SET subtotal_amount = total_amount, final_total = total_amount '
      'WHERE subtotal_amount = 0 AND final_total = 0 AND total_amount != 0',
    );
    final List<Map<String, Object?>> itemColumns = await db.rawQuery(
      'PRAGMA table_info(${DatabaseTables.purchaseItems})',
    );
    final bool hasFoc = itemColumns.any(
      (Map<String, Object?> row) => '${row['name']}' == 'foc_quantity',
    );
    if (!hasFoc) {
      await db.execute(
        'ALTER TABLE ${DatabaseTables.purchaseItems} '
        'ADD COLUMN foc_quantity INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    await ensureTables();
    purchases = await _db.rawQuery('''SELECT p.*,
        COUNT(i.id) AS item_count,
        COALESCE(SUM(i.quantity + i.foc_quantity), 0) AS total_quantity
      FROM ${DatabaseTables.purchases} p
      LEFT JOIN ${DatabaseTables.purchaseItems} i
        ON i.purchase_entry_id = p.id
      GROUP BY p.id
      ORDER BY p.purchase_date DESC, p.id DESC''');
    loading = false;
    notifyListeners();
  }

  Future<int> createPurchase({
    required int? supplierCompanyId,
    required String supplierName,
    required String purchaseDate,
    required String referenceNo,
    required String note,
    required double cashbackPercent,
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
      final double cashbackAmount =
          items.fold<double>(
            0,
            (double sum, Map<String, Object?> item) =>
                sum +
                (item['quantity'] as num).toDouble() *
                    (item['unit_cost'] as num).toDouble(),
          ) *
          cashbackPercent /
          100;

      final int entryId = await txn
          .insert(DatabaseTables.purchases, <String, Object?>{
            'purchase_no': purchaseNo,
            'supplier_company_id': supplierCompanyId,
            'supplier_name': cleanSupplier,
            'reference_no': referenceNo.trim().isEmpty
                ? null
                : referenceNo.trim(),
            'purchase_date': purchaseDate,
            'total_amount': 0,
            'subtotal_amount': 0,
            'cashback_percent': cashbackPercent,
            'cashback_amount': 0,
            'final_total': 0,
            'note': note.trim().isEmpty ? null : note.trim(),
            'created_at': now,
            'updated_at': now,
          });

      final Set<int> usedProducts = <int>{};
      for (final Map<String, Object?> item in items) {
        final int productId = (item['product_id'] as num).toInt();
        final int quantity = (item['quantity'] as num).toInt();
        final int focQuantity = (item['foc_quantity'] as num? ?? 0).toInt();
        final double unitCost = (item['unit_cost'] as num).toDouble();

        if (!usedProducts.add(productId)) {
          throw Exception('The same product cannot be added twice');
        }
        if (quantity <= 0) {
          throw Exception('Purchase quantity must be greater than zero');
        }
        if (focQuantity < 0) {
          throw Exception('FOC quantity cannot be negative');
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
        final int totalStockQuantity = quantity + focQuantity;
        final int newStock = oldStock + totalStockQuantity;
        final double lineTotal = quantity * unitCost;
        totalAmount += lineTotal;

        await txn.insert(DatabaseTables.purchaseItems, <String, Object?>{
          'purchase_entry_id': entryId,
          'product_id': productId,
          'product_name': productName,
          'quantity': quantity,
          'foc_quantity': focQuantity,
          'unit_cost': unitCost,
          'line_total': lineTotal,
          'old_stock': oldStock,
          'new_stock': newStock,
          'created_at': now,
          'updated_at': now,
        });

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

        await txn.insert(DatabaseTables.stockHistories, <String, Object?>{
          'product_id': productId,
          'type': 'purchase',
          'quantity': totalStockQuantity,
          'old_stock': oldStock,
          'new_stock': newStock,
          'note': 'Purchase $purchaseNo from $cleanSupplier',
          'created_at': now,
        });
      }

      await txn.update(
        DatabaseTables.purchases,
        <String, Object?>{
          'total_amount': totalAmount - cashbackAmount,
          'subtotal_amount': totalAmount,
          'cashback_percent': cashbackPercent,
          'cashback_amount': cashbackAmount,
          'final_total': totalAmount - cashbackAmount,
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
    return <String, Object?>{'purchase': entries.first, 'items': items};
  }

  Future<void> deletePurchase(int purchaseId) async {
    await ensureTables();
    final Database db = await _db.database;
    await db.transaction<void>((Transaction txn) async {
      final List<Map<String, Object?>> entries = await txn.query(
        DatabaseTables.purchases,
        where: 'id = ?',
        whereArgs: <Object?>[purchaseId],
        limit: 1,
      );
      if (entries.isEmpty) {
        throw Exception('Purchase entry not found');
      }

      final Map<String, Object?> purchase = entries.first;
      final String purchaseNo = '${purchase['purchase_no'] ?? ''}';
      final String supplier = '${purchase['supplier_name'] ?? ''}';
      final String now = DateTime.now().toIso8601String();
      final List<Map<String, Object?>> items = await txn.query(
        DatabaseTables.purchaseItems,
        where: 'purchase_entry_id = ?',
        whereArgs: <Object?>[purchaseId],
      );

      for (final Map<String, Object?> item in items) {
        final int productId = (item['product_id'] as num).toInt();
        final int quantity = (item['quantity'] as num? ?? 0).toInt();
        final int focQuantity = (item['foc_quantity'] as num? ?? 0).toInt();
        final int removeQuantity = quantity + focQuantity;
        final List<Map<String, Object?>> products = await txn.query(
          DatabaseTables.products,
          columns: <String>['stock_quantity', 'product_name'],
          where: 'id = ?',
          whereArgs: <Object?>[productId],
          limit: 1,
        );
        if (products.isEmpty) {
          throw Exception('Product not found while deleting purchase');
        }
        final int oldStock = (products.first['stock_quantity'] as num? ?? 0)
            .toInt();
        if (oldStock < removeQuantity) {
          throw Exception(
            'Cannot delete $purchaseNo: stock for ${products.first['product_name']} '
            'is already lower than the purchased quantity.',
          );
        }
        final int newStock = oldStock - removeQuantity;
        await txn.update(
          DatabaseTables.products,
          <String, Object?>{'stock_quantity': newStock, 'updated_at': now},
          where: 'id = ?',
          whereArgs: <Object?>[productId],
        );
        await txn.insert(DatabaseTables.stockHistories, <String, Object?>{
          'product_id': productId,
          'type': 'purchase_delete',
          'quantity': -removeQuantity,
          'old_stock': oldStock,
          'new_stock': newStock,
          'note': 'Deleted purchase $purchaseNo from $supplier',
          'created_at': now,
        });
      }

      await txn.delete(
        DatabaseTables.purchaseItems,
        where: 'purchase_entry_id = ?',
        whereArgs: <Object?>[purchaseId],
      );
      await txn.delete(
        DatabaseTables.purchases,
        where: 'id = ?',
        whereArgs: <Object?>[purchaseId],
      );
    });
    await load();
  }

  Future<String> _nextPurchaseNo(Transaction txn, String purchaseDate) async {
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
