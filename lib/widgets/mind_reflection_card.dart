import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/widgets/base_card.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/providers/emotional_mirror_provider.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/models/emotional_mirror_data.dart';
import 'package:spiral_journal/models/emotional_state.dart';
import 'package:spiral_journal/widgets/primary_emotional_state_widget.dart';

class MindReflectionCard extends StatelessWidget {
  const MindReflectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmotionalMirrorProvider, JournalProvider>(
      builder: (context, mirrorProvider, journalProvider, child) {
        return BaseCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section using standardized component
              CardHeader(
                icon: Icons.auto_awesome_rounded,
                title: 'Mind Reflection',
                iconBackgroundColor: DesignTokens.accentYellow,
                iconColor: Colors.white,
              ),
              SizedBox(height: DesignTokens.spaceXL),
              
              // Analysis content section using standardized container
              CardContentContainer(
                child: _buildContent(context, mirrorProvider, journalProvider),
              ),
              SizedBox(height: DesignTokens.spaceXL),
              
              // Footer section using standardized component
              CardFooter(
                description: _getFooterDescription(mirrorProvider, journalProvider),
                ctaText: 'View Details',
                onCtaPressed: () {
                  NavigationService.instance.switchToTab(NavigationService.mirrorTab);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, EmotionalMirrorProvider provider, JournalProvider journalProvider) {
    // Get the primary emotional state from recent journal entries
    final primaryEmotionalState = _getPrimaryEmotionalState(context, journalProvider);
    
    if (provider.isLoading || journalProvider.isLoading) {
      return Column(
        children: [
          CircularProgressIndicator(
            color: DesignTokens.getPrimaryColor(context),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            'Analyzing your emotional state...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      );
    }

    if (provider.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to Load Insights',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            'We couldn\'t analyze your recent entries right now. Try refreshing or check back later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      );
    }

    // If we have a primary emotional state, use the PrimaryEmotionalStateWidget
    if (primaryEmotionalState != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Emotional Reflection',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Use the actual PrimaryEmotionalStateWidget
          PrimaryEmotionalStateWidget(
            primaryState: primaryEmotionalState,
            showAnimation: false, // Disable animations in card context
            showTabs: false, // Only show primary emotion
            showTimestamp: false, // Hide timestamp in card
            focusable: false, // Not focusable in card context
            onTap: () {
              NavigationService.instance.switchToTab(NavigationService.mirrorTab);
            },
          ),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Add personalized insights based on the emotion
          ..._generateInsightsFromState(primaryEmotionalState).asMap().entries.map((entry) {
            final index = entry.key;
            final insight = entry.value;
            return Column(
              children: [
                _buildInsightBullet(context, insight),
                if (index < 2) SizedBox(height: DesignTokens.spaceL), // Only show spacing between first 3 insights
              ],
            );
          }).take(3).toList(),
        ],
      );
    }

    // Fallback to mirror data insights if no primary state
    final mirrorData = provider.mirrorData;
    if (mirrorData == null || mirrorData.insights.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No Insights Yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            'Start journaling to see personalized insights about your emotional patterns and growth.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      );
    }

    // Show insights from the emotional mirror data
    final insights = mirrorData.insights.take(3).toList();
    final moodDescription = mirrorData.moodOverview.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotional Pattern Analysis',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: DesignTokens.getTextPrimary(context),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: DesignTokens.spaceXL),
        
        Text(
          moodDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.4,
            color: DesignTokens.getTextSecondary(context),
          ),
        ),
        SizedBox(height: DesignTokens.spaceXXL),
        
        ...insights.asMap().entries.map((entry) {
          final index = entry.key;
          final insight = entry.value;
          return Column(
            children: [
              _buildInsightBullet(context, insight),
              if (index < insights.length - 1) SizedBox(height: DesignTokens.spaceXL),
            ],
          );
        }).toList(),
      ],
    );
  }

  String _getFooterDescription(EmotionalMirrorProvider provider, JournalProvider journalProvider) {
    // Note: We can't get context here, so we'll check journal provider differently
    final recentEntries = journalProvider.entries.take(5).toList();
    final hasRecentEmotionalData = recentEntries.any((entry) => 
      entry.isAnalyzed && entry.aiAnalysis != null && entry.aiAnalysis!.primaryEmotions.isNotEmpty);
    
    if (hasRecentEmotionalData) {
      return 'Based on your recent emotional state';
    }
    
    final mirrorData = provider.mirrorData;
    if (mirrorData == null) {
      return 'Connect with your emotional patterns';
    }
    
    final analyzedCount = mirrorData.analyzedEntries;
    
    if (analyzedCount == 0) {
      return 'Start journaling to see insights';
    }
    
    return 'Based on $analyzedCount analyzed entries';
  }

  /// Get the primary emotional state from recent journal entries
  EmotionalState? _getPrimaryEmotionalState(BuildContext context, JournalProvider journalProvider) {
    final recentEntries = journalProvider.entries.take(10).toList(); // Look at more entries
    
    if (recentEntries.isEmpty) return null;
    
    // Collect all emotions and intensities from recent analyzed entries
    final List<Map<String, dynamic>> emotionData = [];
    
    for (final entry in recentEntries) {
      if (entry.isAnalyzed && entry.aiAnalysis != null && entry.aiAnalysis!.primaryEmotions.isNotEmpty) {
        for (final emotion in entry.aiAnalysis!.primaryEmotions) {
          emotionData.add({
            'emotion': emotion,
            'intensity': entry.aiAnalysis!.emotionalIntensity,
            'date': entry.date,
          });
        }
      }
    }
    
    if (emotionData.isEmpty) return null;
    
    // Find the most frequent emotion in recent entries
    final emotionCounts = <String, List<double>>{};
    for (final data in emotionData) {
      final emotion = data['emotion'] as String;
      final intensity = data['intensity'] as double;
      
      emotionCounts[emotion] ??= [];
      emotionCounts[emotion]!.add(intensity);
    }
    
    // Calculate weighted average for each emotion
    String dominantEmotion = '';
    double maxWeight = 0.0;
    double avgIntensity = 0.0;
    
    for (final entry in emotionCounts.entries) {
      final emotion = entry.key;
      final intensities = entry.value;
      final avgEmotionIntensity = intensities.reduce((a, b) => a + b) / intensities.length;
      final weight = intensities.length * avgEmotionIntensity; // Frequency * avg intensity
      
      if (weight > maxWeight) {
        maxWeight = weight;
        dominantEmotion = emotion;
        avgIntensity = avgEmotionIntensity;
      }
    }
    
    if (dominantEmotion.isEmpty) return null;
    
    // Ensure intensity is in 0.0-1.0 range
    final normalizedIntensity = avgIntensity > 1.0 ? avgIntensity / 10.0 : avgIntensity;
    final clampedIntensity = normalizedIntensity.clamp(0.0, 1.0);
    
    // Calculate confidence based on frequency and consistency
    final frequency = emotionCounts[dominantEmotion]!.length;
    final confidence = (frequency / recentEntries.length.toDouble()).clamp(0.3, 1.0);
    
    return EmotionalState.create(
      emotion: dominantEmotion,
      intensity: clampedIntensity,
      confidence: confidence,
      context: context,
      customDescription: _getEmotionDescription(dominantEmotion),
    );
  }


  /// Generate insights based on emotional state with variety and context
  List<String> _generateInsightsFromState(EmotionalState state) {
    final insights = <String>[];
    final emotion = state.emotion.toLowerCase();
    final intensity = state.intensity;
    final timestamp = state.timestamp;
    
    // Generate time-aware insights
    final timeContext = _getTimeContext(timestamp);
    final intensityLevel = _getIntensityLevel(intensity);
    
    // Generate varied insights based on emotion and context
    final baseInsights = _getEmotionInsights(emotion, intensityLevel, timeContext);
    insights.addAll(baseInsights);
    
    // Add contextual insights based on time and intensity patterns
    final contextualInsight = _generateContextualInsight(emotion, intensity, timeContext);
    if (contextualInsight.isNotEmpty && !insights.contains(contextualInsight)) {
      insights.add(contextualInsight);
    }
    
    // Add growth-oriented insight
    final growthInsight = _generateGrowthInsight(emotion, intensity);
    if (growthInsight.isNotEmpty && !insights.contains(growthInsight)) {
      insights.add(growthInsight);
    }
    
    // Ensure we have at least 2 unique insights
    if (insights.length < 2) {
      insights.add('Your emotional awareness is developing through mindful reflection');
    }
    
    return insights.take(3).toList();
  }

  /// Get time-based context for insights
  String _getTimeContext(DateTime timestamp) {
    final now = DateTime.now();
    final timeDiff = now.difference(timestamp);
    
    if (timeDiff.inMinutes < 30) return 'recent';
    if (timeDiff.inHours < 6) return 'earlier_today';
    if (timeDiff.inDays < 1) return 'today';
    if (timeDiff.inDays < 7) return 'this_week';
    return 'past';
  }

  /// Get intensity level description
  String _getIntensityLevel(double intensity) {
    if (intensity > 0.8) return 'high';
    if (intensity > 0.6) return 'strong';
    if (intensity > 0.4) return 'moderate';
    if (intensity > 0.2) return 'mild';
    return 'subtle';
  }

  /// Generate varied insights based on emotion type
  List<String> _getEmotionInsights(String emotion, String intensity, String timeContext) {
    final insights = <String>[];
    
    // Create insight pools for each emotion type
    if (emotion.contains('happy') || emotion.contains('joy')) {
      final happyInsights = [
        'Your positive energy creates ripples of joy in your daily experience',
        'Happiness reflects your inner alignment with what truly matters',
        'This joyful state enhances your creativity and social connections',
        'Your optimism is a strength that helps you navigate life\'s challenges',
        'Joy often emerges when we feel grateful and present in the moment',
      ];
      insights.add(_selectVariedInsight(happyInsights, emotion, intensity));
      
    } else if (emotion.contains('calm') || emotion.contains('peaceful')) {
      final calmInsights = [
        'Inner peace allows for deeper self-understanding and clarity',
        'Your calm state creates space for meaningful reflection and growth',
        'Tranquility indicates a healthy balance between action and rest',
        'This peaceful moment offers an opportunity for renewed perspective',
        'Calmness strengthens your ability to respond rather than react',
      ];
      insights.add(_selectVariedInsight(calmInsights, emotion, intensity));
      
    } else if (emotion.contains('anxious') || emotion.contains('worried')) {
      final anxiousInsights = [
        'Anxiety often signals that something important deserves your attention',
        'These feelings show your care and investment in meaningful outcomes',
        'Worry can be transformed into productive planning and preparation',
        'Your sensitivity to uncertainty reflects deep emotional intelligence',
        'This discomfort may be guiding you toward necessary changes',
      ];
      insights.add(_selectVariedInsight(anxiousInsights, emotion, intensity));
      
    } else if (emotion.contains('sad') || emotion.contains('melancholy')) {
      final sadInsights = [
        'Sadness reflects your capacity to value what matters deeply',
        'Processing difficult emotions builds emotional resilience over time',
        'This introspective state often precedes important personal insights',
        'Your willingness to feel sadness shows emotional courage and authenticity',
        'Melancholy can deepen your appreciation for life\'s precious moments',
      ];
      insights.add(_selectVariedInsight(sadInsights, emotion, intensity));
      
    } else if (emotion.contains('excited') || emotion.contains('energetic')) {
      final excitedInsights = [
        'Your enthusiasm creates momentum for positive change and growth',
        'Excitement indicates alignment between your values and opportunities',
        'This energetic state enhances your ability to inspire and connect with others',
        'Your anticipation reflects hope and engagement with life\'s possibilities',
        'Channel this vitality into projects that reflect your authentic interests',
      ];
      insights.add(_selectVariedInsight(excitedInsights, emotion, intensity));
      
    } else {
      final generalInsights = [
        'Every emotional experience offers unique wisdom about your inner landscape',
        'Your emotional complexity reflects a rich and evolving inner life',
        'This feeling provides valuable information about your current needs and values',
        'Emotional awareness is the foundation of personal growth and authentic living',
        'Your willingness to explore emotions demonstrates courage and self-compassion',
      ];
      insights.add(_selectVariedInsight(generalInsights, emotion, intensity));
    }
    
    return insights;
  }

  /// Select varied insight based on emotion and intensity
  String _selectVariedInsight(List<String> insightPool, String emotion, String intensity) {
    // Use a simple hash to vary selection based on emotion and intensity
    final hash = (emotion.hashCode + intensity.hashCode).abs();
    return insightPool[hash % insightPool.length];
  }

  /// Generate contextual insight based on time and patterns
  String _generateContextualInsight(String emotion, double intensity, String timeContext) {
    switch (timeContext) {
      case 'recent':
        if (intensity > 0.7) {
          return 'Strong emotions in the present moment offer immediate opportunities for self-discovery';
        }
        return 'Recent feelings often reveal your immediate responses to current life situations';
      
      case 'earlier_today':
        return 'Reflecting on earlier emotions helps you understand your daily emotional rhythms';
      
      case 'today':
        return 'Today\'s emotional patterns provide insights into your current life phase and priorities';
      
      case 'this_week':
        return 'This week\'s emotional themes may highlight important areas for attention and growth';
      
      default:
        return 'Past emotions viewed with perspective often reveal growth and learning patterns';
    }
  }

  /// Generate growth-oriented insight
  String _generateGrowthInsight(String emotion, double intensity) {
    if (intensity > 0.8) {
      return 'Intense emotions, when embraced with awareness, become catalysts for significant personal evolution';
    } else if (intensity > 0.5) {
      return 'Moderate emotional experiences help you develop nuanced understanding of your inner world';
    } else {
      return 'Subtle emotions require mindful attention and often reveal profound insights about your authentic self';
    }
  }

  /// Get emotion description for the emotional state
  String _getEmotionDescription(String emotion) {
    final descriptions = {
      'happy': 'A sense of joy and contentment fills your being',
      'sad': 'Processing feelings of sadness and introspection',
      'calm': 'Experiencing peace and emotional equilibrium',
      'anxious': 'Navigating feelings of worry and uncertainty',
      'excited': 'Energized with anticipation and enthusiasm',
      'angry': 'Processing intense feelings that need attention',
      'grateful': 'Appreciating the positive aspects of life',
      'frustrated': 'Working through challenging situations',
      'content': 'Finding satisfaction in the present moment',
      'peaceful': 'Embracing tranquility and inner harmony',
    };
    
    return descriptions[emotion.toLowerCase()] ?? 'Experiencing a unique emotional state';
  }


  Widget _buildInsightBullet(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.only(top: DesignTokens.spaceS),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: DesignTokens.spaceL),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
