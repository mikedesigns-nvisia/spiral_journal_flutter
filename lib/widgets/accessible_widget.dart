import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';

/// Accessible widget wrapper that provides comprehensive accessibility support.
/// 
/// This widget wraps other widgets to provide:
/// - Semantic labels and descriptions
/// - Keyboard navigation support
/// - Focus management
/// - Screen reader compatibility
/// - Touch target size optimization
/// 
/// ## Usage Example
/// ```dart
/// AccessibleWidget(
///   semanticLabel: 'Save journal entry',
///   semanticHint: 'Double tap to save your journal entry',
///   onTap: () => saveEntry(),
///   child: ElevatedButton(
///     onPressed: () => saveEntry(),
///     child: Text('Save'),
///   ),
/// )
/// ```
class AccessibleWidget extends StatefulWidget {
  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final String? semanticValue;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFocusChange;
  final bool focusable;
  final bool autoFocus;
  final FocusNode? focusNode;
  final String? tooltip;
  final double? minTouchTargetSize;
  final EdgeInsets? padding;
  final bool enableKeyboardNavigation;
  final List<LogicalKeyboardKey>? activationKeys;

  const AccessibleWidget({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.semanticValue,
    this.excludeSemantics = false,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.focusable = true,
    this.autoFocus = false,
    this.focusNode,
    this.tooltip,
    this.minTouchTargetSize,
    this.padding,
    this.enableKeyboardNavigation = true,
    this.activationKeys,
  });

  @override
  State<AccessibleWidget> createState() => _AccessibleWidgetState();
}

class _AccessibleWidgetState extends State<AccessibleWidget> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChange?.call();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (!widget.enableKeyboardNavigation) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      final activationKeys = widget.activationKeys ?? [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
      ];

      if (activationKeys.contains(event.logicalKey)) {
        widget.onTap?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Build the widget tree from inside out to avoid circular references
    Widget result = widget.child;

    // Apply minimum touch target size
    final minSize = widget.minTouchTargetSize ?? 
                   _accessibilityService.getMinimumTouchTargetSize();
    
    result = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: result,
    );

    // Apply padding if specified
    if (widget.padding != null) {
      result = Padding(
        padding: widget.padding!,
        child: result,
      );
    }

    // Add gesture detection
    if (widget.onTap != null || widget.onLongPress != null) {
      result = GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: result,
      );
    }

    // Add tooltip if specified
    if (widget.tooltip != null) {
      result = Tooltip(
        message: widget.tooltip!,
        child: result,
      );
    }

    // Add focus and keyboard handling - simplified approach
    if (widget.focusable) {
      result = Focus(
        focusNode: _focusNode,
        autofocus: widget.autoFocus,
        onKeyEvent: (node, event) {
          return _handleKeyEvent(event);
        },
        child: Container(
          decoration: _isFocused ? BoxDecoration(
            border: Border.all(
              color: Theme.of(context).focusColor,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ) : null,
          child: result,
        ),
      );
    }

    // Add semantic information
    if (!widget.excludeSemantics) {
      result = Semantics(
        label: widget.semanticLabel,
        hint: widget.semanticHint,
        value: widget.semanticValue,
        button: widget.onTap != null,
        focusable: widget.focusable,
        focused: _isFocused,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: result,
      );
    }

    return result;
  }
}

/// Accessible button with enhanced accessibility features
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? tooltip;
  final ButtonStyle? style;
  final bool autofocus;
  final FocusNode? focusNode;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.semanticLabel,
    this.tooltip,
    this.style,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      semanticHint: accessibilityService.getInteractionHint('tap'),
      onTap: onPressed,
      onLongPress: onLongPress,
      tooltip: tooltip,
      autoFocus: autofocus,
      focusNode: focusNode,
        child: ElevatedButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: style,
          focusNode: focusNode,
          autofocus: autofocus,
          child: child,
        ),
    );
  }
}

/// Accessible text field with enhanced accessibility features
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? semanticLabel;
  final String? semanticHint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;
  final InputDecoration? decoration;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.semanticLabel,
    this.semanticHint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel ?? labelText,
      semanticHint: semanticHint ?? 'Text input field',
      focusNode: focusNode,
      autoFocus: autofocus,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        onTap: onTap,
        autofocus: autofocus,
        focusNode: focusNode,
        decoration: decoration ?? InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Accessible list tile with enhanced accessibility features
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? semanticHint;
  final bool selected;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  const AccessibleListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.selected = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      semanticHint: semanticHint ?? accessibilityService.getInteractionHint('tap'),
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      autoFocus: autofocus,
      focusNode: focusNode,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        selected: selected,
        enabled: enabled,
        focusNode: focusNode,
        autofocus: autofocus,
      ),
    );
  }
}

/// Accessible icon button with enhanced accessibility features
class AccessibleIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final double? iconSize;
  final Color? color;
  final bool autofocus;
  final FocusNode? focusNode;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.iconSize,
    this.color,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel ?? tooltip,
      semanticHint: accessibilityService.getInteractionHint('tap'),
      onTap: onPressed,
      tooltip: tooltip,
      autoFocus: autofocus,
      focusNode: focusNode,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        iconSize: iconSize,
        color: color,
        tooltip: tooltip,
        focusNode: focusNode,
        autofocus: autofocus,
      ),
    );
  }
}

/// Accessible card with enhanced accessibility features
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final bool autofocus;
  final FocusNode? focusNode;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.color,
    this.elevation,
    this.margin,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return AccessibleWidget(
      semanticLabel: semanticLabel,
      semanticHint: semanticHint ?? (onTap != null ? 
          accessibilityService.getInteractionHint('tap') : null),
      onTap: onTap,
      onLongPress: onLongPress,
      autoFocus: autofocus,
      focusNode: focusNode,
      child: Card(
        color: color,
        elevation: elevation,
        margin: margin,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: child,
        ),
      ),
    );
  }
}
