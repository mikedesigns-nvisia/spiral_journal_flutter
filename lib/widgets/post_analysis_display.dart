import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/models/emotional_mirror_data.dart';
import 'package:spiral_journal/models/emotional_analysis.dart';
import 'package:spiral_journal/models/emotion_matrix.dart';
import 'package:spiral_journal/widgets/emotional_journey_visualization.dart';

/// Enhanced widget that displays AI analysis results using the new Claude response structure
class PostAnalysisDisplay extends StatelessWidget {
  final JournalEntry? journalEntry;
  final EmotionalAnalysisResult? analysisResult; // Legacy support
  final List<JournalEntry>? recentEntries; // For the new visualization
  final VoidCallback? onViewAnalysis;

  const PostAnalysisDisplay({
    super.key,
    this.journalEntry,
    this.analysisResult, // Made optional for new structure
    this.recentEntries, // For pattern analysis
    this.onViewAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    // Note: aiAnalysis field doesn't exist in current JournalEntry model
    final analysis = analysisResult; // Use the legacy analysisResult for now
    
    // If no journal entry or no analysis is available, show placeholder
    if (journalEntry == null || analysis == null) {
      return ComponentLibrary.gradientCard(
        gradient: DesignTokens.getCardGradient(context),
        child: _buildNoAnalysisState(context),
      );
    }

    return Column(
      children: [
        // 0. Emotional Journey Visualization (Featured at top)
        EmotionalJourneyVisualization(
          recentEntries: recentEntries ?? (journalEntry != null ? [journalEntry!] : []),
          dominantMoods: _extractDominantMoods(analysis),
        ),
        
        SizedBox(height: DesignTokens.spaceXL),
        
        // 1. Entry Insight Card (Featured)
        if (analysis.entryInsight != null)
          _buildEntryInsightCard(context, analysis),
        
        if (analysis.entryInsight != null)
          SizedBox(height: DesignTokens.spaceL),
        
        // 2. Emotion Matrix Visualization
        _buildEmotionMatrixCard(context, analysis),
        
        SizedBox(height: DesignTokens.spaceL),
        
        // 3. Mind Reflection Card (Enhanced)
        if (analysis.mindReflection != null)
          _buildMindReflectionCard(context, analysis.mindReflection!),
        
        if (analysis.mindReflection != null)
          SizedBox(height: DesignTokens.spaceL),
        
        // 4. Growth Indicators Card
        if (analysis.growthIndicators.isNotEmpty)
          _buildGrowthIndicatorsCard(context, analysis),
        
        if (analysis.growthIndicators.isNotEmpty)
          SizedBox(height: DesignTokens.spaceL),
        
        // 5. Core Impact Analysis
        if (analysis.coreAdjustments.isNotEmpty)
          _buildCoreImpactCard(context, analysis),
        
        if (analysis.coreAdjustments.isNotEmpty)
          SizedBox(height: DesignTokens.spaceL),
        
        // 6. Emotional Patterns
        if (analysis.emotionalPatterns.isNotEmpty)
          _buildEmotionalPatternsCard(context, analysis),
        
        if (analysis.emotionalPatterns.isNotEmpty)
          SizedBox(height: DesignTokens.spaceL),
        
        // Action button to view full analysis (if available)
        if (onViewAnalysis != null)
          _buildViewAnalysisButton(context),
      ],
    );
  }

  /// Build the featured entry insight card
  Widget _buildEntryInsightCard(BuildContext context, EmotionalAnalysis analysis) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.accentYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: DesignTokens.accentYellow,
                  size: DesignTokens.iconSizeL,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: ResponsiveText(
                  'Key Insight',
                  baseFontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL),
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceL),
            decoration: BoxDecoration(
              color: DesignTokens.accentYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: DesignTokens.accentYellow.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ResponsiveText(
              analysis.entryInsight!,
              baseFontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getTextPrimary(context),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  /// Build comprehensive emotion matrix card
  Widget _buildEmotionMatrixCard(BuildContext context, EmotionalAnalysis analysis) {
    final emotionMatrix = analysis.emotionMatrix;
    final topEmotions = emotionMatrix.getTopEmotions(8); // Show top 8 emotions
    final hasSignificantEmotions = topEmotions.any((e) => e.value > 5.0);
    
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: DesignTokens.accentBlue,
                  size: DesignTokens.iconSizeL,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Emotional Spectrum',
                      baseFontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                    if (emotionMatrix.dominantEmotion != null)
                      ResponsiveText(
                        'Dominated by ${emotionMatrix.dominantEmotion}',
                        baseFontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                decoration: BoxDecoration(
                  color: _getEmotionalValenceColor(emotionMatrix.emotionalValence).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEmotionalValenceIcon(emotionMatrix.emotionalValence),
                      size: DesignTokens.iconSizeS,
                      color: _getEmotionalValenceColor(emotionMatrix.emotionalValence),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    ResponsiveText(
                      '${(emotionMatrix.emotionalIntensity * 100).round()}%',
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: _getEmotionalValenceColor(emotionMatrix.emotionalValence),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spaceL),
          
          if (!hasSignificantEmotions)
            // Show placeholder when no significant emotions
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceXL),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sentiment_neutral,
                      size: DesignTokens.iconSizeL,
                      color: DesignTokens.getTextTertiary(context),
                    ),
                    SizedBox(height: DesignTokens.spaceM),
                    ResponsiveText(
                      'Neutral emotional state',
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                  ],
                ),
              ),
            )
          else
            // Show emotion matrix visualization
            Column(
              children: [
                // Top emotions as progress bars
                ...topEmotions.where((e) => e.value > 1.0).map((emotionEntry) {
                  final emotion = emotionEntry.key;
                  final percentage = emotionEntry.value;
                  final isPositive = EmotionalState.isPositiveEmotion(emotion);
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: EdgeInsets.only(right: DesignTokens.spaceS),
                                    decoration: BoxDecoration(
                                      color: isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: ResponsiveText(
                                      emotion.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                                      baseFontSize: DesignTokens.fontSizeM,
                                      fontWeight: DesignTokens.fontWeightMedium,
                                      color: DesignTokens.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ResponsiveText(
                              '${percentage.round()}%',
                              baseFontSize: DesignTokens.fontSizeM,
                              fontWeight: DesignTokens.fontWeightBold,
                              color: isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
                            ),
                          ],
                        ),
                        SizedBox(height: DesignTokens.spaceS),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                            color: DesignTokens.getBackgroundTertiary(context),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (percentage / 100.0).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                                gradient: LinearGradient(
                                  colors: [
                                    isPositive 
                                        ? DesignTokens.successColor.withValues(alpha: 0.6)
                                        : DesignTokens.warningColor.withValues(alpha: 0.6),
                                    isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                // Emotional balance indicator
                SizedBox(height: DesignTokens.spaceL),
                Container(
                  padding: EdgeInsets.all(DesignTokens.spaceL),
                  decoration: BoxDecoration(
                    color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.balance,
                        size: DesignTokens.iconSizeM,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                      SizedBox(width: DesignTokens.spaceM),
                      Expanded(
                        child: ResponsiveText(
                          'Emotional Balance: ${_getEmotionalBalanceDescription(emotionMatrix.emotionalValence)}',
                          baseFontSize: DesignTokens.fontSizeM,
                          fontWeight: DesignTokens.fontWeightRegular,
                          color: DesignTokens.getTextSecondary(context),
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

  /// Get color based on emotional valence
  Color _getEmotionalValenceColor(double valence) {
    if (valence > 0.2) return DesignTokens.successColor;
    if (valence < -0.2) return DesignTokens.warningColor;
    return DesignTokens.accentBlue;
  }

  /// Get icon based on emotional valence
  IconData _getEmotionalValenceIcon(double valence) {
    if (valence > 0.2) return Icons.sentiment_very_satisfied;
    if (valence < -0.2) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_neutral;
  }

  /// Get description of emotional balance
  String _getEmotionalBalanceDescription(double valence) {
    if (valence > 0.4) return 'Very Positive';
    if (valence > 0.2) return 'Positive';
    if (valence > -0.2) return 'Balanced';
    if (valence > -0.4) return 'Negative';
    return 'Very Negative';
  }

  /// Build enhanced mind reflection card
  Widget _buildMindReflectionCard(BuildContext context, MindReflection mindReflection) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: DesignTokens.accentGreen,
                  size: DesignTokens.iconSizeL,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: ResponsiveText(
                  mindReflection.title,
                  baseFontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL),
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceL),
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: ResponsiveText(
              mindReflection.summary,
              baseFontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextPrimary(context),
              maxLines: null,
            ),
          ),
          if (mindReflection.insights.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spaceL),
            ...mindReflection.insights.take(3).map((insight) {
              return Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(top: DesignTokens.spaceS),
                      decoration: BoxDecoration(
                        color: DesignTokens.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceM),
                    Expanded(
                      child: ResponsiveText(
                        insight,
                        baseFontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: DesignTokens.getTextPrimary(context),
                        maxLines: null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Build growth indicators card
  Widget _buildGrowthIndicatorsCard(BuildContext context, EmotionalAnalysis analysis) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: DesignTokens.successColor,
                  size: DesignTokens.iconSizeL,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: ResponsiveText(
                  'Growth Indicators',
                  baseFontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL),
          Wrap(
            spacing: DesignTokens.spaceS,
            runSpacing: DesignTokens.spaceS,
            children: analysis.growthIndicators.map((indicator) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: DesignTokens.successColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: DesignTokens.iconSizeS,
                      color: DesignTokens.successColor,
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    ResponsiveText(
                      indicator,
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: DesignTokens.successColor,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build core impact analysis card
  Widget _buildCoreImpactCard(BuildContext context, EmotionalAnalysis analysis) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.getPrimaryColor(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  Icons.adjust_rounded,
                  color: DesignTokens.getPrimaryColor(context),
                  size: DesignTokens.iconSizeL,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: ResponsiveText(
                  'Core Impact Analysis',
                  baseFontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL),
          ...analysis.coreAdjustments.entries.map((entry) {
            final impactValue = entry.value;
            final isPositive = impactValue > 0;
            final normalizedValue = impactValue.abs().clamp(0.0, 1.0);
            
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        entry.key,
                        baseFontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.getTextPrimary(context),
                      ),
                      Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            size: DesignTokens.iconSizeS,
                            color: isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
                          ),
                          SizedBox(width: DesignTokens.spaceXS),
                          ResponsiveText(
                            '${(normalizedValue * 100).round()}%',
                            baseFontSize: DesignTokens.fontSizeM,
                            fontWeight: DesignTokens.fontWeightBold,
                            color: isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      color: DesignTokens.getBackgroundTertiary(context),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: normalizedValue,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                          color: isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build emotional patterns card
  Widget _buildEmotionalPatternsCard(BuildContext context, EmotionalAnalysis analysis) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: DesignTokens.accentBlue,
                  size: DesignTokens.iconSizeL,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: ResponsiveText(
                  'Emotional Patterns',
                  baseFontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL),
          ...analysis.emotionalPatterns.take(3).map((pattern) {
            return Container(
              margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
              padding: EdgeInsets.all(DesignTokens.spaceL),
              decoration: BoxDecoration(
                color: pattern.isGrowth 
                    ? DesignTokens.successColor.withValues(alpha: 0.1)
                    : DesignTokens.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: pattern.isGrowth 
                      ? DesignTokens.successColor.withValues(alpha: 0.3)
                      : DesignTokens.warningColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceS,
                          vertical: DesignTokens.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: pattern.isGrowth 
                              ? DesignTokens.successColor.withValues(alpha: 0.2)
                              : DesignTokens.warningColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                        child: ResponsiveText(
                          pattern.category,
                          baseFontSize: DesignTokens.fontSizeS,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: pattern.isGrowth 
                              ? DesignTokens.successColor
                              : DesignTokens.warningColor,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spaceS),
                      Icon(
                        pattern.isGrowth ? Icons.trending_up : Icons.info_outline,
                        size: DesignTokens.iconSizeS,
                        color: pattern.isGrowth 
                            ? DesignTokens.successColor
                            : DesignTokens.warningColor,
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  ResponsiveText(
                    pattern.title,
                    baseFontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  ResponsiveText(
                    pattern.description,
                    baseFontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.getTextSecondary(context),
                    maxLines: null,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build no analysis state
  Widget _buildNoAnalysisState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.psychology_outlined,
          size: DesignTokens.iconSizeXL,
          color: DesignTokens.getTextTertiary(context),
        ),
        SizedBox(height: DesignTokens.spaceL),
        ResponsiveText(
          'Processing Pending',
          baseFontSize: DesignTokens.fontSizeL,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.getTextSecondary(context),
        ),
        SizedBox(height: DesignTokens.spaceS),
        ResponsiveText(
          'Your journal entry is being processed...',
          baseFontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.getTextTertiary(context),
        ),
      ],
    );
  }

  Widget _buildViewAnalysisButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onViewAnalysis,
        icon: Icon(
          Icons.psychology_rounded,
          size: DesignTokens.iconSizeM,
        ),
        label: ResponsiveText(
          'View Analysis',
          baseFontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.getPrimaryColor(context),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceXL,
            vertical: DesignTokens.spaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
        ),
      ),
    );
  }
  
  /// Extract dominant moods from EmotionalAnalysis for the new visualization
  List<String> _extractDominantMoods(dynamic analysis) {
    if (analysis == null) {
      // Fallback to journal entry moods if available
      if (journalEntry != null) {
        return journalEntry!.moods.take(4).toList();
      }
      return [];
    }
    
    // Try to get primary emotions from EmotionalAnalysisResult
    try {
      if (analysis.primaryEmotions != null) {
        return List<String>.from(analysis.primaryEmotions).take(4).toList();
      }
    } catch (e) {
      // If field doesn't exist, continue to fallback
    }
    
    // Fallback to journal entry moods if available
    if (journalEntry != null) {
      return journalEntry!.moods.take(4).toList();
    }
    
    return [];
  }
}