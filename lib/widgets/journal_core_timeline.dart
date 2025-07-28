import 'package:flutter/material.dart';
import '../models/core.dart';
import '../models/journal_entry.dart';
import '../design_system/design_tokens.dart';
import 'core_impact_indicator.dart';

/// Timeline item representing a journal entry and its core impacts
class JournalCoreTimelineItem {
  final JournalEntry journalEntry;
  final List<EmotionalCore> affectedCores;
  final Map<String, double> coreImpacts;
  final DateTime timestamp;

  JournalCoreTimelineItem({
    required this.journalEntry,
    required this.affectedCores,
    required this.coreImpacts,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? journalEntry.updatedAt;
}

/// Widget that displays a timeline connecting journal entries to core changes
class JournalCoreTimeline extends StatefulWidget {
  final List<JournalCoreTimelineItem> timelineItems;
  final Function(String coreId)? onCoreImpactTap;
  final Function(String journalEntryId)? onJournalEntryTap;
  final bool showAnimations;
  final int maxItems;

  const JournalCoreTimeline({
    super.key,
    required this.timelineItems,
    this.onCoreImpactTap,
    this.onJournalEntryTap,
    this.showAnimations = true,
    this.maxItems = 10,
  });

  @override
  State<JournalCoreTimeline> createState() => _JournalCoreTimelineState();
}

class _JournalCoreTimelineState extends State<JournalCoreTimeline>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _staggerController = AnimationController(
      duration: Duration(milliseconds: 300 * widget.timelineItems.length),
      vsync: this,
    );

    _itemAnimations = List.generate(
      widget.timelineItems.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.3,
          curve: Curves.easeOutBack,
        ),
      )),
    );

    if (widget.showAnimations) {
      _staggerController.forward();
    } else {
      _staggerController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = widget.timelineItems.take(widget.maxItems).toList();
    
    if (displayItems.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceColor,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius3),
        border: Border.all(
          color: DesignTokens.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: DesignTokens.spacing4),
          
          // Timeline items
          ...displayItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            return AnimatedBuilder(
              animation: _itemAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
                  child: Opacity(
                    opacity: _itemAnimations[index].value,
                    child: _buildTimelineItem(
                      item,
                      isLast: index == displayItems.length - 1,
                    ),
                  ),
                );
              },
            );
          }),
          
          // Show more indicator
          if (widget.timelineItems.length > widget.maxItems) ...[
            const SizedBox(height: DesignTokens.spacing3),
            _buildShowMoreIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacing2),
          decoration: BoxDecoration(
            color: DesignTokens.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
          ),
          child: Icon(
            Icons.timeline,
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
                'Journal-Core Connection Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.primaryColor,
                ),
              ),
              
              Text(
                'How your writing influences personal growth',
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

  Widget _buildTimelineItem(JournalCoreTimelineItem item, {required bool isLast}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : DesignTokens.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          _buildTimelineIndicator(item, isLast: isLast),
          
          const SizedBox(width: DesignTokens.spacing3),
          
          // Content
          Expanded(
            child: _buildTimelineContent(item),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(JournalCoreTimelineItem item, {required bool isLast}) {
    return Column(
      children: [
        // Timeline dot
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getTimelineColor(item),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getTimelineColor(item).withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        
        // Timeline line
        if (!isLast)
          Container(
            width: 2,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacing1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getTimelineColor(item).withValues(alpha: 0.5),
                  DesignTokens.borderColor,
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineContent(JournalCoreTimelineItem item) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius3),
        border: Border.all(
          color: DesignTokens.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journal entry header
          _buildJournalHeader(item),
          
          const SizedBox(height: DesignTokens.spacing2),
          
          // Journal preview
          _buildJournalPreview(item),
          
          if (item.coreImpacts.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacing3),
            
            // Core impacts
            _buildCoreImpacts(item),
          ],
        ],
      ),
    );
  }

  Widget _buildJournalHeader(JournalCoreTimelineItem item) {
    return Row(
      children: [
        Icon(
          Icons.edit_note,
          size: 16,
          color: DesignTokens.textSecondaryColor,
        ),
        
        const SizedBox(width: DesignTokens.spacing1),
        
        Text(
          _formatDate(item.journalEntry.date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: DesignTokens.textSecondaryColor,
          ),
        ),
        
        const Spacer(),
        
        Text(
          _formatTime(item.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DesignTokens.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildJournalPreview(JournalCoreTimelineItem item) {
    return GestureDetector(
      onTap: () => widget.onJournalEntryTap?.call(item.journalEntry.id),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing2),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.journalEntry.preview,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (item.journalEntry.moods.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacing2),
              
              Wrap(
                spacing: DesignTokens.spacing1,
                children: item.journalEntry.moods.take(3).map((mood) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacing2,
                      vertical: DesignTokens.spacing1,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadius1),
                    ),
                    child: Text(
                      mood,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignTokens.primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoreImpacts(JournalCoreTimelineItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core Growth Impact:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: DesignTokens.textSecondaryColor,
          ),
        ),
        
        const SizedBox(height: DesignTokens.spacing2),
        
        Wrap(
          spacing: DesignTokens.spacing2,
          runSpacing: DesignTokens.spacing1,
          children: item.affectedCores.where((core) {
            final impact = item.coreImpacts[core.id] ?? 0.0;
            return impact.abs() > 0.05;
          }).map((core) {
            final impact = item.coreImpacts[core.id] ?? 0.0;
            return CoreImpactIndicator(
              core: core,
              relatedEntry: item.journalEntry,
              impactValue: impact,
              showAnimation: false, // Disable animation in timeline
              onTap: () => widget.onCoreImpactTap?.call(core.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShowMoreIndicator() {
    final remainingCount = widget.timelineItems.length - widget.maxItems;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing3),
      decoration: BoxDecoration(
        color: DesignTokens.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
        border: Border.all(
          color: DesignTokens.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.more_horiz,
            size: 16,
            color: DesignTokens.primaryColor,
          ),
          
          const SizedBox(width: DesignTokens.spacing2),
          
          Text(
            '$remainingCount more entries with core impacts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DesignTokens.primaryColor,
              fontWeight: FontWeight.w500,
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
            Icons.timeline_outlined,
            size: 48,
            color: DesignTokens.textSecondaryColor.withValues(alpha: 0.5),
          ),
          
          const SizedBox(height: DesignTokens.spacing3),
          
          Text(
            'No Journal-Core Connections Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DesignTokens.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: DesignTokens.spacing2),
          
          Text(
            'Start journaling to see how your writing influences your personal growth cores.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DesignTokens.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getTimelineColor(JournalCoreTimelineItem item) {
    // Calculate overall impact magnitude
    final totalImpact = item.coreImpacts.values.fold(0.0, (sum, impact) => sum + impact.abs());
    
    if (totalImpact > 0.5) {
      return DesignTokens.successColor;
    } else if (totalImpact > 0.2) {
      return DesignTokens.primaryColor;
    } else {
      return DesignTokens.neutralColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    
    if (entryDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (entryDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}