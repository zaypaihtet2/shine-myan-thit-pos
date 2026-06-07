import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';

class ReportProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Map<String, num> summary = <String, num>{};
  List<Map<String, Object?>> bestSelling = <Map<String, Object?>>[];
  List<Map<String, Object?>> paymentSummary = <Map<String, Object?>>[];

  Future<void> loadDashboard() async {
    final DateTime start = DateTime.now();
    final DateTime from = DateTime(start.year, start.month, start.day);

    final List<Map<String, Object?>> totals = await _db.rawQuery(
      'SELECT '
      'COALESCE(SUM(final_total),0) AS sales, '
      'COALESCE(SUM(profit_amount),0) AS profit, '
      'COALESCE(SUM(rebate_amount),0) AS rebate, '
      'COALESCE(SUM(customer_cd_amount),0) AS cd, '
      'COALESCE(SUM(customer_cashback_amount),0) AS customer_cashback, '
      'COALESCE(SUM(owner_keep_profit),0) AS owner_keep, '
      'COALESCE(SUM(company_cashback_amount),0) AS cashback '
      'FROM ${DatabaseTables.sales} WHERE sale_date >= ?',
      <Object?>[from.toIso8601String()],
    );

    final List<Map<String, Object?>> productCount = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseTables.products}',
    );

    final List<Map<String, Object?>> lowStock = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseTables.products} WHERE stock_quantity <= low_stock_alert_quantity',
    );

    bestSelling = await _db.rawQuery(
      'SELECT product_name, SUM(quantity) AS qty '
      'FROM ${DatabaseTables.saleItems} '
      'GROUP BY product_name '
      'ORDER BY qty DESC LIMIT 5',
    );

    paymentSummary = await _db.rawQuery(
      'SELECT payment_method, SUM(final_total) AS total '
      'FROM ${DatabaseTables.sales} '
      'WHERE sale_date >= ? '
      'GROUP BY payment_method '
      'ORDER BY total DESC',
      <Object?>[from.toIso8601String()],
    );

    summary = <String, num>{
      'todaySales': (totals.first['sales'] as num? ?? 0),
      'todayProfit': (totals.first['profit'] as num? ?? 0),
      'todayRebate': (totals.first['rebate'] as num? ?? 0),
      'todayCd': (totals.first['cd'] as num? ?? 0),
      'todayDoctorCashback': (totals.first['customer_cashback'] as num? ?? 0),
      'todayCashback': (totals.first['cashback'] as num? ?? 0),
      'todayOfficePayable':
          (totals.first['sales'] as num? ?? 0) -
          (totals.first['cashback'] as num? ?? 0),
      'todayOwnerKeep': (totals.first['owner_keep'] as num? ?? 0) == 0
          ? (totals.first['profit'] as num? ?? 0)
          : (totals.first['owner_keep'] as num? ?? 0),
      'totalProducts': (productCount.first['c'] as num? ?? 0),
      'lowStock': (lowStock.first['c'] as num? ?? 0),
    };
    notifyListeners();
  }
}
