import '../entities/public_report.dart';

abstract class ShareRepository {
  /// Creates a new secure token for the student (revoking any old one),
  /// publishes the first public snapshot, and returns the token.
  Future<String> generateToken(String studentId);

  /// Revokes the student's current token and deletes the public snapshot.
  Future<void> revokeToken(String studentId);

  /// Rebuilds and publishes the public report snapshot if the student
  /// has an active share token. Safe to call after any data change.
  Future<void> syncPublicReport(String studentId);

  /// Reads a public report by token. No authentication required.
  Future<PublicReport?> fetchPublicReport(String token);
}
