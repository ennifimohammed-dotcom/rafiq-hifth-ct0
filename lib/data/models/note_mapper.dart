import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/note.dart';

class NoteMapper {
  NoteMapper._();

  static Note fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Note(
      id: doc.id,
      studentId: (d['studentId'] ?? '') as String,
      text: (d['text'] ?? '') as String,
      visibleToParent: (d['visibleToParent'] ?? true) as bool,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toMap(Note n) => {
        'studentId': n.studentId,
        'text': n.text,
        'visibleToParent': n.visibleToParent,
        'createdAt': Timestamp.fromDate(n.createdAt),
      };
}
