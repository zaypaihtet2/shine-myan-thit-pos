class ProductModel {
  ProductModel({
    this.id,
    required this.productName,
    this.categoryId,
    this.companyId,
    this.barcode,
    this.sku,
    this.imagePath,
    this.discountPercent = 0,
    required this.buyingPrice,
    required this.sellingPrice,
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
  final String? barcode;
  final String? sku;
  final String? imagePath;
  final double discountPercent;
  final double buyingPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int lowStockAlertQuantity;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  ProductModel copyWith({
    int? id,
    String? productName,
    int? categoryId,
    int? companyId,
    String? barcode,
    String? sku,
    String? imagePath,
    double? discountPercent,
    double? buyingPrice,
    double? sellingPrice,
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
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      imagePath: imagePath ?? this.imagePath,
      discountPercent: discountPercent ?? this.discountPercent,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
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
      'barcode': barcode,
      'sku': sku,
      'image_path': imagePath,
      'discount_percent': discountPercent,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
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
      barcode: map['barcode'] as String?,
      sku: map['sku'] as String?,
      imagePath: map['image_path'] as String?,
      discountPercent: (map['discount_percent'] as num? ?? 0).toDouble(),
      buyingPrice: (map['buying_price'] as num? ?? 0).toDouble(),
      sellingPrice: (map['selling_price'] as num? ?? 0).toDouble(),
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      lowStockAlertQuantity: map['low_stock_alert_quantity'] as int? ?? 5,
      status: '${map['status'] ?? 'active'}',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
