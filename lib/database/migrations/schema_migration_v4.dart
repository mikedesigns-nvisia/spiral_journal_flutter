import 'package:sqflite/sqflite.dart';

/// Migration from version 3 to version 4
/// Adds AI analysis fields to journal_entries table
class SchemaMigrationV4 {
  static Future<void> migrate(Database db) async {
    // Add new AI analysis columns to journal_entries table
    await db.execute('ALTER TABLE journal_entries ADD COLUMN aiAnalysis TEXT');
    await db.execute('ALTER TABLE journal_entries ADD COLUMN isAnalyzed INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE journal_entries ADD COLUMN draftContent TEXT');
    await db.execute('ALTER TABLE journal_entries ADD COLUMN aiDetectedMoods TEXT NOT NULL DEFAULT "[]"');
    await db.execute('ALTER TABLE journal_entries ADD COLUMN emotionalIntensity REAL');
    await db.execute('ALTER TABLE journal_entries ADD COLUMN keyThemes TEXT NOT NULL DEFAULT "[]"');
    await db.execute('ALTER TABLE journal_entries ADD COLUMN personalizedInsight TEXT');
    
    // Create additional indexes for AI analysis fields
    await db.execute('CREATE INDEX idx_journal_entries_analyzed ON journal_entries(isAnalyzed)');
    await db.execute('CREATE INDEX idx_journal_entries_intensity ON journal_entries(emotionalIntensity)');
  }
}