class ProductModel {
  ProductModel({
    this.id,
    required this.productName,
    this.categoryId,
    this.companyId,
    this.expiryDate,
    this.sku,
    this.imagePath,
    this.discountPercent = 0,
    required this.buyingPrice,
    required this.sellingPrice,
    this.samePriceAsBuying = false,
    this.focEnabled = false,
    this.focBuyQty = 10,
    this.focFreeQty = 1,
    required this.stockQuantity,
    required this.lowStockAlertQuantity,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String productName;
  final int? categoryId;
  final int? companyId;

  /// Stored in the legacy `barcode` database column so existing installations
  /// can upgrade without a destructive database migration.
  final String? expiryDate;
  final String? sku;
  final String? imagePath;
  final double discountPercent;
  final double buyingPrice;
  final double sellingPrice;
  final bool samePriceAsBuying;
  final bool focEnabled;
  final int focBuyQty;
  final int focFreeQty;
  final int stockQuantity;
  final int lowStockAlertQuantity;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  bool get isExpired {
    final DateTime? date = DateTime.tryParse(expiryDate ?? '');
    if (date == null) return false;
    final DateTime today = DateTime.now();
    final DateTime startOfToday = DateTime(today.year, today.month, today.day);
    return date.isBefore(startOfToday);
  }

  ProductModel copyWith({
    int? id,
    String? productName,
    int? categoryId,
    int? companyId,
    String? expiryDate,
    String? sku,
    String? imagePath,
    double? discountPercent,
    double? buyingPrice,
    double? sellingPrice,
    bool? samePriceAsBuying,
    bool? focEnabled,
    int? focBuyQty,
    int? focFreeQty,
    int? stockQuantity,
    int? lowStockAlertQuantity,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      companyId: companyId ?? this.companyId,
      expiryDate: expiryDate ?? this.expiryDate,
      sku: sku ?? this.sku,
      imagePath: imagePath ?? this.imagePath,
      discountPercent: discountPercent ?? this.discountPercent,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      samePriceAsBuying: samePriceAsBuying ?? this.samePriceAsBuying,
      focEnabled: focEnabled ?? this.focEnabled,
      focBuyQty: focBuyQty ?? this.focBuyQty,
      focFreeQty: focFreeQty ?? this.focFreeQty,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockAlertQuantity:
          lowStockAlertQuantity ?? this.lowStockAlertQuantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'product_name': productName,
      'category_id': categoryId,
      'company_id': companyId,
      // Keep using the existing column to avoid losing old product records.
      'barcode': expiryDate,
      'sku': sku,
      'image_path': imagePath,
      'discount_percent': discountPercent,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'same_price_as_buying': samePriceAsBuying ? 1 : 0,
      'foc_enabled': focEnabled ? 1 : 0,
      'foc_buy_qty': focBuyQty,
      'foc_free_qty': focFreeQty,
      'stock_quantity': stockQuantity,
      'low_stock_alert_quantity': lowStockAlertQuantity,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ProductModel.fromMap(Map<String, Object?> map) {
    return ProductModel(
      id: map['id'] as int?,
      productName: '${map['product_name'] ?? ''}',
      categoryId: map['category_id'] as int?,
      companyId: map['company_id'] as int?,
      expiryDate: _parseExpiry(map['barcode']),
      sku: map['sku'] as String?,
      imagePath: map['image_path'] as String?,
      discountPercent: (map['discount_percent'] as num? ?? 0).toDouble(),
      buyingPrice: (map['buying_price'] as num? ?? 0).toDouble(),
      sellingPrice: (map['selling_price'] as num? ?? 0).toDouble(),
      samePriceAsBuying: (map['same_price_as_buying'] as num? ?? 0) == 1,
      focEnabled: (map['foc_enabled'] as num? ?? 0) == 1,
      focBuyQty: map['foc_buy_qty'] as int? ?? 10,
      focFreeQty: map['foc_free_qty'] as int? ?? 1,
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      lowStockAlertQuantity: map['low_stock_alert_quantity'] as int? ?? 5,
      status: '${map['status'] ?? 'active'}',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  static String? _parseExpiry(Object? value) {
    final String text = '${value ?? ''}'.trim();
    if (text.isEmpty) return null;
    final DateTime? date = DateTime.tryParse(text);
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
