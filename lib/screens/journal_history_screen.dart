import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/design_system/heading_system.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/constants/validation_constants.dart';
import 'package:spiral_journal/widgets/loading_state_widget.dart';
import 'package:spiral_journal/widgets/journal_edit_modal.dart';
import 'package:spiral_journal/utils/animation_utils.dart';
import 'package:intl/intl.dart';

class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;
  @override
  void initState() {
    super.initState();
    
    // Initialize scroll controller for pagination with optimized loading
    _scrollController.addListener(_onScroll);
    
    // Initialize journal provider to load entries
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      journalProvider.initialize();
      
      // Optimize memory usage periodically
      _scheduleMemoryOptimization();
    });
  }
  
  void _scheduleMemoryOptimization() {
    // Schedule periodic memory optimization
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        final journalProvider = Provider.of<JournalProvider>(context, listen: false);
        journalProvider.optimizeMemoryUsage();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      if (journalProvider.hasMorePages && !journalProvider.isLoadingMore) {
        journalProvider.loadMoreEntries();
      }
    }
  }

  Future<void> _loadEntriesForYear(String year) async {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    await journalProvider.loadEntriesForYear(year);
    
    if (journalProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load entries: ${journalProvider.error}'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  List<Widget> _buildEntriesByMonth(Map<String, List<JournalEntry>> groupedEntries) {
    final widgets = <Widget>[];

    for (final monthEntry in groupedEntries.entries) {
      final monthName = monthEntry.key;
      final entries = monthEntry.value;

      // Month header
      widgets.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkBackgroundTertiary 
                  : AppTheme.backgroundTertiary
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: AppTheme.getPrimaryColor(context)),
              const SizedBox(width: 12),
              Text(
                monthName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Text(
                '• ${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextTertiary(context),
                ),
              ),
            ],
          ),
        ),
      );

      widgets.add(const SizedBox(height: 16));

      // Entries for this month
      for (final entry in entries) {
        widgets.add(_buildEntryCard(entry));
        widgets.add(const SizedBox(height: 12));
      }

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildEntryCard(JournalEntry entry) {
    final isEditable = entry.isEditable;
    final isToday = _isToday(entry.date);
    
    return Dismissible(
      key: Key('journal_entry_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Theme.of(context).brightness == Brightness.dark 
                  ? Icons.delete_outline 
                  : Icons.delete_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: HeadingSystem.getLabelMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(entry);
      },
      onDismissed: (direction) {
        _deleteEntry(entry);
      },
      child: Card(
        child: InkWell(
          onTap: () {
            AnimationUtils.lightImpact();
            if (isEditable) {
              _editEntry(entry);
            } else {
              _showEntryDetails(entry);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM d').format(entry.date),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isEditable) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Editable',
                                  style: HeadingSystem.getLabelSmall(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (entry.isAnalyzed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.moodEnergetic,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.psychology_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'AI',
                                      style: HeadingSystem.getLabelSmall(context).copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          entry.dayOfWeek,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextTertiary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    if (entry.moods.isNotEmpty)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.end,
                            children: entry.moods.take(3).map((mood) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.getMoodColor(mood),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  mood,
                                  style: HeadingSystem.getLabelSmall(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.preview,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isEditable) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to edit',
                        style: HeadingSystem.getLabelMedium(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _editEntry(JournalEntry entry) {
    // Show modal for editing instead of navigation
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JournalEditModal(
        entry: entry,
        onSaved: () {
          // Refresh the journal entries after saving
          final journalProvider = Provider.of<JournalProvider>(context, listen: false);
          journalProvider.refresh();
        },
        onCancelled: () {
          // Optional: Handle cancellation if needed
        },
      ),
    );
  }

  void _showEntryDetails(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${DateFormat('MMMM d, y').format(entry.date)} - ${entry.dayOfWeek}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.moods.isNotEmpty) ...[
                Text(
                  'Moods:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.moods.map((mood) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.getMoodColor(mood),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        mood,
                        style: HeadingSystem.getLabelMedium(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // AI Analysis Section
              if (entry.isAnalyzed && entry.aiAnalysis != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            color: AppTheme.accentGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Analysis',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Personal Insight
                      if (entry.aiAnalysis!.personalizedInsight != null && 
                          entry.aiAnalysis!.personalizedInsight!.isNotEmpty) ...[
                        Text(
                          'Personal Insight:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.aiAnalysis!.personalizedInsight!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // AI Detected Emotions
                      if (entry.aiAnalysis!.primaryEmotions.isNotEmpty) ...[
                        Text(
                          'AI Detected Emotions:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: entry.aiAnalysis!.primaryEmotions.map((emotion) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.getMoodColor(emotion),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                emotion,
                                style: HeadingSystem.getLabelSmall(context).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Key Themes
                      if (entry.aiAnalysis!.keyThemes.isNotEmpty) ...[
                        Text(
                          'Key Themes:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...entry.aiAnalysis!.keyThemes.map((theme) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 4,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    theme,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                      
                      // Emotional Intensity
                      Row(
                        children: [
                          Text(
                            'Emotional Intensity: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(entry.aiAnalysis!.emotionalIntensity * 10).toStringAsFixed(1)}/10',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Analysis timestamp
                      Text(
                        'Analyzed: ${DateFormat('MMM d, h:mm a').format(entry.aiAnalysis!.analyzedAt)}',
                        style: HeadingSystem.getLabelSmall(context).copyWith(
                          color: AppTheme.getTextTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Text(
                'Entry:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.content,
                style: Theme.of(context).textTheme.bodyMedium,
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
      ),
    );
  }

  Widget _buildFilterSection() {
    return Consumer<JournalProvider>(
      builder: (context, journalProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundSecondary(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkBackgroundTertiary 
                  : AppTheme.backgroundTertiary
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mood Filter
              Text(
                'Filter by Mood',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120, // Fixed height to prevent overflow
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ValidationConstants.validMoods.map((mood) {
                      final isSelected = journalProvider.selectedMoods.contains(mood);
                      return FilterChip(
                        label: Text(mood),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newMoods = List<String>.from(journalProvider.selectedMoods);
                          if (selected) {
                            newMoods.add(mood);
                          } else {
                            newMoods.remove(mood);
                          }
                          journalProvider.setMoodFilter(newMoods);
                        },
                        backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.darkBackgroundTertiary 
                            : AppTheme.backgroundTertiary,
                        selectedColor: AppTheme.getMoodColor(mood),
                        labelStyle: HeadingSystem.getLabelMedium(context).copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.getTextSecondary(context),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date Range Filter
              Text(
                'Filter by Date Range',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectStartDate(journalProvider),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        journalProvider.startDate != null 
                            ? DateFormat('MMM d, y').format(journalProvider.startDate!)
                            : 'Start Date',
                        style: HeadingSystem.getLabelMedium(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectEndDate(journalProvider),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        journalProvider.endDate != null 
                            ? DateFormat('MMM d, y').format(journalProvider.endDate!)
                            : 'End Date',
                        style: HeadingSystem.getLabelMedium(context),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // AI Analysis Filter
              Text(
                'Filter by Analysis',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Analyzed'),
                    selected: journalProvider.isAnalyzedFilter == true,
                    onSelected: (selected) {
                      journalProvider.setAnalyzedFilter(selected ? true : null);
                    },
                    backgroundColor: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.darkBackgroundTertiary 
                        : AppTheme.backgroundTertiary,
                    selectedColor: AppTheme.accentGreen,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Not Analyzed'),
                    selected: journalProvider.isAnalyzedFilter == false,
                    onSelected: (selected) {
                      journalProvider.setAnalyzedFilter(selected ? false : null);
                    },
                    backgroundColor: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.darkBackgroundTertiary 
                        : AppTheme.backgroundTertiary,
                    selectedColor: AppTheme.accentRed,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectStartDate(JournalProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setDateRangeFilter(picked, provider.endDate);
    }
  }

  Future<void> _selectEndDate(JournalProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.endDate ?? DateTime.now(),
      firstDate: provider.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setDateRangeFilter(provider.startDate, picked);
    }
  }

  Future<bool?> _showDeleteConfirmation(JournalEntry entry) async {
    final wordCount = entry.content.trim().split(RegExp(r'\s+')).length;
    
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: AppTheme.accentRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Journal Entry',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete this journal entry from ${DateFormat('MMMM d, y').format(entry.date)}?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.accentRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will permanently delete $wordCount ${wordCount == 1 ? 'word' : 'words'}. This action cannot be undone.',
                        style: HeadingSystem.getLabelMedium(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: HeadingSystem.getLabelLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteEntry(JournalEntry entry) {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    
    // Delete the entry from the provider
    journalProvider.deleteEntry(entry.id);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Journal entry from ${DateFormat('MMM d').format(entry.date)} deleted',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Add haptic feedback
    AnimationUtils.mediumImpact();
  }

  Widget _buildContent(JournalProvider journalProvider) {
    if (journalProvider.isLoading && journalProvider.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: LoadingStateWidget(
            type: LoadingType.pulse,
            message: 'Loading your journal entries...',
            color: AppTheme.getPrimaryColor(context),
          ),
        ),
      );
    }

    if (journalProvider.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                journalProvider.hasActiveFilters ? Icons.search_off : Icons.book_outlined,
                size: 64,
                color: AppTheme.getTextTertiary(context),
              ),
              const SizedBox(height: 16),
              Text(
                journalProvider.hasActiveFilters ? 'No entries match your filters' : 'No entries found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.getTextTertiary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                journalProvider.hasActiveFilters 
                    ? 'Try adjusting your search or filters'
                    : 'Start journaling to see your entries here!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextTertiary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: _getItemCount(journalProvider),
      itemBuilder: (context, index) {
        return _buildListItem(context, journalProvider, index);
      },
    );
  }

  int _getItemCount(JournalProvider journalProvider) {
    if (journalProvider.hasActiveFilters) {
      // For filtered results, show entries + loading indicator if loading more
      return journalProvider.filteredEntries.length + 
             (journalProvider.isLoadingMore ? 1 : 0);
    } else {
      // For grouped entries, calculate total items including headers
      final groupedEntries = journalProvider.entriesByMonth;
      int itemCount = 0;
      for (final monthEntry in groupedEntries.entries) {
        itemCount += 1; // Month header
        itemCount += monthEntry.value.length; // Entries
      }
      return itemCount + (journalProvider.isLoadingMore ? 1 : 0);
    }
  }

  Widget _buildListItem(BuildContext context, JournalProvider journalProvider, int index) {
    if (journalProvider.hasActiveFilters) {
      // Handle filtered results
      if (index < journalProvider.filteredEntries.length) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildEntryCard(journalProvider.filteredEntries[index]),
        );
      } else {
        // Loading indicator
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: LoadingStateWidget(
              type: LoadingType.dots,
              message: 'Loading more entries...',
              size: 24,
            ),
          ),
        );
      }
    } else {
      // Handle grouped entries
      final groupedEntries = journalProvider.entriesByMonth;
      int currentIndex = 0;
      
      for (final monthEntry in groupedEntries.entries) {
        final monthName = monthEntry.key;
        final entries = monthEntry.value;
        
        // Check if this is the month header
        if (currentIndex == index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getBackgroundSecondary(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.darkBackgroundTertiary 
                      : AppTheme.backgroundTertiary
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: AppTheme.getPrimaryColor(context)),
                  const SizedBox(width: 12),
                  Text(
                    monthName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  Text(
                    '• ${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getTextTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        currentIndex++;
        
        // Check if this is one of the entries for this month
        for (int i = 0; i < entries.length; i++) {
          if (currentIndex == index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildEntryCard(entries[i]),
            );
          }
          currentIndex++;
        }
      }
      
      // Loading indicator
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundPrimary(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header and Search Section
            Padding(
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
                          color: AppTheme.getColorWithOpacity(AppTheme.getPrimaryColor(context), 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: AppTheme.getPrimaryColor(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Journal History',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      Consumer<JournalProvider>(
                        builder: (context, journalProvider, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Filter toggle button
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showFilters = !_showFilters;
                                  });
                                },
                                icon: Icon(
                                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                  color: AppTheme.getPrimaryColor(context),
                                ),
                                tooltip: _showFilters ? 'Hide filters' : 'Show filters',
                              ),
                              // Refresh button
                              IconButton(
                                onPressed: journalProvider.isLoading ? null : () async {
                                  await journalProvider.refresh();
                                  if (mounted && journalProvider.error == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Entries refreshed! 🔄'),
                                        backgroundColor: AppTheme.accentGreen,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                icon: journalProvider.isLoading 
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.getPrimaryColor(context)),
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      color: AppTheme.getPrimaryColor(context),
                                    ),
                                tooltip: 'Refresh entries',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.getTextTertiary(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search your journal entries...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                final provider = Provider.of<JournalProvider>(context, listen: false);
                                provider.setSearchQuery('');
                              },
                              icon: Icon(
                                Icons.clear,
                                color: AppTheme.getTextTertiary(context),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.getBackgroundSecondary(context),
                    ),
                    onChanged: (value) {
                      final provider = Provider.of<JournalProvider>(context, listen: false);
                      provider.setSearchQuery(value);
                    },
                  ),
                  
                  // Filter Section
                  if (_showFilters) ...[
                    const SizedBox(height: 16),
                    _buildFilterSection(),
                  ],
                ],
              ),
            ),
            
            // Content Section
            Expanded(
              child: Consumer<JournalProvider>(
                builder: (context, journalProvider, child) {
                  return Column(
                    children: [
                      // Year Filter Chips (only show if no active filters)
                      if (!journalProvider.hasActiveFilters && journalProvider.availableYears.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: journalProvider.availableYears.length,
                              itemBuilder: (context, index) {
                                final year = journalProvider.availableYears[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: Text(year),
                                    selected: year == journalProvider.selectedYear,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _loadEntriesForYear(year);
                                      }
                                    },
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                        ? AppTheme.darkBackgroundTertiary 
                                        : AppTheme.backgroundTertiary,
                                    selectedColor: AppTheme.moodEnergetic,
                                    labelStyle: HeadingSystem.getLabelLarge(context).copyWith(
                                      fontWeight: year == journalProvider.selectedYear ? FontWeight.w600 : FontWeight.w500,
                                      color: year == journalProvider.selectedYear ? Colors.white : AppTheme.getTextSecondary(context),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Active filters indicator
                      if (journalProvider.hasActiveFilters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                size: 16,
                                color: AppTheme.getPrimaryColor(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filters active',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.getPrimaryColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  final provider = Provider.of<JournalProvider>(context, listen: false);
                                  provider.clearAllFilters();
                                  _searchController.clear();
                                },
                                child: Text(
                                  'Clear all',
                                  style: HeadingSystem.getLabelMedium(context).copyWith(
                                    color: AppTheme.getPrimaryColor(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Content
                      Expanded(
                        child: _buildContent(journalProvider),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
