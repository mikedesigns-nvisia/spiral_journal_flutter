// Dart imports
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
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/utils/ios_theme_enforcer.dart';
import 'package:spiral_journal/widgets/analysis_status_widget.dart';
import 'package:spiral_journal/widgets/compact_analysis_counter.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/widgets/mind_reflection_card.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/post_analysis_display.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';

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
        if (mounted) {
          setState(() {
            _draftContent = draftContent;
            _selectedMoods.clear();
            _selectedMoods.addAll(draftMoods);
          });
        }
        
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
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      // Check if we have an analyzed entry from today
      final lastAnalysisDate = prefs.getString('last_analysis_date');
      final hasAnalyzedToday = lastAnalysisDate == todayKey;
      
      if (hasAnalyzedToday && _isAiEnabled && mounted) {
        // Try to load today's analysis result from cache using JournalProvider
        final journalProvider = Provider.of<JournalProvider>(context, listen: false);
        await journalProvider.initialize();
        
        // Get today's entry from journal provider
        final todaysEntry = await _getTodaysAnalyzedEntry(journalProvider);
        
        if (mounted && todaysEntry != null && todaysEntry.isAnalyzed && todaysEntry.aiAnalysis != null) {
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
      if (mounted) {
        setState(() {
          _hasAnalyzedEntryToday = true;
          _todaysAnalyzedEntry = entry;
          _todaysAnalysisResult = analysisResult;
        });
      }
    } catch (e) {
      debugPrint('Error saving analysis state: $e');
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

        // Refresh cores after saving entry
        await coreProvider.refresh();

        // Refresh journal entries so they appear immediately in history
        await journalProvider.refresh();

        // Clear the form after successful save
        if (mounted) {
          setState(() {
            _journalController.clear();
            _selectedMoods.clear();
          });
        }

        // Show success message with batch analysis info
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: DesignTokens.getPrimaryColor(context),
                        ),
                        const SizedBox(width: AppConstants.spacing8),
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
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Performance metrics
                          Container(
                            padding: const EdgeInsets.all(AppConstants.spacing12),
                            decoration: BoxDecoration(
                              color: DesignTokens.getColorWithOpacity(
                                DesignTokens.getPrimaryColor(context), 
                                0.1
                              ),
                              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.speed,
                                  size: 16,
                                  color: DesignTokens.getPrimaryColor(context),
                                ),
                                const SizedBox(width: AppConstants.spacing8),
                                Text(
                                  'Analysis completed in ${analysisTime.inMilliseconds}ms',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacing20),
                          
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
                                  const SizedBox(height: AppConstants.spacing12),
                                  Container(
                                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.getColorWithOpacity(
                                        DesignTokens.getPrimaryColor(context), 
                                        0.1
                                      ),
                                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                                    ),
                                    child: Text(
                                      analysisResult.personalizedInsight,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.spacing20),
                                ],
                                
                                // Detected emotions
                                if (analysisResult.primaryEmotions.isNotEmpty) ...[
                                  Text(
                                    'Detected Emotions:',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.spacing12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: analysisResult.primaryEmotions.map<Widget>((emotion) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: DesignTokens.getMoodColor(emotion),
                                          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
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
                                  const SizedBox(height: AppConstants.spacing20),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
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
                      // Compact Analysis Counter aligned with title
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
              const AnalysisStatusWidget(),
              
              const SizedBox(height: AppConstants.spacing24),
              
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
              
              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
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
