// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports
import 'package:spiral_journal/core/app_constants.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/heading_system.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/utils/ios_theme_enforcer.dart';
import 'package:spiral_journal/widgets/analysis_status_widget.dart';
import 'package:spiral_journal/widgets/compact_analysis_counter.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/widgets/mind_reflection_card.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/emotional_state_visualization.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import 'package:spiral_journal/models/emotional_mirror_data.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final List<String> _selectedMoods = [];
  
  String? _draftContent;
  String _userName = 'there'; // Default fallback name
  bool _hasProcessedEntryToday = false; // Track if user has already saved an entry today
  
  // Mirror snapshot state
  bool _showingSnapshot = false;
  JournalEntry? _savedEntry;
  
  // Post-analysis state tracking
  bool _isAiEnabled = true; // Will be loaded from settings

  @override
  void initState() {
    super.initState();
    _loadDraftContent();
    _loadUserName();
    _checkTodaysAnalysisStatus();
    _loadAiSettings();
    _startPeriodicAnalysisCheck();
    
    // Initial state refresh to ensure UI is consistent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        refreshJournalScreenState();
      }
    });
  }

  /// Start periodic check for completed analysis and state refresh
  void _startPeriodicAnalysisCheck() {
    // Check every 5 minutes for completed batch analysis and refresh state
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        refreshJournalScreenState();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  // Add this method to show snapshot after save:
  void _showSnapshot(JournalEntry entry) {
    debugPrint('🎯 Showing snapshot for entry: ${entry.id}');
    setState(() {
      _showingSnapshot = true;
      _savedEntry = entry;
      _hasProcessedEntryToday = false; // Reset this so snapshot shows instead of emotional state widget
    });
  }

  // Add this method to reset to input mode:
  void _resetToInputMode() {
    setState(() {
      _showingSnapshot = false;
      _savedEntry = null;
      _journalController.clear();
      _selectedMoods.clear();
    });
  }

  Future<void> _loadDraftContent() async {
    // Load any existing draft content from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftContent = prefs.getString('journal_draft_content');
      final draftMoods = prefs.getStringList('journal_draft_moods') ?? [];
      
      // Check if user has already processed an entry today
      await _checkHasProcessedEntryToday();
      
      if (draftContent != null && draftContent.isNotEmpty) {
        if (mounted) {
          setState(() {
            _draftContent = draftContent;
            _selectedMoods.clear();
            _selectedMoods.addAll(draftMoods);
          });
        }
        
        // Only show recovery dialog if user hasn't already saved an entry today
        // If they have, the draft is likely from the same content they already saved
        if (mounted && !_hasProcessedEntryToday) {
          _showDraftRecoveryDialog(draftContent);
        } else if (_hasProcessedEntryToday) {
          // User already saved today, clear the draft since it's likely already in history
          await _clearDraftContent();
          debugPrint('Cleared draft content - user already has entry in history today');
        }
      }
    } catch (e) {
      debugPrint('Error loading draft content: $e');
    }
  }

  /// Check if user has already processed (saved) an entry today
  Future<void> _checkHasProcessedEntryToday() async {
    try {
      final journalService = JournalService();
      final todaysEntry = await journalService.getTodaysEntry();
      
      if (mounted) {
        setState(() {
          _hasProcessedEntryToday = todaysEntry != null;
        });
      }
    } catch (e) {
      debugPrint('Error checking today\'s processed entry: $e');
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
      
      if (mounted) {
        setState(() {
          _draftContent = content;
        });
      }
    } catch (e) {
      debugPrint('Error saving draft content: $e');
    }
  }

  Future<void> _clearDraftContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('journal_draft_content');
      await prefs.remove('journal_draft_moods');
      
      if (mounted) {
        setState(() {
          _draftContent = null;
        });
      }
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
      if (!_isAiEnabled || !mounted) return;
      
      // Get today's entry from journal provider
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      await journalProvider.initialize();
      
      final todaysEntry = await _getTodaysAnalyzedEntry(journalProvider);
      
      if (mounted && todaysEntry != null) {
        setState(() {
          _hasProcessedEntryToday = true;
        });
        
        if (todaysEntry.isAnalyzed && todaysEntry.aiAnalysis != null) {
          debugPrint('✅ Found today\'s analyzed entry: ${todaysEntry.id}');
        } else {
          debugPrint('📝 Found today\'s entry waiting for analysis: ${todaysEntry.id}');
        }
      } else {
        // Reset state if no entry found
        if (mounted) {
          setState(() {
            _hasProcessedEntryToday = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking today\'s analysis status: $e');
    }
  }

  /// Refresh today's analysis status (called when batch analysis might have completed)
  Future<void> refreshTodaysAnalysisStatus() async {
    debugPrint('🔄 Refreshing today\'s analysis status...');
    await _checkTodaysAnalysisStatus();
  }

  /// Refresh complete journal screen state after entry processing
  Future<void> refreshJournalScreenState() async {
    debugPrint('🔄 Refreshing complete journal screen state...');
    
    // Check if user has processed an entry today
    await _checkHasProcessedEntryToday();
    
    // Refresh analysis status
    await _checkTodaysAnalysisStatus();
    
    // If user has already processed an entry today, clear any lingering drafts
    if (_hasProcessedEntryToday && _draftContent != null) {
      await _clearDraftContent();
      debugPrint('✅ Cleared lingering draft - user already has entry in history');
    }
  }

  /// Handle pull-to-refresh gesture
  Future<void> _handleRefresh() async {
    debugPrint('🔄 Pull-to-refresh triggered');
    
    try {
      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Refreshing journal state...'),
            backgroundColor: DesignTokens.getPrimaryColor(context),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // Refresh journal provider data
      if (mounted) {
        final journalProvider = Provider.of<JournalProvider>(context, listen: false);
        final coreProvider = Provider.of<CoreProvider>(context, listen: false);
        
        await journalProvider.refresh();
        await coreProvider.refresh();
      }
      
      // Refresh complete journal screen state
      await refreshJournalScreenState();
      
      debugPrint('✅ Pull-to-refresh completed successfully');
      
    } catch (e) {
      debugPrint('❌ Pull-to-refresh error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
              const SizedBox(height: AppConstants.spacing12),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing12),
                decoration: BoxDecoration(
                  color: DesignTokens.getColorWithOpacity(DesignTokens.getBackgroundTertiary(context), 0.5),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
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
      if (!mounted) return;
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
                        content: Text('Today\'s entry: "${todaysEntry.content.length > 50 ? '${todaysEntry.content.substring(0, 50)}...' : todaysEntry.content}"'),
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

    if (!mounted) return;
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    // Show initial saving message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saving entry... ✍️'),
        backgroundColor: DesignTokens.getPrimaryColor(context),
        duration: const Duration(seconds: 1),
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

        // Mark that user has processed an entry today and show immediate emotional state widget
        setState(() {
          _hasProcessedEntryToday = true;
        });

        // Refresh cores after saving entry
        await coreProvider.refresh();

        // Refresh journal entries so they appear immediately in history
        await journalProvider.refresh();

        // Get the saved entry and show snapshot
        final todaysEntry = await journalService.getTodaysEntry();
        debugPrint('📝 Retrieved today\'s entry after save: ${todaysEntry?.id}');
        
        if (todaysEntry != null) {
          // Show the snapshot instead of clearing
          debugPrint('🎯 Calling _showSnapshot with entry: ${todaysEntry.id}');
          _showSnapshot(todaysEntry);
        } else {
          debugPrint('❌ No today\'s entry found after save');
        }

        // Show success message with batch analysis info
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Entry saved successfully! 🎉'),
                  const SizedBox(height: AppConstants.spacing4),
                  Text(
                    'AI analysis will be available in the next batch cycle',
                    style: HeadingSystem.getBodySmall(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.accentGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save entry: ${journalProvider.error ?? 'Unknown error'}'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }



  

  /// Calculate mood balance from moods list
  double _calculateMoodBalance(List<String> moods) {
    final positiveEmotions = ['happy', 'joyful', 'excited', 'grateful', 'content', 'peaceful', 'love', 'joy', 'optimistic', 'confident'];
    final negativeEmotions = ['sad', 'angry', 'frustrated', 'anxious', 'worried', 'fear', 'disappointment', 'stress', 'overwhelmed'];
    
    double balance = 0.0;
    for (final mood in moods) {
      if (positiveEmotions.contains(mood.toLowerCase())) {
        balance += 0.3;
      } else if (negativeEmotions.contains(mood.toLowerCase())) {
        balance -= 0.3;
      }
    }
    
    return balance.clamp(-1.0, 1.0);
  }

  /// Create mood overview from saved entry
  MoodOverview _createMoodOverviewFromEntry(JournalEntry entry) {
    if (entry.aiAnalysis != null) {
      // Use AI analysis if available
      final analysis = entry.aiAnalysis!;
      return MoodOverview(
        dominantMoods: analysis.primaryEmotions.take(4).toList(),
        moodBalance: _calculateMoodBalance(analysis.primaryEmotions),
        emotionalVariety: (analysis.primaryEmotions.length / 10.0).clamp(0.0, 1.0),
        description: analysis.personalizedInsight ?? 'Your emotional journey continues...',
      );
    } else {
      // Use the moods from the saved entry
      return MoodOverview(
        dominantMoods: entry.moods.take(4).toList(),
        moodBalance: _calculateMoodBalance(entry.moods),
        emotionalVariety: (entry.moods.length / 10.0).clamp(0.0, 1.0),
        description: 'Your emotional state is being analyzed. Check back soon for deeper insights.',
      );
    }
  }

  Widget _buildNormalJournalInput() {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with date
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: DesignTokens.getColorWithOpacity(
                      DesignTokens.getPrimaryColor(context), 
                      0.15
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Image.asset(
                    'assets/images/spiral_journal_icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    color: DesignTokens.getPrimaryColor(context),
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.auto_stories_rounded,
                        color: DesignTokens.getPrimaryColor(context),
                        size: 24,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.spacing16),
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
                const CompactAnalysisCounter(),
              ],
            ),
            const SizedBox(height: AppConstants.spacing8),
            ResponsiveText(
              dateFormatter.format(now),
              baseFontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextTertiary(context),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.spacing32),
        
        // Greeting
        ResponsiveText(
          'Hi $_userName, how are you feeling today?',
          baseFontSize: DesignTokens.fontSizeXXL,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.getTextPrimary(context),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: AppConstants.spacing16),
        
        // Analysis Status Widget
        AnalysisStatusWidget(
          onAnalysisComplete: refreshJournalScreenState,
        ),
        
        const SizedBox(height: AppConstants.spacing24),
        
        // Conditional: Show emotional state visualization or mood selector + journal input
        _showingSnapshot && _savedEntry != null
          ? Column(
              children: [
                // Your Emotional State Visualization
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with sparkle icon
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: DesignTokens.getPrimaryColor(context),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Emotional State Visualization',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Emotional State Visualization Widget
                    EmotionalStateVisualization(
                      moodOverview: _createMoodOverviewFromEntry(_savedEntry!),
                      showDescription: true,
                      height: 300,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _resetToInputMode,
                  child: const Text('Write Another Entry Tomorrow'),
                ),
              ],
            )
          : Column(
              children: [
                // Mood Selector
                MoodSelector(
                  selectedMoods: _selectedMoods,
                  onMoodChanged: (moods) {
                    if (mounted) {
                      setState(() {
                        _selectedMoods.clear();
                        _selectedMoods.addAll(moods);
                      });
                    }
                  },
                ),
                
                const SizedBox(height: AppConstants.spacing24),
                
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
        
        const SizedBox(height: AppConstants.spacing24),
        
        // Mind Reflection Card
        const MindReflectionCard(),
        
        const SizedBox(height: AppConstants.spacing24),
        
        // Your Cores Card
        const YourCoresCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    // Use iOS-specific keyboard dismissal and safe area handling
    Widget body = AdaptiveScaffold(
        backgroundColor: DesignTokens.getBackgroundPrimary(context),
        padding: EdgeInsets.zero, // Remove default padding to avoid double padding
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: DesignTokens.getPrimaryColor(context),
          backgroundColor: DesignTokens.getBackgroundPrimary(context),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            physics: const AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works even when content doesn't fill screen
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNormalJournalInput(),
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

}
