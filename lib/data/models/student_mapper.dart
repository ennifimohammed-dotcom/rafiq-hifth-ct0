import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/student.dart';

class StudentMapper {
  StudentMapper._();

  static Student fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Student(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      age: d['age'] as int?,
      parentPhone: d['parentPhone'] as String?,
      currentSurah: (d['currentSurah'] ?? 1) as int,
      currentAyahStart: (d['currentAyahStart'] ?? 1) as int,
      currentAyahEnd: (d['currentAyahEnd'] ?? 1) as int,
      totalAyahsMemorized: (d['totalAyahsMemorized'] ?? 0) as int,
      progressPercentage: ((d['progressPercentage'] ?? 0) as num).toDouble(),
      shareToken: d['shareToken'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toMap(Student s) => {
        'name': s.name,
        'age': s.age,
        'parentPhone': s.parentPhone,
        'currentSurah': s.currentSurah,
        'currentAyahStart': s.currentAyahStart,
        'currentAyahEnd': s.currentAyahEnd,
        'totalAyahsMemorized': s.totalAyahsMemorized,
        'progressPercentage': s.progressPercentage,
        'shareToken': s.shareToken,
        'createdAt': Timestamp.fromDate(s.createdAt),
      };
}
