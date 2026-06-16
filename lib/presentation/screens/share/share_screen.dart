import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

/// Generate / manage the parent share link & QR code for a student.
class ShareScreen extends ConsumerStatefulWidget {
  final String studentId;

  const ShareScreen({super.key, required this.studentId});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String errorPrefix) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorPrefix: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() => _run(
        () => ref
            .read(shareRepositoryProvider)
            .generateToken(widget.studentId),
        'تعذر إنشاء الرابط',
      );

  Future<void> _sync() => _run(() async {
        await ref
            .read(shareRepositoryProvider)
            .syncPublicReport(widget.studentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث التقرير ✔')),
          );
        }
      }, 'تعذر التحديث');

  Future<void> _revoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الرابط'),
        content: const Text(
            'سيتوقف الرابط الحالي عن العمل ولن يتمكن ولي الأمر من رؤية التقرير. متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إلغاء الرابط'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref.read(shareRepositoryProvider).revokeToken(widget.studentId),
      'تعذر الإلغاء',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final studentAsync = ref.watch(studentProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('مشاركة التقرير')),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'حدث خطأ',
          subtitle: e.toString(),
        ),
        data: (student) {
          if (student == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'الطالب غير موجود',
            );
          }
          final token = student.shareToken;
          final hasToken = token != null && token.isNotEmpty;

          if (!hasToken) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        size: 72, color: scheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد رابط مشاركة لـ "${student.name}" بعد',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أنشئ رابطاً آمناً يمكن لولي الأمر فتحه لمتابعة التقدم دون تسجيل دخول.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _generate,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.add_link_rounded),
                      label: const Text('إنشاء رابط المشاركة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final url = '${AppConstants.reportBaseUrl}$token';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Column(
                  children: [
                    Text(
                      'تقرير ${student.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: url,
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      url,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم نسخ الرابط ✔')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('نسخ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Share.share(
                        'تقرير حفظ القرآن للطالب ${student.name}:\n$url',
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _sync,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('تحديث بيانات التقرير الآن'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _busy ? null : _revoke,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.link_off_rounded, size: 18),
                label: const Text('إلغاء الرابط'),
              ),
              const SizedBox(height: 8),
              Text(
                'ملاحظة: يتم تحديث بيانات التقرير تلقائياً بعد كل جلسة أو حضور أو ملاحظة جديدة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
            ],
          );
        },
      ),
    );
  }
}
