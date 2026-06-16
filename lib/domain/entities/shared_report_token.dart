/// Registry entry for a generated share token.
class SharedReportToken {
  final String token;
  final String teacherId;
  final String studentId;
  final DateTime createdAt;
  final bool active;

  const SharedReportToken({
    required this.token,
    required this.teacherId,
    required this.studentId,
    required this.createdAt,
    this.active = true,
  });
}
