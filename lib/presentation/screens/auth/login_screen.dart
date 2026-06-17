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
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;

  static const _demoEmail    = 'teacher@demo.com';
  static const _demoPassword = 'demo1234';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      // GoRouter redirect handles navigation automatically.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginDemo() async {
    setState(() {
      _emailCtrl.text    = _demoEmail;
      _passwordCtrl.text = _demoPassword;
      _loading           = true;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _demoEmail,
            password: _demoPassword,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                    // Logo
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
                    const SizedBox(height: 16),
                    Text(AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('متابعة حفظ ومراجعة الطلاب',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 32),

                    // Demo account banner
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
                              color: scheme.primary.withOpacity(0.35)),
                        ),
                        child: Row(children: [
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
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: scheme.primary),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: Divider(color: scheme.outlineVariant)),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('أو',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 13)),
                      ),
                      Expanded(
                          child: Divider(color: scheme.outlineVariant)),
                    ]),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@'))
                              ? 'أدخل بريداً إلكترونياً صالحاً'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    // Password
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

                    // Sign-in button
                    FilledButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white))
                          : const Text('تسجيل الدخول'),
                    ),
                    const SizedBox(height: 12),

                    // Register link
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
