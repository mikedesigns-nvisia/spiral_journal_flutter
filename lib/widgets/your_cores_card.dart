import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/services/accessibility_service.dart';
import 'package:spiral_journal/services/core_visual_consistency_service.dart';
import 'package:spiral_journal/services/core_animation_service.dart';

import 'package:spiral_journal/services/core_navigation_context_service.dart';
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/widgets/base_card.dart';
import 'package:spiral_journal/widgets/resonance_depth_visualizer.dart';

class YourCoresCard extends StatefulWidget {
  const YourCoresCard({super.key});

  @override
  State<YourCoresCard> createState() => _YourCoresCardState();
}

class _YourCoresCardState extends State<YourCoresCard> 
    with TickerProviderStateMixin {
  late final CoreNavigationContextService _navigationService;
  late final AccessibilityService _accessibilityService;
  late final CoreVisualConsistencyService _visualConsistencyService;
  late final CoreAnimationService _animationService;
  late final Map<String, AnimationController> _updateAnimationControllers;
  late final Map<String, Animation<double>> _pulseAnimations;
  late final Map<String, Animation<double>> _progressAnimations;
  late final Map<String, FocusNode> _coreFocusNodes;
  late final AnimationTimingConfig _animationTiming;
  late final CoreSpacingConfig _spacingConfig;

  @override
  void initState() {
    super.initState();
    _navigationService = CoreNavigationContextService();
    _accessibilityService = AccessibilityService();
    _visualConsistencyService = CoreVisualConsistencyService();
    _animationService = CoreAnimationService();
    _updateAnimationControllers = {};
    _pulseAnimations = {};
    _progressAnimations = {};
    _coreFocusNodes = {};
    
    // Initialize accessibility service
    _accessibilityService.initialize();
    
    // Get consistent animation timing and spacing
    _animationTiming = _visualConsistencyService.getAnimationTiming();
    _spacingConfig = _visualConsistencyService.getSpacingConfig();
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _updateAnimationControllers.values) {
      controller.dispose();
    }
    // Dispose focus nodes
    for (final focusNode in _coreFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your personality cores section',
      hint: 'Shows your active emotional patterns and growth progress',
      child: BaseCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section using standardized component with accessibility
            Semantics(
              header: true,
              label: 'Your Cores section header',
              child: CardHeader(
                icon: Icons.auto_awesome_rounded,
                title: 'Your Cores',
              ),
            ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Subtitle with consistent styling and accessibility
          Semantics(
            label: 'Active emotional patterns shaping your mindset',
            excludeSemantics: true,
            child: Text(
              'Active emotional patterns shaping your mindset',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.getTextSecondary(context),
              ),
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Core items using Provider
          Consumer<CoreProvider>(
            builder: (context, coreProvider, child) {
              if (coreProvider.isLoading) {
                return _visualConsistencyService.buildCoreLoadingState(
                  context,
                  loadingText: 'Loading your personality cores...',
                );
              } else if (coreProvider.topCores.isEmpty) {
                return Semantics(
                  label: 'No cores available yet. Start journaling to develop your personality cores.',
                  hint: 'Write your first journal entry to begin tracking your emotional growth',
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.spaceXL),
                      child: Text(
                        'Start journaling to develop your cores!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.getTextTertiary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              } else {
                return Column(
                  children: coreProvider.topCores.asMap().entries.map((entry) {
                    final index = entry.key;
                    final core = entry.value;
                    final isLast = index == coreProvider.topCores.length - 1;
                    
                    return Column(
                      children: [
                        if (index > 0) 
                          _buildCoreConnectionLine(
                            coreProvider.topCores[index - 1],
                            core,
                          ),
                        _buildCoreItem(
                          context,
                          core,
                          index,
                        ),
                        if (!isLast) SizedBox(height: DesignTokens.spaceL),
                      ],
                    );
                  }).toList(),
                );
              }
            },
          ),
          
          // Real-time update stream listener
          StreamBuilder<CoreUpdateEvent>(
            stream: context.read<CoreProvider>().coreUpdateStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final event = snapshot.data!;
                _handleCoreUpdateEvent(event);
              }
              return const SizedBox.shrink();
            },
          ),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Footer section using standardized component with accessibility
          Semantics(
            button: true,
            label: _accessibilityService.getCoreNavigationSemanticLabel(
              'Explore all cores',
              null,
              'journal',
            ),
            hint: _accessibilityService.getCoreInteractionHint('explore_all', null),
            onTap: () => _onExploreAllPressed(context),
            child: CardFooter(
              description: 'Based on your journal patterns',
              ctaText: 'Explore All',
              onCtaPressed: () => _onExploreAllPressed(context),
            ),
          ),
        ],
      ),
    ),
  );
  }

  // Keyboard event handler for core items
  KeyEventResult _handleCoreKeyEvent(KeyEvent event, EmotionalCore core) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _onCorePressed(context, core);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // Context-aware navigation methods
  Future<void> _onCorePressed(BuildContext context, EmotionalCore core) async {
    // Provide contextual haptic feedback
    _animationService.provideHapticFeedback(CoreInteractionType.coreSelection);
    
    // Announce navigation to screen reader
    _accessibilityService.announceToScreenReader(
      'Navigating to ${core.name} core details',
      assertiveness: Assertiveness.polite,
    );
    
    // Create navigation context for journal-to-core navigation
    final navigationContext = _navigationService.createJournalToCoreContext(
      targetCoreId: core.id,
      triggeredBy: 'core_tap',
    );
    
    // Store the context in the navigation service so CoreLibraryScreen can access it
    _navigationService.preserveContext(navigationContext);
    
    // Navigate to core library and highlight the specific core
    NavigationService.instance.switchToTab(NavigationService.insightsTab);
  }
  
  Future<void> _onExploreAllPressed(BuildContext context) async {
    // Provide contextual haptic feedback
    _animationService.provideHapticFeedback(CoreInteractionType.navigation);
    
    // Announce navigation to screen reader
    _accessibilityService.announceToScreenReader(
      'Navigating to explore all personality cores',
      assertiveness: Assertiveness.polite,
    );
    
    // Get current top cores for highlighting
    final coreProvider = context.read<CoreProvider>();
    final highlightCoreIds = coreProvider.topCores.map((c) => c.id).toList();
    
    // Create navigation context for "Explore All"
    final navigationContext = _navigationService.createExploreAllContext(
      highlightCoreIds: highlightCoreIds,
    );
    
    // Store the context in the navigation service so CoreLibraryScreen can access it
    _navigationService.preserveContext(navigationContext);
    
    // Navigate to the existing Core Library tab instead of pushing a new screen
    NavigationService.instance.switchToTab(NavigationService.insightsTab);
  }
  
  // Real-time update handling
  void _handleCoreUpdateEvent(CoreUpdateEvent event) {
    if (!mounted) return;
    
    switch (event.type) {
      case CoreUpdateEventType.levelChanged:
        _animateLevelChange(event.coreId, event.data);
        break;
      case CoreUpdateEventType.trendChanged:
        _animateTrendChange(event.coreId, event.data);
        break;
      case CoreUpdateEventType.milestoneAchieved:
        _animateMilestoneAchievement(event.coreId, event.data);
        break;
      case CoreUpdateEventType.analysisCompleted:
        _animateAnalysisCompletion(event.coreId, event.data);
        break;
      default:
        break;
    }
  }
  
  void _animateLevelChange(String coreId, Map<String, dynamic> data) {
    final controller = _getOrCreateAnimationController(coreId);
    final previousLevel = data['previousLevel'] as double? ?? 0.0;
    final newLevel = data['newLevel'] as double? ?? 0.0;
    
    // Find the core name for accessibility announcement
    final coreProvider = context.read<CoreProvider>();
    final core = coreProvider.topCores.firstWhere(
      (c) => c.id == coreId,
      orElse: () => EmotionalCore(
        id: coreId,
        name: 'Core',
        description: 'Core description',
        currentLevel: newLevel,
        previousLevel: previousLevel,
        trend: 'stable',
        color: '#865219',
        iconPath: 'assets/icons/core.png',
        insight: 'Core insight',
        lastUpdated: DateTime.now(),
        relatedCores: [],
      ),
    );
    
    // Announce level change to screen reader
    _accessibilityService.announceCoreUpdate(
      core.name,
      'level_changed',
      {
        'newLevel': newLevel,
        'previousLevel': previousLevel,
        'change': newLevel - previousLevel,
      },
    );
    
    // Create progress animation (respecting reduced motion)
    final animationDuration = _accessibilityService.getAnimationDuration(
      const Duration(milliseconds: 800),
    );
    
    final progressAnimation = Tween<double>(
      begin: previousLevel,
      end: newLevel,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _accessibilityService.getAnimationCurve(Curves.easeInOutCubic),
    ));
    
    _progressAnimations[coreId] = progressAnimation;
    
    // Start animation
    controller.duration = animationDuration;
    controller.forward(from: 0.0);
  }
  
  void _animateTrendChange(String coreId, Map<String, dynamic> data) {
    final controller = _getOrCreateAnimationController(coreId);
    final newTrend = data['newTrend'] as String?;
    
    // Find the core name for accessibility announcement
    final coreProvider = context.read<CoreProvider>();
    final core = coreProvider.topCores.firstWhere(
      (c) => c.id == coreId,
      orElse: () => EmotionalCore(
        id: coreId,
        name: 'Core',
        description: 'Core description',
        currentLevel: 0.0,
        previousLevel: 0.0,
        trend: newTrend ?? 'stable',
        color: '#865219',
        iconPath: 'assets/icons/core.png',
        insight: 'Core insight',
        lastUpdated: DateTime.now(),
        relatedCores: [],
      ),
    );
    
    // Announce trend change to screen reader
    _accessibilityService.announceCoreUpdate(
      core.name,
      'trend_changed',
      {'newTrend': newTrend},
    );
    
    // Create different pulse animations based on trend (respecting reduced motion)
    late final Animation<double> pulseAnimation;
    
    if (_accessibilityService.reducedMotionMode) {
      // Minimal animation for reduced motion
      pulseAnimation = Tween<double>(
        begin: 1.0,
        end: 1.02,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));
    } else {
      switch (newTrend) {
        case 'rising':
          // Energetic pulse for rising trend
          pulseAnimation = Tween<double>(
            begin: 1.0,
            end: 1.25,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          ));
          break;
        case 'declining':
          // Subtle pulse for declining trend
          pulseAnimation = Tween<double>(
            begin: 1.0,
            end: 1.1,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOut,
          ));
          break;
        default:
          // Standard pulse for stable trend
          pulseAnimation = Tween<double>(
            begin: 1.0,
            end: 1.15,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOutCubic,
          ));
      }
    }
    
    _pulseAnimations[coreId] = pulseAnimation;
    
    // Provide appropriate haptic feedback (respecting accessibility settings)
    if (!_accessibilityService.reducedMotionMode) {
      if (newTrend == 'rising') {
        HapticFeedback.lightImpact();
      } else if (newTrend == 'declining') {
        HapticFeedback.selectionClick();
      }
    }
    
    // Start pulse animation with accessibility-aware duration
    final animationDuration = _accessibilityService.getAnimationDuration(
      const Duration(milliseconds: 600),
    );
    controller.duration = animationDuration;
    
    controller.forward(from: 0.0).then((_) {
      controller.reverse();
    });
  }
  
  void _animateMilestoneAchievement(String coreId, Map<String, dynamic> data) {
    final controller = _getOrCreateAnimationController(coreId);
    
    // Find the core name for accessibility announcement
    final coreProvider = context.read<CoreProvider>();
    final core = coreProvider.topCores.firstWhere(
      (c) => c.id == coreId,
      orElse: () => EmotionalCore(
        id: coreId,
        name: 'Core',
        description: 'Core description',
        currentLevel: 0.0,
        previousLevel: 0.0,
        trend: 'stable',
        color: '#865219',
        iconPath: 'assets/icons/core.png',
        insight: 'Core insight',
        lastUpdated: DateTime.now(),
        relatedCores: [],
      ),
    );
    
    // Announce milestone achievement to screen reader
    _accessibilityService.announceCoreUpdate(
      core.name,
      'milestone_achieved',
      data,
    );
    
    // Create celebration animation (respecting reduced motion)
    final celebrationAnimation = _accessibilityService.reducedMotionMode
        ? Tween<double>(
            begin: 1.0,
            end: 1.05,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.linear,
          ))
        : Tween<double>(
            begin: 1.0,
            end: 1.3,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.bounceOut,
          ));
    
    _pulseAnimations[coreId] = celebrationAnimation;
    
    // Provide haptic feedback for milestone (respecting accessibility settings)
    if (!_accessibilityService.reducedMotionMode) {
      HapticFeedback.mediumImpact();
    }
    
    // Start celebration animation with accessibility-aware duration
    final animationDuration = _accessibilityService.getAnimationDuration(
      const Duration(milliseconds: 1200),
    );
    controller.duration = animationDuration;
    
    controller.forward(from: 0.0).then((_) {
      controller.reverse();
    });
  }
  
  void _animateAnalysisCompletion(String coreId, Map<String, dynamic> data) {
    final controller = _getOrCreateAnimationController(coreId);
    
    // Create subtle pulse for analysis completion
    final pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimations[coreId] = pulseAnimation;
    
    // Start subtle animation
    controller.forward(from: 0.0).then((_) {
      controller.reverse();
    });
  }
  
  AnimationController _getOrCreateAnimationController(String coreId) {
    if (!_updateAnimationControllers.containsKey(coreId)) {
      _updateAnimationControllers[coreId] = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
    }
    return _updateAnimationControllers[coreId]!;
  }

  Widget _buildCoreItem(
    BuildContext context,
    EmotionalCore core,
    int index,
  ) {
    final coreColor = _getCoreColor(core.color);
    final icon = _getCoreIcon(core.name);
    
    // Get animations for this core
    final pulseAnimation = _pulseAnimations[core.id];
    
    // Check if this core has recent updates
    final hasRecentUpdate = _hasRecentUpdate(core);
    final recentChangeIndicator = _buildRecentChangeIndicator(core);
    
    // Get or create focus node for this core
    final focusNode = _coreFocusNodes.putIfAbsent(
      core.id,
      () => _accessibilityService.createAccessibleFocusNode(
        debugLabel: '${core.name} core item',
      ),
    );
    
    // Create comprehensive semantic label for resonance depth
    final semanticLabel = _accessibilityService.getCoreCardSemanticLabel(
      core.name,
      core.currentLevel,
      core.previousLevel,
      core.trend,
      hasRecentUpdate,
    );
    
    final semanticHint = _accessibilityService.getCoreInteractionHint(
      'view_details',
      core.name,
    );

    return AnimatedBuilder(
      animation: pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: _accessibilityService.reducedMotionMode 
              ? 1.0 
              : (pulseAnimation?.value ?? 1.0),
          child: Semantics(
            button: true,
            focusable: true,
            focused: focusNode.hasFocus,
            label: semanticLabel,
            hint: semanticHint,
            onTap: () => _onCorePressed(context, core),
            child: Focus(
              focusNode: focusNode,
              onKeyEvent: (node, event) => _handleCoreKeyEvent(event, core),
              child: GestureDetector(
                onTap: () => _onCorePressed(context, core),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: _accessibilityService.getMinimumTouchTargetSize(),
                  ),
                  padding: EdgeInsets.all(DesignTokens.spaceM),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DesignTokens.getColorWithOpacity(coreColor, 0.1),
                        DesignTokens.getColorWithOpacity(coreColor, 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    border: Border.all(
                      color: DesignTokens.getColorWithOpacity(
                        coreColor, 
                        hasRecentUpdate ? 0.6 : 0.3,
                      ),
                      width: hasRecentUpdate ? 2.0 : 1.0,
                    ),
                    boxShadow: hasRecentUpdate ? [
                      BoxShadow(
                        color: DesignTokens.getColorWithOpacity(coreColor, 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          // Resonance Depth Visualizer (compact)
                          ResonanceDepthVisualizer(
                            core: core,
                            size: 40,
                            showLabel: false,
                            showProgress: false,
                            isCompact: true,
                          ),
                          SizedBox(width: DesignTokens.spaceM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  core.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.getTextPrimary(context),
                                  ),
                                ),
                                SizedBox(height: DesignTokens.spaceXS),
                                Text(
                                  core.resonanceDepth.displayName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: coreColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Trend indicator
                          _buildTrendArrow(core),
                        ],
                      ),
                      // Recent update indicator
                      if (hasRecentUpdate)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: recentChangeIndicator,
                        ),
                      // Journal connection indicator
                      if (_hasJournalConnection(core))
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: _buildJournalConnectionIndicator(core),
                        ),
                      // Transition indicator
                      if (core.isTransitioning)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceS,
                              vertical: DesignTokens.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getAccentColor(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                              border: Border.all(
                                color: AppTheme.getAccentColor(context).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Transitioning',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.getAccentColor(context),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProgressBar(EmotionalCore core, Animation<double>? progressAnimation) {
    final progress = progressAnimation?.value ?? core.currentLevel;
    final coreColor = _getCoreColor(core.color);
    final hasRecentChange = _hasRecentUpdate(core);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar with gradient and animation
        Container(
          height: hasRecentChange ? 6 : 4,
          decoration: BoxDecoration(
            color: DesignTokens.getColorWithOpacity(coreColor, 0.15),
            borderRadius: BorderRadius.circular(hasRecentChange ? 3 : 2),
          ),
          child: Stack(
            children: [
              // Main progress bar
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        coreColor.withValues(alpha: 0.8),
                        coreColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(hasRecentChange ? 3 : 2),
                    boxShadow: hasRecentChange ? [
                      BoxShadow(
                        color: coreColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ] : null,
                  ),
                ),
              ),
              // Shimmer effect for recent updates
              if (hasRecentChange)
                Positioned.fill(
                  child: _buildProgressShimmer(coreColor),
                ),
            ],
          ),
        ),
        SizedBox(height: DesignTokens.spaceXS),
        // Progress details row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Level indicator with trend arrow
            Row(
              children: [
                Text(
                  'Level ${(progress * 10).round()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.getTextSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceXS),
                _buildTrendArrow(core),
              ],
            ),
            // Percentage change indicator
            if (_getPercentageChange(core) != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getTrendColor(core.trend).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  _getPercentageChange(core)!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getTrendColor(core.trend),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildProgressShimmer(Color coreColor) {
    return AnimatedBuilder(
      animation: _getOrCreateAnimationController('shimmer'),
      builder: (context, child) {
        final controller = _getOrCreateAnimationController('shimmer');
        if (!controller.isAnimating) {
          controller.repeat(period: const Duration(seconds: 2));
        }
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                coreColor.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: [
                (controller.value - 0.3).clamp(0.0, 1.0),
                controller.value,
                (controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }
  
  Widget _buildRecentChangeIndicator(EmotionalCore core) {
    final trendColor = _getTrendColor(core.trend);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing outer ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 1500),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          // Inner indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: trendColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: trendColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Subtle badge for core affected by recent journal
          if (_hasJournalConnection(core))
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryOrange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildJournalConnectionIndicator(EmotionalCore core) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primaryOrange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_rounded,
            size: 10,
            color: Colors.white,
          ),
          SizedBox(width: 2),
          Text(
            'Updated',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  // Enhanced method to create color-coded trend arrows
  Widget _buildTrendArrow(EmotionalCore core) {
    final trendColor = _getTrendColor(core.trend);
    IconData trendIcon;
    
    switch (core.trend) {
      case 'rising':
        trendIcon = Icons.trending_up_rounded;
        break;
      case 'declining':
        trendIcon = Icons.trending_down_rounded;
        break;
      default:
        trendIcon = Icons.trending_flat_rounded;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(DesignTokens.spaceXS),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        trendIcon,
        size: DesignTokens.iconSizeS,
        color: trendColor,
      ),
    );
  }
  
  // Visual connection lines between related cores
  Widget _buildCoreConnectionLine(EmotionalCore previousCore, EmotionalCore currentCore) {
    final hasConnection = _coresAreRelated(previousCore, currentCore);
    final connectionStrength = _getConnectionStrength(previousCore, currentCore);
    
    if (!hasConnection) {
      return SizedBox(height: DesignTokens.spaceL);
    }
    
    return SizedBox(
      height: DesignTokens.spaceL,
      child: Stack(
        children: [
          // Connection line
          Positioned(
            left: DesignTokens.spaceXL + DesignTokens.spaceM + (DesignTokens.iconSizeM / 2),
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getCoreColor(previousCore.color).withValues(alpha: 0.3),
                    _getCoreColor(currentCore.color).withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          // Connection strength indicator
          if (connectionStrength > 0.5)
            Positioned(
              left: DesignTokens.spaceXL + DesignTokens.spaceM + (DesignTokens.iconSizeM / 2) - 3,
              top: (DesignTokens.spaceL / 2) - 3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryOrange.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Check if two cores are related
  bool _coresAreRelated(EmotionalCore core1, EmotionalCore core2) {
    // Check if cores share related core IDs
    final core1Related = core1.relatedCores.toSet();
    final core2Related = core2.relatedCores.toSet();
    
    // Check if either core references the other, or they share common related cores
    return core1Related.contains(core2.id) ||
           core2Related.contains(core1.id) ||
           core1Related.intersection(core2Related).isNotEmpty;
  }
  
  // Calculate connection strength between cores
  double _getConnectionStrength(EmotionalCore core1, EmotionalCore core2) {
    if (!_coresAreRelated(core1, core2)) return 0.0;
    
    // Base connection strength
    double strength = 0.3;
    
    // Increase strength if cores directly reference each other
    if (core1.relatedCores.contains(core2.id) || 
        core2.relatedCores.contains(core1.id)) {
      strength += 0.4;
    }
    
    // Increase strength based on similar trends
    if (core1.trend == core2.trend) {
      strength += 0.2;
    }
    
    // Increase strength based on recent updates
    if (_hasRecentUpdate(core1) && _hasRecentUpdate(core2)) {
      strength += 0.1;
    }
    
    return strength.clamp(0.0, 1.0);
  }
  
  // Helper methods
  bool _hasRecentUpdate(EmotionalCore core) {
    final now = DateTime.now();
    final timeDifference = now.difference(core.lastUpdated);
    return timeDifference.inMinutes < 30; // Consider updates within 30 minutes as recent
  }
  
  bool _hasJournalConnection(EmotionalCore core) {
    // Check if this core was recently affected by journal analysis
    final coreProvider = context.read<CoreProvider>();
    final coreContext = coreProvider.coreContexts[core.id];
    
    if (coreContext?.relatedJournalEntryIds.isNotEmpty == true) {
      // Check if any related journal entries are recent (within last 24 hours)
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24));
      return core.lastUpdated.isAfter(cutoff);
    }
    
    return false;
  }
  
  String? _getPercentageChange(EmotionalCore core) {
    final change = core.currentLevel - core.previousLevel;
    if (change.abs() < 0.01) return null; // No significant change
    
    final changePercent = (change * 100).round();
    return changePercent > 0 ? '+$changePercent%' : '$changePercent%';
  }
  
  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising':
        return DesignTokens.accentGreen;
      case 'declining':
        return DesignTokens.accentRed;
      default:
        return DesignTokens.primaryOrange;
    }
  }

  Color _getCoreColor(String colorHex) {
    try {
      // Remove # if present and ensure it's 6 characters
      final cleanHex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (e) {
      return AppTheme.primaryOrange; // Fallback color
    }
  }

  IconData _getCoreIcon(String coreName) {
    switch (coreName.toLowerCase()) {
      case 'optimism':
        return Icons.wb_sunny_rounded; // Bright sun for optimism
      case 'resilience':
        return Icons.security_rounded; // Strong security shield for resilience
      case 'self-awareness':
        return Icons.psychology_rounded; // Brain/mind icon for self-awareness
      case 'creativity':
        return Icons.lightbulb_rounded; // Light bulb for creative ideas
      case 'social connection':
        return Icons.groups_rounded; // Multiple people for social connection
      case 'growth mindset':
        return Icons.escalator_warning_rounded; // Upward movement for growth
      case 'confidence':
        return Icons.emoji_events_rounded; // Trophy for confidence/achievement
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}