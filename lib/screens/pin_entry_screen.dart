import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spiral_journal/services/pin_auth_service.dart';

/// PIN entry screen for authentication when returning to the app.
/// 
/// This screen handles PIN validation, biometric authentication,
/// error handling with retry logic, and PIN reset functionality.
/// Follows Material Design 3 guidelines for consistent UI.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> with TickerProviderStateMixin {
  final PinAuthService _pinAuthService = PinAuthService();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _isLoading = false;
  bool _biometricEnabled = false;
  String? _errorMessage;
  String _biometricType = 'Biometric';
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeShakeAnimation();
    _loadAuthStatus();
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _initializeShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  Future<void> _loadAuthStatus() async {
    final status = await _pinAuthService.getAuthStatus();
    setState(() {
      _biometricEnabled = status.biometricEnabled;
      _failedAttempts = status.failedAttempts;
      _isLockedOut = status.isLockedOut;
      
      if (status.availableBiometrics.isNotEmpty) {
        if (status.availableBiometrics.contains(BiometricType.face)) {
          _biometricType = 'Face ID';
        } else if (status.availableBiometrics.contains(BiometricType.fingerprint)) {
          _biometricType = 'Touch ID';
        }
      }
    });
  }

  Future<void> _tryBiometricAuth() async {
    if (!_biometricEnabled) return;
    
    // Small delay to let the screen settle
    await Future.delayed(const Duration(milliseconds: 500));
    
    final result = await _pinAuthService.authenticateWithBiometric();
    if (result.success && mounted) {
      _navigateToMain();
    }
  }

  void _onPinChanged(String value) {
    setState(() {
      _errorMessage = null;
    });

    // Auto-submit when PIN is complete
    if (value.length >= 4 && value.length <= 6) {
      _validatePin();
    }
  }

  Future<void> _validatePin() async {
    final pin = _pinController.text;
    
    if (pin.length < 4 || pin.length > 6) {
      _showError('PIN must be 4-6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _pinAuthService.validatePin(pin);
      
      if (result.success) {
        _navigateToMain();
      } else {
        _showError(result.message ?? 'Invalid PIN');
        _pinController.clear();
        _shakeController.forward().then((_) {
          _shakeController.reverse();
        });
        
        // Reload status to get updated failed attempts
        await _loadAuthStatus();
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    // Clear error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _tryBiometricAuthManual() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _pinAuthService.authenticateWithBiometric();
      
      if (result.success) {
        _navigateToMain();
      } else {
        _showError(result.message ?? 'Biometric authentication failed');
      }
    } catch (e) {
      _showError('Biometric authentication error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text(
          'Resetting your PIN will permanently delete all your journal entries and app data. This action cannot be undone.\n\nAre you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetPin();
    }
  }

  Future<void> _resetPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _pinAuthService.resetPin();
      
      if (result.success && mounted) {
        // Navigate back to PIN setup
        Navigator.of(context).pushReplacementNamed('/pin-setup');
      } else {
        _showError(result.message ?? 'Failed to reset PIN');
      }
    } catch (e) {
      _showError('Reset error: $e');
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
              const SizedBox(height: 60),
              
              // App Logo/Icon Area
              Container(
                height: 80,
                width: 80,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.book,
                  size: 40,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              
              // Header
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Enter your PIN to access your journal',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // PIN Input Section
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _pinController,
                              focusNode: _pinFocusNode,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 6,
                              enabled: !_isLoading && !_isLockedOut,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: _onPinChanged,
                              onSubmitted: (_) => _validatePin(),
                              decoration: InputDecoration(
                                hintText: _isLockedOut ? 'Account locked' : 'Enter PIN',
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
                            
                            // Failed attempts indicator
                            if (_failedAttempts > 0) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Failed attempts: $_failedAttempts/${PinAuthService.maxFailedAttempts}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Biometric Authentication Button
              if (_biometricEnabled && !_isLockedOut) ...[
                const SizedBox(height: 24),
                
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _tryBiometricAuthManual,
                  icon: Icon(
                    _biometricType == 'Face ID' 
                        ? Icons.face 
                        : Icons.fingerprint,
                  ),
                  label: Text('Use $_biometricType'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
              
              // Loading Indicator
              if (_isLoading) ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 24),
              ],
              
              // Reset PIN Button
              TextButton(
                onPressed: _isLoading ? null : _showResetDialog,
                child: Text(
                  'Forgot PIN? Reset App',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
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
                        'Your data is encrypted and stored securely on your device.',
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