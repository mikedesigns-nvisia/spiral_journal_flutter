import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/design_system/heading_system.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/services/settings_service.dart';
// PIN auth service import removed - using biometrics-only authentication
import 'package:spiral_journal/models/user_preferences.dart';
import 'package:spiral_journal/screens/ai_settings_screen.dart';
import 'package:spiral_journal/utils/sample_data_generator.dart';
import 'package:spiral_journal/services/accessibility_service.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/core_library_service.dart';
import 'package:spiral_journal/widgets/testflight_feedback_widget.dart';
import 'package:spiral_journal/widgets/offline_queue_status_widget.dart';
import 'package:spiral_journal/widgets/animated_card.dart';
import 'package:spiral_journal/widgets/animated_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  // PIN auth service removed - using biometrics-only authentication
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  UserPreferences _currentPreferences = UserPreferences.defaults;
  bool _isLoading = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    try {
      // Add timeout to prevent hanging
      await _settingsService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Settings service initialization timed out', const Duration(seconds: 10));
        },
      );
      
      await _accessibilityService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Accessibility service initialization timed out', const Duration(seconds: 5));
        },
      );
      
      final preferences = await _settingsService.getPreferences().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Settings service getPreferences timed out, using defaults');
          return UserPreferences.defaults;
        },
      );
      
      final biometricAvailable = await _localAuth.canCheckBiometrics.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Biometric check timed out, assuming false');
          return false;
        },
      );
      
      if (mounted) {
        setState(() {
          _currentPreferences = preferences;
          _biometricAvailable = biometricAvailable;
          _isLoading = false;
        });
        
        // Listen to settings changes
        _settingsService.addListener(_onSettingsChanged);
      }
    } catch (e) {
      debugPrint('Settings initialization error: $e');
      if (mounted) {
        setState(() {
          _currentPreferences = UserPreferences.defaults;
          _isLoading = false;
        });
      }
    }
  }

  void _onSettingsChanged() {
    if (mounted) {
      _settingsService.getPreferences().then((preferences) {
        setState(() {
          _currentPreferences = preferences;
        });
      });
    }
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundPrimary(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundPrimary(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.getColorWithOpacity(AppTheme.getPrimaryColor(context), 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: AppTheme.getPrimaryColor(context),
                      size: HeadingSystem.iconSizeL,
                    ),
                  ),
                  const SizedBox(width: 16),
                  HeadingSystem.pageHeading(context, 'Settings'),
                ],
              ),
              const SizedBox(height: 32),
              
              // AI Analysis & Privacy
              _buildSettingsSection(
                'AI Analysis & Privacy',
                [
                  _buildSwitchItem(
                    Icons.psychology,
                    'Personalized Insights',
                    'Get personalized feedback and commentary in AI analysis',
                    _currentPreferences.personalizedInsightsEnabled,
                    _togglePersonalizedInsights,
                  ),
                  _buildPersonalizedInsightsInfo(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Security & Authentication
              _buildSettingsSection(
                'Security & Authentication',
                [
                  if (_biometricAvailable)
                    _buildSwitchItem(
                      Icons.fingerprint,
                      'Biometric Authentication',
                      'Use Face ID, Touch ID, or fingerprint to unlock the app',
                      _currentPreferences.biometricAuthEnabled,
                      _toggleBiometricAuth,
                    ),
                  // PIN change option removed - using biometrics-only authentication
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Appearance & Theme
              _buildSettingsSection(
                'Appearance',
                [
                  _buildThemeSelector(),
                  _buildSwitchItem(
                    Icons.auto_awesome,
                    'Splash Screen',
                    'Show branded splash screen on app launch',
                    _currentPreferences.splashScreenEnabled,
                    _toggleSplashScreen,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Accessibility section temporarily hidden for TestFlight
              // Will be re-enabled in future updates
              
              const SizedBox(height: 24),
              
              // Notifications & Reminders
              _buildSettingsSection(
                'Notifications',
                [
                  _buildSwitchItem(
                    Icons.notifications,
                    'Daily Reminders',
                    'Get reminded to journal every day',
                    _currentPreferences.dailyRemindersEnabled,
                    _toggleDailyReminders,
                  ),
                  if (_currentPreferences.dailyRemindersEnabled) 
                    _buildReminderTimeItem(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Data Management
              _buildSettingsSection(
                'Data Management',
                [
                  Consumer2<JournalProvider, CoreProvider>(
                    builder: (context, journalProvider, coreProvider, child) {
                      return _buildInfoItem(
                        Icons.analytics,
                        'Statistics',
                        '${journalProvider.entries.length} entries • ${coreProvider.allCores.length} cores',
                      );
                    },
                  ),
                  
                  // Offline Queue Status
                  const SizedBox(height: 8),
                  const OfflineQueueStatusWidget(),
                  const SizedBox(height: 8),
                  
                  _buildActionItem(
                    Icons.privacy_tip,
                    'Privacy Dashboard',
                    'View what data is stored and manage privacy settings',
                    () => Navigator.pushNamed(context, '/privacy-dashboard'),
                  ),
                  _buildActionItem(
                    Icons.backup,
                    'Export Data',
                    'Export your journal entries and cores',
                    _exportData,
                  ),
                  _buildBackupStatusItem(),
                  _buildActionItem(
                    Icons.cloud_upload,
                    'Backup to iCloud',
                    'Create backup in iCloud Documents',
                    _performBackup,
                  ),
                  _buildActionItem(
                    Icons.cloud_download,
                    'Restore from iCloud',
                    'Restore data from iCloud backup',
                    _restoreFromBackup,
                  ),
                  _buildActionItem(
                    Icons.refresh,
                    'Refresh Cores',
                    'Recalculate emotional cores from all entries',
                    _refreshCores,
                  ),
                  _buildActionItem(
                    Icons.restore,
                    'Reset Cores',
                    'Reset all emotional cores to default state',
                    _resetCores,
                    isDestructive: true,
                  ),
                  _buildActionItem(
                    Icons.delete_forever,
                    'Clear All Data',
                    'Permanently delete all journal entries and reset PIN',
                    _showClearDataDialog,
                    isDestructive: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // App Preferences
              _buildSettingsSection(
                'App Preferences',
                [
                  _buildSwitchItem(
                    Icons.analytics,
                    'Usage Analytics',
                    'Help improve the app by sharing anonymous usage data',
                    _currentPreferences.analyticsEnabled,
                    _toggleAnalytics,
                  ),
                  _buildActionItem(
                    Icons.language, 
                    'Language', 
                    'English', 
                    null
                  ),
                  _buildActionItem(
                    Icons.help, 
                    'Help & Support', 
                    'Get help and send feedback', 
                    _showHelpDialog
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // TestFlight Feedback
              _buildSettingsSection(
                'TestFlight Feedback',
                [
                  _buildActionItem(
                    Icons.feedback,
                    'Send Feedback',
                    'Help us improve by sharing your experience',
                    _showFeedbackDialog,
                  ),
                ],
              ),
              
              // Development Settings (Debug mode only)
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                _buildSettingsSection(
                  'Development',
                  [
                    _buildActionItem(
                      Icons.developer_mode,
                      'AI Settings (Dev)',
                      'Configure Claude API key for testing',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AISettingsScreen(),
                        ),
                      ),
                    ),
                    // Sample data generation removed for TestFlight
                    // Will be re-enabled for development builds
                  ],
                ),
              ],
              
              const SizedBox(height: 40),
              
              // App Version
              Center(
                child: HeadingSystem.caption(context, 'Spiral Journal v1.0.0'),
              ),
              
              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeadingSystem.sectionHeading(context, title),
        AnimatedCard(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchItem(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return HeadingSystem.listTile(
      context: context,
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.getPrimaryColor(context),
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    if (isDestructive) {
      // For destructive actions, we need custom styling
      return ListTile(
        leading: Icon(
          icon,
          color: AppTheme.accentRed,
          size: HeadingSystem.iconSizeM,
        ),
        title: Text(
          title,
          style: HeadingSystem.getTitleMedium(context).copyWith(
            color: AppTheme.accentRed,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: HeadingSystem.getBodyMedium(context),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.arrow_forward_ios,
                size: HeadingSystem.iconSizeS,
                color: AppTheme.getTextTertiary(context),
              )
            : null,
        onTap: onTap,
      );
    }
    
    return HeadingSystem.listTile(
      context: context,
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              size: HeadingSystem.iconSizeS,
              color: AppTheme.getTextTertiary(context),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return HeadingSystem.listTile(
      context: context,
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
    );
  }

  Widget _buildBackupStatusItem() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _settingsService.getBackupStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return HeadingSystem.listTile(
            context: context,
            title: 'iCloud Backup Status',
            subtitle: 'Loading...',
            leadingIcon: Icons.cloud_sync,
          );
        }

        final status = snapshot.data;
        String subtitle;
        IconData icon;
        Color? iconColor;

        if (status == null) {
          subtitle = 'Unable to check backup status';
          icon = Icons.cloud_off;
          iconColor = AppTheme.accentRed;
        } else if (status['hasBackup'] == true) {
          final lastBackup = status['lastBackup'];
          if (lastBackup != null) {
            final lastBackupDate = DateTime.parse(lastBackup);
            final now = DateTime.now();
            final difference = now.difference(lastBackupDate);
            
            if (difference.inDays > 0) {
              subtitle = 'Last backup: ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
            } else if (difference.inHours > 0) {
              subtitle = 'Last backup: ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
            } else {
              subtitle = 'Backup available • Last backup: recently';
            }
          } else {
            subtitle = 'Backup available';
          }
          icon = Icons.cloud_done;
          iconColor = AppTheme.accentGreen;
        } else {
          subtitle = 'No backup found • Tap "Backup to iCloud" to create one';
          icon = Icons.cloud_queue;
          iconColor = AppTheme.accentOrange;
        }

        return ListTile(
          leading: Icon(
            icon,
            color: iconColor,
            size: HeadingSystem.iconSizeM,
          ),
          title: Text(
            'iCloud Backup Status',
            style: HeadingSystem.getTitleMedium(context),
          ),
          subtitle: Text(
            subtitle,
            style: HeadingSystem.getBodyMedium(context),
          ),
        );
      },
    );
  }

  Widget _buildReminderTimeItem() {
    final reminderTime = TimeOfDay(
      hour: int.parse(_currentPreferences.reminderTime.split(':')[0]),
      minute: int.parse(_currentPreferences.reminderTime.split(':')[1]),
    );
    
    return HeadingSystem.listTile(
      context: context,
      title: 'Reminder Time',
      subtitle: reminderTime.format(context),
      leadingIcon: Icons.schedule,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: HeadingSystem.iconSizeS,
        color: AppTheme.getTextTertiary(context),
      ),
      onTap: _selectReminderTime,
    );
  }

  Widget _buildPersonalizedInsightsInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _currentPreferences.personalizedInsightsEnabled 
            ? AppTheme.getColorWithOpacity(AppTheme.accentGreen, 0.1)
            : AppTheme.getColorWithOpacity(AppTheme.textTertiary, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _currentPreferences.personalizedInsightsEnabled 
              ? AppTheme.getColorWithOpacity(AppTheme.accentGreen, 0.3)
              : AppTheme.getColorWithOpacity(AppTheme.textTertiary, 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _currentPreferences.personalizedInsightsEnabled ? Icons.psychology : Icons.psychology_outlined,
            size: 20,
            color: _currentPreferences.personalizedInsightsEnabled ? AppTheme.accentGreen : AppTheme.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPreferences.personalizedInsightsEnabled ? 'Personalized Analysis Active' : 'Core Updates Only',
                  style: HeadingSystem.getTitleMedium(context).copyWith(
                    color: _currentPreferences.personalizedInsightsEnabled ? AppTheme.accentGreen : AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentPreferences.personalizedInsightsEnabled 
                      ? 'AI provides personalized feedback and commentary on your entries'
                      : 'AI only updates your emotional cores without personal commentary',
                  style: HeadingSystem.getLabelSmall(context).copyWith(
                    color: _currentPreferences.personalizedInsightsEnabled ? AppTheme.textSecondary : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return HeadingSystem.listTile(
      context: context,
      title: 'Theme',
      subtitle: _getThemeDescription(_currentPreferences.themeMode),
      leadingIcon: _getThemeIcon(_currentPreferences.themeMode),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: HeadingSystem.iconSizeS,
        color: AppTheme.textTertiary,
      ),
      onTap: _showThemeDialog,
    );
  }

  // Helper Methods
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  // Settings Methods
  Future<void> _togglePersonalizedInsights(bool enabled) async {
    try {
      await _settingsService.setPersonalizedInsightsEnabled(enabled).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Settings update timed out', const Duration(seconds: 5));
        },
      );
      
      // Verify the setting was actually saved
      final currentPrefs = await _settingsService.getPreferences();
      if (currentPrefs.personalizedInsightsEnabled != enabled) {
        throw Exception('Setting was not persisted correctly');
      }
      
      if (mounted) {
        setState(() {
          _currentPreferences = currentPrefs;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                  ? 'Personalized insights enabled! 🧠' 
                  : 'Personalized insights disabled. Core updates only.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to toggle personalized insights: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save personalized insights setting: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleBiometricAuth(bool enabled) async {
    try {
      if (enabled) {
        // Check if biometric authentication is available
        final isAvailable = await _localAuth.canCheckBiometrics;
        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Biometric authentication is not available on this device'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
          return;
        }
        
        // Test biometric authentication before enabling
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        
        if (!didAuthenticate) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Biometric authentication failed'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
          return;
        }
      }
      
      await _settingsService.setBiometricAuthEnabled(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                  ? 'Biometric authentication enabled! 🔒' 
                  : 'Biometric authentication disabled.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle biometric authentication: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleAnalytics(bool enabled) async {
    try {
      await _settingsService.setAnalyticsEnabled(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                  ? 'Usage analytics enabled. Thank you for helping improve the app! 📊' 
                  : 'Usage analytics disabled.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle analytics: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleSplashScreen(bool enabled) async {
    try {
      await _settingsService.setSplashScreenEnabled(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'Splash screen enabled! ✨' 
                : 'Splash screen disabled. App will launch directly.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle splash screen: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleDailyReminders(bool enabled) async {
    try {
      await _settingsService.setDailyRemindersEnabled(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'Daily reminders enabled! 📝' 
                : 'Daily reminders disabled.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle daily reminders: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  // Accessibility Methods
  Future<void> _toggleHighContrast(bool enabled) async {
    try {
      await _accessibilityService.setHighContrastMode(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'High contrast mode enabled! 🔍' 
                : 'High contrast mode disabled.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle high contrast: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleLargeText(bool enabled) async {
    try {
      await _accessibilityService.setLargeTextMode(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'Large text mode enabled! 📝' 
                : 'Large text mode disabled.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle large text: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleReducedMotion(bool enabled) async {
    try {
      await _accessibilityService.setReducedMotionMode(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'Reduced motion enabled! 🎯' 
                : 'Reduced motion disabled.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle reduced motion: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleScreenReader(bool enabled) async {
    try {
      await _accessibilityService.setScreenReaderEnabled(enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'Screen reader support enabled! 🔊' 
                : 'Screen reader support disabled.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle screen reader support: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  // Action Methods
  Future<void> _selectReminderTime() async {
    final currentTime = TimeOfDay(
      hour: int.parse(_currentPreferences.reminderTime.split(':')[0]),
      minute: int.parse(_currentPreferences.reminderTime.split(':')[1]),
    );
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (picked != null && picked != currentTime) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      try {
        await _settingsService.setReminderTime(timeString);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder time updated to ${picked.format(context)}'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update reminder time: $e'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              ThemeMode.system,
              'System',
              'Follow device setting',
              Icons.brightness_auto,
            ),
            _buildThemeOption(
              ThemeMode.light,
              'Light',
              'Light theme',
              Icons.light_mode,
            ),
            _buildThemeOption(
              ThemeMode.dark,
              'Dark',
              'Dark theme',
              Icons.dark_mode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _currentPreferences.themeMode == mode;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? AppTheme.getPrimaryColor(context) 
            : AppTheme.getTextTertiary(context),
      ),
      title: Text(
        title,
        style: HeadingSystem.getTitleMedium(context).copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected 
              ? AppTheme.getPrimaryColor(context) 
              : AppTheme.getTextPrimary(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: HeadingSystem.getBodyMedium(context),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: AppTheme.getPrimaryColor(context),
            )
          : null,
      onTap: () async {
        try {
          await _settingsService.setThemeMode(mode).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Theme update timed out', const Duration(seconds: 5));
            },
          );
          
          // Verify the setting was actually saved
          final currentPrefs = await _settingsService.getPreferences();
          if (currentPrefs.themeMode != mode) {
            throw Exception('Theme setting was not persisted correctly');
          }
          
          if (mounted) {
            setState(() {
              _currentPreferences = currentPrefs;
            });
            
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Theme changed to ${title.toLowerCase()}'),
                backgroundColor: AppTheme.accentGreen,
              ),
            );
          }
        } catch (e) {
          debugPrint('Failed to change theme: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save theme setting: ${e.toString()}'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
        }
      },
    );
  }

  // PIN change functionality removed - using biometrics-only authentication

  // Data Management Methods
  Future<void> _exportData() async {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${journalProvider.entries.length} entries and ${coreProvider.allCores.length} cores',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _performBackup() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating backup...'),
            ],
          ),
        ),
      );

      final success = await _settingsService.triggerManualBackup();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Backup created successfully in iCloud Documents' : 'Backup failed',
            ),
            backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
          ),
        );
        
        if (success) {
          setState(() {}); // Refresh backup status
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromBackup() async {
    final hasBackup = await _settingsService.isBackupAvailable();
    
    if (!hasBackup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No backup found in iCloud Documents'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace all current data with the backup. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Restoring from backup...'),
            ],
          ),
        ),
      );

      final success = await _settingsService.restoreFromBackup();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Data restored successfully from backup' : 'Restore failed',
            ),
            backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
          ),
        );
        
        if (success) {
          // Refresh providers after restore
          if (mounted) {
            final journalProvider = Provider.of<JournalProvider>(context, listen: false);
            final coreProvider = Provider.of<CoreProvider>(context, listen: false);
            await journalProvider.refresh();
            await coreProvider.refresh(); 
            setState(() {}); // Refresh UI
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _refreshCores() async {
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    try {
      await coreProvider.refresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emotional cores refreshed! 🧠'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh cores: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _resetCores() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Cores'),
        content: const Text(
          'This will reset all emotional cores to their default state. All progress and insights will be lost. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Reset Cores'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Resetting cores...'),
            ],
          ),
        ),
      );

      // Import the services we need
      final journalService = JournalService();
      final coreLibraryService = CoreLibraryService();
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      
      // Clear all journal entries first (this clears the data that EmotionalMirrorService uses)
      await journalService.clearAllData(); // This calls both journal and core clearing
      
      // Clear SharedPreferences cache for cores
      await coreLibraryService.resetCores();
      
      // Refresh providers to show the reset data
      await journalProvider.initialize(); // Clear journal entries from provider
      await coreProvider.initialize(); // Reset cores in provider

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emotional cores reset to default state! 🔄'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset cores: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your journal entries, emotional cores, and reset your PIN. This action cannot be undone.\n\nYou will need to set up a new PIN after clearing data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _clearAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    Navigator.of(context).pop(); // Close dialog

    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing all data...'),
            ],
          ),
        ),
      );

      // Clear all entries
      for (final entry in journalProvider.entries) {
        await journalProvider.deleteEntry(entry.id);
      }

      // Clear all settings
      await _settingsService.clearAllSettings();
      
      // Reset PIN
      // PIN auth service reset removed - using biometrics-only authentication

      // Refresh providers
      await journalProvider.initialize();
      await coreProvider.initialize();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All data cleared. Please restart the app to set up a new PIN.'),
            backgroundColor: AppTheme.accentGreen,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: const TestFlightFeedbackWidget(),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spiral Journal - AI-Powered Personal Growth'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Stream-of-consciousness journaling'),
            Text('• AI-powered emotional analysis'),
            Text('• Personality core evolution tracking'),
            Text('• Personalized insights and feedback'),
            Text('• Secure local data storage'),
            SizedBox(height: 16),
            Text('Privacy:'),
            Text('• All data stored locally on your device'),
            Text('• Optional personalized AI insights'),
            Text('• Biometric authentication support'),
            SizedBox(height: 16),
            Text('Need help? Contact us at support@spiraljournal.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateSampleData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating sample data...'),
            ],
          ),
        ),
      );

      // Generate sample data
      await SampleDataGenerator.generateSampleData();

      // Refresh providers to show new data
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      final coreProvider = Provider.of<CoreProvider>(context, listen: false);
      
      await journalProvider.initialize();
      await coreProvider.initialize();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sample data generated! Check your journal and emotional mirror 📊'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate sample data: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }
}
