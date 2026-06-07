class SaleItemModel {
  SaleItemModel({
    this.id,
    this.saleId,
    required this.productId,
    this.companyId,
    required this.productName,
    this.saleOption = 'normal',
    required this.quantity,
    this.paidQuantity = 0,
    this.focQuantity = 0,
    required this.discountPercent,
    required this.discountAmount,
    this.rebatePercent = 0,
    this.rebateAmount = 0,
    required this.buyingPrice,
    required this.sellingPrice,
    this.unitPriceApplied = 0,
    required this.subtotal,
    this.customerCashbackPercent = 0,
    this.customerCashbackAmount = 0,
    required this.companyCashbackPercent,
    required this.companyCashbackAmount,
    required this.profitAmount,
  });

  final int? id;
  final int? saleId;
  final int productId;
  final int? companyId;
  final String productName;
  final String saleOption;
  final int quantity;
  final int paidQuantity;
  final int focQuantity;
  final double discountPercent;
  final double discountAmount;
  final double rebatePercent;
  final double rebateAmount;
  final double buyingPrice;
  final double sellingPrice;
  final double unitPriceApplied;
  final double subtotal;
  final double customerCashbackPercent;
  final double customerCashbackAmount;
  final double companyCashbackPercent;
  final double companyCashbackAmount;
  final double profitAmount;

  Map<String, Object?> toDbMap() {
    return <String, Object?>{
      'sale_id': saleId,
      'product_id': productId,
      'company_id': companyId,
      'product_name': productName,
      'sale_option': saleOption,
      'quantity': quantity,
      'paid_quantity': paidQuantity,
      'foc_quantity': focQuantity,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'rebate_percent': rebatePercent,
      'rebate_amount': rebateAmount,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'unit_price_applied': unitPriceApplied,
      'subtotal': subtotal,
      'customer_cashback_percent': customerCashbackPercent,
      'customer_cashback_amount': customerCashbackAmount,
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
      saleOption: '${map['sale_option'] ?? 'normal'}',
      quantity: map['quantity'] as int? ?? 0,
      paidQuantity: map['paid_quantity'] as int? ?? 0,
      focQuantity: map['foc_quantity'] as int? ?? 0,
      discountPercent: (map['discount_percent'] as num? ?? 0).toDouble(),
      discountAmount: (map['discount_amount'] as num? ?? 0).toDouble(),
      rebatePercent: (map['rebate_percent'] as num? ?? 0).toDouble(),
      rebateAmount: (map['rebate_amount'] as num? ?? 0).toDouble(),
      buyingPrice: (map['buying_price'] as num? ?? 0).toDouble(),
      sellingPrice: (map['selling_price'] as num? ?? 0).toDouble(),
      unitPriceApplied: (map['unit_price_applied'] as num? ?? 0).toDouble(),
      subtotal: (map['subtotal'] as num? ?? 0).toDouble(),
      customerCashbackPercent: (map['customer_cashback_percent'] as num? ?? 0)
          .toDouble(),
      customerCashbackAmount: (map['customer_cashback_amount'] as num? ?? 0)
          .toDouble(),
      companyCashbackPercent: (map['company_cashback_percent'] as num? ?? 0)
          .toDouble(),
      companyCashbackAmount: (map['company_cashback_amount'] as num? ?? 0)
          .toDouble(),
      profitAmount: (map['profit_amount'] as num? ?? 0).toDouble(),
    );
  }
}
