class AppConstants {
  static const String appTitle = 'Jar Jar POS';
  static const String dbName = 'jar_jar_pos.db';
  static const int dbVersion = 3;

  static const List<String> paymentMethods = <String>[
    'Cash',
    'KPay',
    'WavePay',
    'Bank Transfer',
    'Credit',
  ];

  static const List<String> quickCategories = <String>[
    'Food',
    'Drink',
    'Cosmetic',
    'Accessories',
    'Phone Item',
    'Medicine',
    'Other',
  ];
}
