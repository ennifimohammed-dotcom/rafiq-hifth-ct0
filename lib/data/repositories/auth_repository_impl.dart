import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/auth_repository.dart';

/// Local-first authentication.
///
/// Credentials (email + password) are stored in SharedPreferences.
/// Firebase Anonymous Auth is used ONLY to satisfy Firestore security rules
/// (request.auth != null) — the teacher never sees Firebase Auth.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final SharedPreferences _prefs;
  final _controller = StreamController<String?>.broadcast();

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kTeacherId  = 'lauth_teacher_id';
  static const _kEmail      = 'lauth_email';
  static const _kPassword   = 'lauth_password';
  static const _kLoggedIn   = 'lauth_logged_in';
  static const _kDemoSeeded = 'lauth_demo_seeded';

  static const demoEmail    = 'teacher@demo.com';
  static const demoPassword = 'demo1234';

  AuthRepositoryImpl(this._firebaseAuth, this._prefs);

  // ── Seed demo account on first launch (called from main.dart) ────────────
  static Future<void> seedDemo(SharedPreferences prefs) async {
    if (prefs.getBool(_kDemoSeeded) == true) return;
    // Generate a permanent teacher ID the first time ever.
    if (prefs.getString(_kTeacherId) == null) {
      await prefs.setString(_kTeacherId, const Uuid().v4());
    }
    // Pre-fill demo credentials only if no account exists yet.
    if (prefs.getString(_kEmail) == null) {
      await prefs.setString(_kEmail, demoEmail);
      await prefs.setString(_kPassword, demoPassword);
    }
    await prefs.setBool(_kDemoSeeded, true);
  }

  // ── Ensure Firebase anonymous session (for Firestore rules) ──────────────
  Future<void> _ensureAnonymousAuth() async {
    if (_firebaseAuth.currentUser == null) {
      await _firebaseAuth.signInAnonymously();
    }
  }

  // ── AuthRepository interface ──────────────────────────────────────────────

  @override
  String? get currentTeacherId {
    if (_prefs.getBool(_kLoggedIn) != true) return null;
    return _prefs.getString(_kTeacherId);
  }

  @override
  Stream<String?> watchTeacherId() async* {
    yield currentTeacherId;
    yield* _controller.stream;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final storedEmail    = _prefs.getString(_kEmail);
    final storedPassword = _prefs.getString(_kPassword);

    if (storedEmail == null) {
      throw Exception('لا يوجد حساب — أنشئ حساباً جديداً أولاً');
    }
    if (email.trim().toLowerCase() != storedEmail.toLowerCase() ||
        password != storedPassword) {
      throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }

    await _ensureAnonymousAuth();
    await _prefs.setBool(_kLoggedIn, true);
    _controller.add(_prefs.getString(_kTeacherId));
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    final existing = _prefs.getString(_kEmail);
    // Allow overwriting only the seeded demo account.
    if (existing != null && existing != demoEmail) {
      throw Exception('يوجد حساب مسجّل بالفعل بالبريد: $existing');
    }
    // Generate teacher ID if not yet created (edge case).
    if (_prefs.getString(_kTeacherId) == null) {
      await _prefs.setString(_kTeacherId, const Uuid().v4());
    }
    await _prefs.setString(_kEmail, email.trim().toLowerCase());
    await _prefs.setString(_kPassword, password);
    await _ensureAnonymousAuth();
    await _prefs.setBool(_kLoggedIn, true);
    _controller.add(_prefs.getString(_kTeacherId));
  }

  @override
  Future<void> signOut() async {
    await _prefs.setBool(_kLoggedIn, false);
    // Keep anonymous Firebase session alive to preserve the Firestore UID.
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
