import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/glass_card.dart';
import '../components/empty_state.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: const Center(
          child: EmptyState(
            icon: Icons.class_,
            title: 'No Classes Yet',
            message: 'Create your first class to get started',
          ),
        ),
      ),
    );
  }
}
