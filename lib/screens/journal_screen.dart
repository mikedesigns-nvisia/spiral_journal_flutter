import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/design_system/heading_system.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/widgets/mind_reflection_card.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import 'package:spiral_journal/widgets/compact_analysis_counter.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/widgets/post_analysis_display.dart';
import 'package:spiral_journal/utils/ios_theme_enforcer.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final List<String> _selectedMoods = [];
  
  bool _isSaving = false;
  String? _draftContent;
  String _userName = 'there'; // Default fallback name
  JournalEntry? _todaysEntry; // Track today's entry for editing
  String? _currentDraftId; // Track current draft ID for autosave
  
  // Post-analysis state tracking
  bool _hasAnalyzedEntryToday = false;
  JournalEntry? _todaysAnalyzedEntry;
  EmotionalAnalysisResult? _todaysAnalysisResult;
  bool _isAiEnabled = true; // Will be loaded from settings

  @override
  void initState() {
    super.initState();
    _loadDraftContent();
    _loadUserName();
    _checkTodaysAnalysisStatus();
    _loadAiSettings();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadDraftContent() async {
    // Load any existing draft content from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftContent = prefs.getString('journal_draft_content');
      final draftMoods = prefs.getStringList('journal_draft_moods') ?? [];
      
      if (draftContent != null && draftContent.isNotEmpty) {
        setState(() {
          _draftContent = draftContent;
          _selectedMoods.clear();
          _selectedMoods.addAll(draftMoods);
        });
        
        // Show recovery dialog
        if (mounted) {
          _showDraftRecoveryDialog(draftContent);
        }
      }
    } catch (e) {
      debugPrint('Error loading draft content: $e');
    }
  }

  Future<void> _saveDraftContent(String content) async {
    // Save draft content for crash recovery
    try {
      final prefs = await SharedPreferences.getInstance();
      if (content.trim().isNotEmpty) {
        await prefs.setString('journal_draft_content', content);
        await prefs.setStringList('journal_draft_moods', _selectedMoods);
      } else {
        await prefs.remove('journal_draft_content');
        await prefs.remove('journal_draft_moods');
      }
      
      setState(() {
        _draftContent = content;
      });
    } catch (e) {
      debugPrint('Error saving draft content: $e');
    }
  }

  Future<void> _clearDraftContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('journal_draft_content');
      await prefs.remove('journal_draft_moods');
      
      setState(() {
        _draftContent = null;
      });
    } catch (e) {
      debugPrint('Error clearing draft content: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final profileService = ProfileService();
      final displayName = await profileService.getDisplayName();
      
      if (mounted) {
        setState(() {
          _userName = displayName;
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      // Keep default fallback name 'there'
    }
  }

  Future<void> _loadAiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final aiEnabled = prefs.getBool('ai_analysis_enabled') ?? true;
      
      if (mounted) {
        setState(() {
          _isAiEnabled = aiEnabled;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI settings: $e');
    }
  }

  Future<void> _checkTodaysAnalysisStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      // Check if we have an analyzed entry from today
      final lastAnalysisDate = prefs.getString('last_analysis_date');
      final hasAnalyzedToday = lastAnalysisDate == todayKey;
      
      if (hasAnalyzedToday && _isAiEnabled) {
        // Try to load today's analysis result from cache using JournalProvider
        final journalProvider = Provider.of<JournalProvider>(context, listen: false);
        await journalProvider.initialize();
        
        // Get today's entry from journal provider
        final todaysEntry = await _getTodaysAnalyzedEntry(journalProvider);
        
        if (todaysEntry != null && todaysEntry.isAnalyzed && todaysEntry.aiAnalysis != null) {
          // Convert EmotionalAnalysis to EmotionalAnalysisResult for display
          final analysisResult = _convertToAnalysisResult(todaysEntry.aiAnalysis!);
          
          setState(() {
            _hasAnalyzedEntryToday = true;
            _todaysAnalyzedEntry = todaysEntry;
            _todaysAnalysisResult = analysisResult;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking today\'s analysis status: $e');
    }
  }

  Future<JournalEntry?> _getTodaysAnalyzedEntry(JournalProvider journalProvider) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      // Get all entries and find today's analyzed entry
      final entries = journalProvider.entries;
      for (final entry in entries) {
        if (entry.createdAt.isAfter(todayStart) && 
            entry.createdAt.isBefore(todayEnd) &&
            entry.isAnalyzed) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting today\'s analyzed entry: $e');
      return null;
    }
  }

  EmotionalAnalysisResult _convertToAnalysisResult(EmotionalAnalysis analysis) {
    return EmotionalAnalysisResult(
      primaryEmotions: analysis.primaryEmotions,
      emotionalIntensity: analysis.emotionalIntensity,
      keyThemes: analysis.keyThemes,
      overallSentiment: 0.0, // Not stored in EmotionalAnalysis, use default
      personalizedInsight: analysis.personalizedInsight ?? 'Personal insights from your journal entry.',
      coreImpacts: analysis.coreImpacts,
      emotionalPatterns: [], // Not stored in EmotionalAnalysis, use empty list
      growthIndicators: [], // Not stored in EmotionalAnalysis, use empty list
      validationScore: 0.8, // Default validation score
    );
  }

  Future<void> _saveAnalysisState(JournalEntry entry, EmotionalAnalysisResult analysisResult) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      // Save that we analyzed an entry today
      await prefs.setString('last_analysis_date', todayKey);
      
      // Save the analysis result and entry for display
      // Note: You may want to implement proper JSON serialization
      setState(() {
        _hasAnalyzedEntryToday = true;
        _todaysAnalyzedEntry = entry;
        _todaysAnalysisResult = analysisResult;
      });
    } catch (e) {
      debugPrint('Error saving analysis state: $e');
    }
  }

  void _resetToNewEntry() {
    setState(() {
      _hasAnalyzedEntryToday = false;
      _todaysAnalyzedEntry = null;
      _todaysAnalysisResult = null;
      _journalController.clear();
      _selectedMoods.clear();
    });
    
    // Clear the stored analysis state
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('last_analysis_date');
      prefs.remove('todays_analysis_result');
      prefs.remove('todays_analyzed_entry');
    });
  }

  void _showDraftRecoveryDialog(String draftContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recover Draft'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('We found an unsaved draft from your previous session:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.getColorWithOpacity(DesignTokens.getBackgroundTertiary(context), 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.getColorWithOpacity(DesignTokens.getPrimaryColor(context), 0.3),
                  ),
                ),
                child: Text(
                  draftContent.length > 100 
                      ? '${draftContent.substring(0, 100)}...' 
                      : draftContent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearDraftContent();
                Navigator.of(context).pop();
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                _journalController.text = draftContent;
                Navigator.of(context).pop();
              },
              child: const Text('Recover'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveEntry() async {
    if (_journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write something before saving!'),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
      return;
    }

    if (_selectedMoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one mood!'),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
      return;
    }

    // Phase 5: Check 24-hour entry limit
    final journalService = JournalService();
    final canCreateEntry = await journalService.canCreateEntryToday();
    
    if (!canCreateEntry) {
      final todaysEntry = await journalService.getTodaysEntry();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You\'ve already created an entry today! Come back tomorrow to continue your journey.',
          ),
          backgroundColor: DesignTokens.warningColor,
          duration: const Duration(seconds: 4),
          action: todaysEntry != null 
              ? SnackBarAction(
                  label: 'View Today\'s Entry',
                  onPressed: () {
                    // Navigate to journal history or show today's entry
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Today\'s entry: "${todaysEntry.content.length > 50 ? todaysEntry.content.substring(0, 50) + '...' : todaysEntry.content}"'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
      return;
    }

    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    // Show initial saving message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saving entry and analyzing with AI... 🤖'),
        backgroundColor: DesignTokens.getPrimaryColor(context),
        duration: const Duration(seconds: 2),
      ),
    );

    final success = await journalProvider.createEntry(
      content: _journalController.text.trim(),
      moods: _selectedMoods,
    );

    if (mounted) {
      if (success) {
        // Clear draft content after successful save
        await _clearDraftContent();
        
        // Perform AI analysis on the saved entry
        await _performRealTimeAIAnalysis();

        // Refresh cores after saving entry
        await coreProvider.refresh();

        // Refresh journal entries so they appear immediately in history
        await journalProvider.refresh();

        // Clear the form after successful save
        setState(() {
          _journalController.clear();
          _selectedMoods.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: ${journalProvider.error ?? 'Unknown error'}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _performRealTimeAIAnalysis() async {
    try {
      debugPrint('🔍 Starting real-time AI analysis...');
      final startTime = DateTime.now();
      
      // Get AI service manager and journal provider
      final aiManager = AIServiceManager();
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      
      // Get the most recently saved entry (should be the one we just saved)
      final recentEntries = journalProvider.entries;
      if (recentEntries.isEmpty) {
        debugPrint('❌ No recent entries found for AI analysis');
        return;
      }
      
      final savedEntry = recentEntries.first; // Most recent entry
      debugPrint('📝 Analyzing saved entry: ${savedEntry.content.length} characters');
      debugPrint('🎭 Selected moods: ${savedEntry.moods.join(', ')}');

      // Perform comprehensive AI analysis
      final analysisResult = await aiManager.performEmotionalAnalysis(savedEntry);
      
      final analysisTime = DateTime.now().difference(startTime);
      debugPrint('⚡ AI analysis completed in ${analysisTime.inMilliseconds}ms');
      
      // Log detailed analysis results
      debugPrint('🧠 AI Analysis Results:');
      debugPrint('   Primary Emotions: ${analysisResult.primaryEmotions.join(', ')}');
      debugPrint('   Emotional Intensity: ${analysisResult.emotionalIntensity}');
      debugPrint('   Overall Sentiment: ${analysisResult.overallSentiment}');
      debugPrint('   Key Themes: ${analysisResult.keyThemes.join(', ')}');
      debugPrint('   Growth Indicators: ${analysisResult.growthIndicators.join(', ')}');
      debugPrint('   Personalized Insight: ${analysisResult.personalizedInsight}');

      // Create EmotionalAnalysis object and update the entry
      final emotionalAnalysis = EmotionalAnalysis(
        primaryEmotions: analysisResult.primaryEmotions,
        emotionalIntensity: analysisResult.emotionalIntensity,
        keyThemes: analysisResult.keyThemes,
        personalizedInsight: analysisResult.personalizedInsight,
        analyzedAt: DateTime.now(),
        growthIndicators: analysisResult.growthIndicators,
        coreAdjustments: {},
        mindReflection: null,
        emotionalPatterns: [],
        entryInsight: analysisResult.personalizedInsight,
      );

      // Update the saved entry with AI analysis results
      final updatedEntry = savedEntry.copyWith(
        aiAnalysis: emotionalAnalysis,
        isAnalyzed: true,
        aiDetectedMoods: analysisResult.primaryEmotions,
        emotionalIntensity: analysisResult.emotionalIntensity,
        keyThemes: analysisResult.keyThemes,
        personalizedInsight: analysisResult.personalizedInsight,
      );

      // Save the updated entry with AI analysis
      await journalProvider.updateEntry(updatedEntry);
      debugPrint('💾 AI analysis results saved to entry');

      // Save analysis state for post-analysis display (only if AI is enabled)
      if (_isAiEnabled) {
        await _saveAnalysisState(updatedEntry, analysisResult);
      }

      if (mounted) {
        // Show comprehensive success message with AI insights
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entry saved with AI analysis! 🎉'),
                const SizedBox(height: 4),
                Text(
                  'Found ${analysisResult.primaryEmotions.length} emotions, ${analysisResult.keyThemes.length} themes',
                  style: HeadingSystem.getBodySmall(context).copyWith(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View Analysis',
              onPressed: () => _showDetailedAnalysisResults(analysisResult, analysisTime),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AI Analysis error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Entry saved successfully! 🎉'),
                const SizedBox(height: 4),
                Text(
                  'AI analysis unavailable: ${e.toString().split(':').first}',
                  style: HeadingSystem.getBodySmall(context).copyWith(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentYellow,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDetailedAnalysisResults(dynamic analysisResult, Duration analysisTime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar for dragging
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: DesignTokens.getPrimaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI Analysis Results',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Content area
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Performance metrics
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DesignTokens.getColorWithOpacity(
                                DesignTokens.getPrimaryColor(context), 
                                0.1
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.speed,
                                  size: 16,
                                  color: DesignTokens.getPrimaryColor(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Analysis completed in ${analysisTime.inMilliseconds}ms',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Show the complete PostAnalysisDisplay if we have today's entry
                          if (_todaysAnalyzedEntry != null) 
                            PostAnalysisDisplay(
                              journalEntry: _todaysAnalyzedEntry!,
                              analysisResult: null,
                              onViewAnalysis: null, // Don't show view analysis button in modal
                            )
                          else
                            // Fallback content for old analysis results
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Personal insight
                                if (analysisResult.personalizedInsight.isNotEmpty) ...[
                                  Text(
                                    'Personal Insight:',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.getColorWithOpacity(
                                        DesignTokens.getPrimaryColor(context), 
                                        0.1
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      analysisResult.personalizedInsight,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                
                                // Detected emotions
                                if (analysisResult.primaryEmotions.isNotEmpty) ...[
                                  Text(
                                    'Detected Emotions:',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: analysisResult.primaryEmotions.map<Widget>((emotion) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: DesignTokens.getMoodColor(emotion),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          emotion,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');

    // Use iOS-specific keyboard dismissal and safe area handling
    Widget body = AdaptiveScaffold(
        backgroundColor: DesignTokens.getBackgroundPrimary(context),
        padding: EdgeInsets.zero, // Remove default padding to avoid double padding
        body: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.getPrimaryGradient(context),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with app title, date, and analysis counter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DesignTokens.getColorWithOpacity(
                            DesignTokens.getPrimaryColor(context), 
                            0.15
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/spiral_journal_icon.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          color: DesignTokens.getPrimaryColor(context), // Apply theme-aware color
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to original icon if image fails to load
                            return Icon(
                              Icons.auto_stories_rounded,
                              color: DesignTokens.getPrimaryColor(context),
                              size: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Tooltip(
                          message: 'You can create one journal entry per day to encourage mindful reflection',
                          child: ResponsiveText(
                            'Spiral Journal',
                            baseFontSize: DesignTokens.fontSizeXXXL,
                            fontWeight: DesignTokens.fontWeightBold,
                            color: DesignTokens.getTextPrimary(context),
                          ),
                        ),
                      ),
                      // Compact Analysis Counter aligned with title
                      const CompactAnalysisCounter(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ResponsiveText(
                    dateFormatter.format(now),
                    baseFontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.getTextTertiary(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Greeting
              ResponsiveText(
                'Hi $_userName, how are you feeling today?',
                baseFontSize: DesignTokens.fontSizeXXL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 24),
              
              // Conditional UI: Show post-analysis display or normal journal input
              _hasAnalyzedEntryToday && _isAiEnabled && _todaysAnalyzedEntry != null && _todaysAnalysisResult != null
                ? PostAnalysisDisplay(
                    journalEntry: _todaysAnalyzedEntry!,
                    analysisResult: _todaysAnalysisResult!,
                    onViewAnalysis: () => _showDetailedAnalysisResults(_todaysAnalysisResult, Duration.zero),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood Selector
                      MoodSelector(
                        selectedMoods: _selectedMoods,
                        onMoodChanged: (moods) {
                          setState(() {
                            _selectedMoods.clear();
                            _selectedMoods.addAll(moods);
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Journal Input
                      Consumer<JournalProvider>(
                        builder: (context, journalProvider, child) {
                          return JournalInput(
                            controller: _journalController,
                            onChanged: (text) {
                              // Handle text changes if needed
                            },
                            onSave: _saveEntry,
                            isSaving: journalProvider.isLoading,
                            onAutoSave: _saveDraftContent,
                            draftContent: _draftContent,
                          );
                        },
                      ),
                    ],
                  ),
              
              const SizedBox(height: 24),
              
              // Mind Reflection Card
              const MindReflectionCard(),
              
              const SizedBox(height: 24),
              
              // Your Cores Card
              const YourCoresCard(),
              
              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
    
    // Apply iOS-specific safe area and keyboard handling
    return iOSThemeEnforcer.withSafeArea(
      child: iOSThemeEnforcer.withKeyboardDismissal(
        context: context,
        child: body,
      ),
      bottom: Platform.isIOS, // Only apply bottom safe area on iOS
    );
  }

  List<Map<String, dynamic>> _getAffectedCores(CoreProvider coreProvider, List<String> keyThemes) {
    final allCores = coreProvider.cores;
    final affectedCores = <Map<String, dynamic>>[];
    
    for (final core in allCores) {
      final contribution = _getCoreContribution(core, keyThemes);
      if (contribution.isNotEmpty) {
        affectedCores.add({
          'core': core,
          'contribution': contribution,
        });
      }
    }
    
    return affectedCores;
  }

  String _getCoreContribution(EmotionalCore core, List<String> keyThemes) {
    final coreKeywords = _getCoreKeywords(core.name);
    final matchingThemes = <String>[];
    
    for (final theme in keyThemes) {
      final themeLower = theme.toLowerCase();
      for (final keyword in coreKeywords) {
        if (themeLower.contains(keyword) || keyword.contains(themeLower)) {
          matchingThemes.add(theme);
          break;
        }
      }
    }
    
    if (matchingThemes.isEmpty) return '';
    
    // Generate contribution message based on core type and themes
    final contributions = _generateContributionMessage(core.name, matchingThemes);
    return contributions;
  }

  List<String> _getCoreKeywords(String coreName) {
    switch (coreName.toLowerCase()) {
      case 'optimism':
        return ['hope', 'positive', 'bright', 'future', 'grateful', 'thankful', 'excited', 'happy', 'joy', 'optimism'];
      case 'resilience':
        return ['overcome', 'challenge', 'difficult', 'strong', 'persever', 'bounce back', 'tough', 'endure', 'resilience'];
      case 'self-awareness':
        return ['realize', 'understand', 'reflect', 'insight', 'aware', 'conscious', 'mindful', 'introspect', 'awareness'];
      case 'creativity':
        return ['create', 'imagine', 'artistic', 'innovative', 'original', 'inspire', 'design', 'craft', 'creative'];
      case 'social connection':
        return ['friend', 'family', 'connect', 'relationship', 'social', 'together', 'community', 'bond', 'connection'];
      case 'growth mindset':
        return ['learn', 'grow', 'improve', 'develop', 'progress', 'better', 'skill', 'knowledge', 'growth'];
      default:
        return [coreName.toLowerCase()];
    }
  }

  String _generateContributionMessage(String coreName, List<String> matchingThemes) {
    final themeText = matchingThemes.length == 1 
        ? matchingThemes.first 
        : '${matchingThemes.take(2).join(', ')}${matchingThemes.length > 2 ? ' and others' : ''}';
    
    switch (coreName.toLowerCase()) {
      case 'optimism':
        return 'Reinforced through $themeText, strengthening positive outlook';
      case 'resilience':
        return 'Developed through $themeText, building emotional strength';
      case 'self-awareness':
        return 'Enhanced through $themeText, deepening self-understanding';
      case 'creativity':
        return 'Expressed through $themeText, fostering innovative thinking';
      case 'social connection':
        return 'Nurtured through $themeText, strengthening relationships';
      case 'growth mindset':
        return 'Cultivated through $themeText, promoting continuous learning';
      default:
        return 'Influenced by $themeText in this journal entry';
    }
  }

  Color _getCoreColorFromHex(String colorHex) {
    try {
      final cleanHex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (e) {
      return AppTheme.getPrimaryColor(context);
    }
  }

  IconData _getCoreIcon(String coreName) {
    switch (coreName.toLowerCase()) {
      case 'optimism':
        return Icons.sentiment_very_satisfied_rounded;
      case 'resilience':
        return Icons.shield_rounded;
      case 'self-awareness':
        return Icons.self_improvement_rounded;
      case 'creativity':
        return Icons.palette_rounded;
      case 'social connection':
        return Icons.people_rounded;
      case 'growth mindset':
        return Icons.trending_up_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}
