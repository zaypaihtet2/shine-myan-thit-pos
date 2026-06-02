import 'package:flutter/material.dart';

import '../../services/backup_service.dart';
import '../../services/report_service.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BackupService backup = BackupService();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  const Color(0xFF0F5132),
                  const Color(0xFF1F7A4D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Backup & Restore',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep a copy of your local database and restore it safely when needed.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Local DB',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  _ActionTile(
                    icon: Icons.save_alt_outlined,
                    title: 'Export SQLite Backup',
                    subtitle: 'Save a copy of local database .db file',
                    buttonLabel: 'Export',
                    onPressed: () async {
                      final String? file = await backup.exportBackup();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            file == null
                                ? 'Canceled'
                                : 'Backup exported: $file',
                          ),
                        ),
                      );
                    },
                    filled: true,
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.restore_outlined,
                    title: 'Restore SQLite Backup',
                    subtitle:
                        'Replace current local database with selected backup file',
                    buttonLabel: 'Restore',
                    onPressed: () async {
                      final bool? ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Restore Backup'),
                          content: const Text(
                            'This will overwrite current database. Continue?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Restore'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      final String? file = await backup.restoreBackup();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            file == null ? 'Canceled' : 'Restored from backup',
                          ),
                        ),
                      );
                    },
                    filled: true,
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.description_outlined,
                    title: 'Export Empty CSV Template',
                    subtitle: 'Quick CSV export check for reports',
                    buttonLabel: 'Export CSV',
                    onPressed: () async {
                      final String? file = await ReportService().exportCsv(
                        fileName: 'report_template',
                        rows: const <List<Object?>>[
                          <Object?>['invoice', 'date', 'total', 'payment'],
                        ],
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            file == null ? 'Canceled' : 'CSV exported: $file',
                          ),
                        ),
                      );
                    },
                    filled: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: You can schedule a daily backup by exporting the database to a chosen folder.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    required this.filled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          filled
              ? FilledButton(onPressed: onPressed, child: Text(buttonLabel))
              : OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
