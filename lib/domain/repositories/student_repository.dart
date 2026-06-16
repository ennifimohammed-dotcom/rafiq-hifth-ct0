import '../entities/student.dart';

abstract class StudentRepository {
  Stream<List<Student>> watchStudents();
  Stream<Student?> watchStudent(String studentId);
  Future<Student?> getStudent(String studentId);
  Future<void> addStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String studentId);
}
