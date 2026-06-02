import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Map<String, String> values = <String, String>{};
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    values = await _db.getSettings();
    loading = false;
    notifyListeners();
  }

  String get shopName => values['shop_name'] ?? 'My Shop';
  String get shopPhone => values['shop_phone'] ?? '';
  String get shopAddress => values['shop_address'] ?? '';
  String get currencySymbol => values['currency_symbol'] ?? 'Ks';
  String get voucherFooter => values['voucher_footer_text'] ?? 'Thank you';
  String get voucherLogoPath => values['voucher_logo_path'] ?? '';
  int get voucherPaperSizeMm =>
      int.tryParse(values['voucher_paper_size_mm'] ?? '80') ?? 80;
  double get voucherFontSize =>
      double.tryParse(values['voucher_font_size'] ?? '10') ?? 10;
  double get defaultCdPercent =>
      double.tryParse(values['default_customer_cd_percent'] ?? '2') ?? 2;
  int get lowStockDefault =>
      int.tryParse(values['low_stock_alert_default'] ?? '5') ?? 5;
  bool get darkMode => values['dark_mode'] == '1';
  bool get demoSeeded => values['demo_data_seeded'] == '1';

  Future<void> setValue(String key, String value) async {
    values[key] = value;
    notifyListeners();
    await _db.saveSetting(key, value);
  }
}
