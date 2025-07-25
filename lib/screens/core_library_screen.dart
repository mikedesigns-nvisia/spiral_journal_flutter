import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/core.dart';
import '../models/core_error.dart';
import '../models/journal_entry.dart';
import '../providers/core_provider_refactored.dart';
import '../providers/journal_provider.dart';
import '../services/core_navigation_context_service.dart';
import '../services/accessibility_service.dart';
import '../services/core_visual_consistency_service.dart';

class CoreLibraryScreen extends StatefulWidget {
  final CoreNavigationContext? navigationContext;
  
  const CoreLibraryScreen({
    super.key,
    this.navigationContext,
  });

  @override
  State<CoreLibraryScreen> createState() => _CoreLibraryScreenState();
}

class _CoreLibraryScreenState extends State<CoreLibraryScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _updateAnimationController;
  late Animation<double> _pulseAnimation;
  final CoreNavigationContextService _navigationService = CoreNavigationContextService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final CoreVisualConsistencyService _visualConsistencyService = CoreVisualConsistencyService();
  
  // Track recent updates for visual indicators
  final Set<String> _recentlyUpdatedCores = <String>{};
  final Map<String, DateTime> _updateTimestamps = <String, DateTime>{};
  
  late AnimationTimingConfig _animationTiming;
  late CoreSpacingConfig _spacingConfig;
  late Map<String, CoreColorScheme> _coreColorSchemes;
  late Map<String, IconData> _coreIcons;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _accessibilityService.initialize();
    _animationTiming = _visualConsistencyService.getAnimationTiming();
    _spacingConfig = _visualConsistencyService.getSpacingConfig();
    
    // Initialize animations with consistent timing
    _animationController = AnimationController(
      duration: _animationTiming.coreTransition,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: _animationTiming.standardCurve),
    );
    
    // Initialize update animation controller for real-time updates
    _updateAnimationController = AnimationController(
      duration: _animationTiming.pulseAnimation,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0, 
      end: _accessibilityService.reducedMotionMode ? 1.02 : 1.1,
    ).animate(
      CurvedAnimation(
        parent: _updateAnimationController,
        curve: _animationTiming.standardCurve,
      ),
    );
    
    // Initialize with navigation context if provided
    if (widget.navigationContext != null) {
      _navigationService.preserveContext(widget.navigationContext!);
    }
    
    // Load core data through provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get consistent visual elements
      _coreColorSchemes = _visualConsistencyService.getCoreColorSchemes(context);
      _coreIcons = _visualConsistencyService.getCoreIcons();
      
      _loadCoreData();
      _handleInitialScreenState();
    });
  }
  
  void _handleInitialScreenState() {
    final context = widget.navigationContext;
    if (context == null) return;
    
    // Handle context-aware initial state
    if (context.targetCoreId != null) {
      // Scroll to specific core if specified
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCore(context.targetCoreId!);
      });
    }
    
    // Handle "Explore All" context from Your Cores widget
    if (context.triggeredBy == 'explore_all') {
      // Could highlight cores that were recently updated
      final highlightCoreIds = context.additionalData['highlightCoreIds'] as List<String>?;
      if (highlightCoreIds != null && highlightCoreIds.isNotEmpty) {
        // Store highlighted cores for visual emphasis
        setState(() {
          // This would be used in the UI to highlight specific cores
        });
      }
    }
  }
  
  void _scrollToCore(String coreId) {
    // For now, we'll implement a simple approach
    // In a more complex implementation, we could use a ScrollController
    // to scroll to the specific core in the grid
    debugPrint('Scrolling to core: $coreId');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCoreData() async {
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);
    
    try {
      await coreProvider.loadAllCores();
      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading core data: $e');
    }
  }
  
  Future<void> _refreshCoreData(CoreProvider coreProvider) async {
    await coreProvider.refresh(forceRefresh: true);
  }
  
  Widget _buildErrorState(CoreError error) {
    return _visualConsistencyService.buildCoreErrorState(
      context,
      title: 'Unable to Load Cores',
      message: error.message,
      onRetry: () {
        final coreProvider = Provider.of<CoreProvider>(context, listen: false);
        coreProvider.clearError();
        _loadCoreData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundPrimary(context),
      body: SafeArea(
        child: Consumer<CoreProvider>(
          builder: (context, coreProvider, child) {
            // Handle error states through CoreProvider
            if (coreProvider.error != null) {
              return _buildErrorState(coreProvider.error!);
            }
            
            // Handle loading states
            if (coreProvider.isLoading && coreProvider.allCores.isEmpty) {
              return _visualConsistencyService.buildCoreLoadingState(
                context,
                loadingText: 'Loading your core library...',
              );
            }
            
            return StreamBuilder<CoreUpdateEvent>(
              stream: coreProvider.coreUpdateStream,
              builder: (context, updateSnapshot) {
                // Handle real-time core updates
                if (updateSnapshot.hasData) {
                  _handleCoreUpdateEvent(updateSnapshot.data!);
                }
                
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: () => _refreshCoreData(coreProvider),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildCoreOverview(coreProvider.allCores),
                          const SizedBox(height: 32),
                          _buildCoreGrid(coreProvider.allCores),
                          // TODO: Implement combinations and recommendations through CoreProvider
                          // These will be added in future enhancements
                          const SizedBox(height: 100), // Extra space for bottom navigation
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final navigationContext = widget.navigationContext;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Show back button if we have navigation context
            if (navigationContext != null && _navigationService.canNavigateBack()) ...[
              IconButton(
                onPressed: () => _handleBackNavigation(),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.getColorWithOpacity(
                  AppTheme.getPrimaryColor(context), 
                  0.15
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.getPrimaryColor(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _getContextualTitle(),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getContextualSubtitle(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        // Show contextual banner if from journal
        if (navigationContext?.sourceScreen == 'journal') ...[
          const SizedBox(height: 16),
          _buildJournalContextBanner(),
        ],
      ],
    );
  }
  
  String _getContextualTitle() {
    final context = widget.navigationContext;
    if (context?.triggeredBy == 'explore_all') {
      return 'Explore All Cores';
    }
    if (context?.sourceScreen == 'journal') {
      return 'Your Core Growth';
    }
    return 'Core Library';
  }
  
  String _getContextualSubtitle() {
    final context = widget.navigationContext;
    if (context?.triggeredBy == 'explore_all') {
      return 'See how your recent journaling has influenced your personality cores';
    }
    if (context?.sourceScreen == 'journal') {
      return 'Track your emotional growth from your journal insights';
    }
    return 'Track your emotional growth across six personality cores';
  }
  
  Widget _buildJournalContextBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getPrimaryColor(context).withOpacity(0.1),
            AppTheme.getPrimaryColor(context).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories,
            color: AppTheme.getPrimaryColor(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Viewing cores influenced by your recent journal entry',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleBackNavigation() {
    if (_navigationService.canNavigateBack()) {
      _navigationService.navigateBack(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildCoreOverview(List<EmotionalCore> cores) {
    if (cores.isEmpty) return const SizedBox.shrink();
    
    final averageLevel = cores.map((c) => c.currentLevel).reduce((a, b) => a + b) / cores.length;
    final risingCores = cores.where((c) => c.trend == 'rising').length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getPrimaryColor(context).withOpacity(0.1),
            AppTheme.getPrimaryColor(context).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.getPrimaryColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Overall Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(averageLevel * 100).round()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryColor(context),
                      ),
                    ),
                    Text(
                      'Average Core Level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$risingCores',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    Text(
                      'Cores Rising',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreGrid(List<EmotionalCore> cores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Six Personality Cores',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1, // Further increased to give much more height
          ),
          itemCount: cores.length,
          itemBuilder: (context, index) {
            return _buildCoreCard(cores[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCoreCard(EmotionalCore core) {
    final color = _getCoreColor(core.color);
    final trendColor = _getTrendColor(core.trend);
    final isHighlighted = _shouldHighlightCore(core.id);
    final hasRecentUpdate = _hasRecentUpdate(core);
    
    return GestureDetector(
      onTap: () => _showCoreDetail(core),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getBackgroundSecondary(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted 
                ? color.withOpacity(0.6)
                : color.withOpacity(0.3),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHighlighted ? 0.1 : 0.05),
              blurRadius: isHighlighted ? 12 : 8,
              offset: Offset(0, isHighlighted ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Recent update indicator
            if (hasRecentUpdate) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UPDATED',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Progress Circle with animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final shouldAnimate = _recentlyUpdatedCores.contains(core.id);
                final scale = shouldAnimate ? _pulseAnimation.value : 1.0;
                
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      children: [
                        // Background circle
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.1),
                          ),
                        ),
                        // Progress circle with animated progress
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween<double>(
                            begin: core.previousLevel,
                            end: core.currentLevel,
                          ),
                          curve: Curves.easeInOutCubic,
                          builder: (context, animatedProgress, child) {
                            return CustomPaint(
                              size: const Size(70, 70),
                              painter: CircularProgressPainter(
                                progress: animatedProgress,
                                color: color,
                                strokeWidth: isHighlighted ? 6 : 5,
                              ),
                            );
                          },
                        ),
                        // Center content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getCoreIcon(core.id),
                                color: color,
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 600),
                                tween: Tween<double>(
                                  begin: core.previousLevel * 100,
                                  end: core.currentLevel * 100,
                                ),
                                curve: Curves.easeOut,
                                builder: (context, animatedValue, child) {
                                  return Text(
                                    '${animatedValue.round()}%',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Core name
            Text(
              core.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Trend indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  core.trend == 'rising' ? Icons.trending_up : 
                  core.trend == 'declining' ? Icons.trending_down : Icons.trending_flat,
                  color: trendColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  core.trend.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  void _showCoreDetail(EmotionalCore core) {
    // Create navigation context for core detail
    final detailContext = _navigationService.createContext(
      sourceScreen: 'core_library',
      triggeredBy: 'core_detail',
      targetCoreId: core.id,
      additionalData: {
        'parentContext': widget.navigationContext?.toJson(),
        'preserveReturnState': true,
      },
    );
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CoreDetailSheet(
        core: core,
        navigationContext: detailContext,
      ),
    );
  }

  Color _getCoreColor(String colorHex) {
    try {
      // Handle both formats: with or without '#' prefix
      if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } else {
        return Color(int.parse('0xFF$colorHex'));
      }
    } catch (e) {
      debugPrint('CoreLibraryScreen: Error parsing color: $colorHex, error: $e');
      return AppTheme.getPrimaryColor(context);
    }
  }

  IconData _getCoreIcon(String coreId) {
    switch (coreId) {
      case 'optimism':
        return Icons.wb_sunny;
      case 'resilience':
        return Icons.shield;
      case 'self_awareness':
        return Icons.psychology;
      case 'creativity':
        return Icons.palette;
      case 'social_connection':
        return Icons.people;
      case 'growth_mindset':
        return Icons.trending_up;
      default:
        return Icons.auto_awesome;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising':
        return AppTheme.accentGreen;
      case 'declining':
        return AppTheme.accentRed;
      default:
        return AppTheme.getTextSecondary(context);
    }
  }
  
  bool _shouldHighlightCore(String coreId) {
    final context = widget.navigationContext;
    if (context == null) return false;
    
    // Highlight if this core is the target
    if (context.targetCoreId == coreId) return true;
    
    // Highlight if this core is in the highlight list
    final highlightIds = context.additionalData['highlightCoreIds'] as List<String>?;
    return highlightIds?.contains(coreId) ?? false;
  }
  
  bool _hasRecentUpdate(EmotionalCore core) {
    // Check if core is in recently updated set
    if (_recentlyUpdatedCores.contains(core.id)) {
      return true;
    }
    
    // Also check navigation context for journal source
    final context = widget.navigationContext;
    if (context?.sourceScreen != 'journal') return false;
    
    // Check if core was updated recently (within last hour)
    final now = DateTime.now();
    final timeDifference = now.difference(core.lastUpdated);
    return timeDifference.inHours < 1;
  }
  
  void _handleCoreUpdateEvent(CoreUpdateEvent event) {
    switch (event.type) {
      case CoreUpdateEventType.levelChanged:
        _handleLevelChangeUpdate(event);
        break;
      case CoreUpdateEventType.trendChanged:
        _handleTrendChangeUpdate(event);
        break;
      case CoreUpdateEventType.milestoneAchieved:
        _handleMilestoneAchievement(event);
        break;
      case CoreUpdateEventType.batchUpdate:
        _handleBatchUpdate(event);
        break;
      default:
        _handleGenericUpdate(event);
        break;
    }
  }
  
  void _handleLevelChangeUpdate(CoreUpdateEvent event) {
    // Add to recently updated cores
    _recentlyUpdatedCores.add(event.coreId);
    _updateTimestamps[event.coreId] = event.timestamp;
    
    // Trigger pulse animation
    _updateAnimationController.forward().then((_) {
      _updateAnimationController.reverse();
    });
    
    // Add haptic feedback for significant changes
    final levelChange = event.data['change'] as double?;
    if (levelChange != null && levelChange.abs() > 0.05) {
      _triggerHapticFeedback();
    }
    
    // Remove from recently updated after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _recentlyUpdatedCores.remove(event.coreId);
          _updateTimestamps.remove(event.coreId);
        });
      }
    });
    
    // Trigger rebuild to show visual indicators
    if (mounted) {
      setState(() {});
    }
  }
  
  void _handleTrendChangeUpdate(CoreUpdateEvent event) {
    // Add to recently updated cores
    _recentlyUpdatedCores.add(event.coreId);
    _updateTimestamps[event.coreId] = event.timestamp;
    
    // Trigger haptic feedback for trend changes
    _triggerHapticFeedback();
    
    // Show trend change indicator
    _showTrendChangeIndicator(event);
    
    // Remove from recently updated after delay
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _recentlyUpdatedCores.remove(event.coreId);
          _updateTimestamps.remove(event.coreId);
        });
      }
    });
    
    if (mounted) {
      setState(() {});
    }
  }
  
  void _handleMilestoneAchievement(CoreUpdateEvent event) {
    // Add to recently updated cores
    _recentlyUpdatedCores.add(event.coreId);
    _updateTimestamps[event.coreId] = event.timestamp;
    
    // Trigger celebration animation and haptic feedback
    _triggerCelebrationAnimation(event);
    _triggerHapticFeedback();
    
    // Show milestone achievement notification
    _showMilestoneAchievement(event);
    
    // Keep milestone indicator longer
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _recentlyUpdatedCores.remove(event.coreId);
          _updateTimestamps.remove(event.coreId);
        });
      }
    });
    
    if (mounted) {
      setState(() {});
    }
  }
  
  void _handleBatchUpdate(CoreUpdateEvent event) {
    final updatedCoreIds = event.data['updatedCoreIds'] as List<String>?;
    if (updatedCoreIds != null) {
      for (final coreId in updatedCoreIds) {
        _recentlyUpdatedCores.add(coreId);
        _updateTimestamps[coreId] = event.timestamp;
      }
      
      // Trigger batch update animation
      _updateAnimationController.forward().then((_) {
        _updateAnimationController.reverse();
      });
      
      // Remove batch updates after delay
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) {
          setState(() {
            for (final coreId in updatedCoreIds) {
              _recentlyUpdatedCores.remove(coreId);
              _updateTimestamps.remove(coreId);
            }
          });
        }
      });
      
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  void _handleGenericUpdate(CoreUpdateEvent event) {
    // Handle other types of updates
    _recentlyUpdatedCores.add(event.coreId);
    _updateTimestamps[event.coreId] = event.timestamp;
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _recentlyUpdatedCores.remove(event.coreId);
          _updateTimestamps.remove(event.coreId);
        });
      }
    });
    
    if (mounted) {
      setState(() {});
    }
  }
  
  void _triggerHapticFeedback() {
    // Import flutter/services.dart for HapticFeedback
    // HapticFeedback.lightImpact();
    // For now, we'll just log it
    debugPrint('Haptic feedback triggered');
  }
  
  void _triggerCelebrationAnimation(CoreUpdateEvent event) {
    // Trigger a more pronounced animation for milestones
    _updateAnimationController.forward().then((_) {
      _updateAnimationController.reverse().then((_) {
        // Double pulse for celebration
        _updateAnimationController.forward().then((_) {
          _updateAnimationController.reverse();
        });
      });
    });
  }
  
  void _showTrendChangeIndicator(CoreUpdateEvent event) {
    final newTrend = event.data['newTrend'] as String?;
    if (newTrend != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Core trend changed to $newTrend'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _showMilestoneAchievement(CoreUpdateEvent event) {
    final milestoneTitle = event.data['milestoneTitle'] as String?;
    if (milestoneTitle != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Milestone achieved: $milestoneTitle'),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc with gradient
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.7),
          color,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Core detail sheet widget
class CoreDetailSheet extends StatefulWidget {
  final EmotionalCore core;
  final CoreNavigationContext? navigationContext;

  const CoreDetailSheet({
    super.key, 
    required this.core,
    this.navigationContext,
  });

  @override
  State<CoreDetailSheet> createState() => _CoreDetailSheetState();
}

class _CoreDetailSheetState extends State<CoreDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Core details are now loaded through CoreProvider context
    // The core already contains milestones and insights
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCoreColor(widget.core.color);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundPrimary(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.getTextSecondary(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCoreIcon(widget.core.id),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.core.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(widget.core.currentLevel * 100).round()}% • ${widget.core.trend.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<CoreProvider>(
              builder: (context, coreProvider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        widget.core.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress Timeline
                      _buildProgressTimeline(color),
                      const SizedBox(height: 24),
                      
                      // Recent Insights
                      if (widget.core.recentInsights.isNotEmpty) ...[
                        _buildInsightsSection(widget.core.recentInsights),
                        const SizedBox(height: 24),
                      ],
                      
                      // Milestones
                      _buildMilestonesSection(color, widget.core.milestones),
                      const SizedBox(height: 24),
                      
                      // Supporting Journal Entries
                      _buildSupportingEntriesSection(context, widget.core),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Level',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          '${(widget.core.currentLevel * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: widget.core.currentLevel,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Previous: ${(widget.core.previousLevel * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(List<CoreInsight> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...(insights.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                insight.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ))),
      ],
    );
  }

  Widget _buildMilestonesSection(Color color, List<CoreMilestone> milestones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Milestones',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...(milestones.map((milestone) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
            border: milestone.isAchieved
                ? Border.all(color: color.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                milestone.isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                color: milestone.isAchieved ? color : AppTheme.getTextSecondary(context),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: milestone.isAchieved ? color : null,
                      ),
                    ),
                    Text(
                      milestone.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                    if (milestone.isAchieved && milestone.achievedAt != null)
                      Text(
                        'Achieved ${_formatDate(milestone.achievedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${(milestone.threshold * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: milestone.isAchieved ? color : AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ))),
      ],
    );
  }

  Widget _buildSupportingEntriesSection(BuildContext context, EmotionalCore core) {
    return Consumer<JournalProvider>(
      builder: (context, journalProvider, child) {
        // Get related journal entries for this core
        final supportingEntries = _getSupportingEntries(journalProvider, core);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supporting Journal Entries',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            if (supportingEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundSecondary(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.getTextSecondary(context),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No supporting entries yet',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Journal entries that mention themes related to ${core.name} will appear here.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...supportingEntries.take(5).map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundSecondary(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCoreColor(core.color).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: _getCoreColor(core.color),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(entry.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCoreColor(core.color),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (entry.moods.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.getTextSecondary(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.moods.join(', '),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.getTextSecondary(context),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEntryPreview(entry.content),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.isAnalyzed && entry.aiAnalysis != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCoreColor(core.color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.psychology_rounded,
                              color: _getCoreColor(core.color),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'AI detected themes related to ${core.name}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getCoreColor(core.color),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )),
              
            if (supportingEntries.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '+${supportingEntries.length - 5} more supporting entries',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.getTextSecondary(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<JournalEntry> _getSupportingEntries(JournalProvider journalProvider, EmotionalCore core) {
    // Get all journal entries and filter for those that support this core
    final allEntries = journalProvider.entries;
    
    // For now, we'll use a simple heuristic to find supporting entries:
    // 1. Entries that are analyzed and mention related themes
    // 2. Entries with similar emotional patterns
    // 3. Entries from when the core was actively growing
    
    final supportingEntries = <JournalEntry>[];
    final coreKeywords = _getCoreKeywords(core.name);
    
    for (final entry in allEntries) {
      if (_entrySupportsCore(entry, core, coreKeywords)) {
        supportingEntries.add(entry);
      }
    }
    
    // Sort by date (most recent first)
    supportingEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return supportingEntries;
  }

  List<String> _getCoreKeywords(String coreName) {
    switch (coreName.toLowerCase()) {
      case 'optimism':
        return ['hope', 'positive', 'bright', 'future', 'grateful', 'thankful', 'excited', 'happy', 'joy'];
      case 'resilience':
        return ['overcome', 'challenge', 'difficult', 'strong', 'persever', 'bounce back', 'tough', 'endure'];
      case 'self-awareness':
        return ['realize', 'understand', 'reflect', 'insight', 'aware', 'conscious', 'mindful', 'introspect'];
      case 'creativity':
        return ['create', 'imagine', 'artistic', 'innovative', 'original', 'inspire', 'design', 'craft'];
      case 'social connection':
        return ['friend', 'family', 'connect', 'relationship', 'social', 'together', 'community', 'bond'];
      case 'growth mindset':
        return ['learn', 'grow', 'improve', 'develop', 'progress', 'better', 'skill', 'knowledge'];
      default:
        return [coreName.toLowerCase()];
    }
  }

  bool _entrySupportsCore(JournalEntry entry, EmotionalCore core, List<String> keywords) {
    final contentLower = entry.content.toLowerCase();
    
    // Check if any keywords appear in the content
    final hasKeywords = keywords.any((keyword) => contentLower.contains(keyword));
    
    // Check if the entry was created during a period when this core was growing
    final isFromGrowthPeriod = _isFromCoreGrowthPeriod(entry, core);
    
    // If entry is analyzed, check if AI analysis mentions core-related themes
    final hasAISupport = entry.isAnalyzed && 
                       entry.aiAnalysis != null && 
                       _aiAnalysisSupportsCore(entry.aiAnalysis!.toJson(), core);
    
    return hasKeywords || isFromGrowthPeriod || hasAISupport;
  }

  bool _isFromCoreGrowthPeriod(JournalEntry entry, EmotionalCore core) {
    // Simple heuristic: if the entry was created within 7 days of the core's last update
    // and the core is trending upward, it likely contributed to that growth
    final daysDifference = core.lastUpdated.difference(entry.createdAt).inDays.abs();
    return daysDifference <= 7 && core.trend == 'rising';
  }

  bool _aiAnalysisSupportsCore(Map<String, dynamic> analysis, EmotionalCore core) {
    // Check if the AI analysis mentions themes related to this core
    final analysisText = analysis.toString().toLowerCase();
    final coreKeywords = _getCoreKeywords(core.name);
    
    return coreKeywords.any((keyword) => analysisText.contains(keyword));
  }

  String _getEntryPreview(String content) {
    // Return first 120 characters of the entry as a preview
    if (content.length <= 120) return content;
    return '${content.substring(0, 120)}...';
  }

  Color _getCoreColor(String colorHex) {
    try {
      // Handle both formats: with or without '#' prefix
      if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } else {
        return Color(int.parse('0xFF$colorHex'));
      }
    } catch (e) {
      debugPrint('CoreDetailSheet: Error parsing color: $colorHex, error: $e');
      return AppTheme.getPrimaryColor(context);
    }
  }

  IconData _getCoreIcon(String coreId) {
    switch (coreId) {
      case 'optimism':
        return Icons.wb_sunny;
      case 'resilience':
        return Icons.shield;
      case 'self_awareness':
        return Icons.psychology;
      case 'creativity':
        return Icons.palette;
      case 'social_connection':
        return Icons.people;
      case 'growth_mindset':
        return Icons.trending_up;
      default:
        return Icons.auto_awesome;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    return '${(difference / 30).round()} months ago';
  }
}