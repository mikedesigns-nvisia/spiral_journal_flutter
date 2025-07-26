import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Standardized heading system using golden ratio typography scale
/// 
/// This system ensures consistent heading sizes, icon sizes, and spacing
/// across all screens in the application following the golden ratio (φ ≈ 1.618)
class HeadingSystem {
  // ============================================================================
  // TYPOGRAPHY SCALE - GOLDEN RATIO BASED
  // ============================================================================
  
  /// Base font size for body text
  static const double _baseFontSize = 16.0;
  
  /// Golden ratio typography scale
  /// Each level is multiplied by φ (1.618) for harmonic progression
  static const double displayLarge = 42.0;   // _baseFontSize × φ³ ≈ 42
  static const double displayMedium = 32.0;  // _baseFontSize × φ² ≈ 26 → 32 (adjusted for readability)
  static const double displaySmall = 26.0;   // _baseFontSize × φ¹·⁵ ≈ 26
  
  static const double headlineLarge = 20.0;  // _baseFontSize × φ⁰·⁵ ≈ 20
  static const double headlineMedium = 18.0; // Standard heading
  static const double headlineSmall = 16.0;  // _baseFontSize
  
  static const double titleLarge = 16.0;     // Component titles
  static const double titleMedium = 14.0;    // Card titles
  static const double titleSmall = 12.0;     // Section labels
  
  static const double bodyLarge = 16.0;      // Main body text
  static const double bodyMedium = 14.0;     // Secondary body text
  static const double bodySmall = 12.0;      // Captions and metadata
  
  static const double labelLarge = 14.0;     // Button text
  static const double labelMedium = 12.0;    // Tab labels
  static const double labelSmall = 10.0;     // Chip text
  
  // ============================================================================
  // HEADING STYLES
  // ============================================================================
  
