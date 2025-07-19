import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/theme/app_theme.dart';

/// A consistent background widget that provides theme-aware gradients
/// and backgrounds for all screens in the app.
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool useGradient;
  final bool applyPadding;
  final EdgeInsets? customPadding;
  final bool enableSafeArea;

  const AppBackground({
    super.key,
    required this.child,
    this.useGradient = true,
    this.applyPadding = false,
    this.customPadding,
    this.enableSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply padding if requested
    if (applyPadding || customPadding != null) {
      final padding = customPadding ?? 
          EdgeInsets.all(DesignTokens.screenPadding);
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    // Apply safe area if enabled
    if (enableSafeArea) {
      content = SafeArea(child: content);
    }

    // Create the background container
    return Container(
      decoration: BoxDecoration(
        gradient: useGradient 
            ? AppTheme.getPrimaryGradient(context)
            : null,
        color: useGradient 
            ? null 
            : AppTheme.getBackgroundPrimary(context),
      ),
      child: content,
    );
  }
}

/// A specialized background for screens that need a solid color background
/// instead of a gradient (useful for screens with lots of content)
class AppSolidBackground extends StatelessWidget {
  final Widget child;
  final bool applyPadding;
  final EdgeInsets? customPadding;
  final bool enableSafeArea;
  final Color? backgroundColor;

  const AppSolidBackground({
    super.key,
    required this.child,
    this.applyPadding = false,
    this.customPadding,
    this.enableSafeArea = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply padding if requested
    if (applyPadding || customPadding != null) {
      final padding = customPadding ?? 
          EdgeInsets.all(DesignTokens.screenPadding);
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    // Apply safe area if enabled
    if (enableSafeArea) {
      content = SafeArea(child: content);
    }

    return Container(
      color: backgroundColor ?? AppTheme.getBackgroundPrimary(context),
      child: content,
    );
  }
}

/// A background widget specifically for modal screens and dialogs
class AppModalBackground extends StatelessWidget {
  final Widget child;
  final bool applyPadding;
  final EdgeInsets? customPadding;
  final bool enableSafeArea;

  const AppModalBackground({
    super.key,
    required this.child,
    this.applyPadding = true,
    this.customPadding,
    this.enableSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply padding if requested
    if (applyPadding || customPadding != null) {
      final padding = customPadding ?? 
          EdgeInsets.all(DesignTokens.spaceL);
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    // Apply safe area if enabled
    if (enableSafeArea) {
      content = SafeArea(child: content);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundSecondary(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: content,
    );
  }
}

/// Extension to easily wrap any widget with app background
extension AppBackgroundExtension on Widget {
  /// Wrap this widget with the standard app gradient background
  Widget withAppBackground({
    bool useGradient = true,
    bool applyPadding = false,
    EdgeInsets? customPadding,
    bool enableSafeArea = true,
  }) {
    return AppBackground(
      useGradient: useGradient,
      applyPadding: applyPadding,
      customPadding: customPadding,
      enableSafeArea: enableSafeArea,
      child: this,
    );
  }

  /// Wrap this widget with a solid color background
  Widget withSolidBackground({
    bool applyPadding = false,
    EdgeInsets? customPadding,
    bool enableSafeArea = true,
    Color? backgroundColor,
  }) {
    return AppSolidBackground(
      applyPadding: applyPadding,
      customPadding: customPadding,
      enableSafeArea: enableSafeArea,
      backgroundColor: backgroundColor,
      child: this,
    );
  }

  /// Wrap this widget with a modal background
  Widget withModalBackground({
    bool applyPadding = true,
    EdgeInsets? customPadding,
    bool enableSafeArea = true,
  }) {
    return AppModalBackground(
      applyPadding: applyPadding,
      customPadding: customPadding,
      enableSafeArea: enableSafeArea,
      child: this,
    );
  }
}
