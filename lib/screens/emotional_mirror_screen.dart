import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/emotional_mirror_service.dart';
import '../widgets/emotional_trend_chart.dart';
import '../widgets/mood_distribution_chart.dart';
import '../widgets/loading_state_widget.dart';
import '../utils/animation_utils.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundPrimary(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEmotionalMirrorData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: AppTheme.getPrimaryColor(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emotional Mirror',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          if (_mirrorData != null)
                            Text(
                              'Last 30 days • ${_mirrorData!.totalEntries} entries',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                if (_isLoading)
                  _buildLoadingState()
                else if (_error != null)
                  _buildErrorState()
                else if (_mirrorData != null)
                  ..._buildMirrorContent()
                else
                  _buildEmptyState(),
                
                const SizedBox(height: 100), // Extra space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMirrorContent() {
    return [
      // Mood Overview Card
      _buildMoodOverviewCard(),
      const SizedBox(height: 24),
      
      // Emotional Trends Charts
      if (_intensityTrend != null && _intensityTrend!.isNotEmpty) ...[
        EmotionalTrendChart(
          trendPoints: _intensityTrend!,
          title: 'Emotional Intensity Trend',
          height: 220,
        ),
        const SizedBox(height: 24),
      ],
      
      if (_sentimentTrend != null && _sentimentTrend!.isNotEmpty) ...[
        SentimentTrendChart(
          trendPoints: _sentimentTrend!,
          title: 'Sentiment Over Time',
          height: 220,
        ),
        const SizedBox(height: 24),
      ],
      
      // Mood Distribution
      if (_moodDistribution != null) ...[
        MoodDistributionChart(
          distribution: _moodDistribution!,
          title: 'Mood Distribution',
          height: 280,
          showAIMoods: true,
        ),
        const SizedBox(height: 24),
      ],
      
      // Emotional Patterns
      if (_mirrorData!.emotionalPatterns.isNotEmpty) ...[
        _buildPatternsCard(),
        const SizedBox(height: 24),
      ],
      
      // Self-Awareness Score
      _buildSelfAwarenessCard(),
      const SizedBox(height: 24),
      
      // Insights
      if (_mirrorData!.insights.isNotEmpty)
        _buildInsightsCard(),
    ];
  }

  Widget _buildMoodOverviewCard() {
    final overview = _mirrorData!.moodOverview;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.getCardGradient(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkBackgroundTertiary 
              : AppTheme.backgroundTertiary
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Mood balance bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: _getMoodBalanceColors(overview.moodBalance),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Dominant moods
          if (overview.dominantMoods.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: overview.dominantMoods.take(4).map((mood) {
                return _buildMoodIndicator(
                  _formatMoodName(mood), 
                  _getMoodIcon(mood), 
                  context
                );
              }).toList(),
            ),
          
          const SizedBox(height: 24),
          Text(
            'Your Emotional Balance',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overview.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          // Balance metrics
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricChip(
                'Balance', 
                _formatBalance(overview.moodBalance),
                _getBalanceColor(overview.moodBalance),
              ),
              const SizedBox(width: 12),
              _buildMetricChip(
                'Variety', 
                '${(overview.emotionalVariety * 100).round()}%',
                AppTheme.getPrimaryColor(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.getCardGradient(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkBackgroundTertiary 
              : AppTheme.backgroundTertiary
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotional Patterns',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          ...(_mirrorData!.emotionalPatterns.take(3).map((pattern) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getPatternColor(pattern.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pattern.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pattern.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildSelfAwarenessCard() {
    final score = _mirrorData!.selfAwarenessScore;
    final percentage = (score * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.getCardGradient(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkBackgroundTertiary 
              : AppTheme.backgroundTertiary
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
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
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Self-Awareness Score',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSelfAwarenessDescription(score),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on ${_mirrorData!.analyzedEntries} analyzed entries',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.getCardGradient(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkBackgroundTertiary 
              : AppTheme.backgroundTertiary
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Personal Insights',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...(_mirrorData!.insights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.getPrimaryColor(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      insight,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: LoadingStateWidget(
          type: LoadingType.wave,
          message: 'Analyzing your emotional patterns...',
          color: AppTheme.getPrimaryColor(context),
          size: 48,
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
            size: 64,
            color: AppTheme.getTextSecondary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load emotional mirror',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEmotionalMirrorData,
            child: const Text('Retry'),
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
            size: 64,
            color: AppTheme.getTextSecondary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Emotional Mirror',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start journaling to see your emotional patterns and insights unfold here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIndicator(String label, IconData icon, BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.getPrimaryColor(context), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
    if (balance > 0.3) return Colors.green;
    if (balance < -0.3) return Colors.orange;
    return Colors.blue;
  }

  Color _getPatternColor(String type) {
    switch (type) {
      case 'growth': return Colors.green;
      case 'recurring': return Colors.blue;
      case 'awareness': return Colors.purple;
      default: return AppTheme.primaryLight;
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
