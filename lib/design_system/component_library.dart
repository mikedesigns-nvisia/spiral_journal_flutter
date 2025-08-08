import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'heading_system.dart';

/// Component library that provides pre-built, consistent UI components
/// following the Spiral Journal design system.
class ComponentLibrary {
  
  // ============================================================================
  // GOLDEN RATIO SPACING CONSTANTS
  // ============================================================================
  
  /// Golden ratio constant (phi)
  static const double goldenRatio = 1.618;
  
  /// Base spacing unit for golden ratio calculations
  static const double baseSpacing = 8.0;
  
  /// Golden ratio spacing scale
  static const double spaceGR1 = baseSpacing; // 8
  static const double spaceGR2 = baseSpacing * goldenRatio; // ~13
  static const double spaceGR3 = spaceGR2 * goldenRatio; // ~21
  static const double spaceGR4 = spaceGR3 * goldenRatio; // ~34
  static const double spaceGR5 = spaceGR4 * goldenRatio; // ~55
  static const double spaceGR6 = spaceGR5 * goldenRatio; // ~89
  static const double spaceGR7 = spaceGR6 * goldenRatio; // ~144
  
  /// Fractional golden ratio spacing for fine adjustments
  static const double spaceGRHalf = baseSpacing / goldenRatio; // ~5
  static const double spaceGRQuarter = spaceGRHalf / goldenRatio; // ~3
  
  // ============================================================================
  // BUTTON COMPONENTS
  // ============================================================================
  
