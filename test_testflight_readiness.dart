#!/usr/bin/env dart

import 'dart:io';
import 'package:spiral_journal/utils/sample_data_generator.dart';
import 'package:spiral_journal/services/core_library_service.dart';
import 'package:spiral_journal/repositories/journal_repository_impl.dart';
import 'package:spiral_journal/services/settings_service.dart';

/// TestFlight Readiness Verification Script
/// 
/// This script verifies that the app is in a proper "fresh install" state
/// suitable for TestFlight distribution.
void main() async {
  print('🚀 TestFlight Readiness Verification');
  print('=====================================\n');

  var allTestsPassed = true;

  // Test 1: Sample Data Generation Disabled
  print('📋 Test 1: Sample Data Generation');
  try {
    await SampleDataGenerator.generateSampleData();
    
    // Verify no entries were created
    final repository = JournalRepositoryImpl();
    final entries = await repository.getAllEntries();
    
    if (entries.isEmpty) {
      print('✅ Sample data generation properly disabled');
    } else {
      print('❌ Sample data generation created ${entries.length} entries');
      allTestsPassed = false;
    }
  } catch (e) {
    print('❌ Error testing sample data generation: $e');
    allTestsPassed = false;
  }

  // Test 2: Core Library Fresh State
  print('\n📊 Test 2: Core Library Initial State');
  try {
    final coreService = CoreLibraryService();
    final cores = await coreService.getAllCores();
    
    var allCoresAtZero = true;
    for (final core in cores) {
      if (core.currentLevel != 0.0 || core.previousLevel != 0.0) {
        print('❌ Core ${core.name}: current=${core.currentLevel}, previous=${core.previousLevel}');
        allCoresAtZero = false;
      }
    }
    
    if (allCoresAtZero && cores.length == 6) {
      print('✅ All 6 cores start at 0.0 progress');
    } else {
      print('❌ Cores not in fresh state');
      allTestsPassed = false;
    }
  } catch (e) {
    print('❌ Error testing core library: $e');
    allTestsPassed = false;
  }

  // Test 3: Settings Default State
  print('\n⚙️  Test 3: Settings Default State');
  try {
    final settingsService = SettingsService();
    await settingsService.initialize();
    final preferences = await settingsService.getPreferences();
    
    var settingsCorrect = true;
    final expectedDefaults = {
      'personalizedInsightsEnabled': true,
      'analyticsEnabled': true,
      'biometricAuthEnabled': false,
    };
    
    if (preferences.personalizedInsightsEnabled != expectedDefaults['personalizedInsightsEnabled']) {
      print('❌ personalizedInsightsEnabled: expected ${expectedDefaults['personalizedInsightsEnabled']}, got ${preferences.personalizedInsightsEnabled}');
      settingsCorrect = false;
    }
    
    if (preferences.analyticsEnabled != expectedDefaults['analyticsEnabled']) {
      print('❌ analyticsEnabled: expected ${expectedDefaults['analyticsEnabled']}, got ${preferences.analyticsEnabled}');
      settingsCorrect = false;
    }
    
    if (preferences.biometricAuthEnabled != expectedDefaults['biometricAuthEnabled']) {
      print('❌ biometricAuthEnabled: expected ${expectedDefaults['biometricAuthEnabled']}, got ${preferences.biometricAuthEnabled}');
      settingsCorrect = false;
    }
    
    if (settingsCorrect) {
      print('✅ Settings in proper default state');
    } else {
      allTestsPassed = false;
    }
  } catch (e) {
    print('❌ Error testing settings: $e');
    allTestsPassed = false;
  }

  // Test 4: File Content Verification
  print('\n📁 Test 4: Code Content Verification');
  
  // Check sample data generator
  final sampleDataFile = File('lib/utils/sample_data_generator.dart');
  if (await sampleDataFile.exists()) {
    final content = await sampleDataFile.readAsString();
    if (content.contains('ALWAYS disable sample data generation')) {
      print('✅ Sample data generator properly disabled');
    } else {
      print('❌ Sample data generator not properly disabled');
      allTestsPassed = false;
    }
  } else {
    print('❌ Sample data generator file not found');
    allTestsPassed = false;
  }

  // Check settings screen
  final settingsFile = File('lib/screens/settings_screen.dart');
  if (await settingsFile.exists()) {
    final content = await settingsFile.readAsString();
    if (!content.contains('Generate Sample Data') && 
        !content.contains('High Contrast Mode')) {
      print('✅ Settings screen properly cleaned for TestFlight');
    } else {
      print('❌ Settings screen still contains development features');
      allTestsPassed = false;
    }
  } else {
    print('❌ Settings screen file not found');
    allTestsPassed = false;
  }

  // Test 5: Build Configuration
  print('\n🔧 Test 5: Build Configuration');
  
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    if (content.contains('version: ')) {
      print('✅ Version information present in pubspec.yaml');
    } else {
      print('❌ Version information missing from pubspec.yaml');
      allTestsPassed = false;
    }
  }

  // Final Results
  print('\n🎯 TestFlight Readiness Results');
  print('================================');
  
  if (allTestsPassed) {
    print('✅ ALL TESTS PASSED - App is ready for TestFlight!');
    print('\n🚀 Next Steps:');
    print('1. Run: flutter clean');
    print('2. Run: flutter pub get');
    print('3. Build and upload: cd ios && ./quick_upload.sh');
    exit(0);
  } else {
    print('❌ SOME TESTS FAILED - App needs fixes before TestFlight');
    print('\n🔧 Please address the issues above before deploying');
    exit(1);
  }
}