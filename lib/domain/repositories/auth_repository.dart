/// Authentication contract (teacher is the only user).
abstract class AuthRepository {
  Stream<String?> watchTeacherId();
  String? get currentTeacherId;
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
}
