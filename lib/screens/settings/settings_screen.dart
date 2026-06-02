import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _shopName = TextEditingController();
  final TextEditingController _shopPhone = TextEditingController();
  final TextEditingController _shopAddress = TextEditingController();
  final TextEditingController _defaultCd = TextEditingController();
  final TextEditingController _currency = TextEditingController();
  final TextEditingController _footer = TextEditingController();
  final TextEditingController _voucherFontSize = TextEditingController();
  final TextEditingController _lowStock = TextEditingController();
  String _paperSize = '80';

  bool inited = false;

  @override
  void dispose() {
    _shopName.dispose();
    _shopPhone.dispose();
    _shopAddress.dispose();
    _defaultCd.dispose();
    _currency.dispose();
    _footer.dispose();
    _voucherFontSize.dispose();
    _lowStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider s = context.watch<SettingsProvider>();
    if (!inited && !s.loading) {
      inited = true;
      _shopName.text = s.shopName;
      _shopPhone.text = s.shopPhone;
      _shopAddress.text = s.shopAddress;
      _defaultCd.text = s.defaultCdPercent.toString();
      _currency.text = s.currencySymbol;
      _footer.text = s.voucherFooter;
      _voucherFontSize.text = s.voucherFontSize.toString();
      _lowStock.text = s.lowStockDefault.toString();
      _paperSize = '${s.voucherPaperSizeMm}';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
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
                        'Settings',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Store identity, voucher layout, and system preferences.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Shop Profile',
            icon: Icons.storefront_outlined,
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _shopName,
                  decoration: const InputDecoration(labelText: 'Shop Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _shopPhone,
                  decoration: const InputDecoration(labelText: 'Shop Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _shopAddress,
                  decoration: const InputDecoration(labelText: 'Shop Address'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _defaultCd,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Default Customer CD %',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Currency Symbol',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Voucher Style',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _footer,
                  decoration: const InputDecoration(
                    labelText: 'Voucher Footer Text',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paperSize,
                        decoration: const InputDecoration(
                          labelText: 'Paper Width',
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: '58',
                            child: Text('58 mm'),
                          ),
                          DropdownMenuItem<String>(
                            value: '80',
                            child: Text('80 mm'),
                          ),
                        ],
                        onChanged: (String? v) {
                          setState(() {
                            _paperSize = v ?? '80';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _voucherFontSize,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Voucher Font Size',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('Voucher Logo'),
                  subtitle: Text(
                    s.voucherLogoPath.isEmpty
                        ? 'No logo selected'
                        : s.voucherLogoPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: FilledButton.tonalIcon(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Choose Logo'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'System',
            icon: Icons.tune_outlined,
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _lowStock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Alert Default',
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.darkMode,
                  onChanged: (bool v) => s.setValue('dark_mode', v ? '1' : '0'),
                  title: const Text('Dark Mode'),
                  subtitle: const Text(
                    'Use a darker appearance across the app',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Demo Data',
            icon: Icons.dataset_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _insertDemoData,
                  icon: const Icon(Icons.dataset_outlined),
                  label: Text(
                    s.demoSeeded ? 'Demo Data Already Added' : 'Add Demo Data',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _resetAndReseedDemoData,
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: const Text('Reset Demo Data (Clear + Reseed)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final SettingsProvider s = context.read<SettingsProvider>();
    await s.setValue('shop_name', _shopName.text.trim());
    await s.setValue('shop_phone', _shopPhone.text.trim());
    await s.setValue('shop_address', _shopAddress.text.trim());
    await s.setValue('default_customer_cd_percent', _defaultCd.text.trim());
    await s.setValue('currency_symbol', _currency.text.trim());
    await s.setValue('voucher_footer_text', _footer.text.trim());
    await s.setValue('voucher_paper_size_mm', _paperSize);
    await s.setValue('voucher_font_size', _voucherFontSize.text.trim());
    await s.setValue('low_stock_alert_default', _lowStock.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _pickLogo() async {
    final FilePickerResult? pick = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose voucher logo',
      type: FileType.custom,
      allowedExtensions: <String>['png', 'jpg', 'jpeg', 'webp'],
    );
    if (pick == null || pick.files.single.path == null || !mounted) return;
    await context.read<SettingsProvider>().setValue(
      'voucher_logo_path',
      pick.files.single.path!,
    );
  }

  Future<void> _insertDemoData() async {
    final settings = context.read<SettingsProvider>();
    try {
      await context.read<SalesProvider>().seedDemoData();
      await settings.setValue('demo_data_seeded', '1');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo data added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _resetAndReseedDemoData() async {
    final SalesProvider sales = context.read<SalesProvider>();
    final SettingsProvider settings = context.read<SettingsProvider>();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Demo Data'),
        content: const Text(
          'This will clear products, sales, returns, and stock history, then add fresh demo data. Continue?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      await sales.resetAndReseedDemoData();
      await settings.setValue('demo_data_seeded', '1');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo data reset and reseeded successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
