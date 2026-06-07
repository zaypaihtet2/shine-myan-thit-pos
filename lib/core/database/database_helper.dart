import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/app_constants.dart';
import '../utils/formatters.dart';
import 'database_tables.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<String> databasePath() async {
    final Directory appDir = await getApplicationSupportDirectory();
    await appDir.create(recursive: true);
    return p.join(appDir.path, AppConstants.dbName);
  }

  Future<Database> _open() async {
    final String path = await databasePath();
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: (Database db, int version) async {
        for (final String statement in DatabaseTables.createStatements) {
          await db.execute(statement);
        }
        await _seedDefaults(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await _migrate(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final List<Map<String, Object?>> tableInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.sales})',
      );
      final Set<String> columns = tableInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!columns.contains('sale_type')) {
        await db.execute(
          "ALTER TABLE ${DatabaseTables.sales} ADD COLUMN sale_type TEXT NOT NULL DEFAULT 'sale'",
        );
      }
      if (!columns.contains('reference_sale_id')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN reference_sale_id INTEGER',
        );
      }
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS ${DatabaseTables.saleReturns} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          return_no TEXT NOT NULL,
          note TEXT,
          total_return_amount REAL NOT NULL DEFAULT 0,
          total_return_profit REAL NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT
        )''',
      );
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS ${DatabaseTables.saleReturnItems} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_return_id INTEGER NOT NULL,
          sale_item_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          product_name TEXT,
          return_quantity INTEGER NOT NULL,
          selling_price REAL NOT NULL DEFAULT 0,
          buying_price REAL NOT NULL DEFAULT 0,
          line_total REAL NOT NULL DEFAULT 0,
          line_profit REAL NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT
        )''',
      );
      final String now = DateTime.now().toIso8601String();
      await db.insert(DatabaseTables.settings, <String, Object?>{
        'key': 'voucher_logo_path',
        'value': '',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert(DatabaseTables.settings, <String, Object?>{
        'key': 'voucher_paper_size_mm',
        'value': '80',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert(DatabaseTables.settings, <String, Object?>{
        'key': 'voucher_font_size',
        'value': '10',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert(DatabaseTables.settings, <String, Object?>{
        'key': 'demo_data_seeded',
        'value': '0',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (newVersion >= 2) {
      final List<Map<String, Object?>> rows = await db.query(
        DatabaseTables.settings,
      );
      final Set<String> keys = rows
          .map((Map<String, Object?> row) => '${row['key'] ?? ''}')
          .toSet();
      final String now = DateTime.now().toIso8601String();
      if (!keys.contains('voucher_logo_path')) {
        await db.insert(DatabaseTables.settings, <String, Object?>{
          'key': 'voucher_logo_path',
          'value': '',
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      if (!keys.contains('voucher_paper_size_mm')) {
        await db.insert(DatabaseTables.settings, <String, Object?>{
          'key': 'voucher_paper_size_mm',
          'value': '80',
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      if (!keys.contains('voucher_font_size')) {
        await db.insert(DatabaseTables.settings, <String, Object?>{
          'key': 'voucher_font_size',
          'value': '10',
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      if (!keys.contains('demo_data_seeded')) {
        await db.insert(DatabaseTables.settings, <String, Object?>{
          'key': 'demo_data_seeded',
          'value': '0',
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    if (oldVersion < 3) {
      final List<Map<String, Object?>> productInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.products})',
      );
      final Set<String> productColumns = productInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!productColumns.contains('discount_percent')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.products} ADD COLUMN discount_percent REAL NOT NULL DEFAULT 0',
        );
      }

      final List<Map<String, Object?>> saleItemInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.saleItems})',
      );
      final Set<String> saleItemColumns = saleItemInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!saleItemColumns.contains('discount_percent')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN discount_percent REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleItemColumns.contains('discount_amount')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0',
        );
      }
    }

    if (oldVersion < 4) {
      final List<Map<String, Object?>> saleItemInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.saleItems})',
      );
      final Set<String> saleItemColumns = saleItemInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!saleItemColumns.contains('sale_option')) {
        await db.execute(
          "ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN sale_option TEXT NOT NULL DEFAULT 'normal'",
        );
      }
    }

    if (oldVersion < 5) {
      final List<Map<String, Object?>> saleInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.sales})',
      );
      final Set<String> saleColumns = saleInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!saleColumns.contains('customer_name')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN customer_name TEXT',
        );
      }
    }

    if (oldVersion < 6) {
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS ${DatabaseTables.customers} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'regular',
          rebate_percent REAL NOT NULL DEFAULT 0,
          cashback_percent REAL NOT NULL DEFAULT 0,
          status TEXT DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT
        )''',
      );

      final List<Map<String, Object?>> saleInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.sales})',
      );
      final Set<String> saleColumns = saleInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!saleColumns.contains('customer_id')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN customer_id INTEGER',
        );
      }
      if (!saleColumns.contains('customer_type')) {
        await db.execute(
          "ALTER TABLE ${DatabaseTables.sales} ADD COLUMN customer_type TEXT NOT NULL DEFAULT 'regular'",
        );
      }
    }

    if (oldVersion < 7) {
      final List<Map<String, Object?>> productInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.products})',
      );
      final Set<String> productColumns = productInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!productColumns.contains('same_price_as_buying')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.products} ADD COLUMN same_price_as_buying INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!productColumns.contains('foc_enabled')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.products} ADD COLUMN foc_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!productColumns.contains('foc_buy_qty')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.products} ADD COLUMN foc_buy_qty INTEGER NOT NULL DEFAULT 10',
        );
      }
      if (!productColumns.contains('foc_free_qty')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.products} ADD COLUMN foc_free_qty INTEGER NOT NULL DEFAULT 1',
        );
      }

      final List<Map<String, Object?>> customerInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.customers})',
      );
      final Set<String> customerColumns = customerInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!customerColumns.contains('price_mode')) {
        await db.execute(
          "ALTER TABLE ${DatabaseTables.customers} ADD COLUMN price_mode TEXT NOT NULL DEFAULT 'normal'",
        );
      }
      if (!customerColumns.contains('price_percent')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.customers} ADD COLUMN price_percent REAL NOT NULL DEFAULT 0',
        );
      }

      final List<Map<String, Object?>> saleInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.sales})',
      );
      final Set<String> saleColumns = saleInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!saleColumns.contains('rebate_percent')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN rebate_percent REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleColumns.contains('rebate_amount')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN rebate_amount REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleColumns.contains('customer_cashback_percent')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN customer_cashback_percent REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleColumns.contains('customer_cashback_amount')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN customer_cashback_amount REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleColumns.contains('office_payable_amount')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN office_payable_amount REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleColumns.contains('owner_keep_profit')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.sales} ADD COLUMN owner_keep_profit REAL NOT NULL DEFAULT 0',
        );
      }

      final List<Map<String, Object?>> saleItemInfo = await db.rawQuery(
        'PRAGMA table_info(${DatabaseTables.saleItems})',
      );
      final Set<String> saleItemColumns = saleItemInfo
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}')
          .toSet();
      if (!saleItemColumns.contains('paid_quantity')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN paid_quantity INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!saleItemColumns.contains('foc_quantity')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN foc_quantity INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!saleItemColumns.contains('rebate_percent')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN rebate_percent REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleItemColumns.contains('rebate_amount')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN rebate_amount REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleItemColumns.contains('unit_price_applied')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN unit_price_applied REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleItemColumns.contains('customer_cashback_percent')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN customer_cashback_percent REAL NOT NULL DEFAULT 0',
        );
      }
      if (!saleItemColumns.contains('customer_cashback_amount')) {
        await db.execute(
          'ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN customer_cashback_amount REAL NOT NULL DEFAULT 0',
        );
      }
    }

    if (oldVersion < 8) {
      final String now = DateTime.now().toIso8601String();
      await db.update(
        DatabaseTables.settings,
        <String, Object?>{'value': 'Shine Myan Thit', 'updated_at': now},
        where: 'key = ? AND value = ?',
        whereArgs: <Object?>['shop_name', 'My Shop'],
      );
    }
  }

  Future<void> _seedDefaults(Database db) async {
    final String now = DateTime.now().toIso8601String();
    for (final String name in AppConstants.quickCategories) {
      await db.insert(DatabaseTables.categories, <String, Object?>{
        'name': name,
        'status': 'active',
        'created_at': now,
        'updated_at': now,
      });
    }

    final Map<String, String> defaults = <String, String>{
      'shop_name': 'Shine Myan Thit',
      'shop_phone': '',
      'shop_address': '',
      'default_customer_cd_percent': '2',
      'currency_symbol': 'Ks',
      'voucher_footer_text': 'Thank you. Please come again!',
      'voucher_logo_path': '',
      'voucher_paper_size_mm': '80',
      'voucher_font_size': '10',
      'low_stock_alert_default': '5',
      'dark_mode': '0',
      'demo_data_seeded': '0',
    };

    for (final MapEntry<String, String> item in defaults.entries) {
      await db.insert(DatabaseTables.settings, <String, Object?>{
        'key': item.key,
        'value': item.value,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final Database db = await database;
    return db.rawQuery(sql, args);
  }

  Future<int> insert(String table, Map<String, Object?> data) async {
    final Database db = await database;
    return db.insert(table, data);
  }

  Future<int> update(
    String table,
    Map<String, Object?> data,
    String where,
    List<Object?> whereArgs,
  ) async {
    final Database db = await database;
    return db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<Object?> whereArgs,
  ) async {
    final Database db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final Database db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<Map<String, String>> getSettings() async {
    final List<Map<String, Object?>> rows = await query(
      DatabaseTables.settings,
    );
    return <String, String>{
      for (final Map<String, Object?> row in rows)
        '${row['key']}': '${row['value'] ?? ''}',
    };
  }

  Future<void> saveSetting(String key, String value) async {
    final Database db = await database;
    final String now = DateTime.now().toIso8601String();
    await db.insert(DatabaseTables.settings, <String, Object?>{
      'key': key,
      'value': value,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> nextInvoiceNo() async {
    final Database db = await database;
    final DateTime now = DateTime.now();
    final String datePrefix =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseTables.sales} WHERE invoice_no LIKE ?',
      <Object?>['INV-$datePrefix-%'],
    );
    final int count = (rows.first['c'] as int? ?? 0) + 1;
    return Formatters.invoiceNo(count, now);
  }

  Future<int> saveSale({
    required String invoiceNo,
    required int? customerId,
    required String customerName,
    required String customerType,
    required List<Map<String, Object?>> items,
    required double subtotal,
    required double discountAmount,
    required double rebatePercent,
    required double rebateAmount,
    required double customerCdPercent,
    required double customerCdAmount,
    required double customerCashbackPercent,
    required double customerCashbackAmount,
    required double companyCashbackAmount,
    required double officePayableAmount,
    required double ownerKeepProfit,
    required double finalTotal,
    required double paidAmount,
    required double changeAmount,
    required String paymentMethod,
    required double profitAmount,
  }) async {
    final Database db = await database;
    final String now = DateTime.now().toIso8601String();

    return db.transaction<int>((Transaction txn) async {
      for (final Map<String, Object?> item in items) {
        final int productId = item['product_id'] as int;
        final int qty = item['quantity'] as int;
        final List<Map<String, Object?>> productRows = await txn.query(
          DatabaseTables.products,
          where: 'id = ?',
          whereArgs: <Object?>[productId],
          limit: 1,
        );
        if (productRows.isEmpty) {
          throw Exception('Product not found: $productId');
        }

        final int oldStock = (productRows.first['stock_quantity'] as int? ?? 0);
        if (oldStock < qty) {
          throw Exception(
            'Insufficient stock for ${productRows.first['product_name']}',
          );
        }

        final int newStock = oldStock - qty;
        await txn.update(
          DatabaseTables.products,
          <String, Object?>{'stock_quantity': newStock, 'updated_at': now},
          where: 'id = ?',
          whereArgs: <Object?>[productId],
        );

        await txn.insert(DatabaseTables.stockHistories, <String, Object?>{
          'product_id': productId,
          'type': 'sale',
          'quantity': qty,
          'old_stock': oldStock,
          'new_stock': newStock,
          'note': 'Auto deduction by sale',
          'created_at': now,
        });
      }

      final int saleId = await txn
          .insert(DatabaseTables.sales, <String, Object?>{
            'invoice_no': invoiceNo,
            'customer_id': customerId,
            'customer_name': customerName.trim().isEmpty
                ? null
                : customerName.trim(),
            'customer_type': customerType,
            'sale_type': 'sale',
            'reference_sale_id': null,
            'subtotal': subtotal,
            'discount_amount': discountAmount,
            'rebate_percent': rebatePercent,
            'rebate_amount': rebateAmount,
            'customer_cd_percent': customerCdPercent,
            'customer_cd_amount': customerCdAmount,
            'customer_cashback_percent': customerCashbackPercent,
            'customer_cashback_amount': customerCashbackAmount,
            'company_cashback_amount': companyCashbackAmount,
            'office_payable_amount': officePayableAmount,
            'owner_keep_profit': ownerKeepProfit,
            'final_total': finalTotal,
            'paid_amount': paidAmount,
            'change_amount': changeAmount,
            'payment_method': paymentMethod,
            'profit_amount': profitAmount,
            'sale_date': now,
            'created_at': now,
            'updated_at': now,
          });

      for (final Map<String, Object?> item in items) {
        await txn.insert(DatabaseTables.saleItems, <String, Object?>{
          ...item,
          'sale_id': saleId,
          'created_at': now,
          'updated_at': now,
        });
      }

      return saleId;
    });
  }

  Future<void> deleteSale(int saleId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> items = await txn.query(
        DatabaseTables.saleItems,
        where: 'sale_id = ?',
        whereArgs: <Object?>[saleId],
      );

      final String now = DateTime.now().toIso8601String();
      for (final Map<String, Object?> item in items) {
        final int productId = item['product_id'] as int;
        final int qty = item['quantity'] as int;
        final List<Map<String, Object?>> productRows = await txn.query(
          DatabaseTables.products,
          where: 'id = ?',
          whereArgs: <Object?>[productId],
          limit: 1,
        );
        if (productRows.isNotEmpty) {
          final int oldStock = productRows.first['stock_quantity'] as int? ?? 0;
          final int newStock = oldStock + qty;
          await txn.update(
            DatabaseTables.products,
            <String, Object?>{'stock_quantity': newStock, 'updated_at': now},
            where: 'id = ?',
            whereArgs: <Object?>[productId],
          );
          await txn.insert(DatabaseTables.stockHistories, <String, Object?>{
            'product_id': productId,
            'type': 'sale_delete_revert',
            'quantity': qty,
            'old_stock': oldStock,
            'new_stock': newStock,
            'note': 'Stock reverted from deleted sale',
            'created_at': now,
          });
        }
      }

      await txn.delete(
        DatabaseTables.saleItems,
        where: 'sale_id = ?',
        whereArgs: <Object?>[saleId],
      );
      await txn.delete(
        DatabaseTables.sales,
        where: 'id = ?',
        whereArgs: <Object?>[saleId],
      );
    });
  }

  Future<void> seedDemoData() async {
    final Database db = await database;
    final Map<String, String> settings = await getSettings();
    await db.transaction((Transaction txn) async {
      final String now = DateTime.now().toIso8601String();
      final List<Map<String, Object?>> companyRows = await txn.query(
        DatabaseTables.companies,
        orderBy: 'id ASC',
      );
      final Set<String> existingCompanyNames = companyRows
          .map((Map<String, Object?> e) => '${e['name'] ?? ''}'.toLowerCase())
          .toSet();

      final List<Map<String, Object?>> companySeeds = <Map<String, Object?>>[
        <String, Object?>{'name': 'Elegon', 'cashback_percent': 5.0},
        <String, Object?>{'name': 'Shwe Li Maw', 'cashback_percent': 5.0},
        <String, Object?>{'name': 'Green Land', 'cashback_percent': 12.0},
      ];

      for (final Map<String, Object?> company in companySeeds) {
        final String name = '${company['name'] ?? ''}'.toLowerCase();
        if (!existingCompanyNames.contains(name)) {
          await txn.insert(DatabaseTables.companies, <String, Object?>{
            'name': company['name'],
            'cashback_percent': company['cashback_percent'],
            'status': 'active',
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      final List<Map<String, Object?>> categories = await txn.query(
        DatabaseTables.categories,
        orderBy: 'id ASC',
      );
      final List<Map<String, Object?>> companies = await txn.query(
        DatabaseTables.companies,
        orderBy: 'id ASC',
      );
      final int categoryId = categories.isEmpty
          ? 1
          : (categories.first['id'] as int? ?? 1);
      final int companyId = companies.isEmpty
          ? 1
          : (companies.first['id'] as int? ?? 1);

      int categoryIdByName(String name) {
        for (final Map<String, Object?> c in categories) {
          if ('${c['name'] ?? ''}'.toLowerCase() == name.toLowerCase()) {
            return c['id'] as int? ?? categoryId;
          }
        }
        return categoryId;
      }

      int companyIdByName(String name) {
        for (final Map<String, Object?> c in companies) {
          if ('${c['name'] ?? ''}'.toLowerCase() == name.toLowerCase()) {
            return c['id'] as int? ?? companyId;
          }
        }
        return companyId;
      }

      final List<Map<String, Object?>> existingProductRows = await txn.query(
        DatabaseTables.products,
        orderBy: 'id ASC',
      );
      final Set<String> existingSkus = existingProductRows
          .map((Map<String, Object?> p) => '${p['sku'] ?? ''}'.toUpperCase())
          .toSet();

      final List<Map<String, Object?>> demoProducts = <Map<String, Object?>>[
        <String, Object?>{
          'product_name': 'Premium Cooking Oil 1L',
          'category': 'Food',
          'company': 'Elegon',
          'barcode': '111000111',
          'sku': 'OIL-001',
          'discount_percent': 5,
          'buying_price': 6500,
          'selling_price': 8000,
          'stock_quantity': 40,
          'low_stock_alert_quantity': 5,
        },
        <String, Object?>{
          'product_name': 'Instant Coffee Mix',
          'category': 'Drink',
          'company': 'Shwe Li Maw',
          'barcode': '222000222',
          'sku': 'COF-001',
          'discount_percent': 0,
          'buying_price': 3000,
          'selling_price': 4000,
          'stock_quantity': 60,
          'low_stock_alert_quantity': 10,
        },
        <String, Object?>{
          'product_name': 'Green Tea 30 Pack',
          'category': 'Drink',
          'company': 'Green Land',
          'barcode': '333000333',
          'sku': 'TEA-001',
          'discount_percent': 10,
          'buying_price': 4200,
          'selling_price': 5500,
          'stock_quantity': 35,
          'low_stock_alert_quantity': 8,
        },
        <String, Object?>{
          'product_name': 'Chocolate Biscuit',
          'category': 'Food',
          'company': 'Elegon',
          'barcode': '444000444',
          'sku': 'BIS-001',
          'discount_percent': 0,
          'buying_price': 1200,
          'selling_price': 1800,
          'stock_quantity': 120,
          'low_stock_alert_quantity': 20,
        },
        <String, Object?>{
          'product_name': 'Strawberry Jam 250g',
          'category': 'Food',
          'company': 'Shwe Li Maw',
          'barcode': '555000555',
          'sku': 'JAM-001',
          'discount_percent': 8,
          'buying_price': 2800,
          'selling_price': 3600,
          'stock_quantity': 45,
          'low_stock_alert_quantity': 8,
        },
        <String, Object?>{
          'product_name': 'Hand Wash Lemon 500ml',
          'category': 'Cosmetic',
          'company': 'Green Land',
          'barcode': '666000666',
          'sku': 'COS-001',
          'discount_percent': 0,
          'buying_price': 2600,
          'selling_price': 3400,
          'stock_quantity': 50,
          'low_stock_alert_quantity': 10,
        },
        <String, Object?>{
          'product_name': 'Face Powder Natural',
          'category': 'Cosmetic',
          'company': 'Elegon',
          'barcode': '777000777',
          'sku': 'COS-002',
          'discount_percent': 12,
          'buying_price': 5000,
          'selling_price': 6500,
          'stock_quantity': 28,
          'low_stock_alert_quantity': 6,
        },
        <String, Object?>{
          'product_name': 'Phone USB Cable Type-C',
          'category': 'Phone Item',
          'company': 'Shwe Li Maw',
          'barcode': '888000888',
          'sku': 'PHN-001',
          'discount_percent': 0,
          'buying_price': 2200,
          'selling_price': 3200,
          'stock_quantity': 70,
          'low_stock_alert_quantity': 12,
        },
        <String, Object?>{
          'product_name': 'Power Adapter 20W',
          'category': 'Phone Item',
          'company': 'Green Land',
          'barcode': '999000999',
          'sku': 'PHN-002',
          'discount_percent': 0,
          'buying_price': 6500,
          'selling_price': 8500,
          'stock_quantity': 32,
          'low_stock_alert_quantity': 6,
        },
        <String, Object?>{
          'product_name': 'Pain Relief Tablet 10s',
          'category': 'Medicine',
          'company': 'Elegon',
          'barcode': '101000101',
          'sku': 'MED-001',
          'discount_percent': 0,
          'buying_price': 900,
          'selling_price': 1400,
          'stock_quantity': 150,
          'low_stock_alert_quantity': 25,
        },
        <String, Object?>{
          'product_name': 'Vitamin C 20s',
          'category': 'Medicine',
          'company': 'Green Land',
          'barcode': '102000102',
          'sku': 'MED-002',
          'discount_percent': 5,
          'buying_price': 1800,
          'selling_price': 2600,
          'stock_quantity': 90,
          'low_stock_alert_quantity': 15,
        },
        <String, Object?>{
          'product_name': 'Hair Clip Set',
          'category': 'Accessories',
          'company': 'Shwe Li Maw',
          'barcode': '103000103',
          'sku': 'ACC-001',
          'discount_percent': 0,
          'buying_price': 700,
          'selling_price': 1200,
          'stock_quantity': 140,
          'low_stock_alert_quantity': 20,
        },
      ];

      for (final Map<String, Object?> item in demoProducts) {
        final String sku = '${item['sku'] ?? ''}'.toUpperCase();
        if (sku.isEmpty || existingSkus.contains(sku)) {
          continue;
        }
        await txn.insert(DatabaseTables.products, <String, Object?>{
          'product_name': item['product_name'],
          'category_id': categoryIdByName('${item['category']}'),
          'company_id': companyIdByName('${item['company']}'),
          'barcode': item['barcode'],
          'sku': item['sku'],
          'discount_percent': item['discount_percent'],
          'buying_price': item['buying_price'],
          'selling_price': item['selling_price'],
          'stock_quantity': item['stock_quantity'],
          'low_stock_alert_quantity': item['low_stock_alert_quantity'],
          'status': 'active',
          'created_at': now,
          'updated_at': now,
        });
      }

      final List<Map<String, Object?>> productRows = await txn.query(
        DatabaseTables.products,
        orderBy: 'id ASC',
        limit: 2,
      );
      if (productRows.length >= 2 &&
          (settings['demo_data_seeded'] ?? '0') != '1') {
        final DateTime nowDate = DateTime.now();
        final String datePrefix =
            '${nowDate.year.toString().padLeft(4, '0')}${nowDate.month.toString().padLeft(2, '0')}${nowDate.day.toString().padLeft(2, '0')}';
        final List<Map<String, Object?>> invRows = await txn.rawQuery(
          'SELECT COUNT(*) AS c FROM ${DatabaseTables.sales} WHERE invoice_no LIKE ?',
          <Object?>['INV-$datePrefix-%'],
        );
        final int count = (invRows.first['c'] as int? ?? 0) + 1;
        final String invoice = Formatters.invoiceNo(count, nowDate);
        const int q1 = 2;
        const int q2 = 3;
        final double p1Sell = (productRows[0]['selling_price'] as num? ?? 0)
            .toDouble();
        final double p2Sell = (productRows[1]['selling_price'] as num? ?? 0)
            .toDouble();
        final double p1Buy = (productRows[0]['buying_price'] as num? ?? 0)
            .toDouble();
        final double p2Buy = (productRows[1]['buying_price'] as num? ?? 0)
            .toDouble();
        final double p1DiscountPercent =
            (productRows[0]['discount_percent'] as num? ?? 0).toDouble();
        final double p2DiscountPercent =
            (productRows[1]['discount_percent'] as num? ?? 0).toDouble();
        final double p1DiscountAmount = p1Sell * q1 * p1DiscountPercent / 100;
        final double p2DiscountAmount = p2Sell * q2 * p2DiscountPercent / 100;

        final double subtotal =
            (p1Sell * q1 - p1DiscountAmount) + (p2Sell * q2 - p2DiscountAmount);
        final double customerCdPercent = 2;
        final double customerCdAmount = subtotal * (customerCdPercent / 100);
        const double discount = 500;
        final double cbPercent =
            (companies.first['cashback_percent'] as num? ?? 0).toDouble();
        final double cashback = subtotal * cbPercent / 100;
        final double finalTotal = subtotal - discount - customerCdAmount;
        final double profit = cashback;

        final int saleId = await txn
            .insert(DatabaseTables.sales, <String, Object?>{
              'invoice_no': invoice,
              'sale_type': 'sale',
              'reference_sale_id': null,
              'subtotal': subtotal,
              'discount_amount': discount,
              'customer_cd_percent': customerCdPercent,
              'customer_cd_amount': customerCdAmount,
              'company_cashback_amount': cashback,
              'final_total': finalTotal,
              'paid_amount': finalTotal,
              'change_amount': 0,
              'payment_method': 'Cash',
              'profit_amount': profit,
              'sale_date': now,
              'created_at': now,
              'updated_at': now,
            });

        await txn.insert(DatabaseTables.saleItems, <String, Object?>{
          'sale_id': saleId,
          'product_id': productRows[0]['id'],
          'company_id': productRows[0]['company_id'],
          'product_name': productRows[0]['product_name'],
          'quantity': q1,
          'discount_percent': p1DiscountPercent,
          'discount_amount': p1DiscountAmount,
          'buying_price': p1Buy,
          'selling_price': p1Sell,
          'subtotal': p1Sell * q1 - p1DiscountAmount,
          'company_cashback_percent': cbPercent,
          'company_cashback_amount':
              (p1Sell * q1 - p1DiscountAmount) * cbPercent / 100,
          'profit_amount': (p1Sell * q1 - p1DiscountAmount) * cbPercent / 100,
          'created_at': now,
          'updated_at': now,
        });

        await txn.insert(DatabaseTables.saleItems, <String, Object?>{
          'sale_id': saleId,
          'product_id': productRows[1]['id'],
          'company_id': productRows[1]['company_id'],
          'product_name': productRows[1]['product_name'],
          'quantity': q2,
          'discount_percent': p2DiscountPercent,
          'discount_amount': p2DiscountAmount,
          'buying_price': p2Buy,
          'selling_price': p2Sell,
          'subtotal': p2Sell * q2 - p2DiscountAmount,
          'company_cashback_percent': cbPercent,
          'company_cashback_amount':
              (p2Sell * q2 - p2DiscountAmount) * cbPercent / 100,
          'profit_amount': (p2Sell * q2 - p2DiscountAmount) * cbPercent / 100,
          'created_at': now,
          'updated_at': now,
        });

        final int oldStock1 = productRows[0]['stock_quantity'] as int? ?? 0;
        final int oldStock2 = productRows[1]['stock_quantity'] as int? ?? 0;
        final int newStock1 = oldStock1 - q1;
        final int newStock2 = oldStock2 - q2;

        await txn.update(
          DatabaseTables.products,
          <String, Object?>{'stock_quantity': newStock1, 'updated_at': now},
          where: 'id = ?',
          whereArgs: <Object?>[productRows[0]['id']],
        );
        await txn.update(
          DatabaseTables.products,
          <String, Object?>{'stock_quantity': newStock2, 'updated_at': now},
          where: 'id = ?',
          whereArgs: <Object?>[productRows[1]['id']],
        );

        await txn.insert(DatabaseTables.stockHistories, <String, Object?>{
          'product_id': productRows[0]['id'],
          'type': 'sale',
          'quantity': q1,
          'old_stock': oldStock1,
          'new_stock': newStock1,
          'note': 'Demo sale seed',
          'created_at': now,
        });
        await txn.insert(DatabaseTables.stockHistories, <String, Object?>{
          'product_id': productRows[1]['id'],
          'type': 'sale',
          'quantity': q2,
          'old_stock': oldStock2,
          'new_stock': newStock2,
          'note': 'Demo sale seed',
          'created_at': now,
        });
      }
    });

    final String now = DateTime.now().toIso8601String();
    await db.insert(DatabaseTables.settings, <String, Object?>{
      'key': 'demo_data_seeded',
      'value': '1',
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> resetAndReseedDemoData() async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete(DatabaseTables.saleReturnItems);
      await txn.delete(DatabaseTables.saleReturns);
      await txn.delete(DatabaseTables.saleItems);
      await txn.delete(DatabaseTables.sales);
      await txn.delete(DatabaseTables.stockHistories);
      await txn.delete(DatabaseTables.products);

      final String now = DateTime.now().toIso8601String();
      await txn.insert(DatabaseTables.settings, <String, Object?>{
        'key': 'demo_data_seeded',
        'value': '0',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    await seedDemoData();
  }

  Future<int> createSaleReturn({
    required int saleId,
    required List<Map<String, Object?>> returnLines,
    String note = '',
  }) async {
    final Database db = await database;
    final String now = DateTime.now().toIso8601String();

    return db.transaction<int>((Transaction txn) async {
      final List<Map<String, Object?>> saleRows = await txn.query(
        DatabaseTables.sales,
        where: 'id = ?',
        whereArgs: <Object?>[saleId],
        limit: 1,
      );
      if (saleRows.isEmpty) {
        throw Exception('Sale not found');
      }
      final Map<String, Object?> originalSale = saleRows.first;
      if ('${originalSale['sale_type'] ?? 'sale'}' != 'sale') {
        throw Exception('Only normal sales can be returned');
      }

      double returnSubtotal = 0;
      double returnCashback = 0;
      final List<Map<String, Object?>> itemRows = <Map<String, Object?>>[];

      for (final Map<String, Object?> req in returnLines) {
        final int saleItemId = req['sale_item_id'] as int;
        final int returnQty = req['return_quantity'] as int;
        if (returnQty <= 0) {
          continue;
        }

        final List<Map<String, Object?>> saleItemRows = await txn.query(
          DatabaseTables.saleItems,
          where: 'id = ? AND sale_id = ?',
          whereArgs: <Object?>[saleItemId, saleId],
          limit: 1,
        );
        if (saleItemRows.isEmpty) {
          throw Exception('Invalid sale item id: $saleItemId');
        }

        final Map<String, Object?> saleItem = saleItemRows.first;
        final int soldQty = saleItem['quantity'] as int? ?? 0;
        final List<Map<String, Object?>> returnedQtyRows = await txn.rawQuery(
          'SELECT COALESCE(SUM(return_quantity),0) AS r FROM ${DatabaseTables.saleReturnItems} WHERE sale_item_id = ?',
          <Object?>[saleItemId],
        );
        final int alreadyReturned = returnedQtyRows.first['r'] as int? ?? 0;
        final int availableQty = soldQty - alreadyReturned;

        if (returnQty > availableQty) {
          throw Exception(
            'Return quantity exceeds available for ${saleItem['product_name']}',
          );
        }

        final double selling = (saleItem['selling_price'] as num? ?? 0)
            .toDouble();
        final double buying = (saleItem['buying_price'] as num? ?? 0)
            .toDouble();
        final double lineDiscountAmount =
            (saleItem['discount_amount'] as num? ?? 0).toDouble();
        final double cashbackPercent =
            (saleItem['company_cashback_percent'] as num? ?? 0).toDouble();

        final double lineGross = selling * returnQty;
        final double lineDiscount = soldQty <= 0
            ? 0
            : lineDiscountAmount * (returnQty / soldQty);
        final double lineTotal = lineGross - lineDiscount;
        final double lineCashback = lineTotal * cashbackPercent / 100;
        final double lineProfitReversal = -lineCashback;

        returnSubtotal += lineTotal;
        returnCashback += lineCashback;

        itemRows.add(<String, Object?>{
          'sale_item_id': saleItemId,
          'product_id': saleItem['product_id'],
          'product_name': saleItem['product_name'],
          'return_quantity': returnQty,
          'selling_price': selling,
          'buying_price': buying,
          'line_total': lineTotal,
          'line_profit': lineProfitReversal,
        });
      }

      if (itemRows.isEmpty) {
        throw Exception('No return quantity selected');
      }

      final double originalSubtotal = (originalSale['subtotal'] as num? ?? 0)
          .toDouble();
      final double ratio = originalSubtotal <= 0
          ? 0
          : (returnSubtotal / originalSubtotal);
      final double originalDiscount =
          (originalSale['discount_amount'] as num? ?? 0).toDouble();
      final double originalCdAmount =
          (originalSale['customer_cd_amount'] as num? ?? 0).toDouble();
      final double originalCdPercent =
          (originalSale['customer_cd_percent'] as num? ?? 0).toDouble();

      final double returnDiscount = originalDiscount * ratio;
      final double returnCdAmount = originalCdAmount * ratio;
      final double returnFinal =
          returnSubtotal - returnDiscount - returnCdAmount;
      final double returnProfit = -returnCashback;

      final List<Map<String, Object?>> countRows = await txn.rawQuery(
        'SELECT COUNT(*) AS c FROM ${DatabaseTables.saleReturns} WHERE sale_id = ?',
        <Object?>[saleId],
      );
      final int returnSeq = (countRows.first['c'] as int? ?? 0) + 1;
      final String returnNo = 'RET-${originalSale['invoice_no']}-$returnSeq';

      final int saleReturnId = await txn
          .insert(DatabaseTables.saleReturns, <String, Object?>{
            'sale_id': saleId,
            'return_no': returnNo,
            'note': note,
            'total_return_amount': returnFinal,
            'total_return_profit': returnProfit,
            'created_at': now,
            'updated_at': now,
          });

      for (final Map<String, Object?> item in itemRows) {
        await txn.insert(DatabaseTables.saleReturnItems, <String, Object?>{
          'sale_return_id': saleReturnId,
          ...item,
          'created_at': now,
          'updated_at': now,
        });

        final int productId = item['product_id'] as int;
        final int qty = item['return_quantity'] as int;
        final List<Map<String, Object?>> productRows = await txn.query(
          DatabaseTables.products,
          where: 'id = ?',
          whereArgs: <Object?>[productId],
          limit: 1,
        );
        if (productRows.isNotEmpty) {
          final int oldStock = productRows.first['stock_quantity'] as int? ?? 0;
          final int newStock = oldStock + qty;
          await txn.update(
            DatabaseTables.products,
            <String, Object?>{'stock_quantity': newStock, 'updated_at': now},
            where: 'id = ?',
            whereArgs: <Object?>[productId],
          );
          await txn.insert(DatabaseTables.stockHistories, <String, Object?>{
            'product_id': productId,
            'type': 'sale_return',
            'quantity': qty,
            'old_stock': oldStock,
            'new_stock': newStock,
            'note': 'Return $returnNo',
            'created_at': now,
          });
        }
      }

      await txn.insert(DatabaseTables.sales, <String, Object?>{
        'invoice_no': returnNo,
        'sale_type': 'return',
        'reference_sale_id': saleId,
        'subtotal': -returnSubtotal,
        'discount_amount': -returnDiscount,
        'customer_cd_percent': originalCdPercent,
        'customer_cd_amount': -returnCdAmount,
        'company_cashback_amount': -returnCashback,
        'final_total': -returnFinal,
        'paid_amount': 0,
        'change_amount': 0,
        'payment_method': 'RETURN',
        'profit_amount': returnProfit,
        'sale_date': now,
        'created_at': now,
        'updated_at': now,
      });

      return saleReturnId;
    });
  }

  Future<List<Map<String, Object?>>> saleReturnsBySaleId(int saleId) async {
    return query(
      DatabaseTables.saleReturns,
      where: 'sale_id = ?',
      whereArgs: <Object?>[saleId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, Object?>>> returnItemsByReturnId(
    int saleReturnId,
  ) async {
    return query(
      DatabaseTables.saleReturnItems,
      where: 'sale_return_id = ?',
      whereArgs: <Object?>[saleReturnId],
      orderBy: 'id ASC',
    );
  }
}
