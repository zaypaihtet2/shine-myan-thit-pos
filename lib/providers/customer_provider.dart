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
    final List<Map<String, Object?>> rows = await _db.query(
      DatabaseTables.customers,
      orderBy: 'name ASC',
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
