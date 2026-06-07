class DatabaseTables {
  static const String products = 'products';
  static const String categories = 'categories';
  static const String companies = 'companies';
  static const String customers = 'customers';
  static const String sales = 'sales';
  static const String saleItems = 'sale_items';
  static const String saleReturns = 'sale_returns';
  static const String saleReturnItems = 'sale_return_items';
  static const String stockHistories = 'stock_histories';
  static const String settings = 'settings';

  static const List<String> createStatements = <String>[
    '''CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_name TEXT NOT NULL,
      category_id INTEGER,
      company_id INTEGER,
      barcode TEXT,
      sku TEXT,
      image_path TEXT,
      discount_percent REAL NOT NULL DEFAULT 0,
      buying_price REAL NOT NULL DEFAULT 0,
      selling_price REAL NOT NULL DEFAULT 0,
      same_price_as_buying INTEGER NOT NULL DEFAULT 0,
      foc_enabled INTEGER NOT NULL DEFAULT 0,
      foc_buy_qty INTEGER NOT NULL DEFAULT 10,
      foc_free_qty INTEGER NOT NULL DEFAULT 1,
      stock_quantity INTEGER NOT NULL DEFAULT 0,
      low_stock_alert_quantity INTEGER NOT NULL DEFAULT 5,
      status TEXT DEFAULT 'active',
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      status TEXT DEFAULT 'active',
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE companies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      cashback_percent REAL NOT NULL DEFAULT 0,
      status TEXT DEFAULT 'active',
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'regular',
      price_mode TEXT NOT NULL DEFAULT 'normal',
      price_percent REAL NOT NULL DEFAULT 0,
      rebate_percent REAL NOT NULL DEFAULT 0,
      cashback_percent REAL NOT NULL DEFAULT 0,
      status TEXT DEFAULT 'active',
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_no TEXT NOT NULL,
      customer_id INTEGER,
      customer_name TEXT,
      customer_type TEXT NOT NULL DEFAULT 'regular',
      sale_type TEXT NOT NULL DEFAULT 'sale',
      reference_sale_id INTEGER,
      subtotal REAL NOT NULL DEFAULT 0,
      discount_amount REAL NOT NULL DEFAULT 0,
      rebate_percent REAL NOT NULL DEFAULT 0,
      rebate_amount REAL NOT NULL DEFAULT 0,
      customer_cd_percent REAL NOT NULL DEFAULT 0,
      customer_cd_amount REAL NOT NULL DEFAULT 0,
      customer_cashback_percent REAL NOT NULL DEFAULT 0,
      customer_cashback_amount REAL NOT NULL DEFAULT 0,
      company_cashback_amount REAL NOT NULL DEFAULT 0,
      office_payable_amount REAL NOT NULL DEFAULT 0,
      owner_keep_profit REAL NOT NULL DEFAULT 0,
      final_total REAL NOT NULL DEFAULT 0,
      paid_amount REAL NOT NULL DEFAULT 0,
      change_amount REAL NOT NULL DEFAULT 0,
      payment_method TEXT,
      profit_amount REAL NOT NULL DEFAULT 0,
      sale_date TEXT,
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE sale_returns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      return_no TEXT NOT NULL,
      note TEXT,
      total_return_amount REAL NOT NULL DEFAULT 0,
      total_return_profit REAL NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE sale_return_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_return_id INTEGER NOT NULL,
      sale_item_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT,
      return_quantity INTEGER NOT NULL,
      selling_price REAL NOT NULL DEFAULT 0,
      buying_price REAL NOT NULL DEFAULT 0,
      line_total REAL NOT NULL DEFAULT 0,
      line_profit REAL NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE sale_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      company_id INTEGER,
      product_name TEXT,
      sale_option TEXT NOT NULL DEFAULT 'normal',
      quantity INTEGER NOT NULL,
      paid_quantity INTEGER NOT NULL DEFAULT 0,
      foc_quantity INTEGER NOT NULL DEFAULT 0,
      discount_percent REAL NOT NULL DEFAULT 0,
      discount_amount REAL NOT NULL DEFAULT 0,
      rebate_percent REAL NOT NULL DEFAULT 0,
      rebate_amount REAL NOT NULL DEFAULT 0,
      buying_price REAL NOT NULL DEFAULT 0,
      selling_price REAL NOT NULL DEFAULT 0,
      unit_price_applied REAL NOT NULL DEFAULT 0,
      subtotal REAL NOT NULL DEFAULT 0,
      customer_cashback_percent REAL NOT NULL DEFAULT 0,
      customer_cashback_amount REAL NOT NULL DEFAULT 0,
      company_cashback_percent REAL NOT NULL DEFAULT 0,
      company_cashback_amount REAL NOT NULL DEFAULT 0,
      profit_amount REAL NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )''',
    '''CREATE TABLE stock_histories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      old_stock INTEGER NOT NULL,
      new_stock INTEGER NOT NULL,
      note TEXT,
      created_at TEXT
    )''',
    '''CREATE TABLE settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT NOT NULL UNIQUE,
      value TEXT,
      created_at TEXT,
      updated_at TEXT
    )''',
  ];
}
