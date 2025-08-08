import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/core.dart';
import '../utils/database_exceptions.dart';
import 'database_helper.dart';

/// Data Access Object for emotional core database operations.
/// 
/// This class manages all database operations related to emotional cores,
/// core combinations, and emotional patterns. It provides comprehensive
/// transaction safety, data validation, and supports both individual and
/// batch operations for complex emotional intelligence tracking.
/// 
/// ## Key Features
/// - **Transaction Safety**: All operations use database transactions for consistency
/// - **Default Core Initialization**: Automatically sets up the six core emotional types
/// - **Batch Operations**: Efficient multi-record operations with rollback support
/// - **Data Validation**: Comprehensive validation for core data integrity
/// - **Atomic Updates**: Combined operations for maintaining data consistency
/// 
/// ## Usage Example
/// ```dart
/// final coreDao = CoreDao();
/// 
/// // Initialize default cores (call once on app setup)
/// await coreDao.initializeDefaultCores();
/// 
/// // Update core percentages (AI-driven updates)
/// await coreDao.updateCorePercentage('core-id', 75.5, 'rising');
/// 
/// // Batch updates for multiple cores
/// await coreDao.updateMultipleCorePercentages({
///   'core-1': {'percentage': 80.0, 'trend': 'rising'},
///   'core-2': {'percentage': 65.0, 'trend': 'stable'},
/// });
/// 
/// // Query operations
/// final topCores = await coreDao.getTopCores(3);
/// final risingCores = await coreDao.getCoresByTrend('rising');
/// ```
/// 
/// ## Core System Architecture
/// The system manages six primary emotional cores:
/// - **Optimism**: Hope and positive outlook
/// - **Resilience**: Capacity to bounce back from setbacks
/// - **Self-Awareness**: Understanding of thoughts and emotions
/// - **Creativity**: Innovative thinking and expression
/// - **Social Connection**: Ability to relate and connect with others
/// - **Growth Mindset**: Openness to learning and development
/// 
/// ## Transaction Architecture
/// All database operations are wrapped in transactions using `_executeInTransaction`:
/// - Automatic rollback on any operation failure
/// - Comprehensive error logging and context preservation
/// - Type-safe transaction handling with generic return types
/// - Validation before database operations to prevent invalid states
/// 
/// ## Data Validation Strategy
/// - Core name validation against predefined valid core types
/// - Percentage validation (0-100 range)
/// - Trend validation ('rising', 'stable', 'declining')
/// - Required field validation (name, description, color, etc.)
/// - Relationship validation for core combinations and patterns
class CoreDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // Insert or update an emotional core with transaction safety
  Future<String> insertEmotionalCore(EmotionalCore core) async {
    return await _executeInTransaction<String>((txn) async {
      return await _insertEmotionalCoreInTransaction(txn, core);
    });
  }

  // Internal method for inserting emotional core within a transaction
  Future<String> _insertEmotionalCoreInTransaction(Transaction txn, EmotionalCore core) async {
    // Validate core data before insertion
    _validateEmotionalCore(core);
    
    final now = DateTime.now().toIso8601String();
    final coreWithId = EmotionalCore(
      id: core.id.isEmpty ? _uuid.v4() : core.id,
      name: core.name,
      description: core.description,
      currentLevel: core.currentLevel,
      previousLevel: core.previousLevel,
      lastUpdated: core.lastUpdated,
      trend: core.trend,
      color: core.color,
      iconPath: core.iconPath,
      insight: core.insight,
      relatedCores: core.relatedCores,
    );

    await txn.insert(
      'emotional_cores',
      {
        'id': coreWithId.id,
        'name': coreWithId.name,
        'description': coreWithId.description,
        'current_level': coreWithId.currentLevel,
        'previous_level': coreWithId.previousLevel,
        'trend': coreWithId.trend,
        'color': coreWithId.color,
        'icon_path': coreWithId.iconPath,
        'insight': coreWithId.insight,
        'related_cores': coreWithId.relatedCores.join(','),
        'created_at': now,
        'last_updated': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return coreWithId.id;
  }

  // Get all emotional cores
  Future<List<EmotionalCore>> getAllEmotionalCores() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_cores',
        orderBy: 'current_level DESC',
      );

      return maps.map((map) => _mapToEmotionalCore(map)).toList();
    } catch (e) {
      debugPrint('CoreDao.getAllEmotionalCores failed: $e');
      rethrow;
    }
  }

  // Get emotional core by ID
  Future<EmotionalCore?> getEmotionalCoreById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_cores',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToEmotionalCore(maps.first);
    } catch (e) {
      debugPrint('CoreDao.getEmotionalCoreById failed: $e');
      rethrow;
    }
  }

  // Get emotional core by name
  Future<EmotionalCore?> getEmotionalCoreByName(String name) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_cores',
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToEmotionalCore(maps.first);
    } catch (e) {
      debugPrint('CoreDao.getEmotionalCoreByName failed: $e');
      rethrow;
    }
  }

  // Update emotional core percentage and trend with transaction safety
  Future<void> updateEmotionalCore(EmotionalCore core) async {
    await _executeInTransaction<void>((txn) async {
      await _updateEmotionalCoreInTransaction(txn, core);
    });
  }

  // Internal method for updating emotional core within a transaction
  Future<void> _updateEmotionalCoreInTransaction(Transaction txn, EmotionalCore core) async {
    // Validate core data before update
    _validateEmotionalCore(core);
    
    final now = DateTime.now().toIso8601String();

    final result = await txn.update(
      'emotional_cores',
      {
        'name': core.name,
        'description': core.description,
        'current_level': core.currentLevel,
        'previous_level': core.previousLevel,
        'trend': core.trend,
        'color': core.color,
        'icon_path': core.iconPath,
        'insight': core.insight,
        'related_cores': core.relatedCores.join(','),
        'last_updated': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [core.id],
    );

    if (result == 0) {
      throw const DatabaseTransactionException('Failed to update emotional core: core not found');
    }
  }

  // Update core percentage (for AI-driven updates) with transaction safety
  Future<void> updateCorePercentage(String coreId, double newPercentage, String trend) async {
    await _executeInTransaction<void>((txn) async {
      await _updateCorePercentageInTransaction(txn, coreId, newPercentage, trend);
    });
  }

  // Internal method for updating core percentage within a transaction
  Future<void> _updateCorePercentageInTransaction(Transaction txn, String coreId, double newPercentage, String trend) async {
    // Validate input parameters
    if (coreId.trim().isEmpty) {
      throw ArgumentError('Core ID cannot be empty');
    }
    
    if (newPercentage < 0.0 || newPercentage > 100.0) {
      throw ArgumentError('Percentage must be between 0 and 100');
    }
    
    final validTrends = ['rising', 'stable', 'declining'];
    if (!validTrends.contains(trend)) {
      throw ArgumentError('Invalid trend: $trend. Must be one of: ${validTrends.join(', ')}');
    }
    
    final now = DateTime.now().toIso8601String();

    final result = await txn.update(
      'emotional_cores',
      {
        'current_level': newPercentage / 100.0,
        'previous_level': newPercentage / 100.0,
        'trend': trend,
        'last_updated': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [coreId],
    );

    if (result == 0) {
      throw DatabaseTransactionException('Failed to update core percentage: core $coreId not found');
    }
  }

  // Delete emotional core with transaction safety
  Future<void> deleteEmotionalCore(String id) async {
    await _executeInTransaction<void>((txn) async {
      await _deleteEmotionalCoreInTransaction(txn, id);
    });
  }

  // Internal method for deleting emotional core within a transaction
  Future<void> _deleteEmotionalCoreInTransaction(Transaction txn, String id) async {
    // Validate input
    if (id.trim().isEmpty) {
      throw ArgumentError('Emotional core ID cannot be empty');
    }

    // Check if core exists before deletion
    final existingCore = await txn.query(
      'emotional_cores',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (existingCore.isEmpty) {
      throw DatabaseTransactionException('Cannot delete emotional core: core with ID $id not found');
    }

    final result = await txn.delete(
      'emotional_cores',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result == 0) {
      throw DatabaseTransactionException('Failed to delete emotional core: no rows affected');
    }
  }

  // Get top cores by percentage
  Future<List<EmotionalCore>> getTopCores(int limit) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_cores',
        orderBy: 'current_level DESC',
        limit: limit,
      );

      return maps.map((map) => _mapToEmotionalCore(map)).toList();
    } catch (e) {
      debugPrint('CoreDao.getTopCores failed: $e');
      rethrow;
    }
  }

  // Get cores by trend
  Future<List<EmotionalCore>> getCoresByTrend(String trend) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_cores',
        where: 'trend = ?',
        whereArgs: [trend],
        orderBy: 'current_level DESC',
      );

      return maps.map((map) => _mapToEmotionalCore(map)).toList();
    } catch (e) {
      debugPrint('CoreDao.getCoresByTrend failed: $e');
      rethrow;
    }
  }

  // Insert core combination with transaction safety
  Future<String> insertCoreCombination(CoreCombination combination) async {
    return await _executeInTransaction<String>((txn) async {
      return await _insertCoreCombinationInTransaction(txn, combination);
    });
  }

  // Internal method for inserting core combination within a transaction
  Future<String> _insertCoreCombinationInTransaction(Transaction txn, CoreCombination combination) async {
    // Validate combination data
    if (combination.name.trim().isEmpty) {
      throw ArgumentError('Core combination name cannot be empty');
    }
    
    if (combination.coreIds.isEmpty) {
      throw ArgumentError('Core combination must have at least one core ID');
    }
    
    if (combination.description.trim().isEmpty) {
      throw ArgumentError('Core combination description cannot be empty');
    }
    
    if (combination.benefit.trim().isEmpty) {
      throw ArgumentError('Core combination benefit cannot be empty');
    }

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await txn.insert(
      'core_combinations',
      {
        'id': id,
        'name': combination.name,
        'coreIds': combination.coreIds.join(','),
        'description': combination.description,
        'benefit': combination.benefit,
        'createdAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  // Get all core combinations
  Future<List<CoreCombination>> getAllCoreCombinations() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('core_combinations');
      return maps.map((map) => _mapToCoreCombination(map)).toList();
    } catch (e) {
      debugPrint('Error getting all core combinations: $e');
      rethrow;
    }
  }

  // Insert emotional pattern with transaction safety
  Future<String> insertEmotionalPattern(EmotionalPattern pattern) async {
    return await _executeInTransaction<String>((txn) async {
      return await _insertEmotionalPatternInTransaction(txn, pattern);
    });
  }

  // Internal method for inserting emotional pattern within a transaction
  Future<String> _insertEmotionalPatternInTransaction(Transaction txn, EmotionalPattern pattern) async {
    // Validate pattern data
    if (pattern.category.trim().isEmpty) {
      throw ArgumentError('Emotional pattern category cannot be empty');
    }
    
    if (pattern.title.trim().isEmpty) {
      throw ArgumentError('Emotional pattern title cannot be empty');
    }
    
    if (pattern.description.trim().isEmpty) {
      throw ArgumentError('Emotional pattern description cannot be empty');
    }
    
    final validTypes = ['growth', 'recurring', 'awareness'];
    if (!validTypes.contains(pattern.type)) {
      throw ArgumentError('Invalid pattern type: ${pattern.type}. Must be one of: ${validTypes.join(', ')}');
    }

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await txn.insert(
      'emotional_patterns',
      {
        'id': id,
        'category': pattern.category,
        'title': pattern.title,
        'description': pattern.description,
        'type': pattern.type,
        'createdAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  // Batch operations with transaction safety
  Future<List<String>> insertMultipleEmotionalCores(List<EmotionalCore> cores) async {
    return await _executeInTransaction<List<String>>((txn) async {
      final coreIds = <String>[];
      
      for (final core in cores) {
        final coreId = await _insertEmotionalCoreInTransaction(txn, core);
        coreIds.add(coreId);
      }
      
      return coreIds;
    });
  }

  Future<void> updateMultipleEmotionalCores(List<EmotionalCore> cores) async {
    await _executeInTransaction<void>((txn) async {
      for (final core in cores) {
        await _updateEmotionalCoreInTransaction(txn, core);
      }
    });
  }

  Future<void> deleteMultipleEmotionalCores(List<String> ids) async {
    await _executeInTransaction<void>((txn) async {
      for (final id in ids) {
        await _deleteEmotionalCoreInTransaction(txn, id);
      }
    });
  }

  Future<List<String>> insertMultipleCoreCombinations(List<CoreCombination> combinations) async {
    return await _executeInTransaction<List<String>>((txn) async {
      final combinationIds = <String>[];
      
      for (final combination in combinations) {
        final combinationId = await _insertCoreCombinationInTransaction(txn, combination);
        combinationIds.add(combinationId);
      }
      
      return combinationIds;
    });
  }

  Future<List<String>> insertMultipleEmotionalPatterns(List<EmotionalPattern> patterns) async {
    return await _executeInTransaction<List<String>>((txn) async {
      final patternIds = <String>[];
      
      for (final pattern in patterns) {
        final patternId = await _insertEmotionalPatternInTransaction(txn, pattern);
        patternIds.add(patternId);
      }
      
      return patternIds;
    });
  }

  // Get emotional patterns by type
  Future<List<EmotionalPattern>> getEmotionalPatternsByType(String type) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'emotional_patterns',
        where: 'type = ?',
        whereArgs: [type],
      );
      return maps.map((map) => _mapToEmotionalPattern(map)).toList();
    } catch (e) {
      debugPrint('Error getting emotional patterns by type: $e');
      rethrow;
    }
  }

  // Initialize default cores if database is empty with transaction safety
  Future<void> initializeDefaultCores() async {
    final existingCores = await getAllEmotionalCores();
    if (existingCores.isNotEmpty) return;

    final defaultCores = [
      EmotionalCore(
        id: '',
        name: 'Optimism',
        description: 'Your ability to maintain hope and positive outlook',
        currentLevel: 0.10,
        previousLevel: 0.10,
        lastUpdated: DateTime.now(),
        trend: 'stable',
        color: 'AFCACD',
        iconPath: 'assets/icons/optimism.png',
        insight: 'Your capacity for optimism awaits discovery through your journey',
        relatedCores: ['Growth Mindset', 'Resilience'],
      ),
      EmotionalCore(
        id: '',
        name: 'Resilience',
        description: 'Your capacity to bounce back from setbacks',
        currentLevel: 0.10,
        previousLevel: 0.10,
        lastUpdated: DateTime.now(),
        trend: 'stable',
        color: 'EBA751',
        iconPath: 'assets/icons/resilience.png',
        insight: 'Inner strength lies dormant, ready to emerge through your experiences',
        relatedCores: ['Optimism', 'Self-Awareness'],
      ),
      EmotionalCore(
        id: '',
        name: 'Self-Awareness',
        description: 'Your understanding of your thoughts and emotions',
        currentLevel: 0.10,
        previousLevel: 0.10,
        lastUpdated: DateTime.now(),
        trend: 'stable',
        color: 'A198DD',
        iconPath: 'assets/icons/self_awareness.png',
        insight: 'The path to self-understanding begins with your first reflections',
        relatedCores: ['Growth Mindset', 'Creativity'],
      ),
      EmotionalCore(
        id: '',
        name: 'Creativity',
        description: 'Your innovative thinking and expression',
        currentLevel: 0.10,
        previousLevel: 0.10,
        lastUpdated: DateTime.now(),
        trend: 'stable',
        color: 'B1CDAF',
        iconPath: 'assets/icons/creativity.png',
        insight: 'Creative potential rests within, waiting to be expressed',
        relatedCores: ['Self-Awareness', 'Social Connection'],
      ),
      EmotionalCore(
        id: '',
        name: 'Social Connection',
        description: 'Your ability to relate and connect with others',
        currentLevel: 0.10,
        previousLevel: 0.10,
        lastUpdated: DateTime.now(),
        trend: 'stable',
        color: 'B37A9B',
        iconPath: 'assets/icons/social.png',
        insight: 'The seeds of meaningful connection are ready to be nurtured',
        relatedCores: ['Creativity', 'Growth Mindset'],
      ),
      EmotionalCore(
        id: '',
        name: 'Growth Mindset',
        description: 'Your openness to learning and development',
        currentLevel: 0.10,
        previousLevel: 0.10,
        lastUpdated: DateTime.now(),
        trend: 'stable',
        color: 'AFCACD',
        iconPath: 'assets/icons/growth.png',
        insight: 'Your journey of growth and learning is about to begin',
        relatedCores: ['Optimism', 'Self-Awareness'],
      ),
    ];

    // Initialize all default cores in a single transaction
    await _executeInTransaction<void>((txn) async {
      for (final core in defaultCores) {
        await _insertEmotionalCoreInTransaction(txn, core);
      }
    });
  }

  // Atomic batch update of multiple cores (for AI-driven updates)
  Future<void> updateMultipleCorePercentages(Map<String, Map<String, dynamic>> coreUpdates) async {
    await _executeInTransaction<void>((txn) async {
      final now = DateTime.now().toIso8601String();
      
      for (final update in coreUpdates.entries) {
        final coreId = update.key;
        final updateData = update.value;
        
        final result = await txn.update(
          'emotional_cores',
          {
            'current_level': (updateData['percentage'] ?? 0.0) / 100.0,
            'previous_level': (updateData['percentage'] ?? 0.0) / 100.0,
            'trend': updateData['trend'],
            'last_updated': now,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [coreId],
        );
        
        if (result == 0) {
          throw DatabaseTransactionException('Failed to update emotional core: core $coreId not found');
        }
      }
    });
  }

  // Transaction wrapper for atomic operations with comprehensive error handling
  Future<T> _executeInTransaction<T>(Future<T> Function(Transaction txn) operation) async {
    try {
      final db = await _dbHelper.database;
      
      return await db.transaction<T>((txn) async {
        try {
          return await operation(txn);
        } catch (e) {
          debugPrint('CoreDao transaction error: $e');
          rethrow; // Let the transaction handle the rollback
        }
      });
    } catch (error) {
      // Convert database-specific errors to appropriate exceptions
      if (error is DatabaseException) {
        throw DatabaseTransactionException('Core database transaction failed: ${error.toString()}');
      } else if (error is ArgumentError) {
        throw DatabaseValidationException('Core transaction validation failed: ${error.message}');
      } else {
        throw DatabaseTransactionException('Core transaction failed with unexpected error: ${error.toString()}');
      }
    }
  }

  // Data validation before database operations
  void _validateEmotionalCore(EmotionalCore core) {
    if (core.name.trim().isEmpty) {
      throw ArgumentError('Emotional core name cannot be empty');
    }
    
    if (core.description.trim().isEmpty) {
      throw ArgumentError('Emotional core description cannot be empty');
    }
    
    if (core.currentLevel < 0.0 || core.currentLevel > 1.0) {
      throw ArgumentError('Emotional core current level must be between 0.0 and 1.0');
    }
    
    final validTrends = ['rising', 'stable', 'declining'];
    if (!validTrends.contains(core.trend)) {
      throw ArgumentError('Invalid trend: ${core.trend}. Must be one of: ${validTrends.join(', ')}');
    }
    
    if (core.color.trim().isEmpty) {
      throw ArgumentError('Emotional core color cannot be empty');
    }
    
    if (core.iconPath.trim().isEmpty) {
      throw ArgumentError('Emotional core icon path cannot be empty');
    }
    
    if (core.insight.trim().isEmpty) {
      throw ArgumentError('Emotional core insight cannot be empty');
    }
    
    // Validate core name is one of the expected types
    final validCoreNames = [
      'Optimism', 'Resilience', 'Self-Awareness', 
      'Creativity', 'Social Connection', 'Growth Mindset'
    ];
    
    if (!validCoreNames.contains(core.name)) {
      throw ArgumentError('Invalid core name: ${core.name}. Must be one of: ${validCoreNames.join(', ')}');
    }
  }

  // Reset all cores to default state (for data management)
  Future<void> resetAllCores() async {
    await _executeInTransaction<void>((txn) async {
      // Delete all existing cores
      await txn.delete('emotional_cores');
      
      // Re-initialize default cores
      final defaultCores = [
        EmotionalCore(
          id: '',
          name: 'Optimism',
          description: 'Your ability to maintain hope and positive outlook',
          currentLevel: 0.10,
          previousLevel: 0.10,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: 'AFCACD',
          iconPath: 'assets/icons/optimism.png',
          insight: 'Your capacity for optimism awaits discovery through your journey',
          relatedCores: ['Growth Mindset', 'Resilience'],
        ),
        EmotionalCore(
          id: '',
          name: 'Resilience',
          description: 'Your capacity to bounce back from setbacks',
          currentLevel: 0.10,
          previousLevel: 0.10,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: 'EBA751',
          iconPath: 'assets/icons/resilience.png',
          insight: 'Inner strength lies dormant, ready to emerge through your experiences',
          relatedCores: ['Optimism', 'Self-Awareness'],
        ),
        EmotionalCore(
          id: '',
          name: 'Self-Awareness',
          description: 'Your understanding of your thoughts and emotions',
          currentLevel: 0.10,
          previousLevel: 0.10,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: 'A198DD',
          iconPath: 'assets/icons/self_awareness.png',
          insight: 'The path to self-understanding begins with your first reflections',
          relatedCores: ['Growth Mindset', 'Creativity'],
        ),
        EmotionalCore(
          id: '',
          name: 'Creativity',
          description: 'Your innovative thinking and expression',
          currentLevel: 0.10,
          previousLevel: 0.10,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: 'B1CDAF',
          iconPath: 'assets/icons/creativity.png',
          insight: 'Creative potential rests within, waiting to be expressed',
          relatedCores: ['Self-Awareness', 'Social Connection'],
        ),
        EmotionalCore(
          id: '',
          name: 'Social Connection',
          description: 'Your ability to relate and connect with others',
          currentLevel: 0.10,
          previousLevel: 0.10,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: 'B37A9B',
          iconPath: 'assets/icons/social.png',
          insight: 'The seeds of meaningful connection are ready to be nurtured',
          relatedCores: ['Creativity', 'Growth Mindset'],
        ),
        EmotionalCore(
          id: '',
          name: 'Growth Mindset',
          description: 'Your openness to learning and development',
          currentLevel: 0.10,
          previousLevel: 0.10,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: 'AFCACD',
          iconPath: 'assets/icons/growth.png',
          insight: 'Your journey of growth and learning is about to begin',
          relatedCores: ['Optimism', 'Self-Awareness'],
        ),
      ];

      // Insert all default cores
      for (final core in defaultCores) {
        await _insertEmotionalCoreInTransaction(txn, core);
      }
    });
  }

  // Helper methods to convert database maps to objects
  EmotionalCore _mapToEmotionalCore(Map<String, dynamic> map) {
    return EmotionalCore(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      currentLevel: (map['current_level'] as num?)?.toDouble() ?? 0.0,
      previousLevel: (map['previous_level'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: map['last_updated'] != null 
          ? DateTime.tryParse(map['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      trend: map['trend'] as String? ?? 'stable',
      color: map['color'] as String? ?? 'CCCCCC',
      iconPath: map['icon_path'] as String? ?? '',
      insight: map['insight'] as String? ?? '',
      relatedCores: (map['related_cores'] as String? ?? '').split(',').where((c) => c.isNotEmpty).toList(),
    );
  }

  CoreCombination _mapToCoreCombination(Map<String, dynamic> map) {
    return CoreCombination(
      name: map['name'] as String? ?? '',
      coreIds: (map['coreIds'] as String? ?? '').split(',').where((c) => c.isNotEmpty).toList(),
      description: map['description'] as String? ?? '',
      benefit: map['benefit'] as String? ?? '',
    );
  }

  EmotionalPattern _mapToEmotionalPattern(Map<String, dynamic> map) {
    return EmotionalPattern(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'awareness',
      category: map['category'] ?? 'General',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      firstDetected: map['firstDetected'] != null 
          ? DateTime.parse(map['firstDetected'])
          : DateTime.now(),
      lastSeen: map['lastSeen'] != null 
          ? DateTime.parse(map['lastSeen'])
          : DateTime.now(),
      relatedEmotions: map['relatedEmotions'] != null 
          ? List<String>.from(map['relatedEmotions'].toString().split(',').where((e) => e.isNotEmpty))
          : [],
    );
  }
}
