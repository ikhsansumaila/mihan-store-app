import 'package:flutter/material.dart';

import '../../../data/models/order_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';

/// Pencarian: tidak peka huruf besar/kecil; semua kata harus ada di nama (sama dengan regionsApi.js di web).
String normalizeSearch(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

List<RegionRef> filterRegions(List<RegionRef> items, String query) {
  final words = normalizeSearch(query).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return items;
  return items.where((it) {
    final n = normalizeSearch(it.name);
    return words.every(n.contains);
  }).toList();
}

/// Kolom pilihan wilayah: ketuk untuk membuka daftar yang bisa dicari.
class RegionPickerField extends StatelessWidget {
  final String label;
  final String lower;
  final RegionRef? value;
  final List<RegionRef> items;
  final bool loading;
  final String loadError;
  final VoidCallback onRetry;
  final ValueChanged<RegionRef> onChanged;
  final bool disabled;
  final String disabledHint;
  final String? errorText;

  const RegionPickerField({
    super.key,
    required this.label,
    required this.lower,
    required this.value,
    required this.items,
    required this.loading,
    required this.loadError,
    required this.onRetry,
    required this.onChanged,
    required this.disabled,
    required this.disabledHint,
    this.errorText,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<RegionRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RegionSearchSheet(label: label, lower: lower, items: items, selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final invalid = errorText != null && errorText!.isNotEmpty;
    final String text;
    if (disabled) {
      text = disabledHint;
    } else if (loading) {
      text = 'Memuat daftar $lower...';
    } else {
      text = value?.name ?? 'Pilih $lower';
    }
    final enabled = !disabled && !loading && loadError.isEmpty;

    return LabeledField(
      label: label,
      required: true,
      error: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: enabled ? () => _open(context) : null,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              isEmpty: false,
              decoration: inputDeco(invalid: invalid).copyWith(
                fillColor: enabled ? Colors.white : AppColors.background,
                suffixIcon: loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.expand_more),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: value != null && !disabled ? AppColors.textDark : AppColors.textLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (loadError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(loadError, style: const TextStyle(fontSize: 12, color: AppColors.errorRed)),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RegionSearchSheet extends StatefulWidget {
  final String label;
  final String lower;
  final List<RegionRef> items;
  final RegionRef? selected;

  const _RegionSearchSheet({required this.label, required this.lower, required this.items, this.selected});

  @override
  State<_RegionSearchSheet> createState() => _RegionSearchSheetState();
}

class _RegionSearchSheetState extends State<_RegionSearchSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final shown = filterRegions(widget.items, query);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pilih ${widget.label}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: inputDeco(hint: 'Cari ${widget.lower}...').copyWith(
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada ${widget.lower} yang cocok.',
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final it = shown[i];
                        final sel = it.code == widget.selected?.code;
                        return ListTile(
                          title: Text(it.name),
                          trailing: sel ? const Icon(Icons.check, color: AppColors.primaryPurple) : null,
                          selected: sel,
                          selectedColor: AppColors.primaryPurple,
                          onTap: () => Navigator.pop(context, it),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
