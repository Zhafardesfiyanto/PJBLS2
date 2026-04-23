import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/class/data/class_provider.dart';
import '../../features/class/domain/class_model.dart';

/// Dropdown widget for selecting a class
class ClassDropdown extends ConsumerWidget {
  final ClassModel? selectedClass;
  final ValueChanged<ClassModel?> onChanged;
  final String? hintText;
  final bool enabled;

  const ClassDropdown({
    super.key,
    required this.selectedClass,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(userClassesProvider);

    return classesAsync.when(
      data: (classes) => DropdownButtonFormField<ClassModel>(
        initialValue: selectedClass,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          hintText: hintText ?? 'Pilih kelas...',
          border: const OutlineInputBorder(),
        ),
        items: classes.map((classModel) {
          return DropdownMenuItem<ClassModel>(
            value: classModel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  classModel.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Kode: ${classModel.classCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        validator: (value) {
          if (value == null) {
            return 'Pilih kelas terlebih dahulu';
          }
          return null;
        },
      ),
      loading: () => DropdownButtonFormField<ClassModel>(
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Pilih Kelas',
          hintText: 'Memuat kelas...',
          border: OutlineInputBorder(),
        ),
        items: const [],
      ),
      error: (error, _) => DropdownButtonFormField<ClassModel>(
        onChanged: null,
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          hintText: 'Error: ${error.toString()}',
          border: const OutlineInputBorder(),
          errorText: 'Gagal memuat kelas',
        ),
        items: const [],
      ),
    );
  }
}