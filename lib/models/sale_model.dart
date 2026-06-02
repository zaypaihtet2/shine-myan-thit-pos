class SaleModel {
  SaleModel({
    this.id,
    required this.invoiceNo,
    required this.saleType,
    this.referenceSaleId,
    required this.subtotal,
    required this.discountAmount,
    required this.customerCdPercent,
    required this.customerCdAmount,
    required this.companyCashbackAmount,
    required this.finalTotal,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.profitAmount,
    required this.saleDate,
  });

  final int? id;
  final String invoiceNo;
  final String saleType;
  final int? referenceSaleId;
  final double subtotal;
  final double discountAmount;
  final double customerCdPercent;
  final double customerCdAmount;
  final double companyCashbackAmount;
  final double finalTotal;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final double profitAmount;
  final String saleDate;

  factory SaleModel.fromMap(Map<String, Object?> map) {
    return SaleModel(
      id: map['id'] as int?,
      invoiceNo: '${map['invoice_no'] ?? ''}',
      saleType: '${map['sale_type'] ?? 'sale'}',
      referenceSaleId: map['reference_sale_id'] as int?,
      subtotal: (map['subtotal'] as num? ?? 0).toDouble(),
      discountAmount: (map['discount_amount'] as num? ?? 0).toDouble(),
      customerCdPercent: (map['customer_cd_percent'] as num? ?? 0).toDouble(),
      customerCdAmount: (map['customer_cd_amount'] as num? ?? 0).toDouble(),
      companyCashbackAmount: (map['company_cashback_amount'] as num? ?? 0)
          .toDouble(),
      finalTotal: (map['final_total'] as num? ?? 0).toDouble(),
      paidAmount: (map['paid_amount'] as num? ?? 0).toDouble(),
      changeAmount: (map['change_amount'] as num? ?? 0).toDouble(),
      paymentMethod: '${map['payment_method'] ?? 'Cash'}',
      profitAmount: (map['profit_amount'] as num? ?? 0).toDouble(),
      saleDate: '${map['sale_date'] ?? ''}',
    );
  }
}
