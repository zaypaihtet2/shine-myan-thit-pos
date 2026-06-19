import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';
import '../models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CustomerModel> customers = <CustomerModel>[];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''SELECT c.*,
        COALESCE((
          SELECT SUM(
            CASE
              WHEN s.final_total > s.paid_amount
                THEN s.final_total - s.paid_amount
              ELSE 0
            END
          )
          FROM ${DatabaseTables.sales} s
          WHERE s.customer_id = c.id
            AND s.payment_method = 'Credit'
            AND s.sale_type = 'sale'
        ), 0)
        - COALESCE((
          SELECT SUM(sr.total_return_amount)
          FROM ${DatabaseTables.saleReturns} sr
          INNER JOIN ${DatabaseTables.sales} rs ON rs.id = sr.sale_id
          WHERE rs.customer_id = c.id
            AND rs.payment_method = 'Credit'
        ), 0) AS credit_balance
      FROM ${DatabaseTables.customers} c
      ORDER BY c.name ASC''',
    );
    customers = rows.map(CustomerModel.fromMap).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> save(CustomerModel model) async {
    final String now = DateTime.now().toIso8601String();
    final Map<String, Object?> map = model.toMap()
      ..['updated_at'] = now
      ..['created_at'] = model.createdAt ?? now;

    if (model.id == null) {
      await _db.insert(DatabaseTables.customers, map..remove('id'));
    } else {
      await _db.update(DatabaseTables.customers, map, 'id = ?', <Object?>[
        model.id!,
      ]);
    }
    await load();
  }

  Future<void> delete(int id) async {
    await _db.delete(DatabaseTables.customers, 'id = ?', <Object?>[id]);
    await load();
  }
}
