import 'dart:convert';
import '../utils/date_utils.dart';

class ListModel {
  final int? id;
  final String name;
  final DateTime createdDate;
  final DateTime updatedDate;

  ListModel({
    this.id,
    required this.name,
    required this.createdDate,
    required this.updatedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdDate': MyDateUtils.toUtcDateString(createdDate),
      'updatedDate': MyDateUtils.toUtcDateString(updatedDate),
    };
  }

  factory ListModel.fromMap(Map<String, dynamic> map) {
    return ListModel(
      id: map['id'],
      name: map['name'],
      createdDate: MyDateUtils.fromUtcDateString(map['createdDate']),
      updatedDate: MyDateUtils.fromUtcDateString(map['updatedDate']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ListModel.fromJson(String source) => ListModel.fromMap(json.decode(source));

  ListModel copyWith({
    int? id,
    String? name,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return ListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  @override
  String toString() {
    return 'ListModel(id: $id, name: $name, createdDate: $createdDate, updatedDate: $updatedDate)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          createdDate == other.createdDate &&
          updatedDate == other.updatedDate;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdDate.hashCode ^ updatedDate.hashCode;
}