import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../design_system/heading_system.dart';
import '../providers/emotional_mirror_provider.dart';
import '../widgets/loading_state_widget.dart' as loading_widget;
import '../widgets/primary_emotional_state_widget.dart';
import '../widgets/enhanced_emotional_analysis_card.dart';
import '../utils/iphone_detector.dart';
import '../models/emotional_state.dart';
import '../models/core.dart';

class EmotionalMirrorScreen extends StatefulWidget {
  const EmotionalMirrorScreen({super.key});

  @override
  State<EmotionalMirrorScreen> createState() => _EmotionalMirrorScreenState();
}

class _EmotionalMirrorScreenState extends State<EmotionalMirrorScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late PageController _insightPageController;
  late ScrollController _scrollController;
  
  final List<MoodParticle> _particles = [];
  final Map<String, GlobalKey> _sectionKeys = {
    'milestones': GlobalKey(),
    'emotional_state': GlobalKey(),
    'metrics': GlobalKey(),
    'visualization': GlobalKey(),
    'insights': GlobalKey(),
    'recommendations': GlobalKey(),
  };
  
  bool _showNavigation = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _insightPageController = PageController();
    _scrollController = ScrollController();
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmotionalMirrorProvider>(context, listen: false);
      provider.initialize();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize particles only once when dependencies are ready
    if (_particles.isEmpty) {
      _initializeParticles();
    }
  }
  
  @override
  void dispose() {
    _particleController.dispose();
    _insightPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _initializeParticles() {
    final random = math.Random();
    // Use smaller bounds that will fit within the visualization container
    const visualizationWidth = 280.0;
    const visualizationHeight = 160.0;
    
    for (int i = 0; i < 20; i++) {
      _particles.add(
        MoodParticle(
          position: Offset(
            random.nextDouble() * visualizationWidth,
            random.nextDouble() * visualizationHeight,
          ),
          velocity: Offset(
            (random.nextDouble() - 0.5) * 2,
            (random.nextDouble() - 0.5) * 2,
          ),
          color: _getHighContrastParticleColor(context, random.nextDouble()),
          size: random.nextDouble() * 8 + 4,
        ),
      );
    }
  }
  
  void _scrollToSection(String sectionKey) {
    final key = _sectionKeys[sectionKey];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _toggleNavigation() {
    setState(() {
      _showNavigation = !_showNavigation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.getBackgroundPrimary(context),
      body: SafeArea(
        child: Stack(
          children: [
            Consumer<EmotionalMirrorProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // Compact Header
                    _buildCompactHeader(provider),
                    
                    // Overview Content (no tabs needed)
                    Expanded(
                      child: _buildOverviewContent(provider),
                    ),
                  ],
                );
              },
            ),
            // Floating Section Navigation
            if (_showNavigation) _buildSectionNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionNavigation() {
    final sections = [
      {'key': 'milestones', 'title': 'Milestones', 'icon': Icons.emoji_events_outlined},
      {'key': 'emotional_state', 'title': 'Emotional State', 'icon': Icons.emoji_emotions_rounded},
      {'key': 'metrics', 'title': 'Metrics', 'icon': Icons.analytics_rounded},
      {'key': 'visualization', 'title': 'Visualization', 'icon': Icons.auto_awesome_rounded},
      {'key': 'insights', 'title': 'Emotional Analysis', 'icon': Icons.psychology_alt_rounded},
      {'key': 'recommendations', 'title': 'Recommendations', 'icon': Icons.recommend_rounded},
    ];

    return Positioned(
      top: 80, // Below the header
      right: DesignTokens.spaceL,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showNavigation ? Offset.zero : const Offset(1.2, 0),
        child: Container(
          width: 220,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.getBackgroundPrimary(context),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: DesignTokens.getBackgroundTertiary(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Navigation header
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.getBackgroundSecondary(context),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusL)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.navigation_rounded,
                      color: DesignTokens.getPrimaryColor(context),
                      size: DesignTokens.iconSizeS,
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    Text(
                      'Jump to Section',
                      style: HeadingSystem.getTitleSmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation items
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
                  child: Column(
                    children: sections.map((section) => _buildNavigationItem(
                      section['key'] as String,
                      section['title'] as String,
                      section['icon'] as IconData,
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(String key, String title, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _scrollToSection(key);
          _toggleNavigation(); // Close navigation after selection
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceS,
            vertical: 2,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeS,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Text(
                  title,
                  style: HeadingSystem.getBodyMedium(context),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: DesignTokens.getTextTertiary(context),
                size: DesignTokens.iconSizeXS,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(EmotionalMirrorProvider provider) {
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
              color: DesignTokens.getColorWithOpacity(DesignTokens.getPrimaryColor(context), 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(
              Icons.psychology_rounded,
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
                  'Emotional Mirror',
                  style: HeadingSystem.getHeadlineMedium(context),
                ),
                Text(
                  provider.selectedTimeRange.displayName,
                  style: HeadingSystem.getBodySmall(context),
                ),
              ],
            ),
          ),
          // Time Range Selector
          PopupMenuButton<TimeRange>(
            icon: Icon(
              Icons.calendar_today_rounded,
              color: DesignTokens.getPrimaryColor(context),
              size: DesignTokens.iconSizeM,
            ),
            onSelected: provider.setTimeRange,
            itemBuilder: (context) => TimeRange.values.map((range) {
              return PopupMenuItem<TimeRange>(
                value: range,
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: DesignTokens.iconSizeS,
                      color: provider.selectedTimeRange == range
                          ? DesignTokens.getPrimaryColor(context)
                          : DesignTokens.getTextSecondary(context),
                    ),
                    SizedBox(width: DesignTokens.spaceM),
                    Text(
                      range.displayName,
                      style: TextStyle(
                        color: provider.selectedTimeRange == range
                            ? DesignTokens.getPrimaryColor(context)
                            : DesignTokens.getTextPrimary(context),
                        fontWeight: provider.selectedTimeRange == range
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(width: DesignTokens.spaceS),
          // Section Navigation Button
          IconButton(
            onPressed: _toggleNavigation,
            icon: Icon(
              _showNavigation ? Icons.close_rounded : Icons.menu_rounded,
              color: DesignTokens.getPrimaryColor(context),
            ),
            tooltip: _showNavigation ? 'Close navigation' : 'Show section navigation',
          ),
          // Refresh Button
          IconButton(
            onPressed: provider.refresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: DesignTokens.getPrimaryColor(context),
            ),
            tooltip: 'Refresh data',
          ),
        ],
      ),
    );
  }
  

  Widget _buildPrimaryEmotionalState(EmotionalMirrorProvider provider) {
    // Get both primary and secondary emotional states from provider
    final primaryState = provider.getPrimaryEmotionalState(context);
    final secondaryState = provider.getSecondaryEmotionalState(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.getPrimaryColor(context).withValues(alpha: 0.05),
            DesignTokens.accentBlue.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.only(
              left: DesignTokens.spaceL,
              right: DesignTokens.spaceL,
              top: DesignTokens.spaceL,
              bottom: DesignTokens.spaceM,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_emotions_rounded,
                  color: DesignTokens.getPrimaryColor(context),
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spaceM),
                Text(
                  'Current Emotional State',
                  style: HeadingSystem.getHeadlineSmall(context),
                ),
              ],
            ),
          ),
          
          // Emotional state widget with full features
          PrimaryEmotionalStateWidget(
            primaryState: primaryState,
            secondaryState: secondaryState,
            showTabs: secondaryState != null, // Show tabs only if we have secondary state
            showTimestamp: true, // Show when the analysis was done
            showConfidence: false, // Hide confidence indicators
            focusable: true, // Allow keyboard navigation
            showAnimation: true, // Enable smooth animations
            onTap: primaryState != null ? () => _showEmotionalStateDetails(primaryState, secondaryState) : null,
          ),
        ],
      ),
    );
  }

  void _showEmotionalStateDetails(EmotionalState primaryState, EmotionalState? secondaryState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<EmotionalMirrorProvider>(
        builder: (context, provider, child) => _buildEmotionalStateDetailsSheet(primaryState, secondaryState, provider),
      ),
    );
  }

  Widget _buildEmotionalStateDetailsSheet(EmotionalState primaryState, EmotionalState? secondaryState, EmotionalMirrorProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundPrimary(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXL)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(DesignTokens.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: DesignTokens.spaceL),
                  decoration: BoxDecoration(
                    color: DesignTokens.getBackgroundTertiary(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Text(
                'Emotional State Analysis',
                style: HeadingSystem.getHeadlineMedium(context),
              ),
              SizedBox(height: DesignTokens.spaceXL),
              
              // Primary emotion details
              _buildEmotionDetailCard(
                'Primary Emotion',
                primaryState,
                Icons.star,
                DesignTokens.getPrimaryColor(context),
              ),
              
              if (secondaryState != null) ...[
                SizedBox(height: DesignTokens.spaceL),
                _buildEmotionDetailCard(
                  'Secondary Emotion',
                  secondaryState,
                  Icons.star_half,
                  DesignTokens.accentBlue,
                ),
              ],
              
              // Additional insights based on EmotionalAnalyzer data
              SizedBox(height: DesignTokens.spaceXL),
              _buildEmotionalInsightsCard(provider),
              
              SizedBox(height: DesignTokens.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionDetailCard(String title, EmotionalState state, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                title,
                style: HeadingSystem.getTitleMedium(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Emotion name and intensity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.displayName,
                      style: HeadingSystem.getHeadlineMedium(context),
                    ),
                    SizedBox(height: DesignTokens.spaceXS),
                    Text(
                      state.description,
                      style: HeadingSystem.getBodyMedium(context).copyWith(
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: state.accessibleColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${((state.intensity > 1.0 ? state.intensity / 10.0 : state.intensity) * 100).round()}%',
                  style: HeadingSystem.getTitleMedium(context).copyWith(
                    color: state.accessibleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          // Additional metadata
          SizedBox(height: DesignTokens.spaceM),
          Wrap(
            spacing: DesignTokens.spaceM,
            runSpacing: DesignTokens.spaceS,
            children: [
              _buildMetadataChip(
                Icons.color_lens,
                'Color',
                state.primaryColor,
              ),
              if (state.semanticLabel.isNotEmpty)
                _buildMetadataChip(
                  Icons.accessibility,
                  'Accessible',
                  DesignTokens.successColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: DesignTokens.iconSizeXS, color: color),
          SizedBox(width: DesignTokens.spaceXS),
          Text(
            label,
            style: HeadingSystem.getLabelSmall(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  // Consolidated card widget for insights, patterns, and other content
  Widget _buildUnifiedContentCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    required List<String> items,
    Widget? customContent,
  }) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                title,
                style: HeadingSystem.getTitleMedium(context),
              ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: DesignTokens.spaceM),
            Text(
              subtitle,
              style: HeadingSystem.getBodySmall(context).copyWith(
                color: DesignTokens.getTextSecondary(context),
              ),
            ),
          ],
          SizedBox(height: DesignTokens.spaceM),
          if (customContent != null)
            customContent
          else
            ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 6, right: DesignTokens.spaceM),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: HeadingSystem.getBodyMedium(context),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildEmotionalInsightsCard(EmotionalMirrorProvider provider) {
    return _buildUnifiedContentCard(
      title: 'Emotional Insights',
      icon: Icons.insights_rounded,
      iconColor: DesignTokens.accentYellow,
      subtitle: _generateInsightIntroText(provider),
      items: _getEmotionalInsightItems(provider),
    );
  }

  List<String> _getEmotionalInsightItems(EmotionalMirrorProvider provider) {
    // Get real insights from the provider's mirror data
    if (provider.mirrorData?.insights == null || provider.mirrorData!.insights.isEmpty) {
      return ['Continue journaling to unlock personalized insights based on your entries.'];
    }
    
    final realInsights = provider.mirrorData!.insights;
    return realInsights.take(3).toList();
  }


  Widget _buildMilestonesHeader(EmotionalMirrorProvider provider) {
    final mirrorData = provider.mirrorData!;
    final totalEntries = mirrorData.totalEntries;
    
    // Define milestone thresholds
    final milestones = [
      {'entries': 1, 'title': 'First Step', 'icon': Icons.flag_outlined},
      {'entries': 7, 'title': 'Week Strong', 'icon': Icons.calendar_today},
      {'entries': 30, 'title': 'Monthly Master', 'icon': Icons.event_note},
      {'entries': 100, 'title': 'Century Club', 'icon': Icons.star_outline},
      {'entries': 365, 'title': 'Year of Growth', 'icon': Icons.emoji_events},
    ];
    
    // Find current milestone
    Map<String, dynamic>? currentMilestone;
    Map<String, dynamic>? nextMilestone;
    
    for (int i = 0; i < milestones.length; i++) {
      final milestoneEntries = milestones[i]['entries'] as int;
      if (totalEntries >= milestoneEntries) {
        currentMilestone = milestones[i];
        if (i + 1 < milestones.length) {
          nextMilestone = milestones[i + 1];
        }
      } else {
        nextMilestone = milestones[i];
        break;
      }
    }
    
    // If no current milestone, use the first as next
    if (currentMilestone == null && milestones.isNotEmpty) {
      nextMilestone = milestones[0];
    }
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.getPrimaryColor(context).withValues(alpha: 0.1),
            DesignTokens.accentBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.getPrimaryColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journey Milestones',
                      style: HeadingSystem.getHeadlineSmall(context),
                    ),
                    Text(
                      currentMilestone != null 
                          ? 'Current: ${currentMilestone['title']}'
                          : 'Start your journey today!',
                      style: HeadingSystem.getBodySmall(context),
                    ),
                  ],
                ),
              ),
              if (currentMilestone != null)
                Container(
                  padding: EdgeInsets.all(DesignTokens.spaceS),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    currentMilestone['icon'] as IconData,
                    color: DesignTokens.accentYellow,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
            ],
          ),
          if (nextMilestone != null) ...[
            SizedBox(height: DesignTokens.spaceL),
            // Progress to next milestone
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next: ${nextMilestone['title']}',
                      style: HeadingSystem.getLabelMedium(context),
                    ),
                    Text(
                      '$totalEntries / ${nextMilestone['entries']} entries',
                      style: HeadingSystem.getLabelMedium(context).copyWith(
                        color: DesignTokens.getPrimaryColor(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    color: DesignTokens.getBackgroundTertiary(context),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (totalEntries / (nextMilestone['entries'] as int)).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.accentYellow,
                            DesignTokens.accentYellow.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMetricsGrid(EmotionalMirrorProvider provider) {
    final overview = provider.mirrorData!.moodOverview;
    
    return GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: DesignTokens.spaceM,
        crossAxisSpacing: DesignTokens.spaceM,
        childAspectRatio: 1.0,
        children: [
          _buildMetricTile(
            'Balance',
            _formatBalance(overview.moodBalance),
            _getBalanceColor(overview.moodBalance),
            Icons.balance_rounded,
            '${(overview.moodBalance * 100).round()}%',
          ),
          _buildMetricTile(
            'Range',
            '${(overview.emotionalVariety * 100).round()}%',
            DesignTokens.accentBlue,
            Icons.show_chart_rounded,
            'Emotional range',
          ),
          _buildMetricTile(
            'Entries',
            '${provider.mirrorData!.totalEntries}',
            DesignTokens.accentGreen,
            Icons.edit_note_rounded,
            'Total logged',
          ),
        ],
    );
  }
  
  /// Get high contrast particle color for better dark mode visibility
  Color _getHighContrastParticleColor(BuildContext context, double t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      // Use brighter, more contrasting colors for dark mode
      return Color.lerp(
        const Color(0xFF64B5F6), // Light blue
        const Color(0xFFFFD54F), // Bright yellow
        t,
      )!;
    } else {
      // Use original colors for light mode
      return Color.lerp(
        DesignTokens.accentBlue,
        DesignTokens.accentYellow,
        t,
      )!;
    }
  }
  
  Widget _buildMetricTile(String title, String value, Color color, IconData icon, String subtitle) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: DesignTokens.iconSizeL,
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            value,
            style: HeadingSystem.getTitleLarge(context).copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: HeadingSystem.getLabelMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoodBalanceCard(EmotionalMirrorProvider provider) {
    final overview = provider.mirrorData!.moodOverview;
    
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Your Emotional State Visualization',
                style: HeadingSystem.getHeadlineSmall(context),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          _buildEmotionalStateVisualization(overview),
          SizedBox(height: DesignTokens.spaceL),
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: DesignTokens.iconSizeS,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    Text(
                      'About Your Visualization',
                      style: HeadingSystem.getTitleSmall(context),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),
                Text(
                  _generateVisualizationDescription(overview),
                  style: HeadingSystem.getBodySmall(context),
                ),
                SizedBox(height: DesignTokens.spaceM),
                Text(
                  overview.description,
                  style: HeadingSystem.getBodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Combined insights and patterns with progressive disclosure
  Widget _buildInsightsAndPatternsSection(EmotionalMirrorProvider provider) {
    final enhancedInsights = _generateEnhancedInsights(provider);
    final patterns = _getEmotionalPatterns(provider);
    
    if (enhancedInsights.isEmpty && patterns.isEmpty) {
      return Container();
    }
    
    return _ProgressiveDisclosureCard(
      title: 'Emotional Analysis',
      subtitle: 'Deep insights and patterns from your journal entries',
      primaryIcon: Icons.psychology_alt_rounded,
      primaryIconColor: DesignTokens.accentYellow,
      tabs: [
        if (enhancedInsights.isNotEmpty)
          _ProgressiveDisclosureTab(
            title: 'Insights',
            icon: Icons.psychology_alt_rounded,
            color: DesignTokens.accentYellow,
            content: _buildEnhancedInsightCards(enhancedInsights),
            subtitle: 'Generated from emotional patterns and core resonance',
          ),
        if (patterns.isNotEmpty)
          _ProgressiveDisclosureTab(
            title: 'Patterns',
            icon: Icons.pattern_rounded,
            color: DesignTokens.accentBlue,
            content: _buildPatternTimeline(patterns),
            subtitle: 'Recurring emotional themes in your entries',
          ),
      ],
    );
  }

  List<EmotionalPatternData> _getEmotionalPatterns(EmotionalMirrorProvider provider) {
    // Get real patterns from the provider's mirror data
    if (provider.mirrorData?.emotionalPatterns == null) {
      return [];
    }
    
    final realPatterns = provider.mirrorData!.emotionalPatterns;
    final daysBack = provider.timeRangeDays;
    
    return realPatterns.map((pattern) {
      // Convert EmotionalPattern to EmotionalPatternData
      return EmotionalPatternData(
        title: pattern.title,
        description: pattern.description,
        type: pattern.type,
        category: pattern.category,
        confidence: pattern.confidence,
        occurrences: _calculateOccurrences(pattern, daysBack),
        timeRange: _formatTimeRange(pattern, daysBack),
        impact: _mapTypeToImpact(pattern.type),
        coreAssociations: pattern.relatedEmotions,
      );
    }).toList();
  }
  
  int _calculateOccurrences(EmotionalPattern pattern, int daysBack) {
    // Calculate approximate occurrences based on pattern confidence and time range
    final daysSinceFirst = DateTime.now().difference(pattern.firstDetected).inDays;
    final activeDays = daysSinceFirst.clamp(1, daysBack);
    
    // Higher confidence patterns are assumed to occur more frequently
    final baseOccurrences = (pattern.confidence * 20).round().clamp(1, 15);
    return (baseOccurrences * activeDays / daysBack).round().clamp(1, baseOccurrences);
  }
  
  String _formatTimeRange(EmotionalPattern pattern, int daysBack) {
    final daysSinceFirst = DateTime.now().difference(pattern.firstDetected).inDays;
    final daysSinceLast = DateTime.now().difference(pattern.lastSeen).inDays;
    
    if (daysSinceLast <= 7) {
      return 'Last 7 days';
    } else if (daysSinceFirst <= 30) {
      return 'Last 30 days';
    } else if (daysSinceFirst <= 60) {
      return 'Last 60 days';
    } else if (daysSinceFirst <= 90) {
      return 'Last 90 days';
    } else {
      return 'Ongoing pattern';
    }
  }
  
  PatternImpact _mapTypeToImpact(String type) {
    switch (type.toLowerCase()) {
      case 'growth':
        return PatternImpact.growth_oriented;
      case 'recurring':
        if (type.contains('positive') || type.contains('good')) {
          return PatternImpact.positive;
        }
        return PatternImpact.neutral;
      case 'awareness':
        return PatternImpact.growth_oriented;
      default:
        return PatternImpact.neutral;
    }
  }

  Widget _buildPatternTimeline(List<EmotionalPatternData> patterns) {
    return Column(
      children: patterns.asMap().entries.map((entry) {
        final index = entry.key;
        final pattern = entry.value;
        final isLast = index == patterns.length - 1;
        
        return _buildPatternTimelineItem(pattern, isLast);
      }).toList(),
    );
  }

  Widget _buildPatternTimelineItem(EmotionalPatternData pattern, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : DesignTokens.spaceL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simplified timeline indicator
          Container(
            width: 10,
            height: 10,
            margin: EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: _getPatternImpactColor(pattern.impact),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: DesignTokens.spaceM),
          
          // Cleaner pattern content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simplified header with inline impact
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        pattern.title,
                        style: HeadingSystem.getTitleMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _getPatternImpactLabel(pattern.impact),
                      style: HeadingSystem.getLabelMedium(context).copyWith(
                        color: _getPatternImpactColor(pattern.impact),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),
                
                // Description
                Text(
                  pattern.description,
                  style: HeadingSystem.getBodyMedium(context).copyWith(
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
                SizedBox(height: DesignTokens.spaceM),
                
                // Simplified stats in a single line
                Row(
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: DesignTokens.iconSizeXS,
                      color: DesignTokens.getTextTertiary(context),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      '${pattern.occurrences}x',
                      style: HeadingSystem.getLabelMedium(context),
                    ),
                    SizedBox(width: DesignTokens.spaceL),
                    Icon(
                      Icons.schedule_rounded,
                      size: DesignTokens.iconSizeXS,
                      color: DesignTokens.getTextTertiary(context),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      pattern.timeRange,
                      style: HeadingSystem.getLabelMedium(context),
                    ),
                  ],
                ),
                
                // Simplified core associations
                if (pattern.coreAssociations.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spaceM),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pattern.coreAssociations.map((c) => c.replaceAll('_', ' ')).join(' • '),
                          style: HeadingSystem.getBodySmall(context).copyWith(
                            color: DesignTokens.getPrimaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Add divider if not last
                if (!isLast) ...[
                  SizedBox(height: DesignTokens.spaceL),
                  Divider(
                    color: DesignTokens.getBackgroundTertiary(context),
                    thickness: 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Color _getPatternImpactColor(PatternImpact impact) {
    switch (impact) {
      case PatternImpact.highly_positive:
        return DesignTokens.successColor;
      case PatternImpact.positive:
        return DesignTokens.accentGreen;
      case PatternImpact.growth_oriented:
        return DesignTokens.accentBlue;
      case PatternImpact.neutral:
        return DesignTokens.getTextSecondary(context);
      case PatternImpact.needs_attention:
        return DesignTokens.warningColor;
    }
  }

  String _getPatternImpactLabel(PatternImpact impact) {
    switch (impact) {
      case PatternImpact.highly_positive:
        return 'Highly Positive';
      case PatternImpact.positive:
        return 'Positive';
      case PatternImpact.growth_oriented:
        return 'Growth';
      case PatternImpact.neutral:
        return 'Neutral';
      case PatternImpact.needs_attention:
        return 'Needs Attention';
    }
  }

  Widget _buildRecommendationsCard(EmotionalMirrorProvider provider) {
    final recommendations = _generateRecommendations(provider);
    
    return _buildUnifiedContentCard(
      title: 'Personalized Recommendations',
      icon: Icons.recommend_rounded,
      iconColor: DesignTokens.accentGreen,
      items: [], // We'll use customContent for recommendation items
      customContent: Column(
        children: recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
      ),
    );
  }
  
  Widget _buildRecommendationItem(EnhancedRecommendation recommendation) {
    final categoryColor = _getRecommendationCategoryColor(recommendation.category);
    final priorityColor = _getRecommendationPriorityColor(recommendation.priority);
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceL),
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withValues(alpha: 0.1),
            categoryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and priority
          Row(
            children: [
              Icon(
                recommendation.icon,
                color: categoryColor,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: HeadingSystem.getTitleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getRecommendationCategoryLabel(recommendation.category),
                      style: HeadingSystem.getLabelSmall(context).copyWith(
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  _getRecommendationPriorityLabel(recommendation.priority),
                  style: HeadingSystem.getLabelSmall(context).copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Description
          Text(
            recommendation.description,
            style: HeadingSystem.getBodyMedium(context),
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Expected benefit
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: DesignTokens.iconSizeS,
                  color: DesignTokens.accentYellow,
                ),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    recommendation.expectedBenefit,
                    style: HeadingSystem.getBodySmall(context).copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Time commitment and action steps
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time commitment
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: DesignTokens.iconSizeXS,
                          color: DesignTokens.getTextSecondary(context),
                        ),
                        SizedBox(width: DesignTokens.spaceXS),
                        Text(
                          'Time',
                          style: HeadingSystem.getLabelSmall(context).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spaceXS),
                    Text(
                      recommendation.timeCommitment,
                      style: HeadingSystem.getBodySmall(context),
                    ),
                  ],
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              
              // Action steps
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: DesignTokens.iconSizeXS,
                          color: DesignTokens.getTextSecondary(context),
                        ),
                        SizedBox(width: DesignTokens.spaceXS),
                        Text(
                          'Action Steps',
                          style: HeadingSystem.getLabelSmall(context).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spaceXS),
                    ...recommendation.actionSteps.take(2).map((step) => Padding(
                      padding: EdgeInsets.only(bottom: DesignTokens.spaceXS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: EdgeInsets.only(top: 6, right: DesignTokens.spaceS),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step,
                              style: HeadingSystem.getBodySmall(context),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          
          // Based on information
          SizedBox(height: DesignTokens.spaceM),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceS,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundTertiary(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: DesignTokens.iconSizeXS,
                  color: DesignTokens.getTextTertiary(context),
                ),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    'Based on: ${recommendation.basedOn}',
                    style: HeadingSystem.getLabelSmall(context).copyWith(
                      color: DesignTokens.getTextTertiary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRecommendationCategoryColor(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.growth:
        return DesignTokens.accentGreen;
      case RecommendationCategory.wellbeing:
        return DesignTokens.accentBlue;
      case RecommendationCategory.skill_building:
        return DesignTokens.getPrimaryColor(context);
      case RecommendationCategory.pattern_work:
        return DesignTokens.warningColor;
    }
  }

  String _getRecommendationCategoryLabel(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.growth:
        return 'Personal Growth';
      case RecommendationCategory.wellbeing:
        return 'Wellbeing';
      case RecommendationCategory.skill_building:
        return 'Skill Building';
      case RecommendationCategory.pattern_work:
        return 'Pattern Work';
    }
  }

  Color _getRecommendationPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return DesignTokens.errorColor;
      case RecommendationPriority.medium:
        return DesignTokens.warningColor;
      case RecommendationPriority.low:
        return DesignTokens.successColor;
    }
  }

  String _getRecommendationPriorityLabel(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return 'High Priority';
      case RecommendationPriority.medium:
        return 'Medium Priority';
      case RecommendationPriority.low:
        return 'Low Priority';
    }
  }
  
  List<EnhancedRecommendation> _generateRecommendations(EmotionalMirrorProvider provider) {
    final recommendations = <EnhancedRecommendation>[];
    final mirrorData = provider.mirrorData!;
    
    // Core resonance-based recommendations
    final coreResonanceData = _getCoreResonanceData(provider);
    for (final entry in coreResonanceData.entries) {
      final coreName = entry.key;
      final resonance = entry.value;
      
      if (resonance < 0.6) {
        final coreRecommendation = _generateCoreRecommendation(coreName, resonance);
        if (coreRecommendation != null) {
          recommendations.add(coreRecommendation);
        }
      }
    }
    
    // Growth indicator-based recommendations
    final growthIndicators = _getGrowthIndicators(provider);
    if (growthIndicators.contains('emotional_vocabulary_expansion')) {
      recommendations.add(EnhancedRecommendation(
        title: 'Expand Emotional Vocabulary',
        description: 'Your emotional expressions are growing more nuanced. Try exploring new feeling words to deepen your self-understanding.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.medium,
        icon: Icons.psychology_alt_rounded,
        basedOn: 'Growth indicator analysis showing vocabulary expansion',
        expectedBenefit: 'Enhanced emotional clarity and self-expression',
        coreImpacts: {'emotional_vocabulary': 0.3, 'self_expression': 0.2},
        timeCommitment: '5-10 minutes daily',
        actionSteps: [
          'Use an emotion wheel during journaling',
          'Try describing feelings with more specific words',
          'Reflect on subtle emotional nuances',
        ],
      ));
    }
    
    // Pattern-based recommendations
    final patterns = _getEmotionalPatterns(provider);
    for (final pattern in patterns) {
      if (pattern.impact == PatternImpact.needs_attention) {
        recommendations.add(_generatePatternRecommendation(pattern));
      }
    }
    
    // Mood balance recommendations
    if (mirrorData.moodOverview.moodBalance < 0.3) {
      recommendations.add(EnhancedRecommendation(
        title: 'Emotional Balance Practice',
        description: 'Your entries show more challenging emotions recently. Building resilience through structured practices could help.',
        category: RecommendationCategory.wellbeing,
        priority: RecommendationPriority.high,
        icon: Icons.balance_rounded,
        basedOn: 'Mood balance analysis showing ${(mirrorData.moodOverview.moodBalance * 100).round()}% balance',
        expectedBenefit: 'Improved emotional stability and resilience',
        coreImpacts: {'resilience': 0.4, 'emotional_regulation': 0.3},
        timeCommitment: '10-15 minutes daily',
        actionSteps: [
          'Practice daily gratitude journaling',
          'Try mindfulness meditation',
          'Focus on positive reframing techniques',
        ],
      ));
    }
    
    // Default positive recommendations
    if (recommendations.isEmpty || recommendations.length < 2) {
      recommendations.add(EnhancedRecommendation(
        title: 'Deepen Self-Reflection',
        description: 'Your journaling practice shows consistency. Consider exploring deeper questions about your values and aspirations.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.low,
        icon: Icons.explore_rounded,
        basedOn: 'Consistent journaling pattern analysis',
        expectedBenefit: 'Enhanced self-awareness and personal clarity',
        coreImpacts: {'self_awareness': 0.2, 'personal_values': 0.3},
        timeCommitment: '15-20 minutes per session',
        actionSteps: [
          'Ask yourself "why" questions about your feelings',
          'Explore your core values and beliefs',
          'Reflect on your personal growth journey',
        ],
      ));
    }
    
    return recommendations.take(3).toList();
  }

  Map<String, double> _getCoreResonanceData(EmotionalMirrorProvider provider) {
    // Get real core resonance data from the emotional patterns
    final resonanceMap = <String, double>{};
    
    if (provider.mirrorData?.emotionalPatterns != null) {
      for (final pattern in provider.mirrorData!.emotionalPatterns) {
        // Use pattern confidence as a base resonance indicator
        for (final emotion in pattern.relatedEmotions) {
          final key = emotion.toLowerCase().replaceAll(' ', '_');
          resonanceMap[key] = (resonanceMap[key] ?? 0.0) + (pattern.confidence * 0.3);
        }
      }
    }
    
    // Normalize values and add common core indicators
    resonanceMap.updateAll((key, value) => value.clamp(0.0, 1.0));
    
    // Add default resonance for common cores if not present
    resonanceMap.putIfAbsent('self_awareness', () => 0.6);
    resonanceMap.putIfAbsent('emotional_processing', () => 0.5);
    resonanceMap.putIfAbsent('resilience', () => 0.4);
    
    return resonanceMap;
  }

  List<String> _getGrowthIndicators(EmotionalMirrorProvider provider) {
    // Get real growth indicators from the patterns and insights
    final indicators = <String>[];
    
    if (provider.mirrorData?.emotionalPatterns != null) {
      final patterns = provider.mirrorData!.emotionalPatterns;
      
      // Analyze patterns for growth indicators
      bool hasGrowthPatterns = patterns.any((p) => p.type.toLowerCase() == 'growth');
      bool hasRecurringPatterns = patterns.any((p) => p.type.toLowerCase() == 'recurring');
      bool hasHighConfidence = patterns.any((p) => p.confidence > 0.8);
      
      if (hasGrowthPatterns) {
        indicators.add('personal_growth_development');
      }
      
      if (hasRecurringPatterns) {
        indicators.add('pattern_recognition_improvement');
      }
      
      if (patterns.length > 2) {
        indicators.add('emotional_complexity_understanding');
      }
      
      if (hasHighConfidence) {
        indicators.add('self_awareness_deepening');
      }
      
      // Check vocabulary expansion based on emotion variety
      final uniqueEmotions = patterns
          .expand((p) => p.relatedEmotions)
          .toSet();
      if (uniqueEmotions.length > 5) {
        indicators.add('emotional_vocabulary_expansion');
      }
    }
    
    // If no patterns, use basic growth indicators
    if (indicators.isEmpty) {
      indicators.addAll(['self_reflection_practice', 'emotional_awareness']);
    }
    
    return indicators;
  }
  
  String _generateVisualizationDescription(dynamic overview) {
    final moodCount = overview.dominantMoods?.length ?? 0;
    final varietyScore = (overview.emotionalVariety ?? 0.0) * 100;
    final balanceDesc = overview.moodBalance > 0.7 ? 'balanced' : 
                       overview.moodBalance > 0.3 ? 'moderately balanced' : 'varied';
    
    if (moodCount == 0) {
      return 'Start journaling to see your personalized emotional visualization. As you write, the particles will reflect your unique emotional patterns and growth.';
    }
    
    return 'This visualization represents your emotional landscape with ${moodCount} dominant ${moodCount == 1 ? 'mood' : 'moods'} and ${varietyScore.round()}% emotional variety. The ${balanceDesc} pattern shows your emotional processing style and evolves with each journal entry.';
  }
  
  String _generateInsightIntroText(EmotionalMirrorProvider provider) {
    final entryCount = provider.mirrorData?.totalEntries ?? 0;
    final daysBack = provider.timeRangeDays;
    
    if (entryCount == 0) {
      return 'Start journaling to generate personalized insights:';
    } 
    
    final timeRangeText = daysBack <= 7 ? 'this week' : 
                         daysBack <= 30 ? 'this month' : 
                         daysBack <= 90 ? 'the past 3 months' : 
                         'your recent entries';
    
    return 'Based on analysis of your ${entryCount} journal ${entryCount == 1 ? 'entry' : 'entries'} from ${timeRangeText}:';
  }

  EnhancedRecommendation? _generateCoreRecommendation(String coreName, double resonance) {
    switch (coreName) {
      case 'mindfulness':
        return EnhancedRecommendation(
          title: 'Develop Mindfulness Practice',
          description: 'Your mindfulness core shows room for growth. Regular mindfulness practice can enhance present-moment awareness.',
          category: RecommendationCategory.skill_building,
          priority: RecommendationPriority.medium,
          icon: Icons.self_improvement_rounded,
          basedOn: 'Core resonance analysis showing ${(resonance * 100).round()}% mindfulness development',
          expectedBenefit: 'Increased present-moment awareness and emotional clarity',
          coreImpacts: {'mindfulness': 0.4, 'emotional_regulation': 0.2},
          timeCommitment: '10-15 minutes daily',
          actionSteps: [
            'Start with 5-minute daily meditation',
            'Practice mindful journaling',
            'Use mindfulness apps for guidance',
          ],
        );
        
      case 'emotional_regulation':
        return EnhancedRecommendation(
          title: 'Strengthen Emotional Regulation',
          description: 'Building emotional regulation skills can help you respond rather than react to challenging situations.',
          category: RecommendationCategory.skill_building,
          priority: RecommendationPriority.high,
          icon: Icons.psychology_rounded,
          basedOn: 'Core resonance analysis showing ${(resonance * 100).round()}% emotional regulation development',
          expectedBenefit: 'Better emotional stability and response control',
          coreImpacts: {'emotional_regulation': 0.5, 'resilience': 0.3},
          timeCommitment: '15-20 minutes daily',
          actionSteps: [
            'Practice the STOP technique (Stop, Take a breath, Observe, Proceed)',
            'Journal about emotional triggers',
            'Learn breathing exercises for emotional moments',
          ],
        );
        
      default:
        return null;
    }
  }

  EnhancedRecommendation _generatePatternRecommendation(EmotionalPatternData pattern) {
    return EnhancedRecommendation(
      title: 'Address Pattern: ${pattern.title}',
      description: 'This pattern needs attention. ${pattern.description}',
      category: RecommendationCategory.pattern_work,
      priority: RecommendationPriority.high,
      icon: Icons.warning_amber_rounded,
      basedOn: 'Pattern analysis based on your journal entries',
      expectedBenefit: 'Improved emotional patterns and healthier responses',
      coreImpacts: Map.fromEntries(
        pattern.coreAssociations.map((core) => MapEntry(core, 0.3)),
      ),
      timeCommitment: '20-30 minutes per session',
      actionSteps: [
        'Reflect on the triggers for this pattern',
        'Develop alternative responses',
        'Track pattern changes over time',
      ],
    );
  }
  
  

  Widget _buildOverviewContent(EmotionalMirrorProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }
    
    if (provider.error != null) {
      return _buildErrorState(provider);
    }
    
    if (provider.mirrorData == null) {
      return _buildEmptyState();
    }
    
    return _buildOverviewTab(provider);
  }
  
  Widget _buildOverviewTab(EmotionalMirrorProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Column(
          children: [
            // Milestones Header
            Container(
              key: _sectionKeys['milestones'],
              child: _buildMilestonesHeader(provider),
            ),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Primary Emotional State Widget
            Container(
              key: _sectionKeys['emotional_state'],
              child: _buildPrimaryEmotionalState(provider),
            ),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Key Metrics Grid
            Container(
              key: _sectionKeys['metrics'],
              child: _buildMetricsGrid(provider),
            ),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Interactive Mood Balance Visualization
            Container(
              key: _sectionKeys['visualization'],
              child: _buildMoodBalanceCard(provider),
            ),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Enhanced Emotional Analysis with Core Integration
            Container(
              key: _sectionKeys['insights'],
              child: const EnhancedEmotionalAnalysisCard(),
            ),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Recommendations
            Container(
              key: _sectionKeys['recommendations'],
              child: _buildRecommendationsCard(provider),
            ),
            SizedBox(height: DesignTokens.spaceXXL),
          ],
        ),
      ),
    );
  }
  

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: iPhoneDetector.getAdaptivePadding(context, compact: 24, regular: 32, large: 40),
        child: loading_widget.LoadingStateWidget(
          type: loading_widget.LoadingType.wave,
          message: 'Analyzing your emotional patterns...',
          color: DesignTokens.getPrimaryColor(context),
          size: iPhoneDetector.getAdaptiveIconSize(context, base: 48),
        ),
      ),
    );
  }

  Widget _buildErrorState(EmotionalMirrorProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: 64),
            color: DesignTokens.getTextTertiary(context),
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          Text(
            'Unable to load emotional mirror',
            style: HeadingSystem.getHeadlineSmall(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          Text(
            provider.error ?? 'An unexpected error occurred',
            style: HeadingSystem.getBodyMedium(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          ComponentLibrary.primaryButton(
            text: 'Retry',
            onPressed: provider.refresh,
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: 64),
            color: DesignTokens.getTextTertiary(context),
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          Text(
            'Your Emotional Mirror',
            style: HeadingSystem.getHeadlineSmall(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          Text(
            'Start writing in your journal to generate personalized emotional insights and patterns.',
            style: HeadingSystem.getBodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods

  String _formatBalance(double balance) {
    if (balance > 0.3) return 'Positive';
    if (balance < -0.3) return 'Challenging';
    return 'Balanced';
  }

  Color _getBalanceColor(double balance) {
    if (balance > 0.3) return DesignTokens.successColor;
    if (balance < -0.3) return DesignTokens.warningColor;
    return DesignTokens.getPrimaryColor(context);
  }

  
  Widget _buildEmotionalStateVisualization(dynamic overview) {
    return Container(
      height: 240, // Increased height for richer visualization
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: EnhancedEmotionalStatePainter(
                particles: _particles,
                moodBalance: overview.moodBalance,
                animationValue: _particleController.value,
                emotionalVariety: overview.emotionalVariety,
                dominantMoods: overview.dominantMoods,
                // Enhanced data from EmotionalAnalyzer
                emotionalIntensity: _getAverageEmotionalIntensity(),
                sentimentTrend: _getSentimentTrend(),
                coreResonanceStrength: _getAverageCoreResonance(),
                primaryEmotions: _getPrimaryEmotionsFromAnalysis(),
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  double _getAverageEmotionalIntensity() {
    // Calculate from the current emotional states
    final provider = Provider.of<EmotionalMirrorProvider>(context, listen: false);
    final primaryState = provider.getPrimaryEmotionalState(context);
    final secondaryState = provider.getSecondaryEmotionalState(context);
    
    if (primaryState == null) return 0.5;
    
    // Calculate weighted average if secondary state exists
    if (secondaryState != null) {
      final primaryIntensity = primaryState.intensity > 1.0 ? primaryState.intensity / 10.0 : primaryState.intensity;
      final secondaryIntensity = secondaryState.intensity > 1.0 ? secondaryState.intensity / 10.0 : secondaryState.intensity;
      return (primaryIntensity * 0.7 + secondaryIntensity * 0.3).clamp(0.0, 1.0);
    }
    
    return (primaryState.intensity > 1.0 ? primaryState.intensity / 10.0 : primaryState.intensity).clamp(0.0, 1.0);
  }

  double _getSentimentTrend() {
    // Calculate sentiment trend from mood balance
    final provider = Provider.of<EmotionalMirrorProvider>(context, listen: false);
    if (provider.mirrorData == null) return 0.0;
    
    // Use mood balance as a proxy for sentiment trend
    return provider.mirrorData!.moodOverview.moodBalance.clamp(-1.0, 1.0);
  }

  double _getAverageCoreResonance() {
    // Calculate from emotional variety and self-awareness score
    final provider = Provider.of<EmotionalMirrorProvider>(context, listen: false);
    if (provider.mirrorData == null) return 0.5;
    
    final emotionalVariety = provider.mirrorData!.moodOverview.emotionalVariety;
    final selfAwareness = provider.mirrorData!.selfAwarenessScore;
    
    return ((emotionalVariety + selfAwareness) / 2.0).clamp(0.0, 1.0);
  }

  List<String> _getPrimaryEmotionsFromAnalysis() {
    // Get emotions from the current states and dominant moods
    final provider = Provider.of<EmotionalMirrorProvider>(context, listen: false);
    final emotions = <String>[];
    
    // Add primary and secondary emotions if available
    final primaryState = provider.getPrimaryEmotionalState(context);
    final secondaryState = provider.getSecondaryEmotionalState(context);
    
    if (primaryState != null) {
      emotions.add(primaryState.emotion);
    }
    if (secondaryState != null) {
      emotions.add(secondaryState.emotion);
    }
    
    // Add other dominant moods
    if (provider.mirrorData != null) {
      final dominantMoods = provider.mirrorData!.moodOverview.dominantMoods;
      for (final mood in dominantMoods) {
        if (!emotions.contains(mood) && emotions.length < 5) {
          emotions.add(mood);
        }
      }
    }
    
    return emotions.isNotEmpty ? emotions : ['neutral'];
  }

  List<EnhancedInsight> _generateEnhancedInsights(EmotionalMirrorProvider provider) {
    final insights = <EnhancedInsight>[];
    
    // Get real insights from the provider's mirror data
    if (provider.mirrorData?.insights == null || provider.mirrorData!.insights.isEmpty) {
      return insights;
    }
    
    final realInsights = provider.mirrorData!.insights;
    final patterns = provider.mirrorData!.emotionalPatterns;
    
    // Convert basic insights to enhanced insights
    for (int i = 0; i < realInsights.length && i < 3; i++) {
      final insight = realInsights[i];
      
      // Determine category based on insight content
      final category = _categorizeInsight(insight);
      
      // Generate key themes from the insight text
      final keyThemes = _extractKeyThemes(insight);
      
      // Calculate core resonance based on patterns and themes
      final coreResonance = _calculateCoreResonance(patterns, keyThemes);
      
      insights.add(EnhancedInsight(
        title: _generateInsightTitle(insight, category),
        content: insight,
        category: category,
        confidence: _calculateInsightConfidence(insight, patterns),
        source: 'Real Analysis from Journal Entries',
        keyThemes: keyThemes,
        coreResonance: coreResonance,
      ));
    }
    
    return insights;
  }
  
  InsightCategory _categorizeInsight(String insight) {
    final lowerInsight = insight.toLowerCase();
    
    if (lowerInsight.contains('pattern') || lowerInsight.contains('recurring') || lowerInsight.contains('trend')) {
      return InsightCategory.pattern;
    } else if (lowerInsight.contains('growth') || lowerInsight.contains('development') || lowerInsight.contains('progress')) {
      return InsightCategory.growth;
    } else if (lowerInsight.contains('core') || lowerInsight.contains('resonance') || lowerInsight.contains('authentic')) {
      return InsightCategory.resonance;
    } else {
      return InsightCategory.trend;
    }
  }
  
  List<String> _extractKeyThemes(String insight) {
    final themes = <String>[];
    final lowerInsight = insight.toLowerCase();
    
    // Extract themes based on common emotional keywords
    if (lowerInsight.contains('gratitude') || lowerInsight.contains('grateful')) themes.add('gratitude');
    if (lowerInsight.contains('mindful') || lowerInsight.contains('awareness')) themes.add('mindfulness');
    if (lowerInsight.contains('growth') || lowerInsight.contains('develop')) themes.add('personal_growth');
    if (lowerInsight.contains('reflection') || lowerInsight.contains('reflect')) themes.add('self_reflection');
    if (lowerInsight.contains('emotion') || lowerInsight.contains('feeling')) themes.add('emotional_processing');
    if (lowerInsight.contains('authentic') || lowerInsight.contains('genuine')) themes.add('authenticity');
    if (lowerInsight.contains('resilience') || lowerInsight.contains('resilient')) themes.add('resilience');
    
    return themes.isEmpty ? ['self_reflection'] : themes;
  }
  
  Map<String, double> _calculateCoreResonance(List<EmotionalPattern> patterns, List<String> themes) {
    final resonance = <String, double>{};
    
    // Base resonance from themes
    for (final theme in themes) {
      switch (theme) {
        case 'gratitude':
          resonance['gratitude'] = 0.8;
          break;
        case 'mindfulness':
          resonance['self_awareness'] = 0.7;
          break;
        case 'personal_growth':
          resonance['growth'] = 0.9;
          break;
        case 'self_reflection':
          resonance['self_awareness'] = 0.8;
          break;
        case 'emotional_processing':
          resonance['emotional_intelligence'] = 0.7;
          break;
        case 'authenticity':
          resonance['authenticity'] = 0.9;
          break;
        case 'resilience':
          resonance['resilience'] = 0.8;
          break;
      }
    }
    
    // Add resonance from patterns
    for (final pattern in patterns) {
      for (final emotion in pattern.relatedEmotions) {
        resonance[emotion.toLowerCase()] = (resonance[emotion.toLowerCase()] ?? 0.0) + 0.1;
      }
    }
    
    // Clamp values and ensure at least one resonance
    resonance.updateAll((key, value) => value.clamp(0.0, 1.0));
    if (resonance.isEmpty) {
      resonance['self_awareness'] = 0.7;
    }
    
    return resonance;
  }
  
  double _calculateInsightConfidence(String insight, List<EmotionalPattern> patterns) {
    // Base confidence from insight length and detail
    double confidence = (insight.length / 200.0).clamp(0.5, 0.9);
    
    // Increase confidence if we have supporting patterns
    if (patterns.isNotEmpty) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.5, 0.95);
  }
  
  String _generateInsightTitle(String insight, InsightCategory category) {
    switch (category) {
      case InsightCategory.pattern:
        return 'Emotional Pattern Discovery';
      case InsightCategory.growth:
        return 'Personal Growth Insight';
      case InsightCategory.resonance:
        return 'Core Resonance Analysis';
      case InsightCategory.trend:
        return 'Journal Reflection';
    }
  }

  Widget _buildEnhancedInsightCards(List<EnhancedInsight> insights) {
    return Column(
      children: insights.asMap().entries.map((entry) {
        final index = entry.key;
        final insight = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: DesignTokens.spaceL),
          child: _buildEnhancedInsightCard(insight, index, insights.length),
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedInsightCard(EnhancedInsight insight, int index, int total) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(insight.category).withValues(alpha: 0.1),
            _getCategoryColor(insight.category).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: _getCategoryColor(insight.category).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and confidence
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(insight.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(insight.category),
                      size: DesignTokens.iconSizeXS,
                      color: _getCategoryColor(insight.category),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      _getCategoryDisplayName(insight.category),
                      style: HeadingSystem.getLabelSmall(context).copyWith(
                        color: _getCategoryColor(insight.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Title
          Text(
            insight.title,
            style: HeadingSystem.getTitleMedium(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          
          // Content
          Text(
            insight.content,
            style: HeadingSystem.getBodyMedium(context),
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Key themes
          if (insight.keyThemes.isNotEmpty) ...[
            Wrap(
              spacing: DesignTokens.spaceS,
              runSpacing: DesignTokens.spaceXS,
              children: insight.keyThemes.take(3).map((theme) => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  theme.replaceAll('_', ' ').toLowerCase(),
                  style: HeadingSystem.getLabelSmall(context).copyWith(
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
              )).toList(),
            ),
            SizedBox(height: DesignTokens.spaceM),
          ],
          
          // Core resonance indicators
          if (insight.coreResonance.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.radio_button_checked,
                  size: DesignTokens.iconSizeXS,
                  color: DesignTokens.getTextSecondary(context),
                ),
                SizedBox(width: DesignTokens.spaceXS),
                Text(
                  'Core Resonance',
                  style: HeadingSystem.getLabelSmall(context).copyWith(
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
                Spacer(),
                Text(
                  insight.source,
                  style: HeadingSystem.getLabelSmall(context).copyWith(
                    color: DesignTokens.getTextTertiary(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceS),
            ...insight.coreResonance.entries.take(2).map((entry) => 
              _buildResonanceBar(entry.key, entry.value),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildResonanceBar(String coreName, double strength) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceXS),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              coreName.replaceAll('_', ' '),
              style: HeadingSystem.getLabelSmall(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: DesignTokens.getBackgroundTertiary(context),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: strength,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: DesignTokens.accentBlue,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spaceS),
          Text(
            '${(strength * 100).round()}%',
            style: HeadingSystem.getLabelSmall(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(InsightCategory category) {
    switch (category) {
      case InsightCategory.pattern:
        return DesignTokens.accentBlue;
      case InsightCategory.growth:
        return DesignTokens.accentGreen;
      case InsightCategory.resonance:
        return DesignTokens.getPrimaryColor(context);
      case InsightCategory.trend:
        return DesignTokens.accentYellow;
    }
  }

  IconData _getCategoryIcon(InsightCategory category) {
    switch (category) {
      case InsightCategory.pattern:
        return Icons.pattern_rounded;
      case InsightCategory.growth:
        return Icons.trending_up_rounded;
      case InsightCategory.resonance:
        return Icons.radio_button_checked_rounded;
      case InsightCategory.trend:
        return Icons.show_chart_rounded;
    }
  }

  String _getCategoryDisplayName(InsightCategory category) {
    switch (category) {
      case InsightCategory.pattern:
        return 'Pattern';
      case InsightCategory.growth:
        return 'Growth';
      case InsightCategory.resonance:
        return 'Resonance';
      case InsightCategory.trend:
        return 'Trend';
    }
  }

  
  Widget _buildSwipeableInsightCards(List<String> insights) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: 180, // Increased from 120
      constraints: BoxConstraints(
        minHeight: 180,
        maxHeight: 400, // Allow expansion up to this height
      ),
      child: PageView.builder(
        controller: _insightPageController,
        itemCount: insights.length,
        itemBuilder: (context, index) {
          return _ExpandableInsightCard(
            insight: insights[index],
            index: index,
            totalCount: insights.length,
          );
        },
      ),
    );
  }
  
  
  /// Get high contrast gradient color for charts and visualizations
  Color _getHighContrastGradientColor(double t, {required bool isDark}) {
    if (isDark) {
      // Use brighter, more contrasting colors for dark mode
      return Color.lerp(
        const Color(0xFF42A5F5), // Bright blue
        const Color(0xFFFFEE58), // Bright yellow
        t,
      )!;
    } else {
      // Use original colors for light mode
      return Color.lerp(
        DesignTokens.accentBlue,
        DesignTokens.accentYellow,
        t,
      )!;
    }
  }
}

// Progressive disclosure data classes
class _ProgressiveDisclosureTab {
  final String title;
  final IconData icon;
  final Color color;
  final Widget content;
  final String subtitle;

  _ProgressiveDisclosureTab({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    required this.subtitle,
  });
}

// Progressive disclosure card widget
class _ProgressiveDisclosureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData primaryIcon;
  final Color primaryIconColor;
  final List<_ProgressiveDisclosureTab> tabs;

  const _ProgressiveDisclosureCard({
    required this.title,
    required this.subtitle,
    required this.primaryIcon,
    required this.primaryIconColor,
    required this.tabs,
  });

  @override
  State<_ProgressiveDisclosureCard> createState() => _ProgressiveDisclosureCardState();
}

class _ProgressiveDisclosureCardState extends State<_ProgressiveDisclosureCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  int _selectedTabIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse functionality
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              child: Row(
                children: [
                  Icon(
                    widget.primaryIcon,
                    color: widget.primaryIconColor,
                    size: DesignTokens.iconSizeM,
                  ),
                  SizedBox(width: DesignTokens.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: HeadingSystem.getTitleMedium(context),
                        ),
                        SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          widget.subtitle,
                          style: HeadingSystem.getBodySmall(context).copyWith(
                            color: DesignTokens.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: DesignTokens.getPrimaryColor(context),
                      size: DesignTokens.iconSizeM,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab summary when collapsed
          if (!_isExpanded && widget.tabs.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  children: widget.tabs.asMap().entries.map((entry) {
                    final tab = entry.value;
                    return Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.icon,
                            color: tab.color,
                            size: DesignTokens.iconSizeXS,
                          ),
                          SizedBox(width: DesignTokens.spaceXS),
                          Text(
                            tab.title,
                            style: HeadingSystem.getLabelSmall(context).copyWith(
                              color: tab.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          
          // Expanded content with tabs
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: widget.tabs.length > 1
                ? _buildTabContent()
                : _buildSingleContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Column(
      children: [
        SizedBox(height: DesignTokens.spaceM),
        
        // Tab selector
        Container(
          margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          padding: EdgeInsets.all(DesignTokens.spaceXS),
          decoration: BoxDecoration(
            color: DesignTokens.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Row(
            children: widget.tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == _selectedTabIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: DesignTokens.spaceS,
                      horizontal: DesignTokens.spaceM,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? tab.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          color: isSelected ? tab.color : DesignTokens.getTextSecondary(context),
                          size: DesignTokens.iconSizeS,
                        ),
                        SizedBox(width: DesignTokens.spaceS),
                        Text(
                          tab.title,
                          style: HeadingSystem.getLabelMedium(context).copyWith(
                            color: isSelected ? tab.color : DesignTokens.getTextSecondary(context),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        SizedBox(height: DesignTokens.spaceL),
        
        // Selected tab subtitle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          child: Text(
            widget.tabs[_selectedTabIndex].subtitle,
            style: HeadingSystem.getBodySmall(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ),
        
        SizedBox(height: DesignTokens.spaceM),
        
        // Tab content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          child: widget.tabs[_selectedTabIndex].content,
        ),
        
        SizedBox(height: DesignTokens.spaceM),
      ],
    );
  }

  Widget _buildSingleContent() {
    if (widget.tabs.isEmpty) return Container();
    
    final tab = widget.tabs.first;
    return Column(
      children: [
        SizedBox(height: DesignTokens.spaceM),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          child: Text(
            tab.subtitle,
            style: HeadingSystem.getBodySmall(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spaceM),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          child: tab.content,
        ),
        SizedBox(height: DesignTokens.spaceM),
      ],
    );
  }
}

class MoodParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  
  MoodParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });
}

class EnhancedEmotionalStatePainter extends CustomPainter {
  final List<MoodParticle> particles;
  final double moodBalance;
  final double animationValue;
  final double emotionalVariety;
  final List<String> dominantMoods;
  // Enhanced properties from EmotionalAnalyzer
  final double emotionalIntensity;
  final double sentimentTrend;
  final double coreResonanceStrength;
  final List<String> primaryEmotions;
  
  EnhancedEmotionalStatePainter({
    required this.particles,
    required this.moodBalance,
    required this.animationValue,
    required this.emotionalVariety,
    required this.dominantMoods,
    required this.emotionalIntensity,
    required this.sentimentTrend,
    required this.coreResonanceStrength,
    required this.primaryEmotions,
  });
  
  /// Get high contrast color for painter (assumes dark mode for now)
  Color _getHighContrastGradientColorForPainter(double t) {
    // Use brighter colors for better visibility in dark mode
    return Color.lerp(
      const Color(0xFF42A5F5), // Bright blue
      const Color(0xFFFFEE58), // Bright yellow
      t,
    )!;
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Use enhanced emotional intensity directly from EmotionalAnalyzer
    final normalizedIntensity = emotionalIntensity.clamp(0.0, 1.0);
    
    // Draw multi-layered background reflecting emotional complexity
    _drawBackgroundLayers(canvas, size, paint);
    
    // Draw sentiment trend indicator
    _drawSentimentTrendIndicator(canvas, size, paint);
    
    // Draw core resonance visualization
    _drawCoreResonanceField(canvas, size, paint);
    
    // Draw enhanced animated particles representing emotional complexity
    _drawEnhancedParticles(canvas, size, paint);
    
    // Draw central emotional core
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final coreRadius = 30.0 + emotionalVariety * 20.0;
    
    // Core gradient
    final coreGradient = RadialGradient(
      colors: [
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.6),
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.2),
      ],
    );
    
    paint.shader = coreGradient.createShader(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: coreRadius),
    );
    
    // Pulsing effect
    final pulseRadius = coreRadius * (1.0 + math.sin(animationValue * 2 * math.pi) * 0.1);
    canvas.drawCircle(Offset(centerX, centerY), pulseRadius, paint);
  }

  void _drawBackgroundLayers(Canvas canvas, Size size, Paint paint) {
    // Layer 1: Base emotional state
    final baseGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0 + emotionalVariety * 0.5,
      colors: [
        _getEmotionalStateColor(moodBalance, emotionalVariety).withValues(alpha: 0.4),
        _getEmotionalStateColor(moodBalance, emotionalVariety).withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Layer 2: Emotional intensity overlay
    final intensityGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _getIntensityColor().withValues(alpha: emotionalIntensity * 0.3),
        Colors.transparent,
      ],
    );
    
    paint.shader = intensityGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawSentimentTrendIndicator(Canvas canvas, Size size, Paint paint) {
    if (sentimentTrend.abs() < 0.1) return; // Don't draw for neutral trends
    
    paint.shader = null;
    final isPositiveTrend = sentimentTrend > 0;
    final trendColor = isPositiveTrend 
        ? const Color(0xFF4CAF50) // Green for positive
        : const Color(0xFFFF7043); // Orange for challenging
    
    // Draw subtle trend indicator along the edge
    final trendStrength = sentimentTrend.abs().clamp(0.0, 1.0);
    paint.color = trendColor.withValues(alpha: trendStrength * 0.5);
    
    final trendPath = Path();
    if (isPositiveTrend) {
      // Rising trend - draw ascending wave
      trendPath.moveTo(0, size.height * 0.8);
      trendPath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.6 - (trendStrength * 20),
        size.width, size.height * 0.4,
      );
    } else {
      // Declining trend - draw descending wave  
      trendPath.moveTo(0, size.height * 0.4);
      trendPath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.6 + (trendStrength * 20),
        size.width, size.height * 0.8,
      );
    }
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.0;
    canvas.drawPath(trendPath, paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawCoreResonanceField(Canvas canvas, Size size, Paint paint) {
    if (coreResonanceStrength < 0.3) return; // Only draw for significant resonance
    
    paint.shader = null;
    final resonanceColor = const Color(0xFF9C27B0).withValues(alpha: coreResonanceStrength * 0.2);
    paint.color = resonanceColor;
    
    // Draw resonance field as expanding rings
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = math.min(size.width, size.height) / 3;
    
    for (int i = 0; i < 3; i++) {
      final ringRadius = maxRadius * (0.3 + i * 0.3) * coreResonanceStrength;
      final ringAlpha = (1.0 - i * 0.3) * coreResonanceStrength * 0.3;
      
      paint.color = resonanceColor.withValues(alpha: ringAlpha);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      
      canvas.drawCircle(
        Offset(centerX, centerY), 
        ringRadius + math.sin(animationValue * 2 * math.pi + i) * 5,
        paint,
      );
    }
    paint.style = PaintingStyle.fill;
  }

  void _drawEnhancedParticles(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      paint.shader = null;
      
      // Enhanced particle behavior based on multiple factors
      final particleSpeed = 0.5 + emotionalVariety * 1.5 + emotionalIntensity * 0.5;
      final particleAlpha = 0.3 + emotionalIntensity * 0.4;
      
      // Color particles based on primary emotions
      final emotionColorMod = _getEmotionColorModifier(i);
      final enhancedColor = Color.lerp(particle.color, emotionColorMod, 0.3)!;
      
      paint.color = enhancedColor.withValues(
        alpha: particleAlpha + math.sin(animationValue * 2 * math.pi + particle.position.dx) * 0.2,
      );
      
      // More sophisticated movement patterns
      final phase = i * 0.3;
      final resonanceInfluence = coreResonanceStrength * 0.5;
      final animatedPosition = Offset(
        particle.position.dx + 
          math.sin(animationValue * particleSpeed * math.pi + phase) * (15 * emotionalVariety + resonanceInfluence * 10),
        particle.position.dy + 
          math.cos(animationValue * particleSpeed * math.pi * 1.3 + phase) * (10 * emotionalVariety + resonanceInfluence * 8),
      );
      
      final clampedPosition = Offset(
        animatedPosition.dx.clamp(particle.size, size.width - particle.size),
        animatedPosition.dy.clamp(particle.size, size.height - particle.size),
      );
      
      // Size influenced by emotional intensity and core resonance
      final particleSize = particle.size * (0.8 + emotionalIntensity * 0.4 + coreResonanceStrength * 0.2);
      canvas.drawCircle(clampedPosition, particleSize, paint);
      
      // Enhanced glow effects
      if (moodBalance > 0.3 || coreResonanceStrength > 0.6) {
        paint.color = enhancedColor.withValues(alpha: 0.1);
        canvas.drawCircle(clampedPosition, particleSize * 2, paint);
      }
    }
  }

  Color _getIntensityColor() {
    return Color.lerp(
      const Color(0xFF2196F3), // Blue for low intensity
      const Color(0xFFFF5722), // Orange-red for high intensity
      emotionalIntensity,
    )!;
  }

  Color _getEmotionColorModifier(int particleIndex) {
    if (primaryEmotions.isEmpty) return Colors.white;
    
    final emotionIndex = particleIndex % primaryEmotions.length;
    final emotion = primaryEmotions[emotionIndex];
    
    // Map emotions to colors
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'excited':
        return const Color(0xFFFFEB3B); // Yellow
      case 'calm':
      case 'peaceful':
      case 'content':
        return const Color(0xFF4CAF50); // Green
      case 'grateful':
      case 'love':
        return const Color(0xFFE91E63); // Pink
      case 'focused':
      case 'determined':
        return const Color(0xFF3F51B5); // Indigo
      case 'sad':
      case 'melancholy':
        return const Color(0xFF2196F3); // Blue
      case 'anxious':
      case 'worried':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF607D8B); // Blue-grey
    }
  }
  
  /// Get color representing the emotional state
  Color _getEmotionalStateColor(double balance, double variety) {
    // Positive emotions: warm colors (yellow to orange)
    // Negative emotions: cool colors (blue to purple)
    // Neutral: balanced greens
    
    if (balance > 0.3) {
      // Positive state
      return Color.lerp(
        const Color(0xFFFFD54F), // Warm yellow
        const Color(0xFFFF8A65), // Warm orange
        variety,
      )!;
    } else if (balance < -0.3) {
      // Challenging state
      return Color.lerp(
        const Color(0xFF64B5F6), // Soft blue
        const Color(0xFF9575CD), // Soft purple
        variety,
      )!;
    } else {
      // Balanced state
      return Color.lerp(
        const Color(0xFF81C784), // Soft green
        const Color(0xFF4DB6AC), // Teal
        variety,
      )!;
    }
  }
  
  @override
  bool shouldRepaint(EnhancedEmotionalStatePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.moodBalance != moodBalance ||
           oldDelegate.emotionalVariety != emotionalVariety ||
           oldDelegate.emotionalIntensity != emotionalIntensity ||
           oldDelegate.sentimentTrend != sentimentTrend ||
           oldDelegate.coreResonanceStrength != coreResonanceStrength;
  }
}

class _ExpandableInsightCard extends StatefulWidget {
  final String insight;
  final int index;
  final int totalCount;

  const _ExpandableInsightCard({
    required this.insight,
    required this.index,
    required this.totalCount,
  });

  @override
  State<_ExpandableInsightCard> createState() => _ExpandableInsightCardState();
}

// Enhanced insight data structures
class EnhancedInsight {
  final String title;
  final String content;
  final InsightCategory category;
  final double confidence;
  final String source;
  final List<String> keyThemes;
  final Map<String, double> coreResonance;

  EnhancedInsight({
    required this.title,
    required this.content,
    required this.category,
    required this.confidence,
    required this.source,
    required this.keyThemes,
    required this.coreResonance,
  });
}

enum InsightCategory {
  pattern,
  growth,
  resonance,
  trend,
}

class EmotionalPatternData {
  final String title;
  final String description;
  final String type;
  final String category;
  final double confidence;
  final int occurrences;
  final String timeRange;
  final PatternImpact impact;
  final List<String> coreAssociations;

  EmotionalPatternData({
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.confidence,
    required this.occurrences,
    required this.timeRange,
    required this.impact,
    required this.coreAssociations,
  });
}

enum PatternImpact {
  highly_positive,
  positive,
  growth_oriented,
  neutral,
  needs_attention,
}

class EnhancedRecommendation {
  final String title;
  final String description;
  final RecommendationCategory category;
  final RecommendationPriority priority;
  final IconData icon;
  final String basedOn;
  final String expectedBenefit;
  final Map<String, double> coreImpacts;
  final String timeCommitment;
  final List<String> actionSteps;

  EnhancedRecommendation({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.icon,
    required this.basedOn,
    required this.expectedBenefit,
    required this.coreImpacts,
    required this.timeCommitment,
    required this.actionSteps,
  });
}

enum RecommendationCategory {
  growth,
  wellbeing,
  skill_building,
  pattern_work,
}

enum RecommendationPriority {
  high,
  medium,
  low,
}

class _ExpandableInsightCardState extends State<_ExpandableInsightCard> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
            padding: EdgeInsets.all(DesignTokens.spaceL), // Increased from spaceM
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DesignTokens.getPrimaryColor(context).withValues(alpha: 0.1),
                  DesignTokens.accentBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: DesignTokens.getPrimaryColor(context).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: DesignTokens.getPrimaryColor(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    Text(
                      'Insight ${widget.index + 1} of ${widget.totalCount}',
                      style: HeadingSystem.getLabelSmall(context).copyWith(
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ),
                    Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: DesignTokens.getTextSecondary(context),
                        size: DesignTokens.iconSizeS,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceM), // Increased from spaceS
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.insight,
                    style: HeadingSystem.getBodyLarge(context), // Increased from getBodyMedium
                    maxLines: 4, // Increased from 3 to show more text
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: SingleChildScrollView(
                    child: Text(
                      widget.insight,
                      style: HeadingSystem.getBodyLarge(context), // Increased from getBodyMedium
                    ),
                  ),
                  crossFadeState: _isExpanded 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                  duration: Duration(milliseconds: 300),
                ),
                if (!_isExpanded && widget.insight.length > 100) ...[
                  SizedBox(height: DesignTokens.spaceM), // Increased from spaceXS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tap to read more',
                        style: HeadingSystem.getBodyMedium(context).copyWith( // Increased from getBodySmall
                          color: DesignTokens.getPrimaryColor(context),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

