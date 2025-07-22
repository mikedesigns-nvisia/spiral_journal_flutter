import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';

/// A wrapper component that provides graceful error handling for individual slides
/// while maintaining slide navigation functionality.
class SlideErrorWrapper extends StatelessWidget {
  /// The child widget to display when there's no error
  final Widget child;
  
  /// The error message to display, if any
  final String? error;
  
  /// Callback function to retry the failed operation
  final VoidCallback? onRetry;
  
  /// The title of the slide for error context
  final String slideTitle;
  
  /// Whether the slide is currently loading
  final bool isLoading;
  
  /// Custom error widget builder for specific error types
  final Widget Function(String error, VoidCallback? onRetry)? errorBuilder;

  const SlideErrorWrapper({
    super.key,
    required this.child,
    this.error,
    this.onRetry,
    required this.slideTitle,
    this.isLoading = false,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoading) {
      return _buildLoadingState(context);
    }
    
    // Show error state if there's an error
    if (error != null) {
      return errorBuilder?.call(error!, onRetry) ?? _buildDefaultErrorState(context);
    }
    
    // Show normal content
    return child;
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: DesignTokens.getCardGradient(context),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.getPrimaryColor(context),
              ),
            ),
            SizedBox(height: DesignTokens.spaceL),
            Text(
              'Loading $slideTitle...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: DesignTokens.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: DesignTokens.getCardGradient(context),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DesignTokens.getErrorColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: DesignTokens.getErrorColor(context),
                ),
              ),
              
              SizedBox(height: DesignTokens.spaceL),
              
              // Error title
              Text(
                'Unable to load $slideTitle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: DesignTokens.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: DesignTokens.spaceM),
              
              // Error message
              Text(
                error ?? 'An unexpected error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: DesignTokens.spaceXL),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retry button (if retry callback is provided)
                  if (onRetry != null) ...[
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: Icon(Icons.refresh_rounded),
                      label: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.getPrimaryColor(context),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceL,
                          vertical: DesignTokens.spaceM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        ),
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceM),
                  ],
                  
                  // Skip button (allows navigation to continue)
                  OutlinedButton.icon(
                    onPressed: () {
                      // This allows users to continue navigating even with errors
                      // The slide will remain in error state but navigation works
                    },
                    icon: Icon(Icons.skip_next_rounded),
                    label: Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.getTextSecondary(context),
                      side: BorderSide(
                        color: DesignTokens.getTextSecondary(context).withValues(alpha: 0.3),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceL,
                        vertical: DesignTokens.spaceM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: DesignTokens.spaceL),
              
              // Help text
              Text(
                'You can continue navigating to other slides',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.getTextTertiary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension methods for common error handling patterns in slides
extension SlideErrorHandling on Widget {
  /// Wraps a widget with slide error handling
  Widget withSlideErrorHandling({
    required String slideTitle,
    String? error,
    VoidCallback? onRetry,
    bool isLoading = false,
    Widget Function(String error, VoidCallback? onRetry)? errorBuilder,
  }) {
    return SlideErrorWrapper(
      slideTitle: slideTitle,
      error: error,
      onRetry: onRetry,
      isLoading: isLoading,
      errorBuilder: errorBuilder,
      child: this,
    );
  }
}