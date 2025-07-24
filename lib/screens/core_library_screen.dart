import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/core.dart';
import '../services/core_library_service.dart';

class CoreLibraryScreen extends StatefulWidget {
  const CoreLibraryScreen({super.key});

  @override
  State<CoreLibraryScreen> createState() => _CoreLibraryScreenState();
}

class _CoreLibraryScreenState extends State<CoreLibraryScreen> with TickerProviderStateMixin {
  final CoreLibraryService _coreService = CoreLibraryService();
  List<EmotionalCore> _cores = [];
  List<CoreCombination> _combinations = [];
  List<String> _recommendations = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadCoreData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCoreData() async {
    try {
      final cores = await _coreService.getAllCores();
      final combinations = await _coreService.getCoreCombinations();
      final recommendations = await _coreService.getGrowthRecommendations();
      
      setState(() {
        _cores = cores;
        _combinations = combinations;
        _recommendations = recommendations;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading core data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundPrimary(context),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadCoreData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildCoreOverview(),
                        const SizedBox(height: 32),
                        _buildCoreGrid(),
                        if (_combinations.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildCoreCombinations(),
                        ],
                        if (_recommendations.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildGrowthRecommendations(),
                        ],
                        const SizedBox(height: 100), // Extra space for bottom navigation
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.getColorWithOpacity(
                  AppTheme.getPrimaryColor(context), 
                  0.15
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.getPrimaryColor(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Core Library',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Track your emotional growth across six personality cores',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCoreOverview() {
    if (_cores.isEmpty) return const SizedBox.shrink();
    
    final averageLevel = _cores.map((c) => c.currentLevel).reduce((a, b) => a + b) / _cores.length;
    final risingCores = _cores.where((c) => c.trend == 'rising').length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getPrimaryColor(context).withOpacity(0.1),
            AppTheme.getPrimaryColor(context).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.getPrimaryColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Overall Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(averageLevel * 100).round()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryColor(context),
                      ),
                    ),
                    Text(
                      'Average Core Level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$risingCores',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    Text(
                      'Cores Rising',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
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

  Widget _buildCoreGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Six Personality Cores',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1, // Further increased to give much more height
          ),
          itemCount: _cores.length,
          itemBuilder: (context, index) {
            return _buildCoreCard(_cores[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCoreCard(EmotionalCore core) {
    final color = _getCoreColor(core.color);
    final trendColor = _getTrendColor(core.trend);
    
    return GestureDetector(
      onTap: () => _showCoreDetail(core),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getBackgroundSecondary(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Progress Circle
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                children: [
                  // Background circle
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                  // Progress circle
                  CustomPaint(
                    size: const Size(70, 70),
                    painter: CircularProgressPainter(
                      progress: core.currentLevel,
                      color: color,
                      strokeWidth: 5,
                    ),
                  ),
                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCoreIcon(core.id),
                          color: color,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(core.currentLevel * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Core name
            Text(
              core.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Trend indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  core.trend == 'rising' ? Icons.trending_up : 
                  core.trend == 'declining' ? Icons.trending_down : Icons.trending_flat,
                  color: trendColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  core.trend.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreCombinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core Synergies',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Powerful combinations of your strongest cores',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        ...(_combinations.map((combination) => _buildCombinationCard(combination))),
      ],
    );
  }

  Widget _buildCombinationCard(CoreCombination combination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.getPrimaryColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                combination.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            combination.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              combination.benefit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Growth Recommendations',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personalized suggestions to strengthen your cores',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        ...(_recommendations.map((recommendation) => _buildRecommendationCard(recommendation))),
      ],
    );
  }

  Widget _buildRecommendationCard(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppTheme.accentGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showCoreDetail(EmotionalCore core) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CoreDetailSheet(core: core),
    );
  }

  Color _getCoreColor(String colorHex) {
    try {
      // Handle both formats: with or without '#' prefix
      if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } else {
        return Color(int.parse('0xFF$colorHex'));
      }
    } catch (e) {
      debugPrint('CoreLibraryScreen: Error parsing color: $colorHex, error: $e');
      return AppTheme.getPrimaryColor(context);
    }
  }

  IconData _getCoreIcon(String coreId) {
    switch (coreId) {
      case 'optimism':
        return Icons.wb_sunny;
      case 'resilience':
        return Icons.shield;
      case 'self_awareness':
        return Icons.psychology;
      case 'creativity':
        return Icons.palette;
      case 'social_connection':
        return Icons.people;
      case 'growth_mindset':
        return Icons.trending_up;
      default:
        return Icons.auto_awesome;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising':
        return AppTheme.accentGreen;
      case 'declining':
        return AppTheme.accentRed;
      default:
        return AppTheme.getTextSecondary(context);
    }
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc with gradient
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.7),
          color,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Core detail sheet widget
class CoreDetailSheet extends StatefulWidget {
  final EmotionalCore core;

  const CoreDetailSheet({super.key, required this.core});

  @override
  State<CoreDetailSheet> createState() => _CoreDetailSheetState();
}

class _CoreDetailSheetState extends State<CoreDetailSheet> {
  final CoreLibraryService _coreService = CoreLibraryService();
  List<CoreMilestone> _milestones = [];
  List<CoreInsight> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoreDetails();
  }

  Future<void> _loadCoreDetails() async {
    try {
      final milestones = await _coreService.getCoreMilestones(widget.core.id);
      final insight = await _coreService.generateCoreInsight(widget.core.id);
      
      setState(() {
        _milestones = milestones;
        _insights = [insight];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading core details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCoreColor(widget.core.color);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundPrimary(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.getTextSecondary(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCoreIcon(widget.core.id),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.core.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(widget.core.currentLevel * 100).round()}% • ${widget.core.trend.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(
                          widget.core.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        
                        // Progress Timeline
                        _buildProgressTimeline(color),
                        const SizedBox(height: 24),
                        
                        // Recent Insights
                        if (_insights.isNotEmpty) ...[
                          _buildInsightsSection(),
                          const SizedBox(height: 24),
                        ],
                        
                        // Milestones
                        _buildMilestonesSection(color),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Level',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          '${(widget.core.currentLevel * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: widget.core.currentLevel,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Previous: ${(widget.core.previousLevel * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...(_insights.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                insight.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ))),
      ],
    );
  }

  Widget _buildMilestonesSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Milestones',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...(_milestones.map((milestone) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
            border: milestone.isAchieved
                ? Border.all(color: color.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                milestone.isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                color: milestone.isAchieved ? color : AppTheme.getTextSecondary(context),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: milestone.isAchieved ? color : null,
                      ),
                    ),
                    Text(
                      milestone.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                    if (milestone.isAchieved && milestone.achievedAt != null)
                      Text(
                        'Achieved ${_formatDate(milestone.achievedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${(milestone.threshold * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: milestone.isAchieved ? color : AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ))),
      ],
    );
  }

  Color _getCoreColor(String colorHex) {
    try {
      // Handle both formats: with or without '#' prefix
      if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } else {
        return Color(int.parse('0xFF$colorHex'));
      }
    } catch (e) {
      debugPrint('CoreDetailSheet: Error parsing color: $colorHex, error: $e');
      return AppTheme.getPrimaryColor(context);
    }
  }

  IconData _getCoreIcon(String coreId) {
    switch (coreId) {
      case 'optimism':
        return Icons.wb_sunny;
      case 'resilience':
        return Icons.shield;
      case 'self_awareness':
        return Icons.psychology;
      case 'creativity':
        return Icons.palette;
      case 'social_connection':
        return Icons.people;
      case 'growth_mindset':
        return Icons.trending_up;
      default:
        return Icons.auto_awesome;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    return '${(difference / 30).round()} months ago';
  }
}