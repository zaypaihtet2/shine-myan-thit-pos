import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../core/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<String?> exportBackup() async {
    final String? targetDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select backup folder',
    );
    if (targetDir == null) return null;

    final String dbPath = await _db.databasePath();
    final String backupName =
        'jar_jar_pos_${DateTime.now().millisecondsSinceEpoch}.db';
    final String destination = p.join(targetDir, backupName);
    await File(dbPath).copy(destination);
    return destination;
  }

  Future<String?> restoreBackup() async {
    final FilePickerResult? pick = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select backup database file',
      type: FileType.custom,
      allowedExtensions: <String>['db'],
    );
    if (pick == null || pick.files.single.path == null) return null;

    final String source = pick.files.single.path!;
    final String dbPath = await _db.databasePath();
    await File(source).copy(dbPath);
    return dbPath;
  }
}
