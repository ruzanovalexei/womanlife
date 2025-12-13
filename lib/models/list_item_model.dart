import 'dart:convert';
import '../utils/date_utils.dart';

class ListItemModel {
  final int? id;
  final int listId;
  final String text;
  final bool isCompleted;
  final DateTime createdDate;
  final DateTime updatedDate;

  ListItemModel({
    this.id,
    required this.listId,
    required this.text,
    this.isCompleted = false,
    required this.createdDate,
    required this.updatedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'text': text,
      'isCompleted': isCompleted ? 1 : 0, // SQLite использует INTEGER для boolean
      'createdDate': MyDateUtils.toUtcDateString(createdDate),
      'updatedDate': MyDateUtils.toUtcDateString(updatedDate),
    };
  }

  factory ListItemModel.fromMap(Map<String, dynamic> map) {
    return ListItemModel(
      id: map['id'],
      listId: map['listId'],
      text: map['text'],
      isCompleted: map['isCompleted'] == 1, // Преобразуем INTEGER в boolean
      createdDate: MyDateUtils.fromUtcDateString(map['createdDate']),
      updatedDate: MyDateUtils.fromUtcDateString(map['updatedDate']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ListItemModel.fromJson(String source) => ListItemModel.fromMap(json.decode(source));

  ListItemModel copyWith({
    int? id,
    int? listId,
    String? text,
    bool? isCompleted,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return ListItemModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  @override
  String toString() {
    return 'ListItemModel(id: $id, listId: $listId, text: $text, isCompleted: $isCompleted, createdDate: $createdDate, updatedDate: $updatedDate)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listId == other.listId &&
          text == other.text &&
          isCompleted == other.isCompleted &&
          createdDate == other.createdDate &&
          updatedDate == other.updatedDate;

  @override
  int get hashCode => id.hashCode ^ listId.hashCode ^ text.hashCode ^ isCompleted.hashCode ^ createdDate.hashCode ^ updatedDate.hashCode;
}