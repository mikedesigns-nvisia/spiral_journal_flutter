import 'package:flutter/material.dart';
import '../providers/emotional_mirror_provider.dart';

/// Configuration model for individual slides in the emotional mirror
class SlideConfig {
  /// Display title for the slide
  final String title;
  
  /// Icon to represent the slide
  final IconData icon;
  
  /// Builder function to create the slide widget
  final Widget Function(BuildContext context, EmotionalMirrorProvider provider) builder;
  
  /// Whether this slide requires data to be loaded
  final bool requiresData;
  
  /// Unique identifier for the slide
  final String id;

  const SlideConfig({
    required this.title,
    required this.icon,
    required this.builder,
    required this.id,
    this.requiresData = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideConfig &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          icon == other.icon &&
          requiresData == other.requiresData &&
          id == other.id;

  @override
  int get hashCode =>
      title.hashCode ^
      icon.hashCode ^
      requiresData.hashCode ^
      id.hashCode;

  @override
  String toString() {
    return 'SlideConfig{title: $title, id: $id, requiresData: $requiresData}';
  }
}