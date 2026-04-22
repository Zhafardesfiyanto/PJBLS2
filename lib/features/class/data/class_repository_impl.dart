import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class_model.dart';
import 'class_repository.dart';

part 'class_repository_impl.g.dart';

/// Implementation of ClassRepository using Firestore
class ClassRepositoryImpl implements ClassRepository {
  final FirebaseFirestore _firestore;

  ClassRepositoryImpl(this._firestore);

  @override
  Future<ClassModel> createClass(String name, String description, String teacherId) async {
    final classCode = _generateClassCode();
    
    // Check if class code already exists (very unlikely but possible)
    final existingClass = await getClassByCode(classCode);
    if (existingClass != null) {
      // Regenerate if collision occurs
      return createClass(name, description, teacherId);
    }

    final classData = {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'classCode': classCode,
      'studentIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('classes').add(classData);
    final doc = await docRef.get();
    
    return ClassModel.fromFirestore(doc);
  }

  @override
  Future<void> joinClass(String classCode, String studentId) async {
    final classQuery = await _firestore
        .collection('classes')
        .where('classCode', isEqualTo: classCode)
        .limit(1)
        .get();

    if (classQuery.docs.isEmpty) {
      throw Exception('Kode kelas tidak valid');
    }

    final classDoc = classQuery.docs.first;
    final classData = classDoc.data();
    final studentIds = List<String>.from(classData['studentIds'] ?? []);

    if (studentIds.contains(studentId)) {
      throw Exception('Kamu sudah menjadi anggota kelas ini');
    }

    await classDoc.reference.update({
      'studentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  @override
  Future<void> removeStudent(String classId, String studentId) async {
    await _firestore.collection('classes').doc(classId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  @override
  Future<void> deleteClass(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  @override
  Stream<List<ClassModel>> watchUserClasses(String userId) {
    return _firestore
        .collection('classes')
        .where(Filter.or(
          Filter('teacherId', isEqualTo: userId),
          Filter('studentIds', arrayContains: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<ClassModel?> getClassByCode(String classCode) async {
    final query = await _firestore
        .collection('classes')
        .where('classCode', isEqualTo: classCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return ClassModel.fromFirestore(query.docs.first);
  }

  /// Generate unique 6-character alphanumeric class code
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}

@riverpod
ClassRepository classRepository(ClassRepositoryRef ref) {
  return ClassRepositoryImpl(FirebaseFirestore.instance);
}