import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';

/// A reusable wrapper component for consistent slide presentation in the
/// emotional mirror slide-based interface. Provides consistent layout,
/// styling, and responsive behavior across all slides.
class SlideWrapper extends StatelessWidget {
  /// The title to display in the slide header
  final String title;
  
  /// The main content widget for the slide
  final Widget child;
  
  /// Optional icon to display alongside the title
  final IconData? icon;
  
  /// Optional callback for refresh functionality
  final VoidCallback? onRefresh;
  
  /// Optional footer widget
  final Widget? footer;
  
  /// Whether to show the header (defaults to true)
  final bool showHeader;
  
  /// Custom padding override (uses design tokens by default)
  final EdgeInsets? padding;
  
  /// Background gradient override
  final Gradient? backgroundGradient;
  
  const SlideWrapper({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.onRefresh,
    this.footer,
    this.showHeader = true,
    this.padding,
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? EdgeInsets.all(
      DesignTokens.getiPhoneAdaptiveSpacing(
        context,
        base: DesignTokens.spaceL,
        compactScale: 0.8,
        largeScale: 1.2,
      ),
    );
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: backgroundGradient ?? DesignTokens.getCardGradient(context),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide header
            if (showHeader) _buildHeader(context),
            
            // Main content area
            Expanded(
              child: Padding(
                padding: effectivePadding,
                child: child,
              ),
            ),
            
            // Optional footer
            if (footer != null) _buildFooter(context),
          ],
        ),
      ),
    );
  }
  
  /// Builds the slide header with title and optional icon
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.getiPhoneAdaptiveSpacing(
          context,
          base: DesignTokens.spaceL,
          compactScale: 0.8,
          largeScale: 1.2,
        ),
        vertical: DesignTokens.getiPhoneAdaptiveSpacing(
          context,
          base: DesignTokens.spaceM,
          compactScale: 0.8,
          largeScale: 1.2,
        ),
      ),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundPrimary(context).withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon and title
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: DesignTokens.getiPhoneAdaptiveSpacing(
                      context,
                      base: DesignTokens.iconSizeL,
                      compactScale: 0.9,
                      largeScale: 1.1,
                    ),
                    color: DesignTokens.getPrimaryColor(context),
                  ),
                  SizedBox(width: DesignTokens.spaceM),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: DesignTokens.getTextStyle(
                      fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                        context,
                        base: DesignTokens.fontSizeXXL,
                        compactScale: 0.9,
                        largeScale: 1.1,
                      ),
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Refresh button
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh_rounded,
                size: DesignTokens.iconSizeM,
                color: DesignTokens.getPrimaryColor(context),
              ),
              tooltip: 'Refresh',
              splashRadius: DesignTokens.iconSizeL,
            ),
        ],
      ),
    );
  }
  
  /// Builds the optional footer
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        DesignTokens.getiPhoneAdaptiveSpacing(
          context,
          base: DesignTokens.spaceM,
          compactScale: 0.8,
          largeScale: 1.2,
        ),
      ),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundPrimary(context).withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: footer!,
    );
  }
}

/// A loading wrapper for slides that are still loading content
class SlideLoadingWrapper extends StatelessWidget {
  /// Whether the slide is currently loading
  final bool isLoading;
  
  /// The child widget to display when not loading
  final Widget child;
  
  /// The slide title
  final String title;
  
  /// Optional loading message
  final String? loadingMessage;
  
  /// Optional icon for the slide
  final IconData? icon;
  
  const SlideLoadingWrapper({
    super.key,
    required this.isLoading,
    required this.child,
    required this.title,
    this.loadingMessage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SlideWrapper(
        title: title,
        icon: icon,
        child: _buildLoadingContent(context),
      );
    }
    return child;
  }
  
  /// Builds the loading content display
  Widget _buildLoadingContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading indicator
          SizedBox(
            width: DesignTokens.getiPhoneAdaptiveSpacing(
              context,
              base: DesignTokens.loadingIndicatorSize,
              compactScale: 0.8,
              largeScale: 1.2,
            ),
            height: DesignTokens.getiPhoneAdaptiveSpacing(
              context,
              base: DesignTokens.loadingIndicatorSize,
              compactScale: 0.8,
              largeScale: 1.2,
            ),
            child: CircularProgressIndicator(
              strokeWidth: DesignTokens.loadingStrokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.getPrimaryColor(context),
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Loading message
          Text(
            loadingMessage ?? 'Loading...',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                context,
                base: DesignTokens.fontSizeL,
                compactScale: 0.9,
                largeScale: 1.1,
              ),
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}