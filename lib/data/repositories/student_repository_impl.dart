import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';
import '../models/student_mapper.dart';
import 'firestore_paths.dart';

class StudentRepositoryImpl implements StudentRepository {
  final FirestorePaths _paths;

  StudentRepositoryImpl(this._paths);

  @override
  Stream<List<Student>> watchStudents() {
    return _paths
        .students()
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(StudentMapper.fromDoc).toList());
  }

  @override
  Stream<Student?> watchStudent(String studentId) {
    return _paths.student(studentId).snapshots().map(
        (doc) => doc.exists ? StudentMapper.fromDoc(doc) : null);
  }

  @override
  Future<Student?> getStudent(String studentId) async {
    final doc = await _paths.student(studentId).get();
    return doc.exists ? StudentMapper.fromDoc(doc) : null;
  }

  @override
  Future<void> addStudent(Student student) async {
    await _paths.students().add(StudentMapper.toMap(student));
  }

  @override
  Future<void> updateStudent(Student student) async {
    await _paths.student(student.id).update(StudentMapper.toMap(student));
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    final studentRef = _paths.student(studentId);

    // Revoke any public share before deleting.
    final snapshot = await studentRef.get();
    final token = snapshot.data()?['shareToken'] as String?;

    // Delete subcollections in pages.
    for (final col in ['sessions', 'attendance', 'notes']) {
      while (true) {
        final page = await studentRef.collection(col).limit(200).get();
        if (page.docs.isEmpty) break;
        final batch = _paths.db.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    final batch = _paths.db.batch();
    if (token != null) {
      batch.delete(_paths.sharedTokens().doc(token));
      batch.delete(_paths.publicReports().doc(token));
    }
    batch.delete(studentRef);
    await batch.commit();
  }
}
