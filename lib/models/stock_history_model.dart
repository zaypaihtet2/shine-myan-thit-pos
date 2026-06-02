class StockHistoryModel {
  StockHistoryModel({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.oldStock,
    required this.newStock,
    this.note,
    required this.createdAt,
  });

  final int? id;
  final int productId;
  final String type;
  final int quantity;
  final int oldStock;
  final int newStock;
  final String? note;
  final String createdAt;

  factory StockHistoryModel.fromMap(Map<String, Object?> map) {
    return StockHistoryModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      type: '${map['type'] ?? ''}',
      quantity: map['quantity'] as int? ?? 0,
      oldStock: map['old_stock'] as int? ?? 0,
      newStock: map['new_stock'] as int? ?? 0,
      note: map['note'] as String?,
      createdAt: '${map['created_at'] ?? ''}',
    );
  }
}
