import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';
import '../models/company_model.dart';

class CompanyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CompanyModel> companies = <CompanyModel>[];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final List<Map<String, Object?>> rows = await _db.query(DatabaseTables.companies, orderBy: 'name ASC');
    companies = rows.map(CompanyModel.fromMap).toList();
    loading = false;
    notifyListeners();
  }

  double cashbackByCompanyId(int? id) {
    if (id == null) return 0;
    final CompanyModel? company = companies.where((CompanyModel c) => c.id == id).cast<CompanyModel?>().firstOrNull;
    return company?.cashbackPercent ?? 0;
  }

  Future<void> save(CompanyModel model) async {
    final String now = DateTime.now().toIso8601String();
    final Map<String, Object?> map = model.toMap()
      ..['updated_at'] = now
      ..['created_at'] = model.createdAt ?? now;

    if (model.id == null) {
      await _db.insert(DatabaseTables.companies, map..remove('id'));
    } else {
      await _db.update(DatabaseTables.companies, map, 'id = ?', <Object?>[model.id!]);
    }
    await load();
  }

  Future<void> delete(int id) async {
    await _db.delete(DatabaseTables.companies, 'id = ?', <Object?>[id]);
    await load();
  }
}
