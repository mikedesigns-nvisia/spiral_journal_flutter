import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/core.dart';
import '../models/journal_entry.dart';
import '../design_system/design_tokens.dart';
import '../services/accessibility_service.dart';

/// Data model for theme-core correlation
class ThemeCoreCorrelation {
  final String theme;
  final String coreId;
  final String coreName;
  final double correlationStrength; // -1.0 to 1.0
  final int occurrenceCount;
  final List<DateTime> occurrenceDates;

  ThemeCoreCorrelation({
    required this.theme,
    required this.coreId,
    required this.coreName,
    required this.correlationStrength,
    required this.occurrenceCount,
    required this.occurrenceDates,
  });
}

/// Widget that displays visual correlation charts between writing themes and core growth
class CoreCorrelationChart extends StatefulWidget {
  final List<ThemeCoreCorrelation> correlations;
  final List<EmotionalCore> cores;
  final Function(String coreId)? onCoreSelected;
  final Function(String theme)? onThemeSelected;
  final bool showAnimation;

  const CoreCorrelationChart({
    super.key,
    required this.correlations,
    required this.cores,
    this.onCoreSelected,
    this.onThemeSelected,
    this.showAnimation = true,
  });

  @override
  State<CoreCorrelationChart> createState() => _CoreCorrelationChartState();
}

