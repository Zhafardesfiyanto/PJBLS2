import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../data/class_provider.dart';
import '../data/class_repository_impl.dart';
import '../domain/class_model.dart';

/// Provider for getting a specific class by ID
final classDetailProvider = FutureProvider.family<ClassModel?, String>((ref, classId) async {
  final repository = ref.watch(classRepositoryProvider);
  final userClasses = await ref.watch(userClassesProvider.future);
  
  try {
    return userClasses.firstWhere((c) => c.id == classId);
  } catch (e) {
    return null;
  }
});

/// Screen showing class details with tabs for assignments, quizzes, exams, chat, and members
class ClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;
  
  const ClassDetailScreen({
    super.key,
    required this.classId,
  });

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _copyClassCode(String classCode) async {
    await Clipboard.setData(ClipboardData(text: classCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode berhasil disalin'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeStudent(ClassModel classModel, String studentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluarkan Murid'),
        content: const Text('Apakah Anda yakin ingin mengeluarkan murid ini dari kelas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final remover = ref.read(studentRemoverProvider.notifier);
        await remover.removeStudent(classModel.id, studentId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Murid berhasil dikeluarkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengeluarkan murid: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final classAsync = ref.watch(classDetailProvider(widget.classId));

    return classAsync.when(
      data: (classModel) {
        if (classModel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kelas Tidak Ditemukan')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Kelas tidak ditemukan atau Anda tidak memiliki akses'),
                ],
              ),
            ),
          );
        }

        final isTeacher = classModel.teacherId == user?.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(classModel.name),
            actions: [
              if (isTeacher)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'copy_code':
                        _copyClassCode(classModel.classCode);
                        break;
                      case 'edit':
                        // TODO: Navigate to edit class screen
                        break;
                      case 'delete':
                        // TODO: Implement delete class
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy_code',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Salin Kode Kelas'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Kelas'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Hapus Kelas', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.assignment), text: 'Tugas'),
                Tab(icon: Icon(Icons.quiz), text: 'Kuis'),
                Tab(icon: Icon(Icons.school), text: 'Ujian'),
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
                Tab(icon: Icon(Icons.people), text: 'Anggota'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _AssignmentTab(classModel: classModel, isTeacher: isTeacher),
              _QuizTab(classModel: classModel, isTeacher: isTeacher),
              _ExamTab(classModel: classModel, isTeacher: isTeacher),
              _ChatTab(classModel: classModel),
              _MembersTab(
                classModel: classModel, 
                isTeacher: isTeacher,
                onRemoveStudent: _removeStudent,
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Memuat...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(classDetailProvider(widget.classId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tab widgets
class _AssignmentTab extends StatelessWidget {
  final ClassModel classModel;
  final bool isTeacher;

  const _AssignmentTab({required this.classModel, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Fitur Tugas', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Akan segera hadir', style: TextStyle(color: Colors.grey)),
          if (isTeacher) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create assignment
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Tugas'),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizTab extends StatelessWidget {
  final ClassModel classModel;
  final bool isTeacher;

  const _QuizTab({required this.classModel, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Fitur Kuis', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Akan segera hadir', style: TextStyle(color: Colors.grey)),
          if (isTeacher) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create quiz
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Kuis'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExamTab extends StatelessWidget {
  final ClassModel classModel;
  final bool isTeacher;

  const _ExamTab({required this.classModel, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Fitur Ujian', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Akan segera hadir', style: TextStyle(color: Colors.grey)),
          if (isTeacher) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create exam
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Ujian'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  final ClassModel classModel;

  const _ChatTab({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Fitur Chat Kelas', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Akan segera hadir', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final ClassModel classModel;
  final bool isTeacher;
  final Function(ClassModel, String) onRemoveStudent;

  const _MembersTab({
    required this.classModel,
    required this.isTeacher,
    required this.onRemoveStudent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header with class info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Informasi Kelas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Nama: ${classModel.name}'),
              Text('Deskripsi: ${classModel.description}'),
              Row(
                children: [
                  Text('Kode: ${classModel.classCode}'),
                  const SizedBox(width: 8),
                  if (isTeacher)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: classModel.classCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode berhasil disalin')),
                          );
                        }
                      },
                      tooltip: 'Salin kode',
                    ),
                ],
              ),
              Text('Total Murid: ${classModel.studentIds.length}'),
            ],
          ),
        ),
        
        // Members list
        Expanded(
          child: classModel.studentIds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada murid', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Bagikan kode kelas untuk mengundang murid', 
                           style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classModel.studentIds.length,
                  itemBuilder: (context, index) {
                    final studentId = classModel.studentIds[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('Murid ${index + 1}'),
                        subtitle: Text('ID: ${studentId.substring(0, 8)}...'),
                        trailing: isTeacher
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => onRemoveStudent(classModel, studentId),
                                tooltip: 'Keluarkan murid',
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}