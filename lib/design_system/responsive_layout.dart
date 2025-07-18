import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/utils/iphone_detector.dart';

/// Adaptive scaffold that adjusts to iPhone sizes and safe areas
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsets? padding;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = padding ?? iPhoneDetector.getAdaptivePadding(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? DesignTokens.getBackgroundPrimary(context),
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: adaptivePadding,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Responsive container that adapts to iPhone screen sizes
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = true,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerMaxWidth = maxWidth ?? DesignTokens.maxContentWidth;
    final adaptivePadding = padding ?? iPhoneDetector.getAdaptivePadding(context);

    Widget content = Container(
      width: screenWidth > containerMaxWidth ? containerMaxWidth : double.infinity,
      padding: adaptivePadding,
      child: child,
    );

    if (centerContent && screenWidth > containerMaxWidth) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Adaptive grid that adjusts columns based on iPhone size
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? compactColumns;
  final int? regularColumns;
  final int? largeColumns;
  final double? spacing;
  final double? runSpacing;
  final double? childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.compactColumns,
    this.regularColumns,
    this.largeColumns,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final columns = iPhoneDetector.getAdaptiveColumns(
      context,
      compact: compactColumns ?? 1,
      regular: regularColumns ?? 2,
      large: largeColumns ?? 3,
    );

    final adaptiveSpacing = spacing ?? iPhoneDetector.getAdaptiveSpacing(
      context,
      base: DesignTokens.spaceL,
    );

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: adaptiveSpacing,
        mainAxisSpacing: runSpacing ?? adaptiveSpacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive text that adapts font size to iPhone screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? compactScale;
  final double? largeScale;
  final double? height;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.baseFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.compactScale,
    this.largeScale,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final adaptiveFontSize = iPhoneDetector.getAdaptiveFontSize(
      context,
      base: baseFontSize,
      compactScale: compactScale,
      largeScale: largeScale,
    );

    return Text(
      text,
      style: DesignTokens.getTextStyle(
        fontSize: adaptiveFontSize,
        fontWeight: fontWeight ?? DesignTokens.fontWeightRegular,
        color: color ?? DesignTokens.getTextPrimary(context),
        height: height,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Adaptive button that adjusts size based on iPhone screen size
class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final ButtonType type;
  final double? baseHeight;
  final double? baseFontSize;

  const AdaptiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.type = ButtonType.primary,
    this.baseHeight,
    this.baseFontSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ButtonType.primary:
        return ComponentLibrary.primaryButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
          width: width,
          size: _getButtonSize(context),
        );
      case ButtonType.secondary:
        return ComponentLibrary.secondaryButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
          width: width,
          size: _getButtonSize(context),
        );
      case ButtonType.text:
        return ComponentLibrary.textButton(
          text: text,
          onPressed: onPressed,
          icon: icon,
          size: _getButtonSize(context),
        );
    }
  }

  ButtonSize _getButtonSize(BuildContext context) {
    if (iPhoneDetector.isCompactiPhone(context)) {
      return ButtonSize.small;
    } else if (iPhoneDetector.isLargeiPhone(context)) {
      return ButtonSize.large;
    }
    return ButtonSize.medium;
  }
}

/// Adaptive spacing widget that adjusts based on iPhone size
class AdaptiveSpacing extends StatelessWidget {
  final double baseSize;
  final bool isHorizontal;
  final double? compactScale;
  final double? largeScale;

  const AdaptiveSpacing({
    super.key,
    required this.baseSize,
    this.isHorizontal = false,
    this.compactScale,
    this.largeScale,
  });

  const AdaptiveSpacing.vertical({
    super.key,
    required this.baseSize,
    this.compactScale,
    this.largeScale,
  }) : isHorizontal = false;

  const AdaptiveSpacing.horizontal({
    super.key,
    required this.baseSize,
    this.compactScale,
    this.largeScale,
  }) : isHorizontal = true;

  @override
  Widget build(BuildContext context) {
    final adaptiveSize = iPhoneDetector.getAdaptiveSpacing(
      context,
      base: baseSize,
      compactScale: compactScale,
      largeScale: largeScale,
    );

    return SizedBox(
      width: isHorizontal ? adaptiveSize : null,
      height: isHorizontal ? null : adaptiveSize,
    );
  }
}

/// Adaptive card that adjusts padding and sizing based on iPhone size
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;
  final bool hasBorder;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.onTap,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = padding ?? iPhoneDetector.getAdaptivePadding(context);
    final adaptiveMargin = margin ?? EdgeInsets.all(
      iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceS),
    );

    return ComponentLibrary.card(
      child: child,
      padding: adaptivePadding,
      margin: adaptiveMargin,
      backgroundColor: backgroundColor,
      elevation: elevation,
      onTap: onTap,
      hasBorder: hasBorder,
    );
  }
}

/// Adaptive list view that handles iPhone-specific scrolling and spacing
class AdaptiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const AdaptiveListView({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = padding ?? iPhoneDetector.getAdaptivePadding(context);
    final adaptiveSpacing = spacing ?? iPhoneDetector.getAdaptiveSpacing(
      context,
      base: DesignTokens.spaceM,
    );

    return ListView.separated(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: adaptivePadding,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: adaptiveSpacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Adaptive bottom navigation that handles iPhone safe areas and sizing
class AdaptiveBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  const AdaptiveBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? DesignTokens.getBackgroundPrimary(context),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? DesignTokens.darkBackgroundTertiary
                : DesignTokens.backgroundTertiary,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: selectedItemColor ?? DesignTokens.getPrimaryColor(context),
          unselectedItemColor: unselectedItemColor ?? DesignTokens.getTextTertiary(context),
          selectedLabelStyle: DesignTokens.getTextStyle(
            fontSize: iPhoneDetector.getAdaptiveFontSize(context, base: 12),
            fontWeight: DesignTokens.fontWeightMedium,
            color: selectedItemColor ?? DesignTokens.getPrimaryColor(context),
          ),
          unselectedLabelStyle: DesignTokens.getTextStyle(
            fontSize: iPhoneDetector.getAdaptiveFontSize(context, base: 12),
            fontWeight: DesignTokens.fontWeightRegular,
            color: unselectedItemColor ?? DesignTokens.getTextTertiary(context),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

/// Keyboard-aware scrollable content for iPhone input scenarios
class KeyboardAwareScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool reverse;

  const KeyboardAwareScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = iPhoneDetector.getKeyboardPadding(context);
    final adaptivePadding = padding ?? iPhoneDetector.getAdaptivePadding(context);

    return SingleChildScrollView(
      controller: controller,
      reverse: reverse,
      padding: adaptivePadding.copyWith(
        bottom: adaptivePadding.bottom + keyboardPadding,
      ),
      child: child,
    );
  }
}

/// Button type enumeration for adaptive buttons
enum ButtonType {
  primary,
  secondary,
  text,
}
