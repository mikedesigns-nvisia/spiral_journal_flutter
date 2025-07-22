import 'package:flutter/material.dart';
import '../models/slide_config.dart';
import '../providers/emotional_mirror_provider.dart';

/// Service for preloading adjacent slides to ensure smooth transitions
class SlidePreloader {
  static final Map<String, Widget> _preloadedSlides = {};
  static final Map<String, DateTime> _preloadTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const int _maxCachedSlides = 3;

  /// Preload adjacent slides for smooth transitions
  static Future<void> preloadAdjacentSlides({
    required int currentIndex,
    required List<SlideConfig> slides,
    required EmotionalMirrorProvider provider,
    required BuildContext context,
  }) async {
    // Clean expired cache entries first
    _cleanExpiredCache();
    
    // Preload previous slide
    if (currentIndex > 0) {
      await _preloadSlide(
        slideIndex: currentIndex - 1,
        slides: slides,
        provider: provider,
        context: context,
      );
    }
    
    // Preload next slide
    if (currentIndex < slides.length - 1) {
      await _preloadSlide(
        slideIndex: currentIndex + 1,
        slides: slides,
        provider: provider,
        context: context,
      );
    }
    
    // Manage memory by limiting cached slides
    _manageCacheSize();
  }

  /// Preload a specific slide
  static Future<void> _preloadSlide({
    required int slideIndex,
    required List<SlideConfig> slides,
    required EmotionalMirrorProvider provider,
    required BuildContext context,
  }) async {
    if (slideIndex < 0 || slideIndex >= slides.length) return;
    
    final slide = slides[slideIndex];
    final cacheKey = '${slide.id}_${provider.hashCode}';
    
    // Skip if already cached and not expired
    if (_preloadedSlides.containsKey(cacheKey) && 
        !_isCacheExpired(cacheKey)) {
      return;
    }
    
    try {
      // Build the slide widget in a separate context to avoid interference
      final preloadedWidget = _buildSlideForPreload(slide, provider, context);
      
      // Cache the preloaded widget
      _preloadedSlides[cacheKey] = preloadedWidget;
      _preloadTimestamps[cacheKey] = DateTime.now();
      
      debugPrint('Preloaded slide: ${slide.title} (index: $slideIndex)');
    } catch (e) {
      debugPrint('Failed to preload slide ${slide.title}: $e');
    }
  }

  /// Build a slide widget for preloading
  static Widget _buildSlideForPreload(
    SlideConfig slide,
    EmotionalMirrorProvider provider,
    BuildContext context,
  ) {
    // Create a minimal version of the slide for preloading
    // This reduces memory usage while still preparing the widget tree
    return Builder(
      builder: (context) {
        try {
          return slide.builder(context, provider);
        } catch (e) {
          // Return a placeholder if the slide fails to build
          return Container(
            child: Center(
              child: Text('Slide preparation in progress...'),
            ),
          );
        }
      },
    );
  }

  /// Get a preloaded slide if available
  static Widget? getPreloadedSlide(String slideId, int providerHash) {
    final cacheKey = '${slideId}_$providerHash';
    
    if (_preloadedSlides.containsKey(cacheKey) && 
        !_isCacheExpired(cacheKey)) {
      return _preloadedSlides[cacheKey];
    }
    
    return null;
  }

  /// Check if a slide is preloaded and ready
  static bool isSlidePreloaded(String slideId, int providerHash) {
    final cacheKey = '${slideId}_$providerHash';
    return _preloadedSlides.containsKey(cacheKey) && 
           !_isCacheExpired(cacheKey);
  }

  /// Clear preloaded slide from cache
  static void clearPreloadedSlide(String slideId, int providerHash) {
    final cacheKey = '${slideId}_$providerHash';
    _preloadedSlides.remove(cacheKey);
    _preloadTimestamps.remove(cacheKey);
  }

  /// Clear all preloaded slides
  static void clearAllPreloadedSlides() {
    _preloadedSlides.clear();
    _preloadTimestamps.clear();
    debugPrint('Cleared all preloaded slides');
  }

  /// Check if cache entry is expired
  static bool _isCacheExpired(String cacheKey) {
    final timestamp = _preloadTimestamps[cacheKey];
    if (timestamp == null) return true;
    
    return DateTime.now().difference(timestamp) > _cacheExpiry;
  }

  /// Clean expired cache entries
  static void _cleanExpiredCache() {
    final expiredKeys = <String>[];
    
    _preloadTimestamps.forEach((key, timestamp) {
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _preloadedSlides.remove(key);
      _preloadTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('Cleaned ${expiredKeys.length} expired slide cache entries');
    }
  }

  /// Manage cache size to prevent memory issues
  static void _manageCacheSize() {
    if (_preloadedSlides.length <= _maxCachedSlides) return;
    
    // Sort by timestamp and remove oldest entries
    final sortedEntries = _preloadTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final entriesToRemove = sortedEntries.length - _maxCachedSlides;
    
    for (int i = 0; i < entriesToRemove; i++) {
      final key = sortedEntries[i].key;
      _preloadedSlides.remove(key);
      _preloadTimestamps.remove(key);
    }
    
    debugPrint('Removed $entriesToRemove old slide cache entries to manage memory');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedSlides': _preloadedSlides.length,
      'maxCacheSize': _maxCachedSlides,
      'cacheExpiry': _cacheExpiry.inMinutes,
      'cachedSlideIds': _preloadedSlides.keys.toList(),
    };
  }

  /// Preload slides based on user navigation patterns
  static Future<void> intelligentPreload({
    required int currentIndex,
    required List<SlideConfig> slides,
    required EmotionalMirrorProvider provider,
    required BuildContext context,
    List<int> recentlyVisited = const [],
  }) async {
    // Standard adjacent preloading
    await preloadAdjacentSlides(
      currentIndex: currentIndex,
      slides: slides,
      provider: provider,
      context: context,
    );
    
    // Preload frequently visited slides
    if (recentlyVisited.isNotEmpty) {
      final frequentSlides = _getFrequentlyVisitedSlides(recentlyVisited, currentIndex);
      
      for (final slideIndex in frequentSlides.take(1)) {
        if (slideIndex != currentIndex && 
            slideIndex >= 0 && 
            slideIndex < slides.length) {
          await _preloadSlide(
            slideIndex: slideIndex,
            slides: slides,
            provider: provider,
            context: context,
          );
        }
      }
    }
  }

  /// Get frequently visited slides based on navigation history
  static List<int> _getFrequentlyVisitedSlides(List<int> recentlyVisited, int currentIndex) {
    final frequency = <int, int>{};
    
    for (final slideIndex in recentlyVisited) {
      if (slideIndex != currentIndex) {
        frequency[slideIndex] = (frequency[slideIndex] ?? 0) + 1;
      }
    }
    
    final sortedByFrequency = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedByFrequency.map((e) => e.key).toList();
  }

  /// Dispose of all resources
  static void dispose() {
    clearAllPreloadedSlides();
  }
}