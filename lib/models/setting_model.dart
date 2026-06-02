class SettingModel {
  SettingModel({
    this.id,
    required this.key,
    required this.value,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String key;
  final String value;
  final String? createdAt;
  final String? updatedAt;

  factory SettingModel.fromMap(Map<String, Object?> map) {
    return SettingModel(
      id: map['id'] as int?,
      key: '${map['key'] ?? ''}',
      value: '${map['value'] ?? ''}',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
