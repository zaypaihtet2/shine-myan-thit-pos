class SaleItemModel {
  SaleItemModel({
    this.id,
    this.saleId,
    required this.productId,
    this.companyId,
    required this.productName,
    required this.quantity,
    required this.discountPercent,
    required this.discountAmount,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.subtotal,
    required this.companyCashbackPercent,
    required this.companyCashbackAmount,
    required this.profitAmount,
  });

  final int? id;
  final int? saleId;
  final int productId;
  final int? companyId;
  final String productName;
  final int quantity;
  final double discountPercent;
  final double discountAmount;
  final double buyingPrice;
  final double sellingPrice;
  final double subtotal;
  final double companyCashbackPercent;
  final double companyCashbackAmount;
  final double profitAmount;

  Map<String, Object?> toDbMap() {
    return <String, Object?>{
      'sale_id': saleId,
      'product_id': productId,
      'company_id': companyId,
      'product_name': productName,
      'quantity': quantity,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'subtotal': subtotal,
      'company_cashback_percent': companyCashbackPercent,
      'company_cashback_amount': companyCashbackAmount,
      'profit_amount': profitAmount,
    };
  }

  factory SaleItemModel.fromMap(Map<String, Object?> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      companyId: map['company_id'] as int?,
      productName: '${map['product_name'] ?? ''}',
      quantity: map['quantity'] as int? ?? 0,
      discountPercent: (map['discount_percent'] as num? ?? 0).toDouble(),
      discountAmount: (map['discount_amount'] as num? ?? 0).toDouble(),
      buyingPrice: (map['buying_price'] as num? ?? 0).toDouble(),
      sellingPrice: (map['selling_price'] as num? ?? 0).toDouble(),
      subtotal: (map['subtotal'] as num? ?? 0).toDouble(),
      companyCashbackPercent: (map['company_cashback_percent'] as num? ?? 0)
          .toDouble(),
      companyCashbackAmount: (map['company_cashback_amount'] as num? ?? 0)
          .toDouble(),
      profitAmount: (map['profit_amount'] as num? ?? 0).toDouble(),
    );
  }
}
