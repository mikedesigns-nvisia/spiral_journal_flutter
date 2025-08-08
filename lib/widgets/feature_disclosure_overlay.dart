import 'package:flutter/material.dart';
import '../controllers/onboarding_controller.dart';

class FeatureDisclosureOverlay extends StatefulWidget {
  final OnboardingController controller;
  final String featureName;
  final String title;
  final String description;
  final Widget? customIcon;
  final VoidCallback? onDismiss;

  const FeatureDisclosureOverlay({
    super.key,
    required this.controller,
    required this.featureName,
    required this.title,
    required this.description,
    this.customIcon,
    this.onDismiss,
  });

  @override
  State<FeatureDisclosureOverlay> createState() => _FeatureDisclosureOverlayState();
}

class _FeatureDisclosureOverlayState extends State<FeatureDisclosureOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGotIt() async {
    // Animate out
    await _animationController.reverse();
    
    // Mark feature as shown
    await widget.controller.onFeatureDisclosureGotIt();
    
    // Call dismiss callback if provided
    widget.onDismiss?.call();
  }

  Future<void> _handleDismiss() async {
    // Animate out
    await _animationController.reverse();
    
    // Dismiss without marking as shown
    widget.controller.dismissFeatureDisclosure();
    
    // Call dismiss callback if provided
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return AnimatedOpacity(
          opacity: _opacityAnimation.value,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: Colors.black.withOpacity(0.5 * _opacityAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(32.0),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Feature icon
                      if (widget.customIcon != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: widget.customIcon!,
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 32.0,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      
                      // Title
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12.0),
                      
                      // Description
                      Text(
                        widget.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24.0),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: _handleDismiss,
                            child: Text(
                              'Later',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _handleGotIt,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text('Got it!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FeatureDisclosureManager extends StatelessWidget {
  final OnboardingController controller;
  final Widget child;
  final Map<String, FeatureConfig> featureConfigs;

  const FeatureDisclosureManager({
    super.key,
    required this.controller,
    required this.child,
    required this.featureConfigs,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: [
            child,
            if (controller.isShowingFeatureDisclosure &&
                controller.currentDisclosureFeature != null)
              _buildFeatureDisclosure(context),
          ],
        );
      },
    );
  }

  Widget _buildFeatureDisclosure(BuildContext context) {
    final featureName = controller.currentDisclosureFeature!;
    final config = featureConfigs[featureName] ?? 
        FeatureConfig(title: featureName, description: 'New feature available!');
    
    return FeatureDisclosureOverlay(
      controller: controller,
      featureName: featureName,
      title: config.title,
      description: config.description,
      customIcon: config.customIcon,
    );
  }
}

class FeatureConfig {
  final String title;
  final String description;
  final Widget? customIcon;

  const FeatureConfig({
    required this.title,
    required this.description,
    this.customIcon,
  });
}