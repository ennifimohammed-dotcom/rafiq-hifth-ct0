/// A teacher note about a student.
class Note {
  final String id;
  final String studentId;
  final String text;
  final bool visibleToParent;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.studentId,
    required this.text,
    this.visibleToParent = true,
    required this.createdAt,
  });
}
