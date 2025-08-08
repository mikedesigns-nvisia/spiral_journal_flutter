import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Database migration from v6 to v7: Add status column for tracking entry processing state
/// 
/// This migration adds the essential 'status' column to the journal_entries table
/// to enable proper tracking of entry processing states (draft, saved, processed).
/// This prevents duplicate processing and ensures data integrity.
class SchemaMigrationV7 {
  static Future<void> migrate(Database db) async {
    debugPrint('🔄 Running database migration v6 -> v7: Adding status column for processing state tracking');
    
    await db.transaction((txn) async {
      try {
        // Add status column to journal_entries table
        await txn.execute('''
          ALTER TABLE journal_entries 
          ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'
        ''');
        
        // Update existing entries to have 'saved' status (they are already created)
        await txn.execute('''
          UPDATE journal_entries 
          SET status = 'saved' 
          WHERE status = 'draft'
        ''');
        
        // Create index on status column for efficient filtering
        await txn.execute('''
          CREATE INDEX idx_journal_entries_status ON journal_entries(status)
        ''');
        
        debugPrint('✅ Successfully added status column and index to journal_entries table');
        
      } catch (e) {
        debugPrint('❌ Migration v6 -> v7 failed: $e');
        rethrow;
      }
    });
  }
}