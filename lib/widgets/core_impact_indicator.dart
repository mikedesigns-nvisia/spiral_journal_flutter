import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/core.dart';
import '../models/journal_entry.dart';
import '../design_system/design_tokens.dart';
import '../services/accessibility_service.dart';

/// Widget that shows how recent journal entries have affected cores
class CoreImpactIndicator extends StatefulWidget {
  final EmotionalCore core;
  final JournalEntry? relatedEntry;
  final double impactValue; // -1.0 to 1.0 (negative = decline, positive = growth)
  final bool showAnimation;
  final VoidCallback? onTap;

  const CoreImpactIndicator({
    super.key,
    required this.core,
    this.relatedEntry,
    required this.impactValue,
    this.showAnimation = true,
    this.onTap,
  });

  @override
  State<CoreImpactIndicator> createState() => _CoreImpactIndicatorState();
}

class _CoreImpactIndicatorState extends State<CoreImpactIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late AccessibilityService _accessibilityService;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _accessibilityService = AccessibilityService();
    _focusNode = _accessibilityService.createAccessibleFocusNode(
      debugLabel: '${widget.core.name} impact indicator',
    );
    _initializeAnimations();
    if (widget.showAnimation) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    // Respect reduced motion accessibility setting
    final animationDuration = _accessibilityService.getAnimationDuration(
      const Duration(milliseconds: 800),
    );
    _slideController.duration = animationDuration;
    _slideController.forward();
    
    // Start pulse animation for significant impacts (respecting accessibility)
    if (widget.impactValue.abs() > 0.3 && !_accessibilityService.reducedMotionMode) {
      _pulseController.repeat(reverse: true);
    }
    
    // Announce impact to screen reader
    final relatedContext = widget.relatedEntry != null ? 'recent journal entry' : null;
    final impactLabel = _accessibilityService.getCoreImpactSemanticLabel(
      widget.core.name,
      widget.impactValue,
      relatedContext,
    );
    _accessibilityService.announceToScreenReader(
      impactLabel,
      assertiveness: Assertiveness.polite,
    );
  }

  @override
  void didUpdateWidget(CoreImpactIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Restart animations if impact value changed significantly
    if ((widget.impactValue - oldWidget.impactValue).abs() > 0.1) {
      if (widget.showAnimation) {
        _slideController.reset();
        _slideController.forward();
        
        if (widget.impactValue.abs() > 0.3) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _getImpactColor() {
    if (widget.impactValue > 0.1) {
      return DesignTokens.successColor;
    } else if (widget.impactValue < -0.1) {
      return DesignTokens.warningColor;
    } else {
      return DesignTokens.neutralColor;
    }
  }

  IconData _getImpactIcon() {
    if (widget.impactValue > 0.1) {
      return Icons.trending_up;
    } else if (widget.impactValue < -0.1) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  String _getImpactText() {
    final absValue = widget.impactValue.abs();
    
    if (absValue < 0.1) {
      return 'Stable';
    } else if (absValue < 0.3) {
      return widget.impactValue > 0 ? 'Growing' : 'Declining';
    } else if (absValue < 0.6) {
      return widget.impactValue > 0 ? 'Strong Growth' : 'Notable Decline';
    } else {
      return widget.impactValue > 0 ? 'Major Growth' : 'Significant Decline';
    }
  }

  // Handle keyboard navigation
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (widget.onTap != null) {
          // Provide haptic feedback (respecting accessibility settings)
          if (!_accessibilityService.reducedMotionMode) {
            HapticFeedback.lightImpact();
          }
          widget.onTap!();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Create comprehensive semantic label
    final relatedContext = widget.relatedEntry != null ? 'recent journal entry' : null;
    final semanticLabel = _accessibilityService.getCoreImpactSemanticLabel(
      widget.core.name,
      widget.impactValue,
      relatedContext,
    );
    
    final semanticHint = widget.onTap != null 
        ? 'Double tap to view ${widget.core.name} core details'
        : null;

    return Semantics(
      button: widget.onTap != null,
      focusable: true,
      focused: _focusNode.hasFocus,
      label: semanticLabel,
      hint: semanticHint,
      onTap: widget.onTap,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) => _handleKeyEvent(event),
        child: GestureDetector(
          onTap: () {
            if (widget.onTap != null) {
              // Provide haptic feedback (respecting accessibility settings)
              if (!_accessibilityService.reducedMotionMode) {
                HapticFeedback.lightImpact();
              }
              widget.onTap!();
            }
          },
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final scale = _accessibilityService.reducedMotionMode 
                      ? 1.0 
                      : _pulseAnimation.value;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: _accessibilityService.getMinimumTouchTargetSize(),
                        minWidth: _accessibilityService.getMinimumTouchTargetSize(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing3,
                        vertical: _accessibilityService.getAccessibleSpacing(),
                      ),
                      decoration: BoxDecoration(
                        color: _getImpactColor().withOpacity(
                          _accessibilityService.highContrastMode ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
                        border: Border.all(
                          color: _getImpactColor().withOpacity(
                            _accessibilityService.highContrastMode ? 0.8 : 0.3,
                          ),
                          width: _accessibilityService.highContrastMode ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Core indicator with semantic meaning
                          Semantics(
                            label: '${widget.core.name} core indicator',
                            excludeSemantics: true,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(int.parse(widget.core.color.replaceFirst('#', '0xFF'))),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.psychology,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          
                          SizedBox(width: _accessibilityService.getAccessibleSpacing()),
                          
                          // Impact indicator with semantic meaning
                          Semantics(
                            label: '${_getImpactText()} trend',
                            excludeSemantics: true,
                            child: Icon(
                              _getImpactIcon(),
                              size: 16,
                              color: _getImpactColor(),
                            ),
                          ),
                          
                          const SizedBox(width: DesignTokens.spacing1),
                          
                          // Impact text with accessible styling
                          Text(
                            _getImpactText(),
                            style: _accessibilityService.getAccessibleTextStyles(context).bodySmall?.copyWith(
                              color: _getImpactColor(),
                              fontWeight: _accessibilityService.highContrastMode 
                                  ? FontWeight.bold 
                                  : FontWeight.w600,
                            ),
                          ),
                          
                          // Impact value with accessible formatting
                          if (widget.impactValue.abs() > 0.1) ...[
                            const SizedBox(width: DesignTokens.spacing1),
                            Text(
                              '${widget.impactValue > 0 ? '+' : ''}${(widget.impactValue * 100).toStringAsFixed(0)}%',
                              style: _accessibilityService.getAccessibleTextStyles(context).bodySmall?.copyWith(
                                color: _getImpactColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Widget that shows multiple core impacts from a journal entry
class JournalCoreImpactSummary extends StatelessWidget {
  final JournalEntry journalEntry;
  final List<EmotionalCore> affectedCores;
  final Map<String, double> coreImpacts;
  final bool showAnimation;
  final Function(String coreId)? onCoreImpactTap;

  const JournalCoreImpactSummary({
    super.key,
    required this.journalEntry,
    required this.affectedCores,
    required this.coreImpacts,
    this.showAnimation = true,
    this.onCoreImpactTap,
  });

  @override
  Widget build(BuildContext context) {
    if (coreImpacts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort cores by impact magnitude
    final sortedCores = affectedCores.where((core) {
      final impact = coreImpacts[core.id] ?? 0.0;
      return impact.abs() > 0.05; // Only show meaningful impacts
    }).toList();

    sortedCores.sort((a, b) {
      final impactA = (coreImpacts[a.id] ?? 0.0).abs();
      final impactB = (coreImpacts[b.id] ?? 0.0).abs();
      return impactB.compareTo(impactA);
    });

    if (sortedCores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing3),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceColor,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius3),
        border: Border.all(
          color: DesignTokens.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 20,
                color: DesignTokens.primaryColor,
              ),
              const SizedBox(width: DesignTokens.spacing2),
              Text(
                'Core Impact from Journal',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.spacing3),
          
          // Core impacts
          Wrap(
            spacing: DesignTokens.spacing2,
            runSpacing: DesignTokens.spacing2,
            children: sortedCores.map((core) {
              final impact = coreImpacts[core.id] ?? 0.0;
              return CoreImpactIndicator(
                core: core,
                relatedEntry: journalEntry,
                impactValue: impact,
                showAnimation: showAnimation,
                onTap: () => onCoreImpactTap?.call(core.id),
              );
            }).toList(),
          ),
          
          // Summary text
          if (sortedCores.length > 1) ...[
            const SizedBox(height: DesignTokens.spacing3),
            Text(
              _generateSummaryText(sortedCores.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignTokens.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _generateSummaryText(int affectedCount) {
    if (affectedCount == 1) {
      return 'Your journal entry influenced 1 core area of growth.';
    } else {
      return 'Your journal entry influenced $affectedCount core areas of growth.';
    }
  }
}