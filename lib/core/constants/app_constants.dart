class AppConstants {
  static const String appTitle = 'Shine Myan Thit POS';

  // Keep the existing database filename so current shop data is not lost
  // after the application display name is changed.
  static const String dbName = 'jar_jar_pos.db';
  static const int dbVersion = 8;

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
