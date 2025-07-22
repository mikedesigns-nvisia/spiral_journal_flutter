import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../utils/iphone_detector.dart';

/// Responsive slide layout that adapts to different device sizes and orientations
class ResponsiveSlideLayout extends StatelessWidget {
  final Widget child;
  final String slideId;
  final bool enableOrientationOptimization;
  final bool enableTabletOptimization;
  final EdgeInsets? customPadding;
  final double? maxContentWidth;

  const ResponsiveSlideLayout({
    super.key,
    required this.child,
    required this.slideId,
    this.enableOrientationOptimization = true,
    this.enableTabletOptimization = true,
    this.customPadding,
    this.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final deviceInfo = _getDeviceInfo(context, constraints, orientation);
            
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: _getResponsivePadding(context, deviceInfo),
              child: _buildResponsiveContent(context, deviceInfo),
            );
          },
        );
      },
    );
  }

  /// Get device information for responsive layout decisions
  _DeviceInfo _getDeviceInfo(BuildContext context, BoxConstraints constraints, Orientation orientation) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isCompact = iPhoneDetector.isCompactiPhone(context);
    final isLarge = iPhoneDetector.isLargeiPhone(context);
    
    return _DeviceInfo(
      screenSize: screenSize,
      constraints: constraints,
      orientation: orientation,
      isTablet: isTablet,
      isCompactiPhone: isCompact,
      isLargeiPhone: isLarge,
      isLandscape: orientation == Orientation.landscape,
    );
  }

  /// Get responsive padding based on device info
  EdgeInsets _getResponsivePadding(BuildContext context, _DeviceInfo deviceInfo) {
    if (customPadding != null) return customPadding!;

    // Base padding
    double horizontal = DesignTokens.spaceM;
    double vertical = DesignTokens.spaceM;

    // Adjust for device type
    if (deviceInfo.isTablet && enableTabletOptimization) {
      // iPad optimization - more padding for better content centering
      horizontal = DesignTokens.spaceXL;
      vertical = DesignTokens.spaceL;
    } else if (deviceInfo.isCompactiPhone) {
      // iPhone SE optimization - minimal padding to maximize content
      horizontal = DesignTokens.spaceS;
      vertical = DesignTokens.spaceXS;
    } else if (deviceInfo.isLargeiPhone) {
      // iPhone Pro Max optimization - comfortable padding
      horizontal = DesignTokens.spaceL;
      vertical = DesignTokens.spaceM;
    }

    // Adjust for orientation
    if (deviceInfo.isLandscape && enableOrientationOptimization) {
      // Reduce vertical padding in landscape
      vertical *= 0.6;
      // Increase horizontal padding slightly
      horizontal *= 1.2;
    }

    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  /// Build responsive content based on device info
  Widget _buildResponsiveContent(BuildContext context, _DeviceInfo deviceInfo) {
    Widget content = child;

    // Apply max width constraint for tablets
    if (deviceInfo.isTablet && enableTabletOptimization) {
      final maxWidth = maxContentWidth ?? _getTabletMaxWidth(deviceInfo);
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        ),
      );
    }

    // Handle orientation changes with animation
    if (enableOrientationOptimization) {
      content = AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey('${slideId}_${deviceInfo.orientation}'),
          child: content,
        ),
      );
    }

    return content;
  }

  /// Get maximum content width for tablet optimization
  double _getTabletMaxWidth(_DeviceInfo deviceInfo) {
    if (deviceInfo.isLandscape) {
      // In landscape, use more of the available width
      return deviceInfo.screenSize.width * 0.8;
    } else {
      // In portrait, use a comfortable reading width
      return deviceInfo.screenSize.width * 0.9;
    }
  }
}

/// Responsive chart container for slide charts
class ResponsiveChartContainer extends StatelessWidget {
  final Widget chart;
  final String chartType;
  final double? aspectRatio;
  final EdgeInsets? padding;

