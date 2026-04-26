import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_tracking_provider.dart';
import '../utils/error_handler.dart';

class TeacherStudentTrackingScreen extends StatefulWidget {
  final String kidId;
  final String kidName;

  const TeacherStudentTrackingScreen({
    super.key,
    required this.kidId,
    required this.kidName,
  });

  @override
  State<TeacherStudentTrackingScreen> createState() =>
      _TeacherStudentTrackingScreenState();
}

class _TeacherStudentTrackingScreenState
    extends State<TeacherStudentTrackingScreen> {
  final _behaviorCtrl = TextEditingController();
  final _participationCtrl = TextEditingController();
  final _homeworkCtrl = TextEditingController();
  final _comprehensionCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();

  final _progressTitleCtrl = TextEditingController();
  final _progressNoteCtrl = TextEditingController();
  int _progressPercent = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentTrackingProvider>(context, listen: false)
          .loadAll(widget.kidId);
    });
  }

  @override
  void dispose() {
    _behaviorCtrl.dispose();
    _participationCtrl.dispose();
    _homeworkCtrl.dispose();
    _comprehensionCtrl.dispose();
    _recommendationsCtrl.dispose();
    _progressTitleCtrl.dispose();
    _progressNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    final provider = Provider.of<StudentTrackingProvider>(context, listen: false);
    await ErrorHandler.handleApiCall(
      context,
      () => provider.addNote(
        kidId: widget.kidId,
        behavior: _behaviorCtrl.text,
        participation: _participationCtrl.text,
        homeworkQuality: _homeworkCtrl.text,
        comprehension: _comprehensionCtrl.text,
        recommendations: _recommendationsCtrl.text,
      ),
    );
    _behaviorCtrl.clear();
    _participationCtrl.clear();
    _homeworkCtrl.clear();
    _comprehensionCtrl.clear();
    _recommendationsCtrl.clear();
  }

  Future<void> _submitProgress() async {
    final provider = Provider.of<StudentTrackingProvider>(context, listen: false);
    await ErrorHandler.handleApiCall(
      context,
      () => provider.addProgress(
        kidId: widget.kidId,
        progressPercent: _progressPercent,
        title: _progressTitleCtrl.text,
        note: _progressNoteCtrl.text,
      ),
    );
    _progressTitleCtrl.clear();
    _progressNoteCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentTrackingProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Suivi: ${widget.kidName}')),
      body: provider.isLoading && provider.notes.isEmpty && provider.progressHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadAll(widget.kidId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('Ajouter une note enseignant'),
                  _input(_behaviorCtrl, 'Comportement'),
                  _input(_participationCtrl, 'Participation'),
                  _input(_homeworkCtrl, 'Qualité des devoirs'),
                  _input(_comprehensionCtrl, 'Compréhension'),
                  _input(_recommendationsCtrl, 'Recommandations', maxLines: 3),
                  ElevatedButton.icon(
                    onPressed: _submitNote,
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Enregistrer la note'),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Ajouter une entrée de progression'),
                  _input(_progressTitleCtrl, 'Titre (optionnel)'),
                  _input(_progressNoteCtrl, 'Commentaire', maxLines: 2),
                  Text('Progression: $_progressPercent%'),
                  Slider(
                    value: _progressPercent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$_progressPercent%',
                    onChanged: (v) => setState(() => _progressPercent = v.round()),
                  ),
                  ElevatedButton.icon(
                    onPressed: _submitProgress,
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Enregistrer la progression'),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Historique des notes'),
                  ...provider.notes.take(10).map(_noteCard),
                  const SizedBox(height: 16),
                  _sectionTitle('Historique progression'),
                  ...provider.progressHistory.take(12).map(_progressCard),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _input(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Widget _noteCard(Map<String, dynamic> n) => Card(
        child: ListTile(
          title: Text((n['recommendations'] ?? n['behavior'] ?? 'Note').toString()),
          subtitle: Text(
            [
              if ((n['behavior'] ?? '').toString().isNotEmpty) 'Comportement: ${n['behavior']}',
              if ((n['participation'] ?? '').toString().isNotEmpty) 'Participation: ${n['participation']}',
              if ((n['homeworkQuality'] ?? '').toString().isNotEmpty) 'Devoirs: ${n['homeworkQuality']}',
              if ((n['comprehension'] ?? '').toString().isNotEmpty) 'Compréhension: ${n['comprehension']}',
            ].join('\n'),
          ),
        ),
      );

  Widget _progressCard(Map<String, dynamic> e) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text('${e['progressPercent'] ?? 0}%')),
          title: Text((e['title'] ?? 'Entrée progression').toString()),
          subtitle: Text((e['note'] ?? '').toString()),
        ),
      );
}
