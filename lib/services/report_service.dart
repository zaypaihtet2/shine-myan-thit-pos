import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class ReportService {
  Future<String?> exportCsv({
    required String fileName,
    required List<List<Object?>> rows,
  }) async {
    final String? folder = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select export folder',
    );
    if (folder == null) return null;

    final String csv = const ListToCsvConverter().convert(rows);
    final String filePath = p.join(folder, '$fileName.csv');
    await File(filePath).writeAsString(csv);
    return filePath;
  }
}