class _CoreCorrelationChartState extends State<CoreCorrelationChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AccessibilityService _accessibilityService;
  String? _selectedTheme;
  String? _selectedCore;
  final Map<String, FocusNode> _themeFocusNodes = {};
  final Map<String, FocusNode> _correlationFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _accessibilityService = AccessibilityService();
    _initializeAnimation();
    _initializeFocusNodes();
  }

  void _initializeAnimation() {
    final animationDuration = _accessibilityService.getAnimationDuration(
      const Duration(milliseconds: 1500),
    );
    
    _animationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: _accessibilityService.getAnimationCurve(Curves.easeOutCubic),
    );

    if (widget.showAnimation && !_accessibilityService.reducedMotionMode) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  void _initializeFocusNodes() {
    // Create focus nodes for themes
    for (final correlation in widget.correlations) {
      if (!_themeFocusNodes.containsKey(correlation.theme)) {
        _themeFocusNodes[correlation.theme] = _accessibilityService.createAccessibleFocusNode(
          debugLabel: '${correlation.theme} theme',
        );
      }
      
      final correlationKey = '${correlation.theme}_${correlation.coreId}';
      if (!_correlationFocusNodes.containsKey(correlationKey)) {
        _correlationFocusNodes[correlationKey] = _accessibilityService.createAccessibleFocusNode(
          debugLabel: '${correlation.theme} to ${correlation.coreName} correlation',
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final focusNode in _themeFocusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _correlationFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.correlations.isEmpty) {
      return _buildEmptyState();
    }

    return Semantics(
      label: 'Theme-Core Correlation Analysis Chart',
      hint: 'Shows how your writing themes influence core development. Navigate through themes and correlations using tab or arrow keys.',
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceColor,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadius3),
          border: Border.all(
            color: _accessibilityService.highContrastMode 
                ? DesignTokens.borderColor.withOpacity(0.8)
                : DesignTokens.borderColor,
            width: _accessibilityService.highContrastMode ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            
            const SizedBox(height: DesignTokens.spacing4),
            
            _buildLegend(),
            
            const SizedBox(height: DesignTokens.spacing4),
            
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return _buildCorrelationMatrix();
              },
            ),
            
            const SizedBox(height: DesignTokens.spacing4),
            
            _buildInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacing2),
          decoration: BoxDecoration(
            color: DesignTokens.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
          ),
          child: Icon(
            Icons.scatter_plot,
            size: 20,
            color: DesignTokens.primaryColor,
          ),
        ),
        
        const SizedBox(width: DesignTokens.spacing3),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme-Core Correlation Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.primaryColor,
                ),
              ),
              
              Text(
                'How your writing themes influence core development',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing3),
      decoration: BoxDecoration(
        color: DesignTokens.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
      ),
      child: Row(
        children: [
          _buildLegendItem('Strong Positive', DesignTokens.successColor, 0.8),
          const SizedBox(width: DesignTokens.spacing4),
          _buildLegendItem('Moderate', DesignTokens.primaryColor, 0.5),
          const SizedBox(width: DesignTokens.spacing4),
          _buildLegendItem('Weak', DesignTokens.neutralColor, 0.2),
          const SizedBox(width: DesignTokens.spacing4),
          _buildLegendItem('Negative', DesignTokens.warningColor, 0.3),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double opacity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1),
          ),
        ),
        
        const SizedBox(width: DesignTokens.spacing1),
        
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DesignTokens.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCorrelationMatrix() {
    // Group correlations by theme
    final themeGroups = <String, List<ThemeCoreCorrelation>>{};
    for (final correlation in widget.correlations) {
      themeGroups.putIfAbsent(correlation.theme, () => []).add(correlation);
    }

    // Get top themes by total correlation strength
    final sortedThemes = themeGroups.keys.toList();
    sortedThemes.sort((a, b) {
      final strengthA = themeGroups[a]!.fold(0.0, (sum, c) => sum + c.correlationStrength.abs());
      final strengthB = themeGroups[b]!.fold(0.0, (sum, c) => sum + c.correlationStrength.abs());
      return strengthB.compareTo(strengthA);
    });

    return Column(
      children: sortedThemes.take(6).map((theme) {
        final correlations = themeGroups[theme]!;
        return _buildThemeRow(theme, correlations);
      }).toList(),
    );
  }

  Widget _buildThemeRow(String theme, List<ThemeCoreCorrelation> correlations) {
    final isSelected = _selectedTheme == theme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme header
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedTheme = isSelected ? null : theme;
                _selectedCore = null;
              });
              widget.onThemeSelected?.call(theme);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacing3,
                vertical: DesignTokens.spacing2,
              ),
              decoration: BoxDecoration(
                color: isSelected 
                    ? DesignTokens.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
                border: isSelected 
                    ? Border.all(color: DesignTokens.primaryColor.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 16,
                    color: DesignTokens.primaryColor,
                  ),
                  
                  const SizedBox(width: DesignTokens.spacing2),
                  
                  Expanded(
                    child: Text(
                      theme,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? DesignTokens.primaryColor
                            : DesignTokens.textPrimaryColor,
                      ),
                    ),
                  ),
                  
                  Icon(
                    isSelected ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: DesignTokens.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
          
          // Core correlations
          if (isSelected) ...[
            const SizedBox(height: DesignTokens.spacing2),
            
            Padding(
              padding: const EdgeInsets.only(left: DesignTokens.spacing4),
              child: Wrap(
                spacing: DesignTokens.spacing2,
                runSpacing: DesignTokens.spacing2,
                children: correlations.map((correlation) {
                  return _buildCorrelationBubble(correlation);
                }).toList(),
              ),
            ),
          ] else ...[
            // Compact view showing correlation strength
            const SizedBox(height: DesignTokens.spacing1),
            
            Padding(
              padding: const EdgeInsets.only(left: DesignTokens.spacing4),
              child: _buildCorrelationBar(correlations),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrelationBubble(ThemeCoreCorrelation correlation) {
    final isSelected = _selectedCore == correlation.coreId;
    final strength = correlation.correlationStrength.abs();
    final isPositive = correlation.correlationStrength > 0;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCore = isSelected ? null : correlation.coreId;
        });
        widget.onCoreSelected?.call(correlation.coreId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing3,
          vertical: DesignTokens.spacing2,
        ),
        decoration: BoxDecoration(
          color: _getCorrelationColor(correlation.correlationStrength)
              .withOpacity(0.1 + (strength * 0.3)),
          borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
          border: Border.all(
            color: _getCorrelationColor(correlation.correlationStrength)
                .withOpacity(0.5 + (strength * 0.5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Core indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getCoreColor(correlation.coreId),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 10,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: DesignTokens.spacing2),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  correlation.coreName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getCorrelationColor(correlation.correlationStrength),
                  ),
                ),
                
                Text(
                  '${(correlation.correlationStrength * 100).toStringAsFixed(0)}% impact',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: DesignTokens.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationBar(List<ThemeCoreCorrelation> correlations) {
    final totalStrength = correlations.fold(0.0, (sum, c) => sum + c.correlationStrength.abs());
    final maxStrength = math.max(1.0, totalStrength);
    
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: DesignTokens.borderColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Transform.scale(
          scaleX: _animation.value,
          alignment: Alignment.centerLeft,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.primaryColor.withOpacity(0.3),
                  DesignTokens.primaryColor.withOpacity(0.7),
                ],
              ),
            ),
            child: FractionallySizedBox(
              widthFactor: (totalStrength / maxStrength).clamp(0.0, 1.0),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsights() {
    final strongCorrelations = widget.correlations
        .where((c) => c.correlationStrength.abs() > 0.5)
        .toList();
    
    if (strongCorrelations.isEmpty) {
      return const SizedBox.shrink();
    }

    strongCorrelations.sort((a, b) => b.correlationStrength.abs().compareTo(a.correlationStrength.abs()));
    final topCorrelation = strongCorrelations.first;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing3),
      decoration: BoxDecoration(
        color: DesignTokens.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
        border: Border.all(
          color: DesignTokens.successColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: DesignTokens.successColor,
          ),
          
          const SizedBox(width: DesignTokens.spacing2),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Insight',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.successColor,
                  ),
                ),
                
                const SizedBox(height: DesignTokens.spacing1),
                
                Text(
                  'Writing about "${topCorrelation.theme}" has the strongest positive impact on your ${topCorrelation.coreName} core (${(topCorrelation.correlationStrength * 100).toStringAsFixed(0)}% correlation).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing6),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceColor,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius3),
        border: Border.all(
          color: DesignTokens.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.scatter_plot_outlined,
            size: 48,
            color: DesignTokens.textSecondaryColor.withOpacity(0.5),
          ),
          
          const SizedBox(height: DesignTokens.spacing3),
          
          Text(
            'No Correlations Found Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DesignTokens.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: DesignTokens.spacing2),
          
          Text(
            'Keep journaling to discover patterns between your writing themes and core development.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DesignTokens.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCorrelationColor(double correlation) {
    if (correlation > 0.3) {
      return DesignTokens.successColor;
    } else if (correlation < -0.3) {
      return DesignTokens.warningColor;
    } else {
      return DesignTokens.primaryColor;
    }
  }

  Color _getCoreColor(String coreId) {
    final core = widget.cores.firstWhere(
      (c) => c.id == coreId,
      orElse: () => widget.cores.first,
    );
    
    try {
      return Color(int.parse(core.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return DesignTokens.primaryColor;
    }
  }
}