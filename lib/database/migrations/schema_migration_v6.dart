import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Database migration from v5 to v6: Remove AI-specific fields for local processing focus
/// 
/// This migration removes AI analysis fields and simplifies the journal entry schema
/// to focus on local fallback processing rather than external AI API dependencies.
class SchemaMigrationV6 {
  static Future<void> migrate(Database db) async {
    debugPrint('🔄 Running database migration v5 -> v6: Removing AI-specific fields');
    
    await db.transaction((txn) async {
      try {
        // Step 1: Create new journal_entries table without AI fields
        await txn.execute('''
          CREATE TABLE journal_entries_new (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL DEFAULT 'local_user',
            date TEXT NOT NULL,
            content TEXT NOT NULL,
            moods TEXT NOT NULL,
            dayOfWeek TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 1,
            metadata TEXT NOT NULL DEFAULT '{}',
            draftContent TEXT
          )
        ''');
        
        // Step 2: Copy existing data, excluding AI-specific fields
        await txn.execute('''
          INSERT INTO journal_entries_new (
            id, userId, date, content, moods, dayOfWeek, 
            createdAt, updatedAt, isSynced, metadata, draftContent
          )
          SELECT 
            id, userId, date, content, moods, dayOfWeek,
            createdAt, updatedAt, isSynced, metadata, draftContent
          FROM journal_entries
        ''');
        
        // Step 3: Drop old table
        await txn.execute('DROP TABLE journal_entries');
        
        // Step 4: Rename new table
        await txn.execute('ALTER TABLE journal_entries_new RENAME TO journal_entries');
        
        // Step 5: Recreate indexes for the new table (excluding AI-specific ones)
        await txn.execute('CREATE INDEX idx_journal_entries_date ON journal_entries(date)');
        await txn.execute('CREATE INDEX idx_journal_entries_created_at ON journal_entries(createdAt)');
        await txn.execute('CREATE INDEX idx_journal_entries_moods ON journal_entries(moods)');
        await txn.execute('CREATE INDEX idx_journal_entries_content_fts ON journal_entries(content)');
        
        debugPrint('✅ Successfully removed AI-specific fields from journal_entries table');
        
      } catch (e) {
        debugPrint('❌ Migration v5 -> v6 failed: $e');
        rethrow;
      }
    });
  }
}