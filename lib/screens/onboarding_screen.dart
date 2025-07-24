import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_slide_widget.dart';
import '../widgets/quick_setup_widget.dart';
import '../widgets/app_background.dart';
import '../services/theme_service.dart';
import '../services/settings_service.dart';
// PIN auth service import removed - using biometrics-only authentication
import '../services/navigation_service.dart';
import '../services/navigation_flow_controller.dart';

/// Main onboarding screen with slide flow and navigation
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late OnboardingController _controller;
  late PageController _pageController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
  }

  void _setupControllers() {
    // Create services directly instead of using Provider to avoid dependency issues
    final themeService = ThemeService();
    final settingsService = SettingsService();
    // PIN auth service removed - using biometrics-only authentication

    _controller = OnboardingController(
      themeService: themeService,
      settingsService: settingsService,
      // PIN auth service parameter removed - using biometrics-only authentication
    );

    _pageController = PageController();
    
    // Listen to controller changes to sync page view
    _controller.addListener(_onControllerChanged);
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _backgroundController.repeat();
  }

  void _onControllerChanged() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _controller.currentSlideIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _pageController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            final flowController = NavigationFlowController.instance;
            final canPop = await flowController.handleBackButton('/onboarding');
            if (canPop && context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          body: AppBackground(
            child: SafeArea(
              child: Consumer<OnboardingController>(
                builder: (context, controller, child) {
                  return Column(
                    children: [
                      // Header with progress and skip button
                      _buildHeader(context, controller),
                      
                      // Main content area
                      Expanded(
                        child: _buildPageView(context, controller),
                      ),
                      
                      // Progress indicator
                      _buildProgressIndicator(context, controller),
                      
                      SizedBox(height: DesignTokens.spaceL),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OnboardingController controller) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Progress text
          Text(
            '${controller.currentSlideIndex + 1} of ${controller.totalSlides}',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getTextTertiary(context),
            ),
          ),
          
          // Next button (only show if not on last slide)
          if (!controller.isLastSlide)
            TextButton(
              onPressed: () => _handleNext(controller),
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.getPrimaryColor(context),
                padding: EdgeInsets.all(DesignTokens.spaceM),
              ),
              child: Text(
                'Next',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.getPrimaryColor(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageView(BuildContext context, OnboardingController controller) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        controller.goToSlide(index);
      },
      itemCount: controller.slides.length,
      itemBuilder: (context, index) {
        final slide = controller.slides[index];
        final isActive = index == controller.currentSlideIndex;
        
        return OnboardingSlideWidget(
          slide: slide,
          isActive: isActive,
          onNext: () => _handleNext(controller),
          onSkip: () => _handleSkip(controller),
          quickSetupWidget: slide.hasQuickSetup
              ? QuickSetupWidget(
                  controller: controller,
                  onConfigChanged: () {
                    // Trigger rebuild to apply theme changes immediately
                    _triggerConfigChangeAnimation();
                    // Force rebuild of the entire widget tree to apply theme changes
                    if (mounted) {
                      setState(() {});
                    }
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildProgressIndicator(BuildContext context, OnboardingController controller) {
    return OnboardingProgressIndicator(
      currentIndex: controller.currentSlideIndex,
      totalSlides: controller.totalSlides,
    );
  }

  void _handleNext(OnboardingController controller) async {
    // Track slide completion
    controller.onSlideCompleted(controller.currentSlide);
    
    if (controller.isLastSlide) {
      await _completeOnboarding(controller);
    } else {
      controller.nextSlide();
    }
  }

  void _handleSkip(OnboardingController controller) async {
    controller.onOnboardingSkipped();
    
    // Navigate directly to profile setup instead of just skipping to end
    final flowController = NavigationFlowController.instance;
    if (flowController.isFlowActive) {
      // Skip directly to profile setup in the flow
      if (mounted) {
        await flowController.skipToProfileSetup(context);
      }
    } else {
      // Fallback: navigate to profile setup directly
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/profile-setup');
      }
    }
  }

  Future<void> _completeOnboarding(OnboardingController controller) async {
    try {
      // Show loading state
      if (controller.isLoading) return;
      
      await controller.completeOnboarding();
      
      // Update navigation flow controller state
      final flowController = NavigationFlowController.instance;
      if (flowController.isFlowActive) {
        flowController.updateStateFromRoute('/onboarding');
        // Advance to next state (profile setup)
        if (mounted) {
          await flowController.advanceToNextState(context);
        }
      } else {
        // Navigate back to AuthWrapper to check profile setup (original behavior)
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'Failed to complete onboarding. Please try again.');
      }
    }
  }

  void _triggerConfigChangeAnimation() {
    // Add subtle animation feedback when configuration changes
    // This could be a small scale animation or color change
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Setup Error',
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
        ),
        content: Text(
          message,
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.getPrimaryColor(context),
              ),
            ),
          ),
        ],
        backgroundColor: DesignTokens.getBackgroundSecondary(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
      ),
    );
  }
}

/// Onboarding entry point that checks completion status
class OnboardingEntryScreen extends StatelessWidget {
  const OnboardingEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use SettingsService for consistent onboarding state management
    final settingsService = SettingsService();
    
    return FutureBuilder<bool>(
      future: settingsService.initialize().then((_) => settingsService.hasCompletedOnboarding()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context);
        }

        final hasCompleted = snapshot.data ?? false;
        
        if (hasCompleted) {
          // Navigate to main app
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Create navigation service directly instead of using Provider
            final navigationService = NavigationService();
            navigationService.navigateToMainApp();
          });
          return _buildLoadingScreen(context);
        }

        return const OnboardingScreen();
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: DesignTokens.getPrimaryGradient(context),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: DesignTokens.spaceXL),
              Text(
                'Spiral Journal',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeXXXL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getPrimaryColor(context),
                ),
              ),
              SizedBox(height: DesignTokens.spaceM),
              Text(
                'Loading your personal growth journey...',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug screen for testing onboarding
class OnboardingDebugScreen extends StatelessWidget {
  const OnboardingDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding Debug'),
        backgroundColor: DesignTokens.getBackgroundPrimary(context),
      ),
      body: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await OnboardingController.resetOnboarding();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                  );
                }
              },
              child: const Text('Reset & Show Onboarding'),
            ),
            SizedBox(height: DesignTokens.spaceM),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              },
              child: const Text('Show Onboarding (Force)'),
            ),
            SizedBox(height: DesignTokens.spaceM),
            FutureBuilder<bool>(
              future: () async {
                // Use SettingsService for consistent onboarding state management
                final settingsService = SettingsService();
                await settingsService.initialize();
                return settingsService.hasCompletedOnboarding();
              }(),
              builder: (context, snapshot) {
                final completed = snapshot.data ?? false;
                return Text(
                  'Onboarding Status: ${completed ? 'Completed' : 'Not Completed'}',
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