  /// Primary button following design system
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    ButtonSize size = ButtonSize.medium,
  }) {
    return SizedBox(
      width: width,
      height: _getButtonHeight(size),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? SizedBox(
                width: DesignTokens.iconSizeS,
                height: DesignTokens.iconSizeS,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : (icon != null ? Icon(icon, size: _getButtonIconSize(size)) : const SizedBox.shrink()),
        label: Text(
          text,
          style: DesignTokens.getTextStyle(
            fontSize: _getButtonFontSize(size),
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          padding: _getButtonPadding(size),
          elevation: DesignTokens.elevationS,
        ),
      ),
    );
  }
  
  /// Secondary button following design system
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    ButtonSize size = ButtonSize.medium,
  }) {
    return SizedBox(
      width: width,
      height: _getButtonHeight(size),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? SizedBox(
                width: DesignTokens.iconSizeS,
                height: DesignTokens.iconSizeS,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryOrange),
                ),
              )
            : (icon != null ? Icon(icon, size: _getButtonIconSize(size)) : const SizedBox.shrink()),
        label: Text(
          text,
          style: DesignTokens.getTextStyle(
            fontSize: _getButtonFontSize(size),
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.primaryOrange,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primaryOrange,
          side: const BorderSide(color: DesignTokens.primaryOrange, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          padding: _getButtonPadding(size),
        ),
      ),
    );
  }
  
  /// Text button following design system
  static Widget textButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    Color? color,
  }) {
    final buttonColor = color ?? DesignTokens.primaryOrange;
    
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: _getButtonIconSize(size)) : const SizedBox.shrink(),
      label: Text(
        text,
        style: DesignTokens.getTextStyle(
          fontSize: _getButtonFontSize(size),
          fontWeight: DesignTokens.fontWeightMedium,
          color: buttonColor,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: buttonColor,
        padding: _getButtonPadding(size),
      ),
    );
  }
  
  // ============================================================================
  // CARD COMPONENTS
  // ============================================================================
  
  /// Standard card following design system
  static Widget card({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    double? elevation,
    VoidCallback? onTap,
    bool hasBorder = true,
  }) {
    return Container(
      margin: margin ?? ComponentTokens.cardDefaultMargin,
      child: Material(
        color: backgroundColor ?? DesignTokens.getBackgroundSecondary(context),
        elevation: elevation ?? ComponentTokens.cardDefaultElevation,
        borderRadius: BorderRadius.circular(ComponentTokens.cardDefaultRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ComponentTokens.cardDefaultRadius),
          child: Container(
            padding: padding ?? ComponentTokens.cardDefaultPadding,
            decoration: hasBorder ? BoxDecoration(
              borderRadius: BorderRadius.circular(ComponentTokens.cardDefaultRadius),
              border: Border.all(
                color: DesignTokens.getSubtleBorderColor(context),
                width: ComponentTokens.cardBorderWidth,
              ),
            ) : null,
            child: child,
          ),
        ),
      ),
    );
  }
  
  /// Gradient card following design system
  static Widget gradientCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Gradient? gradient,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? ComponentTokens.cardDefaultMargin,
      decoration: BoxDecoration(
        gradient: gradient ?? DesignTokens.cardGradient,
        borderRadius: BorderRadius.circular(ComponentTokens.cardDefaultRadius),
        boxShadow: DesignTokens.shadowS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ComponentTokens.cardDefaultRadius),
          child: Container(
            padding: padding ?? ComponentTokens.cardDefaultPadding,
            child: child,
          ),
        ),
      ),
    );
  }
  
  // ============================================================================
  // INPUT COMPONENTS
  // ============================================================================
  
  /// Standard text field following design system
  static Widget textField({
    required BuildContext context,
    required String label,
    String? hint,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int? maxLines = 1,
    int? maxLength,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.getTextSecondary(context),
              ),
              children: required ? [
                TextSpan(
                  text: ' *',
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.errorColor,
                  ),
                ),
              ] : null,
            ),
          ),
          const SizedBox(height: ComponentTokens.formLabelSpacing),
        ],
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: DesignTokens.getBackgroundSecondary(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: BorderSide(color: DesignTokens.getBackgroundTertiary(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: BorderSide(color: DesignTokens.getBackgroundTertiary(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: BorderSide(
                color: DesignTokens.getPrimaryColor(context), 
                width: DesignTokens.inputFocusedBorderWidth,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: const BorderSide(color: DesignTokens.errorColor),
            ),
            contentPadding: DesignTokens.inputContentPadding,
            hintStyle: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextTertiary(context),
            ),
          ),
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextPrimary(context),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: ComponentTokens.formHelperSpacing),
          Text(
            helperText,
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextTertiary(context),
            ),
          ),
        ],
      ],
    );
  }
  
  // ============================================================================
  // CHIP COMPONENTS
  // ============================================================================
  
  /// Mood chip following design system
  static Widget moodChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? moodType,
  }) {
    final moodColor = moodType != null 
        ? DesignTokens.getMoodColor(moodType)
        : DesignTokens.primaryOrange;
    
    // Calculate contrast-safe text color
    final textColor = isSelected 
        ? _getContrastingTextColor(moodColor)
        : moodColor;
    
    // For selected state, use a slightly transparent background with border
    final backgroundColor = isSelected 
        ? DesignTokens.getColorWithOpacity(moodColor, 0.85)
        : DesignTokens.getColorWithOpacity(moodColor, 0.1);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: ComponentTokens.moodChipHeight,
        padding: ComponentTokens.moodChipPadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(
            color: moodColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: moodColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: isSelected 
                  ? DesignTokens.fontWeightSemiBold 
                  : DesignTokens.fontWeightMedium,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Filter chip following design system
  static Widget filterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    IconData? icon,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: DesignTokens.iconSizeS),
            const SizedBox(width: DesignTokens.spaceXS),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: DesignTokens.backgroundTertiary,
      selectedColor: DesignTokens.primaryOrange,
      labelStyle: DesignTokens.getTextStyle(
        fontSize: DesignTokens.fontSizeM,
        fontWeight: isSelected 
            ? DesignTokens.fontWeightSemiBold 
            : DesignTokens.fontWeightMedium,
        color: isSelected ? Colors.white : DesignTokens.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      showCheckmark: false,
    );
  }
  
  // ============================================================================
  // STATUS COMPONENTS
  // ============================================================================
  
  /// Status indicator following design system
  static Widget statusIndicator({
    required String status,
    required String message,
    IconData? icon,
    bool showIcon = true,
  }) {
    final statusColor = DesignTokens.getStatusColor(status);
    final statusIcon = icon ?? _getStatusIcon(status);
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: DesignTokens.getColorWithOpacity(statusColor, 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: DesignTokens.getColorWithOpacity(statusColor, 0.3),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              statusIcon,
              color: statusColor,
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spaceM),
          ],
          Expanded(
            child: Text(
              message,
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ============================================================================
  // HEADER COMPONENTS
  // ============================================================================
  
  /// App header following design system - consistent header for all pages
  static Widget appHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? subtitle,
    List<Widget>? actions,
    Color? iconBackgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundPrimary(context),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.getBackgroundTertiary(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceS),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? 
                DesignTokens.getColorWithOpacity(DesignTokens.getPrimaryColor(context), 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(
              icon,
              color: DesignTokens.getPrimaryColor(context),
              size: DesignTokens.iconSizeM,
            ),
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HeadingSystem.getHeadlineMedium(context),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: HeadingSystem.getBodySmall(context),
                  ),
              ],
            ),
          ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }
  
  // ============================================================================
  // LOADING COMPONENTS
  // ============================================================================
  
  /// Loading button with integrated loading state
  static Widget loadingButton({
    required Widget child,
    required VoidCallback? onPressed,
    bool isLoading = false,
    LoadingType loadingType = LoadingType.circular,
    ButtonSize size = ButtonSize.medium,
    Color? backgroundColor,
    Color? foregroundColor,
    double? width,
  }) {
    return SizedBox(
      width: width,
      height: _getButtonHeight(size),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? DesignTokens.primaryOrange,
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          padding: _getButtonPadding(size),
          elevation: DesignTokens.elevationS,
        ),
        child: isLoading 
            ? _buildLoadingIndicator(loadingType, size)
            : child,
      ),
    );
  }
  
  /// Build loading indicator based on type and size
  static Widget _buildLoadingIndicator(LoadingType type, ButtonSize size) {
    final indicatorSize = _getButtonIconSize(size);
    
    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case LoadingType.dots:
        return SizedBox(
          width: indicatorSize * 2,
          height: indicatorSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => 
              Container(
                width: indicatorSize / 4,
                height: indicatorSize / 4,
                margin: EdgeInsets.symmetric(horizontal: indicatorSize / 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  static double _getButtonHeight(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.buttonHeightSmall;
      case ButtonSize.medium:
        return DesignTokens.buttonHeight;
      case ButtonSize.large:
        return DesignTokens.buttonHeightLarge;
    }
  }
  
  static double _getButtonFontSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.fontSizeS;
      case ButtonSize.medium:
        return DesignTokens.fontSizeM;
      case ButtonSize.large:
        return DesignTokens.fontSizeL;
    }
  }
  
  static double _getButtonIconSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.iconSizeS;
      case ButtonSize.medium:
        return DesignTokens.iconSizeM;
      case ButtonSize.large:
        return DesignTokens.iconSizeL;
    }
  }
  
  static EdgeInsets _getButtonPadding(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceL,
          vertical: DesignTokens.spaceS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXXL,
          vertical: DesignTokens.spaceM,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXXXL,
          vertical: DesignTokens.spaceL,
        );
    }
  }
  
  static IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
        return Icons.info;
      default:
        return Icons.info;
    }
  }
  
  /// Calculate contrasting text color based on background
  static Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance using WCAG formula
    final luminance = backgroundColor.computeLuminance();
    
    // Use dark text for light backgrounds, white text for dark backgrounds
    // Threshold of 0.5 provides good contrast for most colors
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// Button size enumeration
enum ButtonSize {
  small,
  medium,
  large,
}

