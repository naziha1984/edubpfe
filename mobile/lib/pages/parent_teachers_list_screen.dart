import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../components/loading.dart';
import '../components/empty_state.dart';
import '../components/teacher_public_card.dart';
import '../utils/error_handler.dart';
import 'parent_teacher_detail_screen.dart';

class ParentTeachersListScreen extends StatefulWidget {
  const ParentTeachersListScreen({
    super.key,
    required this.kidId,
    required this.kidName,
  });

  final String kidId;
  final String kidName;

  @override
  State<ParentTeachersListScreen> createState() => _ParentTeachersListScreenState();
}

class _ParentTeachersListScreenState extends State<ParentTeachersListScreen> {
  List<Map<String, dynamic>> _teachers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final data = await ErrorHandler.handleApiCall<List<dynamic>>(
      context,
      () => api.getAcceptedTeachers(),
    );
    if (!mounted) return;
    setState(() {
      _teachers = (data ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choisir un enseignant - ${widget.kidName}'),
      ),
      body: _loading
          ? const Loading(message: 'Chargement des enseignants...')
          : _teachers.isEmpty
              ? const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'Aucun enseignant disponible',
                  message: 'Aucun enseignant accepté pour le moment.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TeacherPublicCard(
                          teacher: teacher,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ParentTeacherDetailScreen(
                                  kidId: widget.kidId,
                                  kidName: widget.kidName,
                                  teacherId: teacher['id'].toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
