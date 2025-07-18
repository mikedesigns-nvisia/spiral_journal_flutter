import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/database/database_helper.dart';

/// Utility class for database testing
class DatabaseTestUtils {
  /// Initialize the database for testing
  static Future<void> initializeTestDatabase() async {
    // Initialize sqflite_ffi
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Get the database instance to initialize it
    await DatabaseHelper().database;
  }
}