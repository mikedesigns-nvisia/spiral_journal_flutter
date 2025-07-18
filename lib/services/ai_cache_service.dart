import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';

/// Service for caching AI analysis results to reduce API calls and improve performance.
/// 
/// This service provides intelligent caching for AI analysis results with:
/// - Time-based expiration
/// - Content-based cache keys
/// - Automatic cache cleanup
/// - Memory-efficient storage
class AICacheService {
  static final AICacheService _instance = AICacheService._internal();
  factory AICacheService() => _instance;
  AICacheService._internal();

  static const String _cacheKeyPrefix = 'ai_cache_';
  static const String _cacheMetaKey = 'ai_cache_meta';
  static const Duration _defaultExpiration = Duration(hours: 24);
  static const int _maxCacheEntries = 100;

  /// Cache an analysis result for a journal entry
  Future<void> cacheAnalysis(
    JournalEntry entry,
    Map<String, dynamic> analysis, {
    Duration? expiration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(entry);
      final expirationTime = DateTime.now().add(expiration ?? _defaultExpiration);

      final cacheData = {
        'analysis': analysis,
        'timestamp': DateTime.now().toIso8601String(),
        'expiration': expirationTime.toIso8601String(),
        'entry_id': entry.id,
        'content_hash': entry.content.hashCode,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      await _updateCacheMetadata(cacheKey, expirationTime);
      await _cleanupExpiredCache();
    } catch (e) {
      debugPrint('AICacheService cacheAnalysis error: $e');
      // Don't throw - caching failures shouldn't break the app
    }
  }

  /// Retrieve cached analysis for a journal entry
  Future<Map<String, dynamic>?> getCachedAnalysis(JournalEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(entry);
      final cachedData = prefs.getString(cacheKey);

      if (cachedData == null) {
        return null;
      }

      final data = jsonDecode(cachedData);
      final expiration = DateTime.parse(data['expiration']);
      final contentHash = data['content_hash'] as int;

      // Check if cache is expired
      if (DateTime.now().isAfter(expiration)) {
        await _removeCacheEntry(cacheKey);
        return null;
      }

      // Check if content has changed
      if (contentHash != entry.content.hashCode) {
        await _removeCacheEntry(cacheKey);
        return null;
      }

      return Map<String, dynamic>.from(data['analysis']);
    } catch (e) {
      debugPrint('AICacheService getCachedAnalysis error: $e');
      return null;
    }
  }

