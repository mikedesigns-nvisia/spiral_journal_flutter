import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/services/dummy_data_service.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:intl/intl.dart';

class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  String selectedYear = '2025';
  String searchQuery = '';
  List<JournalEntry> get filteredEntries {
    var entries = DummyDataService.journalEntries;
    
    if (searchQuery.isNotEmpty) {
      entries = entries.where((entry) =>
        entry.content.toLowerCase().contains(searchQuery.toLowerCase()) ||
        entry.mood.any((mood) => mood.toLowerCase().contains(searchQuery.toLowerCase())) ||
        entry.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()))
      ).toList();
    }
    
    return entries;
  }

  Map<String, List<JournalEntry>> get groupedEntries {
    final Map<String, List<JournalEntry>> grouped = {};
    for (final entry in filteredEntries) {
      final monthKey = DateFormat('MMMM yyyy').format(entry.date);
      grouped.putIfAbsent(monthKey, () => []).add(entry);
    }
    // Sort entries within each month by date (newest first)
    grouped.forEach((key, entries) {
      entries.sort((a, b) => b.date.compareTo(a.date));
    });
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      color: AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppTheme.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Journal History',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Friday, June 6',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Year Filter Chips
              Wrap(
                spacing: 8,
                children: ['2025', '2024', '2023', '2022'].map((year) {
                  return FilterChip(
                    label: Text(year),
                    selected: year == '2025',
                    onSelected: (selected) {},
                    backgroundColor: AppTheme.backgroundTertiary,
                    selectedColor: AppTheme.moodEnergetic,
                    labelStyle: TextStyle(
                      color: year == '2025' ? Colors.white : AppTheme.textSecondary,
                      fontWeight: year == '2025' ? FontWeight.w600 : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Search Bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search entries, moods, or tags...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryOrange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.backgroundTertiary),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Journal Entries by Month
              ...groupedEntries.entries.map((monthEntry) {
                final monthName = monthEntry.key;
                final entries = monthEntry.value;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.backgroundTertiary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppTheme.primaryOrange),
                          const SizedBox(width: 12),
                          Text(
                            monthName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          Text(
                            '• ${entries.length} entries',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Entries for this month
                    ...entries.map((entry) => _buildEntryCard(entry)),
                    
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
              
              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => _showEntryDetails(entry),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d').format(entry.date),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          entry.dayOfWeek,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 4,
                      children: entry.mood.take(2).map((mood) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.getMoodColor(mood),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          mood,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: entry.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryDetails(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(entry.date),
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('h:mm a').format(entry.date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Moods
                      if (entry.mood.isNotEmpty) ...[
                        Text(
                          'Mood',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.mood.map((mood) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.getMoodColor(mood),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              mood,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Content
                      Text(
                        'Journal Entry',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                      
                      // Tags
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Tags',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.backgroundTertiary),
                            ),
                            child: Text(
                              '#$tag',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
