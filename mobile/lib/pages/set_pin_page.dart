import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../providers/kids_provider.dart';
import '../utils/error_handler.dart';
import 'verify_pin_page.dart';

class SetPinPage extends StatefulWidget {
  final String kidId;

  const SetPinPage({super.key, required this.kidId});

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSetPin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final kidsProvider = Provider.of<KidsProvider>(context, listen: false);

      // 显式返回一个 bool，避免 void 类型带来的编译问题
      final success = await ErrorHandler.handleApiCall<bool>(
        context,
        () async {
          await kidsProvider.setPin(
            kidId: widget.kidId,
            pin: _pinController.text,
          );
          return true;
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN set successfully!'),
              backgroundColor: EduBridgeColors.success,
            ),
          );
          Navigator.pop(context);
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
              ? const Loading(message: 'Setting PIN...')
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
                          'Set PIN',
                          style: EduBridgeTypography.displaySmall.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a 4-digit PIN for your child',
                          style: EduBridgeTypography.bodyLarge.copyWith(
                            color: EduBridgeColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _pinController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'PIN',
                                  prefixIcon: Icon(Icons.lock_outlined),
                                  counterText: '',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a PIN';
                                  }
                                  if (value.length != 4) {
                                    return 'PIN must be 4 digits';
                                  }
                                  if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                                    return 'PIN must contain only numbers';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _confirmPinController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm PIN',
                                  prefixIcon: Icon(Icons.lock_outlined),
                                  counterText: '',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm PIN';
                                  }
                                  if (value != _pinController.text) {
                                    return 'PINs do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              GradientButton(
                                text: 'Set PIN',
                                icon: Icons.lock,
                                onPressed: _handleSetPin,
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
