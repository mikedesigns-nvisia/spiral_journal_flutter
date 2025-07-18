import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spiral_journal/services/local_auth_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthService _authService = LocalAuthService();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isSetupMode = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  AuthStatus? _authStatus;
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check authentication status with timeout to prevent hanging
      final statusFuture = _authService.getAuthStatus()
          .timeout(const Duration(seconds: 5));
      final firstLaunchFuture = _authService.isFirstLaunch()
          .timeout(const Duration(seconds: 3));

      final results = await Future.wait([statusFuture, firstLaunchFuture]);
      final status = results[0] as AuthStatus;
      final isFirstLaunch = results[1] as bool;
      
      if (mounted) {
        setState(() {
          _authStatus = status;
          _isSetupMode = !status.isEnabled || isFirstLaunch;
        });
      }
    } catch (e) {
      // If status check fails, assume setup mode for safety
      if (mounted) {
        setState(() {
          _authStatus = AuthStatus(
            isEnabled: false,
            biometricAvailable: false,
            availableBiometrics: [],
            userId: null,
          );
          _isSetupMode = true;
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use a shorter timeout for better UX
      final result = await _authService.authenticate(
        biometricTimeout: const Duration(seconds: 20),
      );
      
      if (result.success) {
        _onAuthSuccess();
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Biometric authentication failed';
          _isLoading = false;
        });
        
        // Handle different failure types with appropriate fallbacks
        _handleBiometricFailure(result);
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Biometric authentication timed out';
        _isLoading = false;
      });
      _showTimeoutFallback();
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: ${e.toString()}';
        _isLoading = false;
      });
      _showGeneralFallback();
    }
  }

  void _handleBiometricFailure(AuthResult result) {
    switch (result.type) {
      case AuthResultType.biometricFailed:
        _showBiometricFailedFallback();
        break;
      case AuthResultType.timeout:
        _showTimeoutFallback();
        break;
      case AuthResultType.cancelled:
        _showCancelledFallback();
        break;
      case AuthResultType.unavailable:
        _showUnavailableFallback();
        break;
      case AuthResultType.lockedOut:
        _showLockedOutFallback();
        break;
      case AuthResultType.failed:
        _showGeneralFallback();
        break;
      default:
        _showGeneralFallback();
    }
  }

  void _showBiometricFailedFallback() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Biometric authentication failed. Try using your password.'),
        action: SnackBarAction(
          label: 'Use Password',
          onPressed: () {
            // Focus on password field
            _passwordFocusNode.requestFocus();
          },
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }

  void _showTimeoutFallback() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Authentication Timeout'),
          content: const Text(
            'Biometric authentication timed out. Would you like to try again or use your password?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Focus on password field
                _passwordFocusNode.requestFocus();
              },
              child: const Text('Use Password'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _authenticateWithBiometrics();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelledFallback() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Authentication was cancelled. Use your password to continue.'),
        action: SnackBarAction(
          label: 'Use Password',
          onPressed: () {
            _passwordFocusNode.requestFocus();
          },
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  void _showUnavailableFallback() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Biometric authentication is not available. Please use your password.'),
        action: SnackBarAction(
          label: 'Use Password',
          onPressed: () {
            _passwordFocusNode.requestFocus();
          },
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.grey.shade600,
      ),
    );
  }

  void _showLockedOutFallback() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Biometric Authentication Locked'),
          content: const Text(
            'Biometric authentication has been temporarily disabled due to too many failed attempts. '
            'Please use your password or wait before trying biometric authentication again.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _passwordFocusNode.requestFocus();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
              ),
              child: const Text('Use Password'),
            ),
          ],
        );
      },
    );
  }

  void _showGeneralFallback() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Authentication failed. Please try using your password.'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }



  Future<void> _authenticateWithPassword() async {
    // Check if we're in lockout period
    if (_isInLockout()) {
      final remainingTime = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
      setState(() {
        _errorMessage = 'Too many failed attempts. Try again in ${remainingTime}s';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_isSetupMode) {
      // Setup new password
      if (_passwordController.text.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters long';
          _isLoading = false;
        });
        return;
      }

      final success = await _authService.setupPasswordAuth(_passwordController.text);
      if (success) {
        await _authService.markFirstLaunchComplete();
        _resetFailedAttempts();
        _onAuthSuccess();
      } else {
        setState(() {
          _errorMessage = 'Failed to set up authentication';
          _isLoading = false;
        });
      }
    } else {
      // Authenticate with existing password
      final result = await _authService.authenticate(password: _passwordController.text);
      if (result.success) {
        _resetFailedAttempts();
        _onAuthSuccess();
      } else {
        _handleFailedAttempt();
        setState(() {
          _errorMessage = result.error ?? 'Authentication failed';
          _isLoading = false;
        });
      }
    }
  }

  bool _isInLockout() {
    if (_lockoutEndTime == null) return false;
    return DateTime.now().isBefore(_lockoutEndTime!);
  }

  void _handleFailedAttempt() {
    _failedAttempts++;
    
    if (_failedAttempts >= _maxFailedAttempts) {
      _lockoutEndTime = DateTime.now().add(const Duration(minutes: 5));
      setState(() {
        _errorMessage = 'Too many failed attempts. Please wait 5 minutes before trying again.';
      });
      
      // Start a timer to update the lockout message
      _startLockoutTimer();
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutEndTime = null;
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel(); // Cancel any existing timer
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (!_isInLockout()) {
        timer.cancel();
        _lockoutTimer = null;
        setState(() {
          _errorMessage = null;
        });
      } else {
        final remainingTime = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
        setState(() {
          _errorMessage = 'Too many failed attempts. Try again in ${remainingTime}s';
        });
      }
    });
  }

  void _onAuthSuccess() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  void _showEmergencyResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Authentication'),
          content: const Text(
            'This will permanently delete all authentication data and reset the app to first launch state. '
            'You will lose access to any encrypted data. Are you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performEmergencyReset();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performEmergencyReset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.emergencyReset();
      if (success) {
        // Reset local state
        _resetFailedAttempts();
        
        // Show success message and navigate to main
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication has been reset successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to reset authentication. Please restart the app.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Emergency reset failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authStatus == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              Icon(
                Icons.auto_stories_rounded,
                size: 80,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(height: 16),
              Text(
                'Spiral Journal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSetupMode 
                    ? 'Set up authentication to secure your journal'
                    : 'Authenticate to access your journal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Biometric Authentication Button
              if (_authStatus!.biometricAvailable && !_isSetupMode)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _authenticateWithBiometrics,
                        icon: Icon(_getBiometricIcon()),
                        label: Text('Use ${_authStatus!.biometricTypeString}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'or',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Password Input
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: _isSetupMode ? 'Create Password' : 'Password',
                  hintText: _isSetupMode ? 'Enter a secure password' : 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _authenticateWithPassword(),
              ),
              const SizedBox(height: 24),

              // Password Authentication Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWithPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_isSetupMode ? 'Set Up Authentication' : 'Authenticate'),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTheme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Emergency Reset and Skip Options
              const SizedBox(height: 24),
              
              if (_isSetupMode) 
                TextButton(
                  onPressed: () {
                    // Skip authentication for now
                    Navigator.of(context).pushReplacementNamed('/main');
                  },
                  child: Text(
                    'Skip for now',
                    style: AppTheme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else if (_failedAttempts >= _maxFailedAttempts - 1) ...[
                TextButton(
                  onPressed: _showEmergencyResetDialog,
                  child: Text(
                    'Reset Authentication',
                    style: AppTheme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this if you\'ve forgotten your password',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_authStatus!.hasFaceId) {
      return Icons.face;
    } else if (_authStatus!.hasTouchId) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }
}