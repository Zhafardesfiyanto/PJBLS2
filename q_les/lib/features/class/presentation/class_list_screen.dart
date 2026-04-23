import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/logout_button.dart';
import '../../../features/auth/domain/user_model.dart';
import '../data/class_provider.dart';
import '../domain/class_model.dart';

/// Screen untuk menampilkan daftar kelas
class ClassListScreen extends ConsumerStatefulWidget {
  const ClassListScreen({super.key});

  @override
  ConsumerState<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends ConsumerState<ClassListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClassModel> _filterClasses(List<ClassModel> classes) {
    if (_searchQuery.isEmpty) return classes;
    
    return classes.where((classModel) {
      return classModel.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final classesAsync = ref.watch(userClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profil',
          ),
          const LogoutButton(isIconButton: true),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari kelas...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Class list
          Expanded(
            child: classesAsync.when(
              data: (classes) {
                final filteredClasses = _filterClasses(classes);
                
                if (filteredClasses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.class_ : Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Belum ada kelas'
                              : 'Tidak ada kelas yang ditemukan',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            user?.isGuru == true 
                                ? 'Buat kelas pertama Anda'
                                : 'Bergabung dengan kelas menggunakan kode',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredClasses.length,
                  itemBuilder: (context, index) {
                    final classModel = filteredClasses[index];
                    final isTeacher = classModel.teacherId == user?.uid;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isTeacher ? Colors.blue : Colors.green,
                          child: Icon(
                            isTeacher ? Icons.school : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          classModel.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(classModel.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Kode: ${classModel.classCode}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${classModel.studentIds.length} murid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        onTap: () {
                          context.push('/classes/${classModel.id}');
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat kelas',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(userClassesProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: user?.isGuru == true && user?.isVerified == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/classes/create'),
              icon: const Icon(Icons.add),
              label: const Text('Buat Kelas'),
            )
          : user?.isMurid == true
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/classes/join'),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Gabung Kelas'),
                )
              : null,
    );
  }
}