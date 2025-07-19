import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import '../models/onboarding_slide.dart';
import '../widgets/accessible_widget.dart';

/// Individual onboarding slide widget with animations and accessibility support
class OnboardingSlideWidget extends StatefulWidget {
  final OnboardingSlide slide;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final bool isActive;
  final Widget? quickSetupWidget;

  const OnboardingSlideWidget({
    super.key,
    required this.slide,
    this.onNext,
    this.onSkip,
    this.isActive = true,
    this.quickSetupWidget,
  });

  @override
  State<OnboardingSlideWidget> createState() => _OnboardingSlideWidgetState();
}

class _OnboardingSlideWidgetState extends State<OnboardingSlideWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void didUpdateWidget(OnboardingSlideWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleWidget(
      child: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildSlideContent(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlideContent(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spaceXL),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       MediaQuery.of(context).padding.bottom - 
                       (DesignTokens.spaceXL * 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual Asset
              if (widget.slide.visualAsset != null) ...[
                _buildVisualAsset(context),
                SizedBox(height: DesignTokens.spaceXL),
              ],

              // Title
              Text(
                widget.slide.title,
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeXXXL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
                semanticsLabel: 'Onboarding: ${widget.slide.title}',
              ),

              SizedBox(height: DesignTokens.spaceL),

              // Content
              Text(
                widget.slide.content,
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.getTextSecondary(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              // Key Points
              if (widget.slide.keyPoints.isNotEmpty) ...[
                SizedBox(height: DesignTokens.spaceL),
                _buildKeyPoints(context),
              ],

              // Quick Setup Widget
              if (widget.quickSetupWidget != null) ...[
                SizedBox(height: DesignTokens.spaceXL),
                widget.quickSetupWidget!,
              ],

              SizedBox(height: DesignTokens.spaceXL),

              // CTA Button
              _buildCTAButton(context),

              // Skip Button (only show on non-completion slides)
              if (widget.slide.type != OnboardingSlideType.completion &&
                  widget.onSkip != null) ...[
                SizedBox(height: DesignTokens.spaceM),
                _buildSkipButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualAsset(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: DesignTokens.getPrimaryGradient(context),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.getColorWithOpacity(
              DesignTokens.getPrimaryColor(context),
              0.3,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _getVisualIcon(context),
    );
  }

  Widget _getVisualIcon(BuildContext context) {
    IconData iconData;
    switch (widget.slide.visualAsset) {
      case 'spiral_growth':
        iconData = Icons.auto_awesome;
        break;
      case 'shield_lock':
        iconData = Icons.security;
        break;
      case 'brain_heart':
        iconData = Icons.psychology;
        break;
      case 'process_flow':
        iconData = Icons.schedule;
        break;
      case 'diverse_hands':
        iconData = Icons.accessibility_new;
        break;
      case 'settings_gear':
        iconData = Icons.settings;
        break;
      case 'open_journal':
        iconData = Icons.book;
        break;
      default:
        iconData = Icons.star;
    }

    return Icon(
      iconData,
      size: 60,
      color: Colors.white,
      semanticLabel: 'Visual representation of ${widget.slide.title}',
    );
  }

  Widget _buildKeyPoints(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.slide.keyPoints.map((point) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: EdgeInsets.only(
                    top: DesignTokens.spaceS,
                    right: DesignTokens.spaceM,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.getPrimaryColor(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: DesignTokens.getTextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.getPrimaryColor(context),
          foregroundColor: Colors.white,
          padding: DesignTokens.buttonPaddingVertical,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          elevation: DesignTokens.elevationS,
        ),
        child: Text(
          widget.slide.ctaText,
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return TextButton(
      onPressed: widget.onSkip,
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.getTextTertiary(context),
        padding: EdgeInsets.all(DesignTokens.spaceM),
      ),
      child: Text(
        'Skip for now',
        style: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.getTextTertiary(context),
        ),
      ),
    );
  }
}

/// Progress indicator for onboarding slides
class OnboardingProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalSlides;
  final VoidCallback? onTap;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalSlides,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSlides, (index) {
        final isActive = index == currentIndex;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceXS),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? DesignTokens.getPrimaryColor(context)
                  : DesignTokens.getColorWithOpacity(
                      DesignTokens.getTextTertiary(context),
                      0.3,
                    ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
