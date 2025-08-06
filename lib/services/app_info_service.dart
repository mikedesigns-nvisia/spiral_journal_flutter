import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for retrieving application information dynamically
class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  PackageInfo? _packageInfo;
  static const String _appName = 'Spiral Journal';
  static const String _supportEmail = 'support@spiraljournal.com';
  static const String _website = 'https://spiraljournal.tbd';
  static const String _appDescription = 'Personal Growth & Reflection';

  /// Initialize the service by loading package info
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('AppInfoService initialize error: $e');
    }
  }

  /// Get the app name
  String get appName => _packageInfo?.appName ?? _appName;

  /// Get the app version
  String get version => _packageInfo?.version ?? '1.0.0';

  /// Get the build number
  String get buildNumber => _packageInfo?.buildNumber ?? '1';

  /// Get the full version string (version + build)
  String get fullVersion => '$version+$buildNumber';

  /// Get the version display string
  String get versionDisplay => '$_appName v$version';

  /// Get the package name
  String get packageName => _packageInfo?.packageName ?? 'com.example.spiral_journal';

  /// Get the support email
  String get supportEmail => _supportEmail;

  /// Get the website URL
  String get website => _website;

  /// Get the app description
  String get appDescription => _appDescription;

  /// Get the full app title with description
  String get fullTitle => '$_appName - $_appDescription';

  /// Check if package info is loaded
  bool get isInitialized => _packageInfo != null;

  /// Get app info as a map for debugging
  Map<String, dynamic> get debugInfo => {
    'appName': appName,
    'version': version,
    'buildNumber': buildNumber,
    'packageName': packageName,
    'isInitialized': isInitialized,
  };
}