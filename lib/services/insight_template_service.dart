import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/insight_template.dart';

/// Service for managing and selecting insight templates
class InsightTemplateService {
  static final InsightTemplateService _instance = InsightTemplateService._internal();
  factory InsightTemplateService() => _instance;
  InsightTemplateService._internal();

  final List<InsightTemplate> _templates = [];
  final Random _random = Random();

  /// Initialize with all built-in templates
  void initialize() {
    if (_templates.isNotEmpty) return;
    
    _templates.addAll([
      ..._getGrowthTemplates(),
      ..._getReflectionTemplates(),
      ..._getActionTemplates(),
      ..._getCelebrationTemplates(),
    ]);

    if (kDebugMode) {
      debugPrint('📋 Initialized ${_templates.length} insight templates');
    }
  }

  /// Select best template for given context
  TemplateSelection? selectTemplate(TemplateContext context, {
    InsightCategory? category,
    List<String>? tags,
    bool allowFallback = true,
  }) {
    // Filter templates by category and tags
    var candidates = _templates.where((template) => template.isActive).toList();
    
    if (category != null) {
      candidates = candidates.where((t) => t.category == category).toList();
    }
    
    if (tags != null && tags.isNotEmpty) {
      candidates = candidates.where((t) => 
          tags.any((tag) => t.tags.contains(tag))).toList();
    }

    // Filter by conditions
    candidates = candidates.where((t) => t.matchesConditions(context)).toList();

    if (candidates.isEmpty && allowFallback) {
      // Fallback to any template that has required variables
      candidates = _templates.where((t) => 
          t.isActive && t.hasRequiredVariables(context)).toList();
    }

    if (candidates.isEmpty) return null;

    // Score and sort candidates
    final scoredTemplates = candidates
        .map((template) => {
          'template': template,
          'score': template.calculateScore(context),
        })
        .where((item) => (item['score']! as num) > 0)
        .toList();

    if (scoredTemplates.isEmpty) return null;

    scoredTemplates.sort((a, b) => (b['score']! as double).compareTo(a['score']! as double));

    // Select from top 3 to add some variety
    final topCandidates = scoredTemplates.take(3).toList();
    final selectedItem = topCandidates[_random.nextInt(topCandidates.length)];
    final selectedTemplate = selectedItem['template'] as InsightTemplate;
    final score = selectedItem['score'] as double;

    final generatedInsight = selectedTemplate.generateInsight(context);

    return TemplateSelection(
      template: selectedTemplate,
      score: score,
      generatedInsight: generatedInsight,
      context: context,
    );
  }

  /// Get templates by category
  List<InsightTemplate> getTemplatesByCategory(InsightCategory category) {
    return _templates.where((t) => t.category == category && t.isActive).toList();
  }

  /// Get all active templates
  List<InsightTemplate> getAllTemplates() {
    return _templates.where((t) => t.isActive).toList();
  }

  /// Add custom template
  void addTemplate(InsightTemplate template) {
    _templates.removeWhere((t) => t.id == template.id);
    _templates.add(template);
  }

  /// Remove template
  void removeTemplate(String templateId) {
    _templates.removeWhere((t) => t.id == templateId);
  }

  /// Growth category templates (15+)
  List<InsightTemplate> _getGrowthTemplates() {
    return [
      // Core improvement templates
      InsightTemplate(
        id: 'growth_core_increase',
        title: 'Core Growth',
        content: 'Your {coreName} increased by {corePercentage}% this {timeframe}! 🌱',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueIncreased, TemplateCondition.trendUpward],
        requiredVariables: [ContextVariable.coreName, ContextVariable.corePercentage, ContextVariable.timeframe],
        priority: TemplatePriority.high,
        animationType: AnimationType.slideUp,
        tags: ['improvement', 'progress'],
      ),
      
      InsightTemplate(
        id: 'growth_breakthrough',
        title: 'Major Breakthrough',
        content: 'Breakthrough moment! Your {coreName} just reached a new personal best of {coreValue}. This kind of growth shows real dedication! ⭐',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.breakthrough, TemplateCondition.newRecord],
        requiredVariables: [ContextVariable.coreName, ContextVariable.coreValue],
        priority: TemplatePriority.critical,
        animationType: AnimationType.bounce,
        tags: ['breakthrough', 'record', 'achievement'],
      ),

