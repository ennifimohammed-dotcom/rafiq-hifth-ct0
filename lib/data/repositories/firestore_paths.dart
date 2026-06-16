import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore collection references.
class FirestorePaths {
  final FirebaseFirestore db;
  final String teacherId;

  const FirestorePaths(this.db, this.teacherId);

  DocumentReference<Map<String, dynamic>> teacher() =>
      db.collection('teachers').doc(teacherId);

  CollectionReference<Map<String, dynamic>> students() =>
      teacher().collection('students');

  DocumentReference<Map<String, dynamic>> student(String id) =>
      students().doc(id);

  CollectionReference<Map<String, dynamic>> sessions(String studentId) =>
      student(studentId).collection('sessions');

  CollectionReference<Map<String, dynamic>> attendance(String studentId) =>
      student(studentId).collection('attendance');

  CollectionReference<Map<String, dynamic>> notes(String studentId) =>
      student(studentId).collection('notes');

  CollectionReference<Map<String, dynamic>> sharedTokens() =>
      db.collection('shared_tokens');

  CollectionReference<Map<String, dynamic>> publicReports() =>
      db.collection('public_reports');
}
