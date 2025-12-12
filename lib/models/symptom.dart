class Symptom {
  final int? id;
  final String name; // Название симптома на текущем языке
  final bool isDefault; // Является ли симптомом по умолчанию

  const Symptom({
    this.id,
    required this.name,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory Symptom.fromMap(Map<String, dynamic> map) {
    return Symptom(
      id: map['id'],
      name: map['name'] ?? '',
      isDefault: map['isDefault'] == 1,
    );
  }

  Symptom copyWith({
    int? id,
    String? name,
    bool? isDefault,
  }) {
    return Symptom(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'Symptom{id: $id, name: $name, isDefault: $isDefault}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Symptom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}