      InsightTemplate(
        id: 'growth_steady_progress',
        title: 'Steady Progress',
        content: 'Small steps, big results! Your {coreName} has been steadily improving over the past {timeframe}. Consistency is your superpower! 💪',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.consistency, TemplateCondition.streak],
        requiredVariables: [ContextVariable.coreName, ContextVariable.timeframe],
        priority: TemplatePriority.high,
        animationType: AnimationType.pulse,
        tags: ['consistency', 'steady', 'progress'],
      ),

      InsightTemplate(
        id: 'growth_milestone_reached',
        title: 'Milestone Achievement',
        content: 'Milestone unlocked! 🎯 You\'ve reached an important goal in your {coreName} journey. Take a moment to appreciate how far you\'ve come!',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.milestone],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.critical,
        animationType: AnimationType.heartbeat,
        tags: ['milestone', 'achievement', 'goal'],
      ),

      InsightTemplate(
        id: 'growth_resilience_building',
        title: 'Building Resilience',
        content: 'Your resilience is growing stronger! Even during tough times, you\'re maintaining a {coreValue} level in {coreName}. That\'s true strength! 🛡️',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueStable, TemplateCondition.moodNegative],
        requiredVariables: [ContextVariable.coreValue, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.scaleIn,
        tags: ['resilience', 'strength', 'stability'],
      ),

      InsightTemplate(
        id: 'growth_momentum_building',
        title: 'Building Momentum',
        content: 'You\'re building powerful momentum! {streakCount} days of growth in {coreName}. Keep this energy flowing! 🚀',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.streak],
        requiredVariables: [ContextVariable.streakCount, ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.slideUp,
        tags: ['momentum', 'streak', 'energy'],
      ),

      InsightTemplate(
        id: 'growth_learning_curve',
        title: 'Learning & Growing',
        content: 'Every experience is teaching you something valuable! Your {coreName} reflects deep learning and personal evolution. 📚✨',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.fadeIn,
        tags: ['learning', 'evolution', 'wisdom'],
      ),

      InsightTemplate(
        id: 'growth_self_awareness',
        title: 'Self-Awareness Boost',
        content: 'Your self-awareness is expanding beautifully! Understanding yourself at this level ({coreValue}) shows incredible personal growth. 🧠💡',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreValue],
        priority: TemplatePriority.high,
        animationType: AnimationType.shimmer,
        tags: ['self-awareness', 'understanding', 'insight'],
      ),

      InsightTemplate(
        id: 'growth_emotional_maturity',
        title: 'Emotional Growth',
        content: 'Your emotional maturity is shining through! The way you\'re handling {dominantEmotion} shows real growth in your {coreName}. 🌟',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.moodPositive],
        requiredVariables: [ContextVariable.dominantEmotion, ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.pulse,
        tags: ['emotional', 'maturity', 'feelings'],
      ),

      InsightTemplate(
        id: 'growth_creative_expansion',
        title: 'Creative Flowering',
        content: 'Your creativity is blossoming! {corePercentage}% growth in creative thinking this {timeframe}. Your imagination is your playground! 🎨',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.corePercentage, ContextVariable.timeframe],
        priority: TemplatePriority.medium,
        animationType: AnimationType.flipIn,
        tags: ['creativity', 'imagination', 'artistic'],
      ),

      InsightTemplate(
        id: 'growth_social_connection',
        title: 'Connection Deepening',
        content: 'Your relationships are growing stronger! Social connection levels at {coreValue} show you\'re building meaningful bonds. 🤝❤️',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreValue],
        priority: TemplatePriority.medium,
        animationType: AnimationType.heartbeat,
        tags: ['social', 'relationships', 'connection'],
      ),

      InsightTemplate(
        id: 'growth_mindset_shift',
        title: 'Mindset Evolution',
        content: 'Your growth mindset is evolving beautifully! From {previousValue} to {coreValue} in {coreName} - that\'s the power of believing in yourself! 🧠🚀',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.previousValue, ContextVariable.coreValue, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.scaleIn,
        tags: ['mindset', 'belief', 'evolution'],
      ),

      InsightTemplate(
        id: 'growth_recovery_strength',
        title: 'Recovery & Renewal',
        content: 'What a comeback! Your {coreName} is recovering beautifully, showing your incredible inner strength. You\'re unstoppable! 💎',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.recovery, TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.bounce,
        tags: ['recovery', 'comeback', 'strength'],
      ),

      InsightTemplate(
        id: 'growth_daily_dedication',
        title: 'Daily Dedication',
        content: 'Your daily commitment to growth is paying off! Each day brings you closer to becoming your best self. Today\'s progress in {coreName}: inspiring! 🌅',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.dailyReflection],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.fadeIn,
        tags: ['daily', 'commitment', 'dedication'],
      ),

      InsightTemplate(
        id: 'growth_pattern_recognition',
        title: 'Pattern Awareness',
        content: 'You\'re developing amazing pattern recognition! Noticing these growth patterns in your {coreName} shows deep self-understanding. 🔍✨',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.consistency],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.shimmer,
        tags: ['patterns', 'awareness', 'recognition'],
      ),

      InsightTemplate(
        id: 'growth_potential_unleashing',
        title: 'Unleashing Potential',
        content: 'You\'re unleashing your true potential! This {corePercentage}% improvement in {coreName} is just the beginning of what you can achieve! 🦋',
        category: InsightCategory.growth,
        conditions: [TemplateCondition.valueIncreased, TemplateCondition.breakthrough],
        requiredVariables: [ContextVariable.corePercentage, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.flipIn,
        tags: ['potential', 'transformation', 'achievement'],
      ),
    ];
  }

  /// Reflection category templates (15+)
  List<InsightTemplate> _getReflectionTemplates() {
    return [
      InsightTemplate(
        id: 'reflection_emotional_depth',
        title: 'Emotional Depth',
        content: 'Your emotional depth today shows real maturity. Feeling {dominantEmotion} with this level of awareness takes courage. 🤔💙',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.moodMixed],
        requiredVariables: [ContextVariable.dominantEmotion],
        priority: TemplatePriority.medium,
        animationType: AnimationType.fadeIn,
        tags: ['emotions', 'depth', 'awareness'],
      ),

      InsightTemplate(
        id: 'reflection_weekly_patterns',
        title: 'Weekly Reflection',
        content: 'This week brought interesting patterns in your {coreName}. From {previousValue} to {coreValue} - what story does this tell about your journey? 📊',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.weeklyInsight],
        requiredVariables: [ContextVariable.coreName, ContextVariable.previousValue, ContextVariable.coreValue],
        priority: TemplatePriority.medium,
        animationType: AnimationType.slideUp,
        tags: ['weekly', 'patterns', 'journey'],
      ),

      InsightTemplate(
        id: 'reflection_inner_wisdom',
        title: 'Inner Wisdom',
        content: 'Your inner wisdom is speaking through your {coreName} levels. Sometimes the quietest insights are the most profound. 🧘‍♀️✨',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueStable, TemplateCondition.moodNeutral],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.pulse,
        tags: ['wisdom', 'insight', 'inner'],
      ),

      InsightTemplate(
        id: 'reflection_growth_contemplation',
        title: 'Growth Contemplation',
        content: 'Take a moment to appreciate your growth journey. Your {coreName} has evolved {corePercentage}% - each step was meaningful. 🌱🤔',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.coreName, ContextVariable.corePercentage],
        priority: TemplatePriority.high,
        animationType: AnimationType.shimmer,
        tags: ['growth', 'journey', 'appreciation'],
      ),

      InsightTemplate(
        id: 'reflection_emotional_intelligence',
        title: 'Emotional Intelligence',
        content: 'Your emotional intelligence shines today. Processing {dominantEmotion} with {emotionIntensity} intensity shows deep self-understanding. 🧠❤️',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.moodPositive],
        requiredVariables: [ContextVariable.dominantEmotion, ContextVariable.emotionIntensity],
        priority: TemplatePriority.high,
        animationType: AnimationType.heartbeat,
        tags: ['emotional-intelligence', 'processing', 'understanding'],
      ),

      InsightTemplate(
        id: 'reflection_life_balance',
        title: 'Life Balance Reflection',
        content: 'Your {coreName} levels suggest you\'re finding your balance. Sometimes equilibrium is more valuable than extremes. ⚖️🌸',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueMedium, TemplateCondition.valueStable],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.fadeIn,
        tags: ['balance', 'equilibrium', 'harmony'],
      ),

      InsightTemplate(
        id: 'reflection_seasonal_changes',
        title: 'Seasonal Reflection',
        content: 'Like the seasons, you\'re in a natural cycle of change. Your {coreName} today reflects where you are in your personal season. 🍃',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueStable],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.low,
        animationType: AnimationType.pulse,
        tags: ['seasons', 'cycles', 'natural'],
      ),

      InsightTemplate(
        id: 'reflection_resilience_moments',
        title: 'Resilience Moments',
        content: 'In challenging times, your {coreName} at {coreValue} shows your resilience. You\'re stronger than you know. 💪🌟',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.moodNegative, TemplateCondition.valueStable],
        requiredVariables: [ContextVariable.coreName, ContextVariable.coreValue],
        priority: TemplatePriority.high,
        animationType: AnimationType.scaleIn,
        tags: ['resilience', 'strength', 'challenges'],
      ),

      InsightTemplate(
        id: 'reflection_gratitude_moments',
        title: 'Gratitude Reflection',
        content: 'Today\'s {coreName} levels remind us to be grateful for growth, both big and small. Every step counts. 🙏✨',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.moodPositive],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.shimmer,
        tags: ['gratitude', 'appreciation', 'mindfulness'],
      ),

      InsightTemplate(
        id: 'reflection_personal_truth',
        title: 'Personal Truth',
        content: 'Your authentic self is showing through your {coreName}. Being true to yourself at {coreValue} takes real courage. 🌈',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreName, ContextVariable.coreValue],
        priority: TemplatePriority.high,
        animationType: AnimationType.flipIn,
        tags: ['authenticity', 'truth', 'courage'],
      ),

      InsightTemplate(
        id: 'reflection_mindful_awareness',
        title: 'Mindful Awareness',
        content: 'Your mindful awareness today is beautiful. Observing your {coreName} with this clarity shows deep presence. 🧘‍♂️🌸',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.moodNeutral],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.pulse,
        tags: ['mindfulness', 'awareness', 'presence'],
      ),

      InsightTemplate(
        id: 'reflection_learning_journey',
        title: 'Learning Journey',
        content: 'Every day teaches you something new about yourself. Your {coreName} journey this {timeframe} has been a masterclass in self-discovery. 📚🔍',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.coreName, ContextVariable.timeframe],
        priority: TemplatePriority.medium,
        animationType: AnimationType.slideUp,
        tags: ['learning', 'discovery', 'education'],
      ),

      InsightTemplate(
        id: 'reflection_emotional_landscape',
        title: 'Emotional Landscape',
        content: 'Your emotional landscape today is rich and complex. Feeling {dominantEmotion} adds another layer to your beautiful human experience. 🎨🌄',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.moodMixed],
        requiredVariables: [ContextVariable.dominantEmotion],
        priority: TemplatePriority.medium,
        animationType: AnimationType.fadeIn,
        tags: ['emotions', 'landscape', 'complexity'],
      ),

      InsightTemplate(
        id: 'reflection_gentle_self_compassion',
        title: 'Self-Compassion',
        content: 'Be gentle with yourself today. Your {coreName} levels show you\'re human, and that\'s perfectly beautiful. 💝🌺',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueLow],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.heartbeat,
        tags: ['self-compassion', 'gentleness', 'acceptance'],
      ),

      InsightTemplate(
        id: 'reflection_wisdom_integration',
        title: 'Integrating Wisdom',
        content: 'You\'re integrating deep wisdom into your daily life. Your {coreName} reflects the beautiful synthesis of experience and understanding. 🦉📖',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.valueHigh, TemplateCondition.consistency],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.shimmer,
        tags: ['wisdom', 'integration', 'synthesis'],
      ),

      InsightTemplate(
        id: 'reflection_present_moment',
        title: 'Present Moment Awareness',
        content: 'Right now, in this moment, your {coreName} tells a story of presence and awareness. This is where life happens. ⏰🌸',
        category: InsightCategory.reflection,
        conditions: [TemplateCondition.dailyReflection],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.pulse,
        tags: ['present', 'moment', 'awareness'],
      ),
    ];
  }

  /// Action category templates (15+)
  List<InsightTemplate> _getActionTemplates() {
    return [
      InsightTemplate(
        id: 'action_momentum_boost',
        title: 'Momentum Boost',
        content: 'Time to amplify this momentum! Your {coreName} is rising - let\'s keep this energy flowing with focused action! ⚡🚀',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueIncreased, TemplateCondition.trendUpward],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.bounce,
        tags: ['momentum', 'energy', 'action'],
      ),

      InsightTemplate(
        id: 'action_breakthrough_capitalize',
        title: 'Capitalize on Breakthrough',
        content: 'This breakthrough in {coreName} is your launchpad! Now\'s the perfect time to take bold action and reach even higher! 🎯⭐',
        category: InsightCategory.action,
        conditions: [TemplateCondition.breakthrough, TemplateCondition.newRecord],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.critical,
        animationType: AnimationType.flipIn,
        tags: ['breakthrough', 'capitalize', 'bold'],
      ),

      InsightTemplate(
        id: 'action_streak_maintain',
        title: 'Maintain the Streak',
        content: '{streakCount} days strong! Let\'s keep this {coreName} streak alive with consistent daily action. You\'ve got this! 💪🔥',
        category: InsightCategory.action,
        conditions: [TemplateCondition.streak],
        requiredVariables: [ContextVariable.streakCount, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.pulse,
        tags: ['streak', 'consistency', 'momentum'],
      ),

      InsightTemplate(
        id: 'action_recovery_focus',
        title: 'Recovery Focus',
        content: 'Recovery mode activated! Focus your energy on gentle, nurturing actions that support your {coreName} healing. 🌱💚',
        category: InsightCategory.action,
        conditions: [TemplateCondition.recovery, TemplateCondition.valueLow],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.fadeIn,
        tags: ['recovery', 'healing', 'nurturing'],
      ),

      InsightTemplate(
        id: 'action_skill_development',
        title: 'Skill Development',
        content: 'Your {coreName} is ready for the next level! Time to develop new skills and expand your capabilities. What will you learn today? 📚⚡',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.slideUp,
        tags: ['skills', 'development', 'learning'],
      ),

      InsightTemplate(
        id: 'action_creative_expression',
        title: 'Creative Expression',
        content: 'Your creativity is calling! Channel this {coreName} energy into creative expression. Let your imagination run wild! 🎨✨',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueHigh, TemplateCondition.moodPositive],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.shimmer,
        tags: ['creativity', 'expression', 'imagination'],
      ),

      InsightTemplate(
        id: 'action_social_connection',
        title: 'Connect with Others',
        content: 'Your {coreName} energy is perfect for connecting! Reach out, share your experience, build meaningful relationships today. 🤝❤️',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.heartbeat,
        tags: ['social', 'connection', 'relationships'],
      ),

      InsightTemplate(
        id: 'action_challenge_embrace',
        title: 'Embrace Challenge',
        content: 'You\'re strong enough for this! Your {coreName} at {coreValue} shows you\'re ready to embrace new challenges. Step forward boldly! 💎⚡',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueHigh, TemplateCondition.consistency],
        requiredVariables: [ContextVariable.coreName, ContextVariable.coreValue],
        priority: TemplatePriority.high,
        animationType: AnimationType.scaleIn,
        tags: ['challenge', 'courage', 'growth'],
      ),

      InsightTemplate(
        id: 'action_mindful_practice',
        title: 'Mindful Practice',
        content: 'Perfect time for mindful practice! Your {coreName} is in a beautiful space for meditation, reflection, or gentle movement. 🧘‍♀️🌸',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueMedium, TemplateCondition.moodNeutral],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.pulse,
        tags: ['mindfulness', 'practice', 'meditation'],
      ),

      InsightTemplate(
        id: 'action_knowledge_sharing',
        title: 'Share Your Wisdom',
        content: 'Your {coreName} wisdom is valuable! Consider sharing your insights and experiences to help others on their journey. 📖✨',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueHigh, TemplateCondition.consistency],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.slideUp,
        tags: ['sharing', 'wisdom', 'helping'],
      ),

      InsightTemplate(
        id: 'action_goal_setting',
        title: 'Set New Goals',
        content: 'Time to dream bigger! Your {coreName} progress shows you\'re ready for new, exciting goals. What\'s your next adventure? 🎯🌟',
        category: InsightCategory.action,
        conditions: [TemplateCondition.milestone, TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.flipIn,
        tags: ['goals', 'dreams', 'planning'],
      ),

      InsightTemplate(
        id: 'action_self_care_priority',
        title: 'Prioritize Self-Care',
        content: 'Your {coreName} is calling for gentle care. Make self-compassion and nurturing your top priority today. You deserve it! 💝🌺',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueLow, TemplateCondition.moodNegative],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.critical,
        animationType: AnimationType.heartbeat,
        tags: ['self-care', 'nurturing', 'priority'],
      ),

      InsightTemplate(
        id: 'action_celebration_plan',
        title: 'Plan a Celebration',
        content: 'This {corePercentage}% growth in {coreName} deserves celebration! Plan something special to honor your progress. 🎉✨',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueIncreased, TemplateCondition.milestone],
        requiredVariables: [ContextVariable.corePercentage, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.bounce,
        tags: ['celebration', 'honor', 'progress'],
      ),

      InsightTemplate(
        id: 'action_habit_formation',
        title: 'Build Strong Habits',
        content: 'Your {coreName} consistency is building! Let\'s turn this positive trend into lasting habits. Small actions, big results! 🔄💪',
        category: InsightCategory.action,
        conditions: [TemplateCondition.consistency, TemplateCondition.streak],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.pulse,
        tags: ['habits', 'consistency', 'building'],
      ),

      InsightTemplate(
        id: 'action_energy_channeling',
        title: 'Channel Your Energy',
        content: 'You have amazing energy today! Channel this {dominantEmotion} feeling and {coreName} strength into meaningful action. ⚡🎯',
        category: InsightCategory.action,
        conditions: [TemplateCondition.moodPositive, TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.dominantEmotion, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.shimmer,
        tags: ['energy', 'channeling', 'action'],
      ),

      InsightTemplate(
        id: 'action_boundary_setting',
        title: 'Set Healthy Boundaries',
        content: 'Your {coreName} needs protection to flourish. Time to set healthy boundaries and protect your energy. Your wellbeing matters! 🛡️💚',
        category: InsightCategory.action,
        conditions: [TemplateCondition.valueLow, TemplateCondition.moodNegative],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.scaleIn,
        tags: ['boundaries', 'protection', 'wellbeing'],
      ),
    ];
  }

  /// Celebration category templates (15+)
  List<InsightTemplate> _getCelebrationTemplates() {
    return [
      InsightTemplate(
        id: 'celebration_record_breaking',
        title: 'Record Breaker!',
        content: '🏆 NEW RECORD! Your {coreName} just hit {coreValue} - the highest it\'s ever been! You\'re absolutely amazing! 🌟🎉',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.newRecord, TemplateCondition.breakthrough],
        requiredVariables: [ContextVariable.coreName, ContextVariable.coreValue],
        priority: TemplatePriority.critical,
        animationType: AnimationType.bounce,
        tags: ['record', 'achievement', 'amazing'],
      ),

      InsightTemplate(
        id: 'celebration_milestone_party',
        title: 'Milestone Party!',
        content: '🎊 MILESTONE ACHIEVED! Your {coreName} journey just reached a major milestone! Time to party and celebrate this incredible achievement! 🥳✨',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.milestone],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.critical,
        animationType: AnimationType.flipIn,
        tags: ['milestone', 'party', 'achievement'],
      ),

      InsightTemplate(
        id: 'celebration_streak_champion',
        title: 'Streak Champion!',
        content: '🔥 {streakCount} DAYS STRONG! You\'re a {coreName} champion! This consistency is absolutely incredible! Keep shining! ⭐🏅',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.streak],
        requiredVariables: [ContextVariable.streakCount, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.heartbeat,
        tags: ['streak', 'champion', 'consistency'],
      ),

      InsightTemplate(
        id: 'celebration_growth_explosion',
        title: 'Growth Explosion!',
        content: '💥 WOW! {corePercentage}% growth in {coreName} this {timeframe}! You\'re on fire and absolutely unstoppable! 🚀🌟',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.valueIncreased, TemplateCondition.breakthrough],
        requiredVariables: [ContextVariable.corePercentage, ContextVariable.coreName, ContextVariable.timeframe],
        priority: TemplatePriority.critical,
        animationType: AnimationType.shimmer,
        tags: ['growth', 'explosion', 'unstoppable'],
      ),

      InsightTemplate(
        id: 'celebration_resilience_hero',
        title: 'Resilience Hero!',
        content: '🦸‍♀️ You\'re a resilience HERO! Maintaining {coreName} strength through challenges shows your incredible inner power! 💪⭐',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.recovery, TemplateCondition.valueStable],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.scaleIn,
        tags: ['resilience', 'hero', 'strength'],
      ),

      InsightTemplate(
        id: 'celebration_emotional_mastery',
        title: 'Emotional Mastery!',
        content: '🧠✨ EMOTIONAL MASTERY UNLOCKED! Your ability to process {dominantEmotion} with such grace is truly inspiring! You\'re amazing! 💎',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.moodPositive, TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.dominantEmotion],
        priority: TemplatePriority.high,
        animationType: AnimationType.pulse,
        tags: ['emotional', 'mastery', 'grace'],
      ),

      InsightTemplate(
        id: 'celebration_consistency_king',
        title: 'Consistency Royalty!',
        content: '👑 CONSISTENCY ROYALTY! Your steady {coreName} progress makes you absolute royalty in the kingdom of personal growth! 🏰✨',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.consistency, TemplateCondition.streak],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.flipIn,
        tags: ['consistency', 'royalty', 'progress'],
      ),

      InsightTemplate(
        id: 'celebration_breakthrough_moment',
        title: 'Breakthrough Moment!',
        content: '⚡ BREAKTHROUGH MOMENT! This leap in {coreName} is absolutely phenomenal! You\'ve just leveled up in the most amazing way! 🌟🎯',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.breakthrough],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.critical,
        animationType: AnimationType.bounce,
        tags: ['breakthrough', 'phenomenal', 'level-up'],
      ),

      InsightTemplate(
        id: 'celebration_self_love_champion',
        title: 'Self-Love Champion!',
        content: '💖 SELF-LOVE CHAMPION! Your {coreName} shows incredible self-compassion and love! You\'re treating yourself like the treasure you are! 💎🌈',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.valueHigh, TemplateCondition.moodPositive],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.heartbeat,
        tags: ['self-love', 'champion', 'treasure'],
      ),

      InsightTemplate(
        id: 'celebration_wisdom_master',
        title: 'Wisdom Master!',
        content: '🦉 WISDOM MASTER ACHIEVED! Your deep understanding and {coreName} insight make you a true master of wisdom! Absolutely brilliant! ✨📚',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.valueHigh, TemplateCondition.consistency],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.shimmer,
        tags: ['wisdom', 'master', 'brilliant'],
      ),

      InsightTemplate(
        id: 'celebration_creativity_genius',
        title: 'Creativity Genius!',
        content: '🎨 CREATIVITY GENIUS! Your imaginative spirit and {coreName} brilliance make you an absolute creative genius! Keep creating magic! ✨🌟',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.flipIn,
        tags: ['creativity', 'genius', 'magic'],
      ),

      InsightTemplate(
        id: 'celebration_social_butterfly',
        title: 'Social Butterfly!',
        content: '🦋 SOCIAL BUTTERFLY! Your {coreName} connection skills are absolutely beautiful! You bring joy and connection wherever you go! 💫🤝',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.pulse,
        tags: ['social', 'butterfly', 'connection'],
      ),

      InsightTemplate(
        id: 'celebration_growth_superstar',
        title: 'Growth Superstar!',
        content: '⭐ GROWTH SUPERSTAR! From {previousValue} to {coreValue} in {coreName} - you\'re absolutely STELLAR! Keep shining bright! 🌟💫',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.previousValue, ContextVariable.coreValue, ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.scaleIn,
        tags: ['growth', 'superstar', 'stellar'],
      ),

      InsightTemplate(
        id: 'celebration_daily_hero',
        title: 'Daily Hero!',
        content: '🦸‍♂️ DAILY HERO STATUS! Your commitment to {coreName} growth every single day makes you an absolute everyday hero! Amazing! 💪🌟',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.dailyReflection, TemplateCondition.consistency],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.medium,
        animationType: AnimationType.bounce,
        tags: ['daily', 'hero', 'commitment'],
      ),

      InsightTemplate(
        id: 'celebration_mindfulness_master',
        title: 'Mindfulness Master!',
        content: '🧘‍♀️ MINDFULNESS MASTER! Your present-moment awareness and {coreName} clarity are absolutely masterful! You\'re living in beautiful presence! ✨🌸',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.moodNeutral, TemplateCondition.valueHigh],
        requiredVariables: [ContextVariable.coreName],
        priority: TemplatePriority.high,
        animationType: AnimationType.pulse,
        tags: ['mindfulness', 'master', 'presence'],
      ),

      InsightTemplate(
        id: 'celebration_transformation_wizard',
        title: 'Transformation Wizard!',
        content: '🪄 TRANSFORMATION WIZARD! The magical way you\'ve transformed your {coreName} by {corePercentage}% is pure wizardry! Absolutely spellbinding! ✨🌟',
        category: InsightCategory.celebration,
        conditions: [TemplateCondition.breakthrough, TemplateCondition.valueIncreased],
        requiredVariables: [ContextVariable.coreName, ContextVariable.corePercentage],
        priority: TemplatePriority.critical,
        animationType: AnimationType.shimmer,
        tags: ['transformation', 'wizard', 'magical'],
      ),
    ];
  }
}