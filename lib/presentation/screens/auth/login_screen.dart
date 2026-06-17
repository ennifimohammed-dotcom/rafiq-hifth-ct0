import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool _loading         = false;
  bool _obscure         = true;

  static const _demoEmail    = 'teacher@demo.com';
  static const _demoPassword = 'demo1234';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Sign-in (regular)
  // -----------------------------------------------------------------------
  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_authMessage(e.code))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -----------------------------------------------------------------------
  // Demo account: create if not exists then sign in
  // -----------------------------------------------------------------------
  Future<void> _loginDemo() async {
    setState(() {
      _emailCtrl.text    = _demoEmail;
      _passwordCtrl.text = _demoPassword;
      _loading           = true;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      // Try sign-in first
      await auth.signIn(email: _demoEmail, password: _demoPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // Account doesn't exist yet — create it
        try {
          await auth.register(email: _demoEmail, password: _demoPassword);
        } on FirebaseAuthException catch (e2) {
          // email-already-in-use: race condition — just sign in again
          if (e2.code != 'email-already-in-use') rethrow;
          await auth.signIn(email: _demoEmail, password: _demoPassword);
        }
      } else {
        rethrow;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الدخول التجريبي: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -----------------------------------------------------------------------
  String _authMessage(String code) => switch (code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        'too-many-requests'      => 'محاولات كثيرة، حاول لاحقاً',
        'network-request-failed' => 'تحقق من اتصال الإنترنت',
        _                        => 'حدث خطأ أثناء تسجيل الدخول',
      };

  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo ──────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 84, height: 84,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Colors.white, size: 42),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'متابعة حفظ ومراجعة الطلاب',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14,
                          color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 36),

                    // ── Demo banner ───────────────────────────────────
                    InkWell(
                      onTap: _loading ? null : _loginDemo,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: scheme.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_outline_rounded,
                                color: scheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('استخدام الحساب التجريبي',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.primary,
                                          fontSize: 14)),
                                  Text(
                                    '$_demoEmail  •  $_demoPassword',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant,
                                        fontFamily: 'monospace'),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: scheme.primary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('أو',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                    ]),
                    const SizedBox(height: 20),

                    // ── Email / Password ──────────────────────────────
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'أدخل بريداً إلكترونياً صالحاً'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'كلمة المرور 6 أحرف على الأقل'
                          : null,
                      onFieldSubmitted: (_) => _signIn(),
                    ),
                    const SizedBox(height: 24),

                    // ── Sign-in button ────────────────────────────────
                    FilledButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white))
                          : const Text('تسجيل الدخول'),
                    ),
                    const SizedBox(height: 14),

                    // ── Register link ─────────────────────────────────
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('إنشاء حساب جديد'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
