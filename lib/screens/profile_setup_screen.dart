import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../screens/main_screen.dart';
import '../widgets/app_background.dart';
import '../services/navigation_flow_controller.dart';

/// Profile setup screen for TestFlight version
/// Collects basic user information: first name and birthday
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _profileService = ProfileService();
  
  DateTime? _selectedBirthday;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    super.dispose();
  }

  /// Show date picker for birthday selection
  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthday ?? DateTime(now.year - 25, now.month, now.day);
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 120), // 120 years ago
      lastDate: DateTime(now.year - 13), // Must be at least 13 years old
      helpText: 'Select your birthday',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.getPrimaryColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthday = pickedDate;
        _errorMessage = null; // Clear any previous errors
      });
    }
  }

  /// Validate and save profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBirthday == null) {
      setState(() {
        _errorMessage = 'Please select your birthday';
      });
      return;
    }

    final firstName = _firstNameController.text.trim();

    // Validate profile data
    if (!_profileService.validateProfile(
      firstName: firstName,
      birthday: _selectedBirthday!,
    )) {
      setState(() {
        _errorMessage = 'Please check your information and try again';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create and save profile
      final profile = UserProfile.create(
        firstName: firstName,
        birthday: _selectedBirthday!,
      );

      final success = await _profileService.saveProfile(profile);

      if (success) {
        // Mark onboarding as completed when profile is saved
        final settingsService = SettingsService();
        await settingsService.initialize();
        await settingsService.setOnboardingCompleted(true);
        
        // Provide haptic feedback
        HapticFeedback.lightImpact();
        
        // Update navigation flow controller and navigate
        final flowController = NavigationFlowController.instance;
        if (flowController.isFlowActive) {
          flowController.updateStateFromRoute('/profile-setup');
          // Advance to next state (main screen)
          if (mounted) {
            await flowController.advanceToNextState(context);
          }
        } else {
          // Navigate to main screen (original behavior)
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save profile. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Format birthday for display
  String _formatBirthday(DateTime birthday) {
    return '${birthday.month}/${birthday.day}/${birthday.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final flowController = NavigationFlowController.instance;
          final canPop = await flowController.handleBackButton('/profile-setup');
          if (canPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const SizedBox(height: AppConstants.extraLargePadding),
                
                    // Welcome header
                    Text(
                  'Welcome to Spiral Journal',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    Text(
                  'Let\'s get started with some basic information',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                    const SizedBox(height: AppConstants.extraLargePadding),
                    
                    // First name input
                    Text(
                  'First Name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your first name',
                    hintStyle: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide(
                        color: AppTheme.getBorderColor(context),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide(
                        color: AppTheme.getBorderColor(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      borderSide: BorderSide(
                        color: AppTheme.getPrimaryColor(context),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.getBackgroundSecondary(context),
                  ),
                  style: TextStyle(
                    color: AppTheme.getTextPrimary(context),
                    fontSize: 16,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                
                    const SizedBox(height: AppConstants.largePadding),
                    
                    // Birthday selection
                    Text(
                  'Birthday',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    InkWell(
                  onTap: _selectBirthday,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.getBorderColor(context),
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      color: AppTheme.getBackgroundSecondary(context),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.getPrimaryColor(context),
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: Text(
                            _selectedBirthday != null
                                ? _formatBirthday(_selectedBirthday!)
                                : 'Select your birthday',
                            style: TextStyle(
                              color: _selectedBirthday != null
                                  ? AppTheme.getTextPrimary(context)
                                  : AppTheme.getTextSecondary(context),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ],
                    ),
                  ),
                ),
                
                    const Spacer(),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.smallPadding),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                    ],
                    
                    // Get started button
                    ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.getPrimaryColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.defaultPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    elevation: 0,
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
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                    const SizedBox(height: AppConstants.largePadding),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
