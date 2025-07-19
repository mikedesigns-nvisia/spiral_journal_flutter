import 'dart:io';

/// Simple script to reset onboarding preferences without Flutter dependencies
void main() async {
  print('=== RESETTING ONBOARDING STATE ===');
  
  try {
    // On macOS, SharedPreferences are stored in ~/Library/Preferences/
    final homeDir = Platform.environment['HOME'];
    if (homeDir == null) {
      print('❌ Could not find home directory');
      return;
    }
    
    // The app bundle identifier would be something like com.example.spiralJournal
    // SharedPreferences files are typically stored as .plist files
    final prefsDir = Directory('$homeDir/Library/Preferences');
    
    if (!prefsDir.existsSync()) {
      print('❌ Preferences directory not found');
      return;
    }
    
    print('Looking for app preference files...');
    
    // List all preference files to find the app's plist
    final files = prefsDir.listSync();
    for (final file in files) {
      if (file.path.contains('spiral') || file.path.contains('journal')) {
        print('Found potential app preferences: ${file.path}');
      }
    }
    
    print('\n=== MANUAL RESET INSTRUCTIONS ===');
    print('Since we can\'t directly modify the preferences, here are the steps:');
    print('');
    print('1. Close the Spiral Journal app completely');
    print('2. Open Terminal and run:');
    print('   defaults delete com.example.spiralJournal');
    print('   (Replace com.example.spiralJournal with your actual bundle ID)');
    print('');
    print('3. Or delete the app and reinstall it');
    print('');
    print('4. Alternatively, you can add a debug button in the app to reset onboarding');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}