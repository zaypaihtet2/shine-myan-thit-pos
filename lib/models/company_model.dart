class CompanyModel {
  CompanyModel({
    this.id,
    required this.name,
    required this.cashbackPercent,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final double cashbackPercent;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'cashback_percent': cashbackPercent,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CompanyModel.fromMap(Map<String, Object?> map) {
    return CompanyModel(
      id: map['id'] as int?,
      name: '${map['name'] ?? ''}',
      cashbackPercent: (map['cashback_percent'] as num? ?? 0).toDouble(),
      status: '${map['status'] ?? 'active'}',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
