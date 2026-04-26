import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_tracking_provider.dart';

class ParentChildProgressScreen extends StatefulWidget {
  final String kidId;
  final String kidName;

  const ParentChildProgressScreen({
    super.key,
    required this.kidId,
    required this.kidName,
  });

  @override
  State<ParentChildProgressScreen> createState() =>
      _ParentChildProgressScreenState();
}

class _ParentChildProgressScreenState extends State<ParentChildProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentTrackingProvider>(context, listen: false)
          .loadAll(widget.kidId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<StudentTrackingProvider>(context);
    final ov = p.overview ?? {};
    final latest = ((ov['latestProgressPercent'] ?? 0) as num).toDouble();
    final avg = ((ov['averageRecentProgress'] ?? 0) as num).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text('Notes & progrès - ${widget.kidName}')),
      body: p.isLoading && p.progressHistory.isEmpty && p.notes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => p.loadAll(widget.kidId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progression globale',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('Dernière progression: ${latest.toInt()}%'),
                          LinearProgressIndicator(value: latest / 100),
                          const SizedBox(height: 10),
                          Text('Moyenne récente: ${avg.toInt()}%'),
                          LinearProgressIndicator(value: avg / 100),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dernières notes enseignant',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...p.notes.take(5).map(
                    (n) => Card(
                      child: ListTile(
                        title: Text((n['recommendations'] ?? 'Note enseignant').toString()),
                        subtitle: Text(
                          [
                            if ((n['behavior'] ?? '').toString().isNotEmpty)
                              'Comportement: ${n['behavior']}',
                            if ((n['participation'] ?? '').toString().isNotEmpty)
                              'Participation: ${n['participation']}',
                            if ((n['homeworkQuality'] ?? '').toString().isNotEmpty)
                              'Devoirs: ${n['homeworkQuality']}',
                            if ((n['comprehension'] ?? '').toString().isNotEmpty)
                              'Compréhension: ${n['comprehension']}',
                          ].join('\n'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Historique progression',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...p.progressHistory.take(12).map(
                    (e) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${e['progressPercent'] ?? 0}%'),
                        ),
                        title: Text((e['title'] ?? 'Entrée progression').toString()),
                        subtitle: Text((e['note'] ?? '').toString()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
