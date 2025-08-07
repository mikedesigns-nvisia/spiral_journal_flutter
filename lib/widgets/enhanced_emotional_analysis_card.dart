import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/design_tokens.dart';
import '../design_system/heading_system.dart';
import '../design_system/component_library.dart';
import '../models/core.dart';
import '../providers/emotional_mirror_provider.dart';
import '../services/core_library_service.dart';
import 'simple_resonance_visualizer.dart';
import '../models/journal_entry.dart';
import 'emotional_journey_visualization.dart';

class EnhancedEmotionalAnalysisCard extends StatefulWidget {
  const EnhancedEmotionalAnalysisCard({super.key});

  @override
  State<EnhancedEmotionalAnalysisCard> createState() => _EnhancedEmotionalAnalysisCardState();
}

class _EnhancedEmotionalAnalysisCardState extends State<EnhancedEmotionalAnalysisCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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
    final provider = Provider.of<EmotionalMirrorProvider>(context);
    final coreService = CoreLibraryService();
    
    return FutureBuilder<List<EmotionalCore>>(
      future: coreService.getAllCores(),
      builder: (context, snapshot) {
        return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with core resonance indicator
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_alt_rounded,
                        color: DesignTokens.accentYellow,
                        size: DesignTokens.iconSizeL,
                      ),
                      SizedBox(width: DesignTokens.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emotional Analysis',
                              style: HeadingSystem.getHeadlineSmall(context),
                            ),
                            SizedBox(height: DesignTokens.spaceXS),
                            Text(
                              'Deep insights and patterns from your journal entries',
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
                          color: DesignTokens.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spaceM),
                  // Core resonance preview
                  _buildCoreResonancePreview(coreService),
                ],
              ),
            ),
          ),
          
          // Expanded content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded ? _buildExpandedContent(provider, coreService) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildCoreResonancePreview(CoreLibraryService coreService) {
    final topCores = coreService.getTopResonatingCores(3);
    
    if (topCores.isEmpty) {
      return _buildEmptyStatePreview();
    }
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meaningful pattern header
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: DesignTokens.iconSizeS,
                color: DesignTokens.accentBlue,
              ),
              SizedBox(width: DesignTokens.spaceS),
              Text(
                'Your Emotional Patterns',
                style: HeadingSystem.getTitleSmall(context),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Show actual insights instead of percentages
          _buildMeaningfulCoreInsights(topCores),
          
          SizedBox(height: DesignTokens.spaceM),
          
          // Mini emotional journey preview
          Container(
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _generateCoreGradient(topCores),
            ),
            child: Center(
              child: Text(
                _generateCoreInsightText(topCores),
                style: HeadingSystem.getLabelSmall(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternInsights() {
    // Instead of abstract percentages, show meaningful insights
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What We\'ll Discover Together',
          style: HeadingSystem.getTitleMedium(context),
        ),
        SizedBox(height: DesignTokens.spaceS),
        
        // Example pattern insights
        _buildInsightItem(
          icon: Icons.wb_sunny_outlined,
          text: 'How your mornings shape your day',
        ),
        SizedBox(height: DesignTokens.spaceS),
        _buildInsightItem(
          icon: Icons.weekend_outlined,
          text: 'Your weekend vs weekday patterns',
        ),
        SizedBox(height: DesignTokens.spaceS),
        _buildInsightItem(
          icon: Icons.trending_up_rounded,
          text: 'What activities boost your energy',
        ),
      ],
    );
  }

  Widget _buildInsightItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeXS,
          color: DesignTokens.getTextSecondary(context),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          child: Text(
            text,
            style: HeadingSystem.getBodySmall(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStatePreview() {
    // Get provider to check for recent entries
    final provider = Provider.of<EmotionalMirrorProvider>(context);
    
    return Container(
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
                Icons.insights_rounded,
                size: DesignTokens.iconSizeS,
                color: DesignTokens.accentBlue,
              ),
              SizedBox(width: DesignTokens.spaceS),
              Text(
                'Pattern Discovery',
                style: HeadingSystem.getTitleSmall(context).copyWith(
                  color: DesignTokens.accentBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Meaningful pattern insights instead of abstract percentages
          _buildPatternInsights(),
          
          SizedBox(height: DesignTokens.spaceM),
          
          // Visual journey hint instead of intensity bar
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceS),
            decoration: BoxDecoration(
              border: Border.all(
                color: DesignTokens.getBackgroundTertiary(context),
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline_rounded,
                      size: DesignTokens.iconSizeXS,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      'Your Emotional Journey',
                      style: HeadingSystem.getLabelSmall(context),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceXS),
                // Mini gradient preview bar
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
                        DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Start journaling to see your emotional flow',
                      style: HeadingSystem.getLabelSmall(context).copyWith(
                        color: DesignTokens.getTextSecondary(context),
                      ),
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

  Widget _buildMiniCoreIndicator(EmotionalCore core) {
    return Column(
      children: [
        SimpleResonanceVisualizer(
          core: core,
          size: 40,
          animationValue: 0.0,
        ),
        SizedBox(height: DesignTokens.spaceXS),
        Text(
          core.name,
          style: HeadingSystem.getLabelSmall(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildResonanceBar(List<EmotionalCore> cores) {
    if (cores.isEmpty) return const SizedBox.shrink();
    
    final averageResonance = cores
        .map((c) => c.currentLevel)
        .reduce((a, b) => a + b) / cores.length;
    
    return Container(
      width: 100.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${(averageResonance * 100).toInt()}%',
            style: HeadingSystem.getTitleSmall(context),
          ),
          SizedBox(height: DesignTokens.spaceXS),
          LinearProgressIndicator(
            value: averageResonance,
            backgroundColor: DesignTokens.getBackgroundTertiary(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getResonanceColor(averageResonance),
            ),
          ),
        ],
      ),
    );
  }

  Color _getResonanceColor(double level) {
    if (level < 0.3) return DesignTokens.warningColor;
    if (level < 0.6) return DesignTokens.accentBlue;
    return DesignTokens.accentGreen;
  }

  Widget _buildExpandedContent(EmotionalMirrorProvider provider, CoreLibraryService coreService) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        children: [
          // Tab selector
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundSecondary(context),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                _buildTab('Insights', 0, Icons.psychology_alt_rounded),
                _buildTab('Patterns', 1, Icons.pattern_rounded),
                _buildTab('Core Links', 2, Icons.hub_rounded),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
          // Tab content
          IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildInsightsTab(provider),
              _buildPatternsTab(provider),
              _buildCoreLinksTab(provider, coreService),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: DesignTokens.spaceM,
            horizontal: DesignTokens.spaceS,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? DesignTokens.getPrimaryColor(context).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: DesignTokens.iconSizeS,
                color: isSelected 
                    ? DesignTokens.getPrimaryColor(context)
                    : DesignTokens.getTextSecondary(context),
              ),
              SizedBox(width: DesignTokens.spaceXS),
              Text(
                title,
                style: HeadingSystem.getLabelMedium(context).copyWith(
                  color: isSelected 
                      ? DesignTokens.getPrimaryColor(context)
                      : DesignTokens.getTextSecondary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsTab(EmotionalMirrorProvider provider) {
    final insights = provider.mirrorData?.insights ?? [];
    
    if (insights.isEmpty) {
      return _buildEmptyInsights();
    }
    
    return Column(
      children: insights.take(3).map((insight) => Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
        child: _buildInsightCard(insight),
      )).toList(),
    );
  }

  Widget _buildPatternsTab(EmotionalMirrorProvider provider) {
    final patterns = provider.mirrorData?.emotionalPatterns ?? [];
    
    if (patterns.isEmpty) {
      return _buildEmptyPatterns();
    }
    
    return Column(
      children: patterns.take(3).map((pattern) => Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
        child: _buildPatternCard(pattern),
      )).toList(),
    );
  }

  Widget _buildCoreLinksTab(EmotionalMirrorProvider provider, CoreLibraryService coreService) {
    final patterns = provider.mirrorData?.emotionalPatterns ?? [];
    
    return FutureBuilder<List<EmotionalCore>>(
      future: coreService.getAllCores(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: DesignTokens.getPrimaryColor(context),
            ),
          );
        }
        
        final cores = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How your emotions connect to your cores',
              style: HeadingSystem.getBodyMedium(context),
            ),
            SizedBox(height: DesignTokens.spaceL),
            ...cores.where((core) => core.currentLevel > 0.1).map((core) => 
              _buildCoreConnectionCard(core, patterns),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoreConnectionCard(EmotionalCore core, List<dynamic> patterns) {
    // Find patterns related to this core
    final relatedPatterns = patterns.where((p) => 
      p.relatedEmotions?.any((e) => 
        core.description.toLowerCase().contains(e.toLowerCase()) ||
        core.insight.toLowerCase().contains(e.toLowerCase())
      ) ?? false
    ).toList();
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        children: [
          SimpleResonanceVisualizer(
            core: core,
            size: 48,
            animationValue: 0.0,
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  core.name,
                  style: HeadingSystem.getTitleSmall(context),
                ),
                if (relatedPatterns.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spaceXS),
                  Text(
                    '${relatedPatterns.length} related patterns detected',
                    style: HeadingSystem.getBodySmall(context).copyWith(
                      color: DesignTokens.accentBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: DesignTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: _getCoreColor(core.color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              '${(core.currentLevel * 100).toInt()}%',
              style: HeadingSystem.getLabelSmall(context).copyWith(
                color: _getCoreColor(core.color),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(dynamic insight) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: DesignTokens.accentYellow,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Text(
              insight.toString(),
              style: HeadingSystem.getBodyMedium(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(dynamic pattern) {
    return Container(
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
                Icons.pattern_rounded,
                color: DesignTokens.accentBlue,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Text(
                  pattern.title ?? 'Pattern',
                  style: HeadingSystem.getTitleSmall(context),
                ),
              ),
            ],
          ),
          if (pattern.description != null) ...[
            SizedBox(height: DesignTokens.spaceS),
            Text(
              pattern.description,
              style: HeadingSystem.getBodySmall(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyInsights() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'No insights yet',
            style: HeadingSystem.getTitleMedium(context),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            'Continue journaling to generate insights',
            style: HeadingSystem.getBodySmall(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatterns() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        children: [
          Icon(
            Icons.pattern_outlined,
            size: 48,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'No patterns detected',
            style: HeadingSystem.getTitleMedium(context),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            'Patterns emerge after multiple journal entries',
            style: HeadingSystem.getBodySmall(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCoreColor(String colorHex) {
    try {
      if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } else {
        return Color(int.parse('0xFF$colorHex'));
      }
    } catch (e) {
      return DesignTokens.accentBlue;
    }
  }

  Widget _buildMeaningfulCoreInsights(List<EmotionalCore> cores) {
    if (cores.isEmpty) return const SizedBox.shrink();
    
    // Generate insights based on core patterns
    final insights = <Widget>[];
    
    // Find the strongest core
    final strongestCore = cores.reduce((a, b) => a.currentLevel > b.currentLevel ? a : b);
    
    insights.add(
      _buildInsightItem(
        icon: Icons.star_outline_rounded,
        text: 'Your ${strongestCore.name} core is most active',
      ),
    );
    
    // Check for balance
    if (cores.length >= 2) {
      final levelDifference = (cores[0].currentLevel - cores[1].currentLevel).abs();
      if (levelDifference < 0.2) {
        insights.add(
          SizedBox(height: DesignTokens.spaceS),
        );
        insights.add(
          _buildInsightItem(
            icon: Icons.balance_rounded,
            text: 'Strong balance between ${cores[0].name} and ${cores[1].name}',
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights,
    );
  }

  LinearGradient _generateCoreGradient(List<EmotionalCore> cores) {
    if (cores.isEmpty) {
      return LinearGradient(
        colors: [
          DesignTokens.getTextTertiary(context).withValues(alpha: 0.3),
          DesignTokens.getTextTertiary(context).withValues(alpha: 0.3),
        ],
      );
    }
    
    final colors = cores.map((core) => _getCoreColor(core.color)).toList();
    if (colors.length == 1) {
      colors.add(colors.first);
    }
    
    return LinearGradient(
      colors: colors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  String _generateCoreInsightText(List<EmotionalCore> cores) {
    if (cores.isEmpty) return 'Start journaling to discover your cores';
    
    if (cores.length == 1) {
      return '${cores.first.name} is guiding you';
    }
    
    return '${cores.map((c) => c.name).take(2).join(' & ')} active';
  }
}