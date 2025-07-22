import 'package:flutter/material.dart';
import '../providers/emotional_mirror_provider.dart';
import '../design_system/design_tokens.dart';
import '../widgets/self_awareness_evolution_card.dart';
import '../widgets/loading_state_widget.dart' as loading_widget;


/// Comprehensive emotional mirror view focused on self-awareness and emotional overview
class EmotionalMirrorSlideView extends StatefulWidget {
  /// The emotional mirror provider for data access
  final EmotionalMirrorProvider provider;
  
  /// Optional callback when content changes
  final void Function(int index)? onSlideChanged;

  const EmotionalMirrorSlideView({
    super.key,
    required this.provider,
    this.onSlideChanged,
  });

  @override
  State<EmotionalMirrorSlideView> createState() => _EmotionalMirrorSlideViewState();
}

class _EmotionalMirrorSlideViewState extends State<EmotionalMirrorSlideView> {

  @override
  Widget build(BuildContext context) {
    if (widget.provider.isLoading) {
      return _buildLoadingState('Analyzing your emotional patterns...');
    }
    
    if (widget.provider.error != null) {
      return _buildErrorState(widget.provider.error!, widget.provider.refresh);
    }
    
    if (widget.provider.mirrorData == null) {
      return _buildEmptyState(
        'No Analysis Data',
        'Your emotional insights will appear here as you journal.',
        Icons.psychology_rounded,
      );
    }

    final insights = widget.provider.getFilteredInsights();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        children: [
          // Self-Awareness Evolution Card
          SelfAwarenessEvolutionCard(
            selfAwarenessScore: widget.provider.mirrorData!.selfAwarenessScore,
            analyzedEntries: widget.provider.mirrorData!.analyzedEntries,
            totalEntries: widget.provider.mirrorData!.totalEntries,
            coreEvolution: widget.provider.journeyData?.coreEvolution,
          ),
          
          // Personal Insights Section (if available)
          if (insights.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spaceXXL),
            _buildInsightsCard(insights),
          ],
          
          // Emotional Overview Section
          SizedBox(height: DesignTokens.spaceXXL),
          _buildEnhancedMoodOverview(widget.provider),
        ],
      ),
    );
  }

  /// Build enhanced mood overview content (from original screen)
  Widget _buildEnhancedMoodOverview(EmotionalMirrorProvider provider) {
    final overview = provider.mirrorData!.moodOverview;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_rounded,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Emotional Overview',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Mood balance visualization
          Container(
            height: DesignTokens.spaceL,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              gradient: LinearGradient(
                colors: _getMoodBalanceColors(overview.moodBalance),
              ),
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Enhanced metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Balance',
                  _formatBalance(overview.moodBalance),
                  _getBalanceColor(overview.moodBalance),
                  Icons.balance_rounded,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: _buildMetricCard(
                  'Variety',
                  '${(overview.emotionalVariety * 100).round()}%',
                  DesignTokens.accentBlue,
                  Icons.palette_rounded,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: _buildMetricCard(
                  'Entries',
                  '${provider.mirrorData!.totalEntries}',
                  DesignTokens.accentGreen,
                  Icons.edit_note_rounded,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          Text(
            overview.description,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Build metric card for mood overview
  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            value,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spaceXS),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build loading state for slides
  Widget _buildLoadingState(String message) {
    return Center(
      child: loading_widget.LoadingStateWidget(
        type: loading_widget.LoadingType.wave,
        message: message,
        color: DesignTokens.getPrimaryColor(context),
        size: 48,
      ),
    );
  }

  /// Build error state for slides
  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            'Unable to load this section',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.getTextPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            error,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spaceL),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build empty state for slides
  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.getTextPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            message,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get mood balance colors for visualization
  List<Color> _getMoodBalanceColors(double balance) {
    if (balance > 0.6) {
      return [DesignTokens.accentGreen, DesignTokens.accentGreen.withValues(alpha: 0.7)];
    } else if (balance > 0.4) {
      return [DesignTokens.accentYellow, DesignTokens.accentYellow.withValues(alpha: 0.7)];
    } else {
      return [DesignTokens.accentBlue, DesignTokens.accentBlue.withValues(alpha: 0.7)];
    }
  }

  /// Format balance value for display
  String _formatBalance(double balance) {
    if (balance > 0.7) return 'Excellent';
    if (balance > 0.5) return 'Good';
    if (balance > 0.3) return 'Fair';
    return 'Needs Focus';
  }

  /// Get balance color based on value
  Color _getBalanceColor(double balance) {
    if (balance > 0.6) return DesignTokens.accentGreen;
    if (balance > 0.4) return DesignTokens.accentYellow;
    return DesignTokens.accentBlue;
  }

  /// Build insights card for personal insights
  Widget _buildInsightsCard(List<String> insights) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: DesignTokens.getCardGradient(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
        ),
      ),
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
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Personal Insights',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          ...insights.map((insight) {
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
                    child: Text(
                      insight,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: DesignTokens.getTextSecondary(context),
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
}
