import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../providers/kids_provider.dart';
import '../utils/error_handler.dart';

class AddKidPage extends StatefulWidget {
  const AddKidPage({super.key});

  @override
  State<AddKidPage> createState() => _AddKidPageState();
}

class _AddKidPageState extends State<AddKidPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _handleAddKid() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final kidsProvider = Provider.of<KidsProvider>(context, listen: false);

      final success = await ErrorHandler.handleApiCall(
        context,
        () => kidsProvider.addKid(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          grade: _gradeController.text.trim().isEmpty
              ? null
              : _gradeController.text.trim(),
          school: _schoolController.text.trim().isEmpty
              ? null
              : _schoolController.text.trim(),
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success == true) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Loading(message: 'Adding kid...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                          color: EduBridgeColors.textPrimary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Add Kid',
                          style: EduBridgeTypography.displaySmall.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'First Name',
                                        prefixIcon: Icon(Icons.person_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Last Name',
                                        prefixIcon: Icon(Icons.person_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _gradeController,
                                decoration: const InputDecoration(
                                  labelText: 'Grade (Optional)',
                                  prefixIcon: Icon(Icons.grade_outlined),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _schoolController,
                                decoration: const InputDecoration(
                                  labelText: 'School (Optional)',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                              ),
                              const SizedBox(height: 24),
                              GradientButton(
                                text: 'Add Kid',
                                icon: Icons.add,
                                onPressed: _handleAddKid,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
