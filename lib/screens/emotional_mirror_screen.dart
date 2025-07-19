import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../services/emotional_mirror_service.dart';
import '../widgets/emotional_trend_chart.dart';
import '../widgets/mood_distribution_chart.dart';
import '../widgets/loading_state_widget.dart' as loading_widget;
import '../utils/animation_utils.dart';
import '../utils/iphone_detector.dart';

class EmotionalMirrorScreen extends StatefulWidget {
  const EmotionalMirrorScreen({super.key});

  @override
  State<EmotionalMirrorScreen> createState() => _EmotionalMirrorScreenState();
}

class _EmotionalMirrorScreenState extends State<EmotionalMirrorScreen> {
  final EmotionalMirrorService _mirrorService = EmotionalMirrorService();
  
  EmotionalMirrorData? _mirrorData;
  List<EmotionalTrendPoint>? _intensityTrend;
  List<SentimentTrendPoint>? _sentimentTrend;
  MoodDistribution? _moodDistribution;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmotionalMirrorData();
  }

  Future<void> _loadEmotionalMirrorData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all emotional mirror data
      final results = await Future.wait([
        _mirrorService.getEmotionalMirrorData(daysBack: 30),
        _mirrorService.getEmotionalIntensityTrend(daysBack: 30),
        _mirrorService.getSentimentTrend(daysBack: 30),
        _mirrorService.getMoodDistribution(daysBack: 30),
      ]);

      setState(() {
        _mirrorData = results[0] as EmotionalMirrorData;
        _intensityTrend = results[1] as List<EmotionalTrendPoint>;
        _sentimentTrend = results[2] as List<SentimentTrendPoint>;
        _moodDistribution = results[3] as MoodDistribution;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load emotional mirror data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: DesignTokens.getBackgroundPrimary(context),
      body: RefreshIndicator(
        onRefresh: _loadEmotionalMirrorData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXXL),
                
                if (_isLoading)
                  _buildLoadingState()
                else if (_error != null)
                  _buildErrorState()
                else if (_mirrorData != null)
                  ..._buildMirrorContent()
                else
                  _buildEmptyState(),
                
                AdaptiveSpacing.vertical(baseSize: 100), // Extra space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceS)),
          decoration: BoxDecoration(
            color: DesignTokens.accentYellow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.psychology_rounded,
            color: DesignTokens.getPrimaryColor(context),
            size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeL),
          ),
        ),
        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'Emotional Mirror',
                baseFontSize: DesignTokens.fontSizeXXXL,
                fontWeight: DesignTokens.fontWeightBold,
                color: DesignTokens.getTextPrimary(context),
              ),
              if (_mirrorData != null)
                ResponsiveText(
                  'Last 30 days • ${_mirrorData!.totalEntries} entries',
                  baseFontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.getTextSecondary(context),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMirrorContent() {
    return [
      // Mood Overview Card
      _buildMoodOverviewCard(),
      AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
      
      // Emotional Trends Charts
      if (_intensityTrend != null && _intensityTrend!.isNotEmpty) ...[
        EmotionalTrendChart(
          trendPoints: _intensityTrend!,
          title: 'Emotional Intensity Trend',
          height: 220,
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
      ],
      
      if (_sentimentTrend != null && _sentimentTrend!.isNotEmpty) ...[
        SentimentTrendChart(
          trendPoints: _sentimentTrend!,
          title: 'Sentiment Over Time',
          height: 220,
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
      ],
      
      // Mood Distribution
      if (_moodDistribution != null) ...[
        MoodDistributionChart(
          distribution: _moodDistribution!,
          title: 'Mood Distribution',
          height: 280,
          showAIMoods: true,
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
      ],
      
      // Emotional Patterns
      if (_mirrorData!.emotionalPatterns.isNotEmpty) ...[
        _buildPatternsCard(),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
      ],
      
      // Self-Awareness Score
      _buildSelfAwarenessCard(),
      AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
      
      // Insights
      if (_mirrorData!.insights.isNotEmpty)
        _buildInsightsCard(),
    ];
  }

  Widget _buildMoodOverviewCard() {
    final overview = _mirrorData!.moodOverview;
    
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Mood Overview',
            baseFontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Mood balance bar
          Container(
            height: DesignTokens.spaceM,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              gradient: LinearGradient(
                colors: _getMoodBalanceColors(overview.moodBalance),
              ),
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Dominant moods
          if (overview.dominantMoods.isNotEmpty)
            Container(
              width: double.infinity,
              child: Wrap(
                spacing: DesignTokens.spaceXL,
                runSpacing: DesignTokens.spaceL,
                alignment: WrapAlignment.center,
                children: overview.dominantMoods.take(4).map((mood) {
                  return _buildMoodIndicator(
                    _formatMoodName(mood), 
                    _getMoodIcon(mood), 
                    context
                  );
                }).toList(),
              ),
            ),
          
          SizedBox(height: DesignTokens.spaceXXXL),
          ResponsiveText(
            'Your Emotional Balance',
            baseFontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
          SizedBox(height: DesignTokens.spaceL),
          ResponsiveText(
            overview.description,
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
          ),
          
          // Balance metrics
          SizedBox(height: DesignTokens.spaceXXL),
          Row(
            children: [
              _buildMetricChip(
                'Balance', 
                _formatBalance(overview.moodBalance),
                _getBalanceColor(overview.moodBalance),
              ),
              SizedBox(width: DesignTokens.spaceL),
              _buildMetricChip(
                'Variety', 
                '${(overview.emotionalVariety * 100).round()}%',
                DesignTokens.getPrimaryColor(context),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL), // Extra bottom padding
        ],
      ),
    );
  }

  Widget _buildPatternsCard() {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Emotional Patterns',
            baseFontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          ...(_mirrorData!.emotionalPatterns.take(3).map((pattern) {
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceXL),
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: _getPatternColor(pattern.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: _getPatternColor(pattern.type).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPatternIcon(pattern.type),
                          color: _getPatternColor(pattern.type),
                          size: DesignTokens.iconSizeM,
                        ),
                        SizedBox(width: DesignTokens.spaceL),
                        Expanded(
                          child: ResponsiveText(
                            pattern.title,
                            baseFontSize: DesignTokens.fontSizeM,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: DesignTokens.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spaceL),
                    ResponsiveText(
                      pattern.description,
                      baseFontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                  ],
                ),
              ),
            );
          }).toList()),
          SizedBox(height: DesignTokens.spaceL), // Extra bottom padding
        ],
      ),
    );
  }

  Widget _buildSelfAwarenessCard() {
    final score = _mirrorData!.selfAwarenessScore;
    final percentage = (score * 100).round();
    
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DesignTokens.getPrimaryColor(context),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: score,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 4,
                      ),
                    ),
                    ResponsiveText(
                      '$percentage%',
                      baseFontSize: 16,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              SizedBox(width: DesignTokens.spaceXL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Self-Awareness Score',
                      baseFontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                    SizedBox(height: DesignTokens.spaceL),
                    ResponsiveText(
                      _getSelfAwarenessDescription(score),
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          ResponsiveText(
            'Based on ${_mirrorData!.analyzedEntries} analyzed entries',
            baseFontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(height: DesignTokens.spaceL), // Extra bottom padding
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceL),
              ResponsiveText(
                'Personal Insights',
                baseFontSize: DesignTokens.fontSizeXL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          ...(_mirrorData!.insights.map((insight) {
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(
                      top: DesignTokens.spaceS, 
                      right: DesignTokens.spaceL
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.getPrimaryColor(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: ResponsiveText(
                      insight,
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
          SizedBox(height: DesignTokens.spaceL), // Extra bottom padding
        ],
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

  Widget _buildErrorState() {
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
          ResponsiveText(
            'Unable to load emotional mirror',
            baseFontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          ResponsiveText(
            _error ?? 'An unexpected error occurred',
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          AdaptiveButton(
            text: 'Retry',
            onPressed: _loadEmotionalMirrorData,
            type: ButtonType.primary,
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
          ResponsiveText(
            'Your Emotional Mirror',
            baseFontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          ResponsiveText(
            'Start journaling to see your emotional patterns and insights unfold here.',
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIndicator(String label, IconData icon, BuildContext context) {
    return Column(
      children: [
        Icon(
          icon, 
          color: DesignTokens.getPrimaryColor(context), 
          size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeM)
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
        ResponsiveText(
          label,
          baseFontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.getTextTertiary(context),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceM),
        vertical: iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceS),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            label,
            baseFontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: color,
          ),
          AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceXS),
          ResponsiveText(
            value,
            baseFontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightBold,
            color: color,
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<Color> _getMoodBalanceColors(double balance) {
    if (balance > 0.3) {
      return [Colors.green.shade300, Colors.green.shade600];
    } else if (balance < -0.3) {
      return [Colors.red.shade300, Colors.red.shade600];
    } else {
      return [Colors.blue.shade300, Colors.orange.shade400, Colors.green.shade300];
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': case 'joyful': return Icons.sentiment_very_satisfied;
      case 'excited': return Icons.celebration;
      case 'grateful': return Icons.favorite;
      case 'content': case 'peaceful': return Icons.sentiment_satisfied;
      case 'sad': return Icons.sentiment_dissatisfied;
      case 'angry': case 'frustrated': return Icons.sentiment_very_dissatisfied;
      case 'anxious': case 'worried': return Icons.psychology;
      case 'reflective': case 'thoughtful': return Icons.self_improvement;
      case 'curious': return Icons.search;
      default: return Icons.sentiment_neutral;
    }
  }

  String _formatMoodName(String mood) {
    return mood.split('_').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

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

  Color _getPatternColor(String type) {
    switch (type) {
      case 'growth': return DesignTokens.successColor;
      case 'recurring': return DesignTokens.getPrimaryColor(context);
      case 'awareness': return Colors.purple;
      default: return DesignTokens.getPrimaryColor(context);
    }
  }

  IconData _getPatternIcon(String type) {
    switch (type) {
      case 'growth': return Icons.trending_up;
      case 'recurring': return Icons.repeat;
      case 'awareness': return Icons.visibility;
      default: return Icons.insights;
    }
  }

  String _getSelfAwarenessDescription(double score) {
    if (score >= 0.8) {
      return 'Excellent emotional awareness and deep self-reflection through consistent journaling.';
    } else if (score >= 0.6) {
      return 'Strong emotional awareness with good insights from your journaling practice.';
    } else if (score >= 0.4) {
      return 'Developing emotional awareness. Continue journaling for deeper insights.';
    } else {
      return 'Building emotional awareness. Regular journaling will enhance your self-understanding.';
    }
  }
}
