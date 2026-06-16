import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/quran_data.dart';
import '../../../domain/entities/student.dart';
import '../../providers/app_providers.dart';
import '../../widgets/surah_picker_field.dart';

/// Create or edit a student. Pass [studentId] for edit mode.
class StudentFormScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const StudentFormScreen({super.key, this.studentId});

  bool get isEdit => studentId != null;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ayahStartController = TextEditingController(text: '1');
  final _ayahEndController = TextEditingController(text: '1');

  int _surah = 1;
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _ayahStartController.dispose();
    _ayahEndController.dispose();
    super.dispose();
  }

  void _prefill(Student student) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = student.name;
    _ageController.text = student.age?.toString() ?? '';
    _phoneController.text = student.parentPhone ?? '';
    _ayahStartController.text = student.currentAyahStart.toString();
    _ayahEndController.text = student.currentAyahEnd.toString();
    _surah = student.currentSurah;
  }

  Future<void> _save(Student? existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final repo = ref.read(studentRepositoryProvider);
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final phone = _phoneController.text.trim();
    final ayahStart = int.parse(_ayahStartController.text.trim());
    final ayahEnd = int.parse(_ayahEndController.text.trim());

    try {
      if (existing != null) {
        await repo.updateStudent(existing.copyWith(
          name: name,
          age: age,
          parentPhone: phone.isEmpty ? null : phone,
          currentSurah: _surah,
          currentAyahStart: ayahStart,
          currentAyahEnd: ayahEnd,
        ));
        // Refresh parent snapshot if the student is shared.
        // ignore: unawaited_futures
        ref.read(shareRepositoryProvider).syncPublicReport(existing.id);
      } else {
        final student = Student(
          id: const Uuid().v4(),
          name: name,
          age: age,
          parentPhone: phone.isEmpty ? null : phone,
          currentSurah: _surah,
          currentAyahStart: ayahStart,
          currentAyahEnd: ayahEnd,
          createdAt: DateTime.now(),
        );
        await repo.addStudent(student);
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Student? existing;
    if (widget.isEdit) {
      final async = ref.watch(studentProvider(widget.studentId!));
      existing = async.value;
      if (existing != null) _prefill(existing);
      if (async.isLoading && existing == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('تعديل طالب')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    final maxAyah = QuranData.byNumber(_surah).ayahCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'تعديل طالب' : 'طالب جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم الطالب *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'العمر',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 3 || n > 99) {
                        return 'عمر غير صالح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'هاتف ولي الأمر',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'الموضع الحالي في الحفظ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SurahPickerField(
              selectedSurah: _surah,
              onSelected: (surah) => setState(() => _surah = surah.number),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ayahStartController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'من الآية'),
                    validator: (v) => _validateAyah(v, maxAyah),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ayahEndController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'إلى الآية'),
                    validator: (v) {
                      final base = _validateAyah(v, maxAyah);
                      if (base != null) return base;
                      final start =
                          int.tryParse(_ayahStartController.text.trim());
                      final end = int.parse(v!.trim());
                      if (start != null && end < start) {
                        return 'أصغر من البداية';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(existing),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(widget.isEdit ? 'حفظ التعديلات' : 'إضافة الطالب'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateAyah(String? v, int maxAyah) {
    if (v == null || v.trim().isEmpty) return 'مطلوب';
    final n = int.tryParse(v.trim());
    if (n == null || n < 1) return 'رقم غير صالح';
    if (n > maxAyah) return 'الحد الأقصى $maxAyah';
    return null;
  }
}
