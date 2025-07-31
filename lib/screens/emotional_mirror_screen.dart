import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../design_system/heading_system.dart';
import '../providers/emotional_mirror_provider.dart';
import '../widgets/loading_state_widget.dart' as loading_widget;
import '../utils/iphone_detector.dart';
import '../models/emotional_state.dart';

class EmotionalMirrorScreen extends StatefulWidget {
  const EmotionalMirrorScreen({super.key});

  @override
  State<EmotionalMirrorScreen> createState() => _EmotionalMirrorScreenState();
}

class _EmotionalMirrorScreenState extends State<EmotionalMirrorScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late PageController _insightPageController;
  
  final List<MoodParticle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _insightPageController = PageController();
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.getBackgroundPrimary(context),
      body: SafeArea(
        child: Consumer<EmotionalMirrorProvider>(
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
    // Create sample primary emotional state for demonstration
    // In a real implementation, this would come from the provider
    final primaryState = _createSampleEmotionalState(provider, isPrimary: true);
    
    if (primaryState == null) {
      return Container(); // Return empty if no state
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryState.primaryColor.withValues(alpha: 0.1),
            primaryState.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: primaryState.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with emotion name and icon
          Padding(
            padding: EdgeInsets.all(DesignTokens.spaceL),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spaceS),
                  decoration: BoxDecoration(
                    color: primaryState.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    _getEmotionIcon(primaryState.emotion),
                    color: primaryState.primaryColor,
                    size: DesignTokens.iconSizeL,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Emotion',
                        style: HeadingSystem.getLabelMedium(context),
                      ),
                      Text(
                        primaryState.displayName,
                        style: HeadingSystem.getHeadlineMedium(context).copyWith(
                          color: primaryState.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // AI Confidence Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceM,
                    vertical: DesignTokens.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(primaryState.confidence).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    border: Border.all(
                      color: _getConfidenceColor(primaryState.confidence).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: DesignTokens.iconSizeS,
                        color: _getConfidenceColor(primaryState.confidence),
                      ),
                      SizedBox(width: DesignTokens.spaceS),
                      Text(
                        '${(primaryState.confidence * 100).round()}%',
                        style: HeadingSystem.getTitleSmall(context).copyWith(
                          color: _getConfidenceColor(primaryState.confidence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Emotion intensity bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intensity',
                      style: HeadingSystem.getLabelMedium(context),
                    ),
                    Text(
                      '${(primaryState.intensity * 100).round()}%',
                      style: HeadingSystem.getLabelMedium(context).copyWith(
                        color: primaryState.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    color: DesignTokens.getBackgroundTertiary(context),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: primaryState.intensity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        gradient: LinearGradient(
                          colors: [
                            primaryState.primaryColor,
                            primaryState.primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          Padding(
            padding: EdgeInsets.all(DesignTokens.spaceL),
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: DesignTokens.getTextTertiary(context),
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Text(
                      primaryState.description,
                      style: HeadingSystem.getBodyMedium(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  EmotionalState? _createSampleEmotionalState(EmotionalMirrorProvider provider, {required bool isPrimary}) {
    final mirrorData = provider.mirrorData;
    if (mirrorData == null) return null;
    
    // Extract emotion from mood overview
    final moodOverview = mirrorData.moodOverview;
    final balance = moodOverview.moodBalance;
    final variety = moodOverview.emotionalVariety;
    
    // Determine emotions based on balance and available data
    String emotion;
    double intensity;
    double confidence;
    String description;
    
    if (isPrimary) {
      // Primary emotion logic
      if (balance > 0.3) {
        emotion = 'content';
        intensity = 0.7;
        confidence = 0.8;
        description = 'You\'re experiencing a sense of contentment and satisfaction with your current state.';
      } else if (balance < -0.3) {
        emotion = 'stressed';
        intensity = 0.6;
        confidence = 0.75;
        description = 'You\'re feeling some stress and tension in your daily experiences.';
      } else {
        emotion = 'calm';
        intensity = 0.5;
        confidence = 0.7;
        description = 'You\'re in a balanced, calm emotional state with steady feelings.';
      }
    } else {
      // Secondary emotion logic - often complementary or underlying
      if (balance > 0.3) {
        emotion = variety > 0.6 ? 'excited' : 'grateful';
        intensity = 0.5;
        confidence = 0.65;
        description = variety > 0.6 
            ? 'There\'s an underlying excitement about possibilities and opportunities.'
            : 'You have a deep sense of gratitude for the positive aspects of your life.';
      } else if (balance < -0.3) {
        emotion = variety > 0.5 ? 'anxious' : 'tired';
        intensity = 0.4;
        confidence = 0.6;
        description = variety > 0.5
            ? 'Beneath the stress, there\'s some anxiety about upcoming challenges.'
            : 'You\'re feeling emotionally drained and need some rest and recovery.';
      } else {
        emotion = 'curious';
        intensity = 0.4;
        confidence = 0.65;
        description = 'There\'s a quiet curiosity about what lies ahead and how things will unfold.';
      }
    }
    
    // Create emotional state using the factory constructor
    return EmotionalState.create(
      emotion: emotion,
      intensity: intensity,
      confidence: confidence,
      context: context,
      customDescription: description,
    );
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
            Icons.palette_rounded,
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
                  'This unique visualization represents your current emotional state based on your journal entries. The particles\' movement, color, and density are personalized to reflect your emotional patterns and evolve as you continue your journaling journey.',
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
  
  Widget _buildInsightsSection(EmotionalMirrorProvider provider) {
    final insights = provider.getFilteredInsights();
    
    if (insights.isEmpty) {
      return Container();
    }
    
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.accentYellow,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Personal Insights',
                style: HeadingSystem.getHeadlineSmall(context),
              ),
              Spacer(),
              Text(
                'Swipe to explore',
                style: HeadingSystem.getBodySmall(context).copyWith(
                  color: DesignTokens.getTextSecondary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          _buildSwipeableInsightCards(insights),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationsCard(EmotionalMirrorProvider provider) {
    final recommendations = _generateRecommendations(provider);
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.accentGreen.withValues(alpha: 0.1),
            DesignTokens.accentBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.accentGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend_rounded,
                color: DesignTokens.accentGreen,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Recommended for You',
                style: HeadingSystem.getHeadlineSmall(context),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL),
          ...recommendations.map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.accentGreen.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            recommendation['icon'] as IconData,
            color: DesignTokens.accentGreen,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'] as String,
                  style: HeadingSystem.getTitleMedium(context),
                ),
                SizedBox(height: DesignTokens.spaceXS),
                Text(
                  recommendation['description'] as String,
                  style: HeadingSystem.getBodySmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _generateRecommendations(EmotionalMirrorProvider provider) {
    final recommendations = <Map<String, dynamic>>[];
    final mirrorData = provider.mirrorData!;
    
    if (mirrorData.moodOverview.moodBalance < 0.4) {
      recommendations.add({
        'icon': Icons.self_improvement_rounded,
        'title': 'Try Mindfulness Practice',
        'description': 'Your mood balance suggests mindfulness could help restore emotional equilibrium.',
      });
    }
    
    if (mirrorData.analyzedEntries < mirrorData.totalEntries * 0.5) {
      recommendations.add({
        'icon': Icons.edit_calendar_rounded,
        'title': 'Increase Journaling Frequency',
        'description': 'More frequent journaling can provide deeper insights into your emotional patterns.',
      });
    }
    
    recommendations.add({
      'icon': Icons.nature_people_rounded,
      'title': 'Connect with Nature',
      'description': 'Spending time outdoors can boost mood and reduce stress levels.',
    });
    
    return recommendations.take(3).toList();
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Column(
          children: [
            // Milestones Header
            _buildMilestonesHeader(provider),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Primary Emotional State Widget
            _buildPrimaryEmotionalState(provider),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Key Metrics Grid
            _buildMetricsGrid(provider),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Interactive Mood Balance Visualization
            _buildMoodBalanceCard(provider),
            SizedBox(height: DesignTokens.spaceXL),
            
            
            // Personal Insights
            _buildInsightsSection(provider),
            SizedBox(height: DesignTokens.spaceXL),
            
            // Recommendations
            _buildRecommendationsCard(provider),
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
          message: 'Reflecting on your journey...',
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
            'Begin your journaling journey to unlock personal growth insights.',
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

  IconData _getEmotionIcon(String emotion) {
    final iconMap = {
      'happy': Icons.sentiment_very_satisfied,
      'sad': Icons.sentiment_very_dissatisfied,
      'angry': Icons.sentiment_very_dissatisfied,
      'anxious': Icons.sentiment_dissatisfied,
      'excited': Icons.sentiment_very_satisfied,
      'calm': Icons.sentiment_satisfied,
      'frustrated': Icons.sentiment_dissatisfied,
      'content': Icons.sentiment_satisfied,
      'worried': Icons.sentiment_dissatisfied,
      'joyful': Icons.sentiment_very_satisfied,
      'peaceful': Icons.sentiment_satisfied,
      'stressed': Icons.sentiment_dissatisfied,
      'optimistic': Icons.sentiment_satisfied,
      'melancholy': Icons.sentiment_neutral,
      'energetic': Icons.sentiment_very_satisfied,
      'tired': Icons.sentiment_neutral,
      'confident': Icons.sentiment_satisfied,
      'uncertain': Icons.sentiment_neutral,
      'grateful': Icons.sentiment_satisfied,
      'lonely': Icons.sentiment_dissatisfied,
    };
    
    return iconMap[emotion.toLowerCase()] ?? Icons.sentiment_neutral;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return DesignTokens.successColor;
    if (confidence >= 0.6) return DesignTokens.accentYellow;
    if (confidence >= 0.4) return DesignTokens.accentBlue;
    return DesignTokens.warningColor;
  }
  
  Widget _buildEmotionalStateVisualization(dynamic overview) {
    return Container(
      height: 200,
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
              painter: EmotionalStatePainter(
                particles: _particles,
                moodBalance: overview.moodBalance,
                animationValue: _particleController.value,
                emotionalVariety: overview.emotionalVariety,
                dominantMoods: overview.dominantMoods,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildSwipeableInsightCards(List<String> insights) {
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _insightPageController,
        itemCount: insights.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
            padding: EdgeInsets.all(DesignTokens.spaceM),
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
                      'Insight ${index + 1} of ${insights.length}',
                      style: HeadingSystem.getLabelSmall(context).copyWith(
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    insights[index],
                    style: HeadingSystem.getBodyMedium(context),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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

class EmotionalStatePainter extends CustomPainter {
  final List<MoodParticle> particles;
  final double moodBalance;
  final double animationValue;
  final double emotionalVariety;
  final List<String> dominantMoods;
  
  EmotionalStatePainter({
    required this.particles,
    required this.moodBalance,
    required this.animationValue,
    required this.emotionalVariety,
    required this.dominantMoods,
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
    
    // Calculate emotional state intensity based on mood balance
    final emotionalIntensity = (moodBalance + 1.0) / 2.0; // Normalize from -1..1 to 0..1
    
    // Draw background gradient based on emotional state
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0 + emotionalVariety * 0.5, // Expand radius based on emotional variety
      colors: [
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.3),
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw animated particles representing emotional complexity
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      paint.shader = null;
      
      // Vary particle behavior based on emotional state
      final particleSpeed = 0.5 + emotionalVariety * 1.5; // More variety = faster movement
      final particleAlpha = 0.3 + emotionalIntensity * 0.4; // Higher intensity = more visible
      
      paint.color = particle.color.withValues(
        alpha: particleAlpha + math.sin(animationValue * 2 * math.pi + particle.position.dx) * 0.2,
      );
      
      // Create organic movement patterns
      final phase = i * 0.3; // Different phase for each particle
      final animatedPosition = Offset(
        particle.position.dx + math.sin(animationValue * particleSpeed * math.pi + phase) * 15 * emotionalVariety,
        particle.position.dy + math.cos(animationValue * particleSpeed * math.pi * 1.3 + phase) * 10 * emotionalVariety,
      );
      
      // Clamp particle position to stay within bounds
      final clampedPosition = Offset(
        animatedPosition.dx.clamp(particle.size, size.width - particle.size),
        animatedPosition.dy.clamp(particle.size, size.height - particle.size),
      );
      
      // Draw particle with size influenced by emotional balance
      final particleSize = particle.size * (0.8 + emotionalIntensity * 0.4);
      canvas.drawCircle(clampedPosition, particleSize, paint);
      
      // Add glow effect for positive emotional states
      if (moodBalance > 0.3) {
        paint.color = particle.color.withValues(alpha: 0.1);
        canvas.drawCircle(clampedPosition, particleSize * 2, paint);
      }
    }
    
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
  bool shouldRepaint(EmotionalStatePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.moodBalance != moodBalance ||
           oldDelegate.emotionalVariety != emotionalVariety;
  }
}

