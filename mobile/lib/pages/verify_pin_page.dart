import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../providers/kids_provider.dart';
import '../utils/error_handler.dart';
import 'subjects_page.dart';

class VerifyPinPage extends StatefulWidget {
  final String kidId;
  final String kidName;
  final int? schoolLevel;

  const VerifyPinPage({
    super.key,
    required this.kidId,
    required this.kidName,
    this.schoolLevel,
  });

  @override
  State<VerifyPinPage> createState() => _VerifyPinPageState();
}

class _VerifyPinPageState extends State<VerifyPinPage> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyPin() async {
    if (_pinController.text.length == 4) {
      setState(() {
        _isLoading = true;
      });

      final kidsProvider = Provider.of<KidsProvider>(context, listen: false);

      final result = await ErrorHandler.handleApiCall(
        context,
        () => kidsProvider.verifyPin(
          kidId: widget.kidId,
          pin: _pinController.text,
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result != null && result['kidToken'] != null) {
          // kidToken is already set in ApiService by verifyPin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectsPage(
                kidId: widget.kidId,
                kidName: widget.kidName,
                schoolLevel: widget.schoolLevel,
              ),
            ),
          );
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
              ? const Loading(message: 'Vérification du PIN...')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Retour à la liste des enfants',
                            onPressed: () => Navigator.of(context).maybePop(),
                            color: EduBridgeColors.textPrimary,
                          ),
                          Expanded(
                            child: Text(
                              'Compte enfant',
                              style: EduBridgeTypography.bodySmall.copyWith(
                                color: EduBridgeColors.textSecondary,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Code PIN',
                                style: EduBridgeTypography.displaySmall.copyWith(
                                  color: EduBridgeColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'pour ${widget.kidName}',
                                style: EduBridgeTypography.bodyLarge.copyWith(
                                  color: EduBridgeColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 40),
                              GlassCard(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _pinController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                      obscureText: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        letterSpacing: 8,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'PIN',
                                        counterText: '',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        if (value.length == 4) {
                                          _handleVerifyPin();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    GradientButton(
                                      text: 'Vérifier',
                                      icon: Icons.check,
                                      onPressed: _handleVerifyPin,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
