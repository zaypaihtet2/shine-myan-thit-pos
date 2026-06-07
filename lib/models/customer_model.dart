class CustomerModel {
  CustomerModel({
    this.id,
    required this.name,
    this.type = 'regular',
    this.priceMode = 'normal',
    this.pricePercent = 0,
    this.rebatePercent = 0,
    this.cashbackPercent = 0,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String type;
  final String priceMode;
  final double pricePercent;
  final double rebatePercent;
  final double cashbackPercent;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'type': type,
      'price_mode': priceMode,
      'price_percent': pricePercent,
      'rebate_percent': rebatePercent,
      'cashback_percent': cashbackPercent,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CustomerModel.fromMap(Map<String, Object?> map) {
    return CustomerModel(
      id: map['id'] as int?,
      name: '${map['name'] ?? ''}',
      type: '${map['type'] ?? 'regular'}',
      priceMode: '${map['price_mode'] ?? 'normal'}',
      pricePercent: (map['price_percent'] as num? ?? 0).toDouble(),
      rebatePercent: (map['rebate_percent'] as num? ?? 0).toDouble(),
      cashbackPercent: (map['cashback_percent'] as num? ?? 0).toDouble(),
      status: '${map['status'] ?? 'active'}',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
