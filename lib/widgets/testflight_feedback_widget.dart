import 'package:flutter/material.dart';
import 'package:spiral_journal/services/feedback_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/core/app_constants.dart';
import 'package:spiral_journal/services/analytics_service.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

/// TestFlight feedback widget for collecting user feedback
class TestFlightFeedbackWidget extends StatefulWidget {
  const TestFlightFeedbackWidget({super.key});

  @override
  State<TestFlightFeedbackWidget> createState() => _TestFlightFeedbackWidgetState();
}

class _TestFlightFeedbackWidgetState extends State<TestFlightFeedbackWidget> {
  final FeedbackService _feedbackService = FeedbackService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  String _selectedCategory = 'General';
  int _rating = 5;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  bool _includeDeviceInfo = true;
  Map<String, dynamic> _deviceData = {};

  final List<String> _categories = [
    'General',
    'Bug Report',
    'Feature Request',
    'Performance',
    'UI/UX',
    'Authentication',
    'Journal Writing',
    'AI Analysis',
    'Core Library',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceData = {
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Please enter your feedback');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare device info if user opted in
      final Map<String, dynamic> deviceInfo = _includeDeviceInfo ? _deviceData : {};
      
      // Log feedback submission start
      await _analyticsService.logTestFlightEvent('feedback_submission_started', extra: {
        'category': _selectedCategory,
        'rating': _rating,
        'has_email': _emailController.text.trim().isNotEmpty,
      });

      await _feedbackService.submitFeedback(
        category: _selectedCategory,
        feedback: _feedbackController.text.trim(),
        rating: _rating,
        userEmail: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        additionalData: {
          'app_version': '1.0.0',
          'build_number': '1',
          'platform': 'iOS',
          'feedback_length': _feedbackController.text.length,
          'device_info': deviceInfo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Log successful submission
      await _analyticsService.logTestFlightEvent('feedback_submission_completed', extra: {
        'category': _selectedCategory,
        'rating': _rating,
      });

      setState(() {
        _hasSubmitted = true;
        _isSubmitting = false;
      });

      _showSnackBar('Thank you for your feedback!');
      
      // Clear form
      _feedbackController.clear();
      _emailController.clear();
      _rating = 5;
      _selectedCategory = 'General';

    } catch (e) {
      // Log submission failure
      await _analyticsService.logError('feedback_submission_failed', 
          context: e.toString(), 
          stackTrace: StackTrace.current);
      
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar('Failed to submit feedback. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.getPrimaryColor(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted) {
      return _buildThankYouCard();
    }

    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.feedback_outlined,
                  color: AppTheme.getPrimaryColor(context),
                  size: 28,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'TestFlight Feedback',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Help us improve Spiral Journal by sharing your experience. Your feedback is invaluable for our development process.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Category Selection
            Text(
              'Category',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  
                  // Log category selection
                  _analyticsService.logTestFlightEvent('feedback_category_selected', extra: {
                    'category': value,
                  });
                }
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Rating
            Text(
              'Overall Rating',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                    
                    // Log rating selection
                    _analyticsService.logTestFlightEvent('feedback_rating_selected', extra: {
                      'rating': index + 1,
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppConstants.smallPadding),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: AppTheme.getPrimaryColor(context),
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Feedback Text
            Text(
              'Your Feedback',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us about your experience, bugs you found, or features you\'d like to see...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
                contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Email (Optional)
            Text(
              'Email (Optional)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'your.email@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
                contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Include Device Info
            Row(
              children: [
                Checkbox(
                  value: _includeDeviceInfo,
                  onChanged: (value) {
                    setState(() {
                      _includeDeviceInfo = value ?? true;
                    });
                  },
                  activeColor: AppTheme.getPrimaryColor(context),
                ),
                Expanded(
                  child: Text(
                    'Include device information to help us diagnose issues',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.defaultPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Center(
              child: TextButton(
                onPressed: () {
                  // Log help center tap
                  _analyticsService.logTestFlightEvent('help_center_tapped');
                  
                  // Show help dialog
                  showDialog(
                    context: context,
                    builder: (context) => _buildHelpDialog(context),
                  );
                },
                child: Text(
                  'Need help with something specific?',
                  style: TextStyle(
                    color: AppTheme.getPrimaryColor(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThankYouCard() {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.getPrimaryColor(context),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Thank You!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Your feedback has been submitted and will help us improve Spiral Journal. We appreciate your time and insights!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _hasSubmitted = false;
                    });
                    
                    // Log additional feedback request
                    _analyticsService.logTestFlightEvent('additional_feedback_requested');
                  },
                  child: Text(
                    'Submit More Feedback',
                    style: TextStyle(
                      color: AppTheme.getPrimaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    
                    // Log feedback completion
                    _analyticsService.logTestFlightEvent('feedback_flow_completed');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.getPrimaryColor(context)),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppTheme.getPrimaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelpDialog(BuildContext context) {
    return AlertDialog(
      title: Text(
        'TestFlight Help',
        style: TextStyle(
          color: AppTheme.getTextPrimary(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How to provide effective feedback:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _buildHelpItem(
              context,
              '1. Be specific about what you experienced',
              'Instead of "app crashed", try "app crashed when saving a journal entry with emoji characters"',
            ),
            _buildHelpItem(
              context,
              '2. Include steps to reproduce issues',
              'List the exact steps that led to any problems you encountered',
            ),
            _buildHelpItem(
              context,
              '3. Mention your device model and iOS version',
              'Different devices may experience different issues',
            ),
            _buildHelpItem(
              context,
              '4. Suggest improvements',
              'We value your ideas on how to make the app better!',
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'You can also take screenshots while using the app and annotate them using TestFlight\'s built-in feedback tool.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            
            // Log help dialog closed
            _analyticsService.logTestFlightEvent('help_dialog_closed');
          },
          child: Text(
            'Got it',
            style: TextStyle(
              color: AppTheme.getPrimaryColor(context),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHelpItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}