  const ResponsiveChartContainer({
    super.key,
    required this.chart,
    required this.chartType,
    this.aspectRatio,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final deviceInfo = _getDeviceInfo(context, constraints, orientation);
            final chartAspectRatio = _getChartAspectRatio(deviceInfo);
            
            return Container(
              padding: padding ?? _getChartPadding(deviceInfo),
              child: AspectRatio(
                aspectRatio: chartAspectRatio,
                child: chart,
              ),
            );
          },
        );
      },
    );
  }

  _DeviceInfo _getDeviceInfo(BuildContext context, BoxConstraints constraints, Orientation orientation) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isCompact = iPhoneDetector.isCompactiPhone(context);
    final isLarge = iPhoneDetector.isLargeiPhone(context);
    
    return _DeviceInfo(
      screenSize: screenSize,
      constraints: constraints,
      orientation: orientation,
      isTablet: isTablet,
      isCompactiPhone: isCompact,
      isLargeiPhone: isLarge,
      isLandscape: orientation == Orientation.landscape,
    );
  }

  double _getChartAspectRatio(_DeviceInfo deviceInfo) {
    if (aspectRatio != null) return aspectRatio!;

    // Default aspect ratios based on chart type and device
    switch (chartType) {
      case 'line':
      case 'trend':
        if (deviceInfo.isTablet) {
          return deviceInfo.isLandscape ? 2.5 : 1.8;
        } else if (deviceInfo.isCompactiPhone) {
          return deviceInfo.isLandscape ? 2.2 : 1.4;
        } else {
          return deviceInfo.isLandscape ? 2.3 : 1.6;
        }
      
      case 'pie':
      case 'donut':
        return 1.0; // Always square for pie charts
      
      case 'bar':
      case 'column':
        if (deviceInfo.isTablet) {
          return deviceInfo.isLandscape ? 2.0 : 1.5;
        } else if (deviceInfo.isCompactiPhone) {
          return deviceInfo.isLandscape ? 1.8 : 1.2;
        } else {
          return deviceInfo.isLandscape ? 1.9 : 1.4;
        }
      
      default:
        return deviceInfo.isLandscape ? 2.0 : 1.5;
    }
  }

  EdgeInsets _getChartPadding(_DeviceInfo deviceInfo) {
    if (deviceInfo.isTablet) {
      return const EdgeInsets.all(16.0);
    } else if (deviceInfo.isCompactiPhone) {
      return const EdgeInsets.all(8.0);
    } else {
      return const EdgeInsets.all(12.0);
    }
  }
}

/// Responsive text container that adapts to device size
class ResponsiveTextContainer extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveTextContainer({
    super.key,
    required this.text,
    this.baseStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.shortestSide >= 600;
        final isCompact = iPhoneDetector.isCompactiPhone(context);
        
        final scaleFactor = _getTextScaleFactor(isTablet, isCompact);
        final adjustedStyle = _getAdjustedTextStyle(context, scaleFactor);
        
        return Text(
          text,
          style: adjustedStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }

  double _getTextScaleFactor(bool isTablet, bool isCompact) {
    if (isTablet) {
      return 1.2; // Larger text for tablets
    } else if (isCompact) {
      return 0.9; // Smaller text for compact devices
    } else {
      return 1.0; // Normal text for regular devices
    }
  }

  TextStyle _getAdjustedTextStyle(BuildContext context, double scaleFactor) {
    final defaultStyle = baseStyle ?? Theme.of(context).textTheme.bodyMedium!;
    
    return defaultStyle.copyWith(
      fontSize: (defaultStyle.fontSize ?? 14.0) * scaleFactor,
    );
  }
}

/// Responsive grid for slide content
class ResponsiveSlideGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final double? childAspectRatio;

  const ResponsiveSlideGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final deviceInfo = _getDeviceInfo(context, constraints, orientation);
            final columns = _getColumnCount(deviceInfo);
            final gridSpacing = spacing ?? _getGridSpacing(deviceInfo);
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: runSpacing ?? gridSpacing,
                childAspectRatio: childAspectRatio ?? _getChildAspectRatio(deviceInfo),
              ),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
            );
          },
        );
      },
    );
  }

  _DeviceInfo _getDeviceInfo(BuildContext context, BoxConstraints constraints, Orientation orientation) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isCompact = iPhoneDetector.isCompactiPhone(context);
    final isLarge = iPhoneDetector.isLargeiPhone(context);
    
    return _DeviceInfo(
      screenSize: screenSize,
      constraints: constraints,
      orientation: orientation,
      isTablet: isTablet,
      isCompactiPhone: isCompact,
      isLargeiPhone: isLarge,
      isLandscape: orientation == Orientation.landscape,
    );
  }

  int _getColumnCount(_DeviceInfo deviceInfo) {
    if (deviceInfo.isTablet) {
      return deviceInfo.isLandscape ? 3 : 2;
    } else if (deviceInfo.isCompactiPhone) {
      return 1;
    } else {
      return deviceInfo.isLandscape ? 2 : 1;
    }
  }

  double _getGridSpacing(_DeviceInfo deviceInfo) {
    if (deviceInfo.isTablet) {
      return 16.0;
    } else if (deviceInfo.isCompactiPhone) {
      return 8.0;
    } else {
      return 12.0;
    }
  }

  double _getChildAspectRatio(_DeviceInfo deviceInfo) {
    if (deviceInfo.isTablet) {
      return 1.2;
    } else if (deviceInfo.isCompactiPhone) {
      return 1.5;
    } else {
      return 1.3;
    }
  }
}

/// Device information helper class
class _DeviceInfo {
  final Size screenSize;
  final BoxConstraints constraints;
  final Orientation orientation;
  final bool isTablet;
  final bool isCompactiPhone;
  final bool isLargeiPhone;
  final bool isLandscape;

  _DeviceInfo({
    required this.screenSize,
    required this.constraints,
    required this.orientation,
    required this.isTablet,
    required this.isCompactiPhone,
    required this.isLargeiPhone,
    required this.isLandscape,
  });
}
