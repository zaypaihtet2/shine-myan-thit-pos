import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CategoryModel> categories = <CategoryModel>[];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final List<Map<String, Object?>> rows = await _db.query(DatabaseTables.categories, orderBy: 'name ASC');
    categories = rows.map(CategoryModel.fromMap).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> save(CategoryModel model) async {
    final String now = DateTime.now().toIso8601String();
    final Map<String, Object?> map = model.toMap()
      ..['updated_at'] = now
      ..['created_at'] = model.createdAt ?? now;

    if (model.id == null) {
      await _db.insert(DatabaseTables.categories, map..remove('id'));
    } else {
      await _db.update(DatabaseTables.categories, map, 'id = ?', <Object?>[model.id!]);
    }
    await load();
  }

  Future<void> delete(int id) async {
    await _db.delete(DatabaseTables.categories, 'id = ?', <Object?>[id]);
    await load();
  }
}