  /// Get display text style (largest headings)
  static TextStyle getDisplayLarge(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: displayLarge,
      fontWeight: DesignTokens.fontWeightBold,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightTight,
    );
  }
  
  static TextStyle getDisplayMedium(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: displayMedium,
      fontWeight: DesignTokens.fontWeightSemiBold,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightTight,
    );
  }
  
  static TextStyle getDisplaySmall(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: displaySmall,
      fontWeight: DesignTokens.fontWeightSemiBold,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightTight,
    );
  }
  
  /// Get headline text styles (section headings)
  static TextStyle getHeadlineLarge(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: headlineLarge,
      fontWeight: DesignTokens.fontWeightSemiBold,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  static TextStyle getHeadlineMedium(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: headlineMedium,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  static TextStyle getHeadlineSmall(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: headlineSmall,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  /// Get title text styles (component headings)
  static TextStyle getTitleLarge(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: titleLarge,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  static TextStyle getTitleMedium(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: titleMedium,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  static TextStyle getTitleSmall(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: titleSmall,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextSecondary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  /// Get body text styles
  static TextStyle getBodyLarge(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: bodyLarge,
      fontWeight: DesignTokens.fontWeightRegular,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightRelaxed,
    );
  }
  
  static TextStyle getBodyMedium(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: bodyMedium,
      fontWeight: DesignTokens.fontWeightRegular,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightRelaxed,
    );
  }
  
  static TextStyle getBodySmall(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: bodySmall,
      fontWeight: DesignTokens.fontWeightRegular,
      color: DesignTokens.getTextSecondary(context),
      height: DesignTokens.lineHeightRelaxed,
    );
  }
  
  /// Get label text styles
  static TextStyle getLabelLarge(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: labelLarge,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  static TextStyle getLabelMedium(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: labelMedium,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  static TextStyle getLabelSmall(BuildContext context) {
    return DesignTokens.getTextStyle(
      fontSize: labelSmall,
      fontWeight: DesignTokens.fontWeightMedium,
      color: DesignTokens.getTextSecondary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }
  
  // ============================================================================
  // STANDARDIZED HEADING COMPONENTS
  // ============================================================================
  
  /// Screen title (used in app bars)
  static Widget screenTitle(BuildContext context, String text) {
    return Text(
      text,
      style: getHeadlineMedium(context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// Page heading (main heading on a screen)
  static Widget pageHeading(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spaceL),
      child: Text(
        text,
        style: getHeadlineLarge(context),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// Section heading
  static Widget sectionHeading(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(
        top: DesignTokens.spaceXL,
        bottom: DesignTokens.spaceM,
      ),
      child: Text(
        text,
        style: getHeadlineSmall(context),
      ),
    );
  }
  
  /// Card title
  static Widget cardTitle(BuildContext context, String text) {
    return Text(
      text,
      style: getTitleLarge(context),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// List item title
  static Widget listItemTitle(BuildContext context, String text) {
    return Text(
      text,
      style: getTitleMedium(context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// Caption or metadata text
  static Widget caption(BuildContext context, String text) {
    return Text(
      text,
      style: getBodySmall(context),
    );
  }
  
  // ============================================================================
  // ICON SIZE SYSTEM - GOLDEN RATIO BASED
  // ============================================================================
  
  /// Standardized icon sizes following golden ratio
  static const double iconSizeXS = 10.0;   // Tiny icons
  static const double iconSizeS = 16.0;    // Small icons (inline with text)
  static const double iconSizeM = 20.0;    // Default icon size
  static const double iconSizeL = 24.0;    // Large icons (app bar, buttons)
  static const double iconSizeXL = 32.0;   // Extra large (feature icons)
  static const double iconSizeXXL = 48.0;  // Huge icons (empty states)
  
  /// Get icon size for specific contexts
  static double getAppBarIconSize() => iconSizeL;
  static double getButtonIconSize() => iconSizeM;
  static double getListItemIconSize() => iconSizeM;
  static double getBottomNavIconSize() => iconSizeL;
  static double getEmptyStateIconSize() => iconSizeXXL;
  static double getInlineIconSize() => iconSizeS;
  
  // ============================================================================
  // HEADING WITH ICON COMPONENTS
  // ============================================================================
  
  /// App bar with standardized title and icon
  static AppBar appBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    Widget? leading,
  }) {
    return AppBar(
      title: screenTitle(context, title),
      centerTitle: centerTitle,
      elevation: DesignTokens.appBarElevation,
      backgroundColor: DesignTokens.getBackgroundPrimary(context),
      foregroundColor: DesignTokens.getTextPrimary(context),
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(
        size: getAppBarIconSize(),
        color: DesignTokens.getTextPrimary(context),
      ),
    );
  }
  
  /// Section heading with optional icon
  static Widget sectionHeadingWithIcon({
    required BuildContext context,
    required String text,
    IconData? icon,
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: DesignTokens.spaceXL,
        bottom: DesignTokens.spaceM,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSizeM,
              color: DesignTokens.getTextPrimary(context),
            ),
            SizedBox(width: DesignTokens.spaceS),
          ],
          Expanded(
            child: Text(
              text,
              style: getHeadlineSmall(context),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
  
  /// List tile with standardized text and icon sizes
  static Widget listTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.screenPadding,
        vertical: DesignTokens.spaceXS,
      ),
      leading: leadingIcon != null
          ? Icon(
              leadingIcon,
              size: getListItemIconSize(),
              color: DesignTokens.getTextSecondary(context),
            )
          : null,
      title: listItemTitle(context, title),
      subtitle: subtitle != null
          ? Padding(
              padding: EdgeInsets.only(top: DesignTokens.spaceXXS),
              child: Text(
                subtitle,
                style: getBodySmall(context),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
  
  // ============================================================================
  // RESPONSIVE HELPERS
  // ============================================================================
  
  /// Get responsive font size based on device size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseSize,
  ) {
    return DesignTokens.getiPhoneAdaptiveFontSize(
      context,
      base: baseSize,
      compactScale: 0.9,
      largeScale: 1.1,
    );
  }
  
  /// Get responsive icon size based on device size
  static double getResponsiveIconSize(
    BuildContext context,
    double baseSize,
  ) {
    return DesignTokens.getiPhoneAdaptiveFontSize(
      context,
      base: baseSize,
      compactScale: 0.85,
      largeScale: 1.15,
    );
  }
}

/// Standardized empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: HeadingSystem.getEmptyStateIconSize(),
              color: DesignTokens.getTextTertiary(context),
            ),
            SizedBox(height: DesignTokens.spaceL),
            Text(
              title,
              style: HeadingSystem.getHeadlineSmall(context),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: DesignTokens.spaceM),
              Text(
                message!,
                style: HeadingSystem.getBodyMedium(context).copyWith(
                  color: DesignTokens.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: DesignTokens.spaceXL),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}