  /// Cache a monthly insight
  Future<void> cacheMonthlyInsight(
    List<JournalEntry> entries,
    String insight, {
    Duration? expiration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateInsightCacheKey(entries);
      final expirationTime = DateTime.now().add(expiration ?? Duration(hours: 6));

      final cacheData = {
        'insight': insight,
        'timestamp': DateTime.now().toIso8601String(),
        'expiration': expirationTime.toIso8601String(),
        'entries_count': entries.length,
        'entries_hash': _generateEntriesHash(entries),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      await _updateCacheMetadata(cacheKey, expirationTime);
    } catch (e) {
      debugPrint('AICacheService cacheMonthlyInsight error: $e');
    }
  }

  /// Retrieve cached monthly insight
  Future<String?> getCachedMonthlyInsight(List<JournalEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateInsightCacheKey(entries);
      final cachedData = prefs.getString(cacheKey);

      if (cachedData == null) {
        return null;
      }

      final data = jsonDecode(cachedData);
      final expiration = DateTime.parse(data['expiration']);
      final entriesHash = data['entries_hash'] as int;

      // Check if cache is expired
      if (DateTime.now().isAfter(expiration)) {
        await _removeCacheEntry(cacheKey);
        return null;
      }

      // Check if entries have changed
      if (entriesHash != _generateEntriesHash(entries)) {
        await _removeCacheEntry(cacheKey);
        return null;
      }

      return data['insight'] as String;
    } catch (e) {
      debugPrint('AICacheService getCachedMonthlyInsight error: $e');
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      await prefs.remove(_cacheMetaKey);
    } catch (e) {
      debugPrint('AICacheService clearCache error: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
      
      int totalEntries = keys.length;
      int expiredEntries = 0;
      int validEntries = 0;
      
      for (final key in keys) {
        final cachedData = prefs.getString(key);
        if (cachedData != null) {
          try {
            final data = jsonDecode(cachedData);
            final expiration = DateTime.parse(data['expiration']);
            
            if (DateTime.now().isAfter(expiration)) {
              expiredEntries++;
            } else {
              validEntries++;
            }
          } catch (e) {
            expiredEntries++;
          }
        }
      }

      return {
        'total_entries': totalEntries,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
        'cache_hit_potential': validEntries / (totalEntries > 0 ? totalEntries : 1),
      };
    } catch (e) {
      debugPrint('AICacheService getCacheStats error: $e');
      return {
        'total_entries': 0,
        'valid_entries': 0,
        'expired_entries': 0,
        'cache_hit_potential': 0.0,
      };
    }
  }

  // Private methods

  String _generateCacheKey(JournalEntry entry) {
    // Create a unique key based on entry content and moods
    final contentHash = entry.content.hashCode;
    final moodsHash = entry.moods.join(',').hashCode;
    return '${_cacheKeyPrefix}analysis_${contentHash}_$moodsHash';
  }

  String _generateInsightCacheKey(List<JournalEntry> entries) {
    final entriesHash = _generateEntriesHash(entries);
    final month = DateTime.now().month;
    final year = DateTime.now().year;
    return '${_cacheKeyPrefix}insight_${year}_${month}_$entriesHash';
  }

  int _generateEntriesHash(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0;
    
    // Create hash based on entry IDs and content
    final combined = entries
        .map((e) => '${e.id}_${e.content.hashCode}')
        .join('|');
    return combined.hashCode;
  }

  Future<void> _updateCacheMetadata(String cacheKey, DateTime expiration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaData = prefs.getString(_cacheMetaKey);
      
      Map<String, dynamic> meta = {};
      if (metaData != null) {
        meta = Map<String, dynamic>.from(jsonDecode(metaData));
      }

      meta[cacheKey] = expiration.toIso8601String();
      await prefs.setString(_cacheMetaKey, jsonEncode(meta));
    } catch (e) {
      debugPrint('AICacheService _updateCacheMetadata error: $e');
    }
  }

  Future<void> _removeCacheEntry(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);

      // Update metadata
      final metaData = prefs.getString(_cacheMetaKey);
      if (metaData != null) {
        final meta = Map<String, dynamic>.from(jsonDecode(metaData));
        meta.remove(cacheKey);
        await prefs.setString(_cacheMetaKey, jsonEncode(meta));
      }
    } catch (e) {
      debugPrint('AICacheService _removeCacheEntry error: $e');
    }
  }

  Future<void> _cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaData = prefs.getString(_cacheMetaKey);
      
      if (metaData == null) return;

      final meta = Map<String, dynamic>.from(jsonDecode(metaData));
      final now = DateTime.now();
      final expiredKeys = <String>[];

      // Find expired entries
      for (final entry in meta.entries) {
        try {
          final expiration = DateTime.parse(entry.value);
          if (now.isAfter(expiration)) {
            expiredKeys.add(entry.key);
          }
        } catch (e) {
          expiredKeys.add(entry.key);
        }
      }

      // Remove expired entries
      for (final key in expiredKeys) {
        await prefs.remove(key);
        meta.remove(key);
      }

      // Check if we need to remove oldest entries to stay under limit
      if (meta.length > _maxCacheEntries) {
        final sortedEntries = meta.entries.toList()
          ..sort((a, b) {
            try {
              final aTime = DateTime.parse(a.value);
              final bTime = DateTime.parse(b.value);
              return aTime.compareTo(bTime);
            } catch (e) {
              return 0;
            }
          });

        final entriesToRemove = sortedEntries.length - _maxCacheEntries;
        for (int i = 0; i < entriesToRemove; i++) {
          final key = sortedEntries[i].key;
          await prefs.remove(key);
          meta.remove(key);
        }
      }

      await prefs.setString(_cacheMetaKey, jsonEncode(meta));
    } catch (e) {
      debugPrint('AICacheService _cleanupExpiredCache error: $e');
    }
  }
}