/// Layout helper components
class LayoutComponents {
  
  /// Responsive container that adapts to screen size
  static Widget responsiveContainer({
    required Widget child,
    EdgeInsets? padding,
    double? maxWidth,
  }) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final containerMaxWidth = maxWidth ?? DesignTokens.maxContentWidth;
        
        return Container(
          width: screenWidth > containerMaxWidth ? containerMaxWidth : double.infinity,
          padding: padding ?? EdgeInsets.all(
            DesignTokens.getResponsiveValue(
              context,
              mobile: DesignTokens.spaceL,
              tablet: DesignTokens.spaceXL,
              desktop: DesignTokens.spaceXXL,
            ),
          ),
          child: child,
        );
      },
    );
  }
  
  /// Responsive grid layout
  static Widget responsiveGrid({
    required List<Widget> children,
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
    double spacing = DesignTokens.spaceL,
  }) {
    return Builder(
      builder: (context) {
        final columns = DesignTokens.getResponsiveValue(
          context,
          mobile: mobileColumns ?? 1,
          tablet: tabletColumns ?? 2,
          desktop: desktopColumns ?? 3,
        );
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
  
  /// Spacer component with consistent spacing
  static Widget spacer({SpacingSize size = SpacingSize.medium}) {
    final height = _getSpacingHeight(size);
    return SizedBox(height: height);
  }
  
  /// Horizontal spacer component
  static Widget horizontalSpacer({SpacingSize size = SpacingSize.medium}) {
    final width = _getSpacingHeight(size);
    return SizedBox(width: width);
  }
  
  static double _getSpacingHeight(SpacingSize size) {
    switch (size) {
      case SpacingSize.xs:
        return DesignTokens.spaceXS;
      case SpacingSize.small:
        return DesignTokens.spaceS;
      case SpacingSize.medium:
        return DesignTokens.spaceL;
      case SpacingSize.large:
        return DesignTokens.spaceXXL;
      case SpacingSize.xl:
        return DesignTokens.spaceXXXL;
    }
  }
}

/// Spacing size enumeration
enum SpacingSize {
  xs,
  small,
  medium,
  large,
  xl,
}

/// Loading type enumeration
enum LoadingType {
  circular,
  dots,
}

/// Loading button widget for consistent loading states
class LoadingButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LoadingType loadingType;
  final ButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const LoadingButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.loadingType = LoadingType.circular,
    this.size = ButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.loadingButton(
      child: child,
      onPressed: onPressed,
      isLoading: isLoading,
      loadingType: loadingType,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      width: width,
    );
  }
}
