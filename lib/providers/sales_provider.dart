import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';
import '../models/sale_item_model.dart';
import '../models/sale_model.dart';

class SalesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<SaleModel> sales = <SaleModel>[];
  bool loading = false;

  Future<void> load({
    DateTime? from,
    DateTime? to,
    String? invoiceQuery,
  }) async {
    loading = true;
    notifyListeners();

    final StringBuffer sql = StringBuffer(
      'SELECT * FROM ${DatabaseTables.sales} WHERE 1=1',
    );
    final List<Object?> args = <Object?>[];

    if (invoiceQuery != null && invoiceQuery.trim().isNotEmpty) {
      final String query = '%${invoiceQuery.trim()}%';
      sql.write(
        ' AND (invoice_no LIKE ? OR customer_name LIKE ? OR sale_date LIKE ?)',
      );
      args.addAll(<Object?>[query, query, query]);
    }

    if (from != null) {
      sql.write(' AND sale_date >= ?');
      args.add(from.toIso8601String());
    }

    if (to != null) {
      sql.write(' AND sale_date <= ?');
      args.add(to.toIso8601String());
    }

    sql.write(' ORDER BY sale_date DESC, id DESC');

    final List<Map<String, Object?>> rows = await _db.rawQuery(
      sql.toString(),
      args,
    );
    sales = rows.map(SaleModel.fromMap).toList();

    loading = false;
    notifyListeners();
  }

  Future<List<SaleItemModel>> saleItems(int saleId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      DatabaseTables.saleItems,
      where: 'sale_id = ?',
      whereArgs: <Object?>[saleId],
      orderBy: 'id ASC',
    );
    return rows.map(SaleItemModel.fromMap).toList();
  }

  Future<void> deleteSale(int saleId) async {
    await _db.deleteSale(saleId);
    await load();
  }

  Future<void> seedDemoData() async {
    await _db.seedDemoData();
    await load();
  }

  Future<void> resetAndReseedDemoData() async {
    await _db.resetAndReseedDemoData();
    await load();
  }

  Future<int> createReturn({
    required int saleId,
    required List<Map<String, Object?>> returnLines,
    String note = '',
  }) async {
    final int id = await _db.createSaleReturn(
      saleId: saleId,
      returnLines: returnLines,
      note: note,
    );
    await load();
    return id;
  }

  Future<List<Map<String, Object?>>> saleReturnsBySaleId(int saleId) {
    return _db.saleReturnsBySaleId(saleId);
  }

  Future<List<Map<String, Object?>>> returnItemsByReturnId(int returnId) {
    return _db.returnItemsByReturnId(returnId);
  }
}
