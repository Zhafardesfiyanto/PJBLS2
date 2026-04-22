import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_model.freezed.dart';
part 'class_model.g.dart';

/// Class model representing a classroom in the system
@freezed
class ClassModel with _$ClassModel {
  const factory ClassModel({
    required String id,
    required String name,
    required String description,
    required String teacherId,
    required String classCode,
    required List<String> studentIds,
    required DateTime createdAt,
  }) = _ClassModel;

  const ClassModel._();

  /// Create ClassModel from Firestore document
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacherId'] ?? '',
      classCode: data['classCode'] ?? '',
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert ClassModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'classCode': classCode,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create ClassModel from JSON
  factory ClassModel.fromJson(Map<String, dynamic> json) => _$ClassModelFromJson(json);
}