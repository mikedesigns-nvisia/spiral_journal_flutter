/// Entry status enumeration
enum EntryStatus {
  draft,     // Entry is being written/edited
  saved,     // Entry is saved but can still be edited (same day)
  processed  // Entry is processed and cannot be edited (past days)
}

class JournalEntry {
  final String id;
  final String userId; // For multi-user support
  final DateTime date;
  final String content;
  final List<String> moods;
  final String dayOfWeek;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced; // For offline/online sync
  final Map<String, dynamic> metadata; // For additional data
  
  final String? draftContent; // For crash recovery
  
  // Entry status tracking
  final EntryStatus status; // draft, saved, processed
  final bool isEditable; // Whether entry can be edited

  JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.content,
    required this.moods,
    required this.dayOfWeek,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.metadata = const {},
    this.draftContent,
    this.status = EntryStatus.draft,
    bool? isEditable,
  }) : isEditable = isEditable ?? _calculateEditability(date, status);

  // Helper method to calculate if entry is editable
  static bool _calculateEditability(DateTime entryDate, EntryStatus status) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
    
    // Entry is editable if it's from today and not processed
    return entryDay.isAtSameMomentAs(today) && status != EntryStatus.processed;
  }

  // Create a new entry with current date
  factory JournalEntry.create({
    required String content,
    required List<String> moods,
    String? id,
    String? userId,
  }) {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return JournalEntry(
      id: id ?? '',
      userId: userId ?? 'local_user', // Default for local-only
      date: now,
      content: content,
      moods: moods,
      dayOfWeek: dayNames[now.weekday - 1],
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create a copy with updated fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? content,
    List<String>? moods,
    String? dayOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    Map<String, dynamic>? metadata,
    String? draftContent,
    EntryStatus? status,
    bool? isEditable,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      content: content ?? this.content,
      moods: moods ?? this.moods,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      metadata: metadata ?? this.metadata,
      draftContent: draftContent ?? this.draftContent,
      status: status ?? this.status,
      isEditable: isEditable ?? this.isEditable,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'content': content,
      'moods': moods,
      'dayOfWeek': dayOfWeek,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'metadata': metadata,
      'draftContent': draftContent,
      'status': status.name,
    };
  }

  // Create from JSON
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      userId: json['userId'] ?? 'local_user',
      date: DateTime.parse(json['date']),
      content: json['content'],
      moods: List<String>.from(json['moods'] ?? []),
      dayOfWeek: json['dayOfWeek'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isSynced: json['isSynced'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      draftContent: json['draftContent'],
      status: EntryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EntryStatus.draft,
      ),
    );
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, date: $date, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Getter for month-year grouping
  String get monthYear {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Getter for preview text
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // Getter for formatted date string
  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}