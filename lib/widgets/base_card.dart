import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/widgets/animated_card.dart';
import 'package:spiral_journal/widgets/animated_button.dart';

/// Base card component that provides consistent styling and layout
/// for all cards throughout the application with smooth animations
class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.boxShadow,
    this.gradient,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? DesignTokens.cardRadius;
    
    return AnimatedCard(
      onTap: onTap,
      margin: margin ?? EdgeInsets.all(DesignTokens.spaceS),
      padding: EdgeInsets.zero, // We'll handle padding in the inner container
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      color: Colors.transparent, // Make the card transparent since we'll use gradient
      child: Container(
        padding: padding ?? EdgeInsets.all(DesignTokens.cardPadding),
        decoration: BoxDecoration(
          gradient: gradient ?? DesignTokens.getCardGradient(context),
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          border: Border.all(
            color: borderColor ?? DesignTokens.getSubtleBorderColor(context),
            width: borderWidth ?? 1.0,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Standardized card header component with icon and title
class CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? titleStyle;
  final EdgeInsets? padding;

  const CardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconBackgroundColor,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? 
                     DesignTokens.getColorWithOpacity(
                       DesignTokens.getPrimaryColor(context), 
                       0.15,
                     ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            ),
            child: Icon(
              icon,
              color: iconColor ?? DesignTokens.getPrimaryColor(context),
              size: iconSize ?? DesignTokens.iconSizeM,
            ),
          ),
          SizedBox(width: DesignTokens.spaceL),
          Expanded(
            child: Text(
              title,
              style: titleStyle ?? Theme.of(context).textTheme.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized card footer with description and CTA button
class CardFooter extends StatelessWidget {
  final String description;
  final String ctaText;
  final VoidCallback onCtaPressed;
  final TextStyle? descriptionStyle;
  final TextStyle? ctaStyle;
  final Color? ctaColor;
  final EdgeInsets? padding;

  const CardFooter({
    super.key,
    required this.description,
    required this.ctaText,
    required this.onCtaPressed,
    this.descriptionStyle,
    this.ctaStyle,
    this.ctaColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              description,
              style: descriptionStyle ?? 
                     Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: DesignTokens.getTextTertiary(context),
                     ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: DesignTokens.spaceM),
          StandardCTAButton(
            text: ctaText,
            onPressed: onCtaPressed,
            textStyle: ctaStyle,
            color: ctaColor,
          ),
        ],
      ),
    );
  }
}

/// Standardized CTA button component for consistent styling with animations
class StandardCTAButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final TextStyle? textStyle;
  final Color? color;
  final EdgeInsets? padding;

  const StandardCTAButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textStyle,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM, 
        vertical: DesignTokens.spaceS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: textStyle ?? 
                   Theme.of(context).textTheme.bodySmall?.copyWith(
                     color: color ?? DesignTokens.getPrimaryColor(context),
                     fontWeight: FontWeight.w500,
                   ),
          ),
          SizedBox(width: DesignTokens.spaceXS),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: DesignTokens.iconSizeXS,
            color: color ?? DesignTokens.getPrimaryColor(context),
          ),
        ],
      ),
    );
  }
}

/// Standardized content container for card content sections
class CardContentContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;

  const CardContentContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceL,
        vertical: DesignTokens.spaceXL,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? DesignTokens.getBackgroundPrimary(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(
          borderRadius ?? DesignTokens.radiusL, // Use larger radius for smoother corners
        ),
        border: Border.all(
          color: borderColor ?? DesignTokens.getSubtleBorderColor(context).withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
