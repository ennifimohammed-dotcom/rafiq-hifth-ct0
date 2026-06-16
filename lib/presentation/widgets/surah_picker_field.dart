import 'package:flutter/material.dart';

import '../../core/constants/quran_data.dart';

/// Tap-to-open searchable surah picker — fast input on mobile.
class SurahPickerField extends StatelessWidget {
  final int selectedSurah;
  final ValueChanged<Surah> onSelected;

  const SurahPickerField({
    super.key,
    required this.selectedSurah,
    required this.onSelected,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<Surah>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _SurahPickerSheet(),
    );
    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surah = QuranData.byNumber(selectedSurah);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'السورة',
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          '${surah.number}. ${surah.displayName}  (${surah.ayahCount} آية)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SurahPickerSheet extends StatefulWidget {
  const _SurahPickerSheet();

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = QuranData.surahs
        .where((s) =>
            _query.isEmpty ||
            s.name.contains(_query) ||
            s.number.toString() == _query)
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'ابحث عن سورة...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final surah = filtered[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text(
                      '${surah.number}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(surah.displayName),
                  subtitle: Text('${surah.ayahCount} آية'),
                  onTap: () => Navigator.of(context).pop(surah),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
