import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spiral_journal/services/pin_auth_service.dart';

/// PIN setup screen for first-time authentication configuration.
/// 
/// This screen guides users through setting up a 4-6 digit PIN for
/// securing their journal entries. It includes PIN confirmation,
/// biometric setup options, and follows Material Design 3 guidelines.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinAuthService _pinAuthService = PinAuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();

  bool _isLoading = false;
  bool _showConfirmPin = false;
  bool _biometricAvailable = false;
  bool _enableBiometric = false;
  String? _errorMessage;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _pinAuthService.isBiometricAvailable();
    final biometrics = await _pinAuthService.getAvailableBiometrics();
    
    setState(() {
      _biometricAvailable = available;
      if (biometrics.isNotEmpty) {
        if (biometrics.contains(BiometricType.face)) {
          _biometricType = 'Face ID';
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          _biometricType = 'Touch ID';
        }
      }
    });
  }

  void _onPinChanged(String value) {
    setState(() {
      _errorMessage = null;
    });

    if (value.length >= 4 && value.length <= 6) {
      if (!_showConfirmPin) {
        setState(() {
          _showConfirmPin = true;
        });
        // Auto-focus confirm PIN field
        Future.delayed(const Duration(milliseconds: 100), () {
          _confirmPinFocusNode.requestFocus();
        });
      }
    } else if (_showConfirmPin && value.length < 4) {
      setState(() {
        _showConfirmPin = false;
        _confirmPinController.clear();
      });
    }
  }

  void _onConfirmPinChanged(String value) {
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _setupPin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    // Validate PIN
    if (pin.length < 4 || pin.length > 6) {
      setState(() {
        _errorMessage = 'PIN must be 4-6 digits';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Set up PIN
      final result = await _pinAuthService.setPin(pin);
      
      if (result.success) {
        // Set up biometric if enabled
        if (_biometricAvailable && _enableBiometric) {
          await _pinAuthService.setBiometricEnabled(true);
        }

        // Mark first launch complete
        await _pinAuthService.markFirstLaunchComplete();

        // Navigate to main app
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Failed to set up PIN';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Header
              Text(
                'Secure Your Journal',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Set up a PIN to keep your personal reflections private and secure.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // PIN Input Section
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // PIN Input
                      Text(
                        'Enter PIN (4-6 digits)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: _onPinChanged,
                        decoration: InputDecoration(
                          hintText: 'Enter your PIN',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          letterSpacing: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Confirm PIN Input (shown after PIN is entered)
                      if (_showConfirmPin) ...[
                        const SizedBox(height: 24),
                        
                        Text(
                          'Confirm PIN',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _confirmPinController,
                          focusNode: _confirmPinFocusNode,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: _onConfirmPinChanged,
                          onSubmitted: (_) => _setupPin(),
                          decoration: InputDecoration(
                            hintText: 'Confirm your PIN',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            letterSpacing: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Biometric Option
              if (_biometricAvailable) ...[
                const SizedBox(height: 24),
                
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          _biometricType == 'Face ID' 
                              ? Icons.face 
                              : Icons.fingerprint,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable $_biometricType',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Quick access with $_biometricType',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enableBiometric,
                          onChanged: (value) {
                            setState(() {
                              _enableBiometric = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Setup Button
              FilledButton(
                onPressed: _isLoading || !_showConfirmPin 
                    ? null 
                    : _setupPin,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Set Up PIN',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Security Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your PIN is stored securely on your device and never shared.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}