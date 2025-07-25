import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/widgets/mind_reflection_card.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import 'package:spiral_journal/widgets/compact_analysis_counter.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDraftContent();
    _loadUserName();
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
        coreImpacts: {}, // TODO: Add core impacts if available
        analyzedAt: DateTime.now(),
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
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View Details',
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
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: DesignTokens.getPrimaryColor(context),
              ),
              const SizedBox(width: 8),
              const Text('AI Analysis Results'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Performance metrics
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.getColorWithOpacity(
                      DesignTokens.getPrimaryColor(context), 
                      0.1
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Analysis completed in ${analysisTime.inMilliseconds}ms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Personal insight
                if (analysisResult.personalizedInsight.isNotEmpty) ...[
                  Text(
                    'Personal Insight:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysisResult.personalizedInsight,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Detected emotions
                if (analysisResult.primaryEmotions.isNotEmpty) ...[
                  Text(
                    'Detected Emotions:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: analysisResult.primaryEmotions.map<Widget>((emotion) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DesignTokens.getMoodColor(emotion),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          emotion,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Key themes
                if (analysisResult.keyThemes.isNotEmpty) ...[
                  Text(
                    'Key Themes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...analysisResult.keyThemes.map<Widget>((theme) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: DesignTokens.getTextSecondary(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              theme,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
                
                // Emotional metrics
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Intensity',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(analysisResult.emotionalIntensity * 10).toStringAsFixed(1)}/10',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sentiment',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            analysisResult.overallSentiment > 0.1 
                                ? 'Positive' 
                                : analysisResult.overallSentiment < -0.1 
                                    ? 'Negative' 
                                    : 'Neutral',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AdaptiveScaffold(
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
      ),
    );
  }
}
