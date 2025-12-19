class NoteModel {
  final int? id;
  final String title;
  final String content;
  final DateTime createdDate;
  final DateTime updatedDate;

  NoteModel({
    this.id,
    required this.title,
    required this.content,
    required this.createdDate,
    required this.updatedDate,
  });

  // Копирование объекта с изменением полей
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  // Преобразование в Map для базы данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
    };
  }

  // Создание объекта из Map
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdDate: DateTime.parse(map['createdDate']),
      updatedDate: DateTime.parse(map['updatedDate']),
    );
  }

  @override
  String toString() {
    return 'NoteModel{id: $id, title: $title, content: $content, createdDate: $createdDate, updatedDate: $updatedDate}';
  }
}