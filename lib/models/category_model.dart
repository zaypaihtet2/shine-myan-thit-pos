class CategoryModel {
  CategoryModel({
    this.id,
    required this.name,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: '${map['name'] ?? ''}',
      status: '${map['status'] ?? 'active'}',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
