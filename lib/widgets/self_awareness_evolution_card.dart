import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../design_system/heading_system.dart';
import '../models/emotional_mirror_data.dart';
import '../utils/iphone_detector.dart';

/// Large premium card showing self-awareness evolution with progress tracking
class SelfAwarenessEvolutionCard extends StatefulWidget {
  final double selfAwarenessScore;
  final int analyzedEntries;
  final int totalEntries;
  final Map<String, List<CoreEvolutionPoint>>? coreEvolution;
  final VoidCallback? onTap;

  const SelfAwarenessEvolutionCard({
    super.key,
    required this.selfAwarenessScore,
    required this.analyzedEntries,
    required this.totalEntries,
    this.coreEvolution,
    this.onTap,
  });

  @override
  State<SelfAwarenessEvolutionCard> createState() => _SelfAwarenessEvolutionCardState();
}

class _SelfAwarenessEvolutionCardState extends State<SelfAwarenessEvolutionCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.selfAwarenessScore,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _progressController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          _buildMainScoreDisplay(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          _buildProgressMetrics(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          _buildSkillBreakdown(),
          if (widget.coreEvolution != null && widget.coreEvolution!.isNotEmpty) ...[
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
            _buildCoreEvolution(),
          ],
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          _buildRecommendations(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceM)),
          decoration: BoxDecoration(
            color: DesignTokens.accentGreen,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.psychology_rounded,
            color: Colors.white,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeL),
          ),
        ),
        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Self-Awareness Evolution',
                style: HeadingSystem.getHeadlineLarge(context),
              ),
              AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
              Text(
                'Track your emotional intelligence growth',
                style: HeadingSystem.getBodySmall(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainScoreDisplay() {
    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: iPhoneDetector.getAdaptiveValue(context, compact: 120, regular: 140, large: 160),
                  height: iPhoneDetector.getAdaptiveValue(context, compact: 120, regular: 140, large: 160),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              DesignTokens.accentGreen.withOpacity(0.1),
                              DesignTokens.accentGreen.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                      
                      // Progress circle
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: iPhoneDetector.getAdaptiveValue(context, compact: 100, regular: 120, large: 140),
                            height: iPhoneDetector.getAdaptiveValue(context, compact: 100, regular: 120, large: 140),
                            child: CircularProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: DesignTokens.accentGreen.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accentGreen),
                              strokeWidth: iPhoneDetector.getAdaptiveValue(context, compact: 8, regular: 10, large: 12),
                            ),
                          );
                        },
                      ),
                      
                      // Score text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Text(
                                '${(_progressAnimation.value * 100).round()}%',
                                style: HeadingSystem.getDisplaySmall(context).copyWith(
                                  color: DesignTokens.accentGreen,
                                ),
                              );
                            },
                          ),
                          Text(
                            'Awareness',
                            style: HeadingSystem.getLabelMedium(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          
          Text(
            _getScoreDescription(widget.selfAwarenessScore),
            style: HeadingSystem.getTitleMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Analyzed Entries',
            '${widget.analyzedEntries}',
            '${widget.totalEntries} total',
            Icons.analytics_rounded,
            DesignTokens.accentBlue,
          ),
        ),
        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
        Expanded(
          child: _buildMetricCard(
            'Analysis Rate',
            '${((widget.analyzedEntries / widget.totalEntries) * 100).round()}%',
            'of entries',
            Icons.trending_up_rounded,
            DesignTokens.accentYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: DesignTokens.iconSizeM,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          Text(
            value,
            style: HeadingSystem.getTitleLarge(context).copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
          Text(
            title,
            style: HeadingSystem.getLabelSmall(context),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: HeadingSystem.getLabelSmall(context).copyWith(
              color: DesignTokens.getTextTertiary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBreakdown() {
    final skills = _getSkillBreakdown();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Breakdown',
          style: HeadingSystem.getHeadlineSmall(context),
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        ...skills.map((skill) => Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
          child: _buildSkillBar(skill),
        )).toList(),
      ],
    );
  }

  Widget _buildSkillBar(SkillData skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skill.name,
              style: HeadingSystem.getTitleMedium(context),
            ),
            Text(
              '${(skill.level * 100).round()}%',
              style: HeadingSystem.getLabelMedium(context).copyWith(
                color: skill.color,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ],
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: skill.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: skill.level,
            child: Container(
              decoration: BoxDecoration(
                color: skill.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoreEvolution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core Evolution',
          style: HeadingSystem.getHeadlineSmall(context),
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.coreEvolution!.length,
            itemBuilder: (context, index) {
              final coreName = widget.coreEvolution!.keys.elementAt(index);
              final evolution = widget.coreEvolution![coreName]!;
              final currentPercentage = evolution.isNotEmpty ? evolution.last.percentage : 0.0;
              final previousPercentage = evolution.length > 1 ? evolution[evolution.length - 2].percentage : 0.0;
              final growth = currentPercentage - previousPercentage;
              
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: DesignTokens.spaceM),
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.getBackgroundSecondary(context),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: DesignTokens.getBackgroundTertiary(context),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      coreName,
                      baseFontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.getTextPrimary(context),
                      maxLines: 1,
                    ),
                    AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
                    ResponsiveText(
                      '${currentPercentage.round()}%',
                      baseFontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.accentGreen,
                    ),
                    AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
                    Row(
                      children: [
                        Icon(
                          growth >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: growth >= 0 ? DesignTokens.accentGreen : DesignTokens.accentRed,
                          size: DesignTokens.iconSizeXS,
                        ),
                        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceXS),
                        ResponsiveText(
                          '${growth >= 0 ? '+' : ''}${growth.round()}%',
                          baseFontSize: DesignTokens.fontSizeXS,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: growth >= 0 ? DesignTokens.accentGreen : DesignTokens.accentRed,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _getRecommendations();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Growth Recommendations',
          style: HeadingSystem.getHeadlineSmall(context),
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        ...recommendations.map((recommendation) => Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: DesignTokens.accentYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: DesignTokens.accentYellow.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: DesignTokens.accentYellow,
                  size: DesignTokens.iconSizeM,
                ),
                AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
                Expanded(
                  child: ResponsiveText(
                    recommendation,
                    baseFontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 0.8) {
      return 'Exceptional emotional awareness and deep self-understanding';
    } else if (score >= 0.6) {
      return 'Strong emotional intelligence with consistent growth';
    } else if (score >= 0.4) {
      return 'Developing awareness with good potential for growth';
    } else {
      return 'Building foundation for emotional self-awareness';
    }
  }


  List<SkillData> _getSkillBreakdown() {
    final baseScore = widget.selfAwarenessScore;
    
    return [
      SkillData(
        name: 'Emotional Recognition',
        level: (baseScore * 1.1).clamp(0.0, 1.0),
        color: DesignTokens.accentBlue,
      ),
      SkillData(
        name: 'Pattern Awareness',
        level: (baseScore * 0.9).clamp(0.0, 1.0),
        color: DesignTokens.accentGreen,
      ),
      SkillData(
        name: 'Self-Reflection',
        level: baseScore,
        color: DesignTokens.accentYellow,
      ),
      SkillData(
        name: 'Growth Mindset',
        level: (baseScore * 1.05).clamp(0.0, 1.0),
        color: DesignTokens.primaryOrange,
      ),
    ];
  }

  List<String> _getRecommendations() {
    final score = widget.selfAwarenessScore;
    
    if (score >= 0.8) {
      return [
        'Share your insights with others to deepen understanding',
        'Explore advanced emotional intelligence techniques',
        'Consider mentoring others in their emotional journey',
      ];
    } else if (score >= 0.6) {
      return [
        'Focus on identifying subtle emotional patterns',
        'Practice mindfulness to enhance present-moment awareness',
        'Explore the connection between thoughts and emotions',
      ];
    } else if (score >= 0.4) {
      return [
        'Increase journaling frequency for better pattern recognition',
        'Pay attention to emotional triggers and responses',
        'Practice naming emotions with greater specificity',
      ];
    } else {
      return [
        'Start with daily emotional check-ins',
        'Use the AI analysis to understand your patterns',
        'Focus on consistent journaling habits',
      ];
    }
  }
}

class SkillData {
  final String name;
  final double level;
  final Color color;

  SkillData({
    required this.name,
    required this.level,
    required this.color,
  });
}
