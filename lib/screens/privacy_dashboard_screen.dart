import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../services/data_export_service.dart';
import '../services/settings_service.dart';
import '../services/secure_data_deletion_service.dart';
import '../repositories/journal_repository.dart';
import '../services/core_library_service.dart';
import '../database/database_helper.dart';
import '../widgets/loading_state_widget.dart' as loading_widget;
import '../theme/app_theme.dart';

/// Privacy Dashboard Screen for Spiral Journal
/// 
/// This screen provides complete transparency about what data is stored locally
/// and how it's used. It includes:
/// - Data storage overview
/// - Privacy controls
/// - Secure data deletion
/// - Data usage explanations
/// - API key management
class PrivacyDashboardScreen extends StatefulWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  State<PrivacyDashboardScreen> createState() => _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState extends State<PrivacyDashboardScreen> {
  final DataExportService _exportService = DataExportService();
  final SettingsService _settingsService = SettingsService();
  final SecureDataDeletionService _deletionService = SecureDataDeletionService();
  
  // Data statistics
  int _journalEntryCount = 0;
  int _analyzedEntryCount = 0;
  int _coreCount = 0;
  double _totalDataSize = 0.0;
  bool _isLoadingStats = true;
  
  // Privacy settings
  bool _personalizedInsightsEnabled = true;
  bool _analyticsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadDataStatistics();
    _loadPrivacySettings();
  }

  Future<void> _loadDataStatistics() async {
    setState(() => _isLoadingStats = true);
    
    try {
      await _exportService.initialize();
      
      // Try to get journal statistics from actual repositories
      try {
        // Try to access repository through Provider if available
        final journalRepository = Provider.of<JournalRepository>(context, listen: false);
        final allEntries = await journalRepository.getAllEntries();
        _journalEntryCount = allEntries.length;
        
        // Count analyzed entries (those with AI analysis)
        _analyzedEntryCount = allEntries.where((entry) => entry.aiAnalysis != null).length;
        
        // Calculate approximate data size
        _totalDataSize = await _calculateDataSize(allEntries, []);
      } catch (providerError) {
        debugPrint('Repository not available through Provider: $providerError');
        // Use database helper directly as fallback
        await _loadStatsFromDatabase();
      }
      
      // Get core count
      final coreLibraryService = CoreLibraryService();
      final cores = await coreLibraryService.getAllCores();
      _coreCount = cores.length;
      
    } catch (e) {
      debugPrint('Error loading data statistics: $e');
      // Fallback to default values if repositories aren't available
      _journalEntryCount = 0;
      _analyzedEntryCount = 0;
      _coreCount = 6; // Standard 6 emotional cores
      _totalDataSize = 0.0;
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadPrivacySettings() async {
    try {
      await _settingsService.initialize();
      final preferences = await _settingsService.getPreferences();
      
      setState(() {
        _personalizedInsightsEnabled = preferences.personalizedInsightsEnabled;
        _analyticsEnabled = preferences.analyticsEnabled;
      });
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    }
  }

  Future<void> _loadStatsFromDatabase() async {
    try {
      // Use database helper directly to get statistics
      final databaseHelper = DatabaseHelper();
      final db = await databaseHelper.database;
      
      // Get journal entry count
      final entryCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM journal_entries');
      _journalEntryCount = entryCountResult.first['count'] as int? ?? 0;
      
      // Get analyzed entry count (entries with AI analysis)
      final analyzedCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM journal_entries WHERE ai_analysis IS NOT NULL'
      );
      _analyzedEntryCount = analyzedCountResult.first['count'] as int? ?? 0;
      
      // Estimate data size based on entry count
      _totalDataSize = (_journalEntryCount * 1024.0) + 2048; // Rough estimate
      
    } catch (e) {
      debugPrint('Error loading stats from database: $e');
      // Use fallback values
      _journalEntryCount = 0;
      _analyzedEntryCount = 0;
      _totalDataSize = 0.0;
    }
  }

  Future<double> _calculateDataSize(List<dynamic> entries, List<dynamic> cores) async {
    double totalSize = 0.0;
    
    // Estimate journal entries size
    for (final entry in entries) {
      if (entry.toString().isNotEmpty) {
        totalSize += entry.toString().length * 2; // Rough estimate including metadata
      }
    }
    
    // Estimate cores data size
    totalSize += cores.length * 1024; // Rough estimate for core data
    
    // Add estimated size for settings and other data
    totalSize += 2048; // Settings, preferences, etc.
    
    return totalSize;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Dashboard'),
        backgroundColor: DesignTokens.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: DesignTokens.getBackgroundPrimary(context),
      body: _isLoadingStats
          ? Center(
              child: loading_widget.LoadingStateWidget(
                type: loading_widget.LoadingType.circular,
                message: 'Loading privacy data...',
                color: DesignTokens.getPrimaryColor(context),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacyHeader(),
                  SizedBox(height: DesignTokens.spaceXXL),
                  _buildDataStorageOverview(),
                  SizedBox(height: DesignTokens.spaceXXL),
                  _buildPrivacyControls(),
                  SizedBox(height: DesignTokens.spaceXXL),
                  _buildDataUsageExplanation(),
                  SizedBox(height: DesignTokens.spaceXXL),
                  _buildSecurityFeatures(),
                  SizedBox(height: DesignTokens.spaceXXL),
                  _buildDataDeletionSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPrivacyHeader() {
    return ComponentLibrary.card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip, 
                color: DesignTokens.primaryOrange, 
                size: DesignTokens.iconSizeXL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Your Privacy Matters',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'Spiral Journal is designed with privacy-first principles. All your data is stored '
            'locally on your device and encrypted for security. You have complete control over '
            'your information.',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStorageOverview() {
    return ComponentLibrary.card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Stored Locally',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeXL,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
          
          _buildDataItem(
            icon: Icons.book,
            title: 'Journal Entries',
            count: _journalEntryCount,
            description: 'Your personal journal entries and reflections',
          ),
          
          _buildDataItem(
            icon: Icons.psychology,
            title: 'AI Analysis Results',
            count: _analyzedEntryCount,
            description: 'Emotional insights and patterns from AI analysis',
          ),
          
          _buildDataItem(
            icon: Icons.favorite,
            title: 'Emotional Cores',
            count: _coreCount,
            description: 'Your personality core progress and development',
          ),
          
          _buildDataItem(
            icon: Icons.settings,
            title: 'App Preferences',
            count: 1,
            description: 'Your app settings and customizations',
          ),
          
          Divider(height: DesignTokens.spaceXXL),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Storage Used',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
              Text(
                _formatDataSize(_totalDataSize),
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String title,
    required int count,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spaceL),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: DesignTokens.primaryOrange.withOpacity(0.1),
            child: Icon(icon, color: DesignTokens.primaryOrange),
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: DesignTokens.getTextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      count.toString(),
                      style: DesignTokens.getTextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.primaryOrange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceXS),
                Text(
                  description,
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyControls() {
    return ComponentLibrary.card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Controls',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeXL,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
          
          SwitchListTile(
            title: Text(
              'Personalized AI Insights',
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.getTextPrimary(context),
              ),
            ),
            subtitle: Text(
              'Allow AI to provide personalized feedback and commentary on your entries',
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.getTextSecondary(context),
              ),
            ),
            value: _personalizedInsightsEnabled,
            onChanged: _updatePersonalizedInsights,
            activeColor: DesignTokens.primaryOrange,
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: Text(
              'Usage Analytics',
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.getTextPrimary(context),
              ),
            ),
            subtitle: Text(
              'Help improve the app by sharing anonymous usage statistics',
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.getTextSecondary(context),
              ),
            ),
            value: _analyticsEnabled,
            onChanged: _updateAnalytics,
            activeColor: DesignTokens.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildDataUsageExplanation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Your Data is Used',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildUsageItem(
              icon: Icons.storage,
              title: 'Local Storage Only',
              description: 'All your data is stored locally on your device. Nothing is sent to external servers except for AI analysis.',
            ),
            
            _buildUsageItem(
              icon: Icons.psychology,
              title: 'AI Analysis',
              description: 'When you write an entry, the content is sent to Claude AI for emotional analysis. The AI service does not store your data.',
            ),
            
            _buildUsageItem(
              icon: Icons.lock,
              title: 'Encryption',
              description: 'Your journal entries and sensitive data are encrypted using industry-standard AES-256 encryption.',
            ),
            
            _buildUsageItem(
              icon: Icons.no_accounts,
              title: 'No Account Required',
              description: 'The app works completely offline. No account creation or personal information is required.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DesignTokens.primaryOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: Icon(Icons.pin, color: DesignTokens.primaryOrange),
              title: const Text('PIN Protection'),
              subtitle: const Text('Your journal is protected by a secure PIN'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            
            ListTile(
              leading: Icon(Icons.fingerprint, color: DesignTokens.primaryOrange),
              title: const Text('Biometric Authentication'),
              subtitle: const Text('Use Face ID or Touch ID for quick access'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            
            ListTile(
              leading: Icon(Icons.enhanced_encryption, color: DesignTokens.primaryOrange),
              title: const Text('Data Encryption'),
              subtitle: const Text('AES-256 encryption for all stored data'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            
            ListTile(
              leading: Icon(Icons.key, color: DesignTokens.primaryOrange),
              title: const Text('Secure API Keys'),
              subtitle: const Text('AI service keys stored in device keychain'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDeletionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'You have complete control over your data. You can export it at any time or '
              'permanently delete everything from your device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.backup),
                    label: const Text('Export Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeleteAllDataDialog,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePersonalizedInsights(bool value) async {
    try {
      final preferences = await _settingsService.getPreferences();
      await _settingsService.updatePreferences(
        preferences.copyWith(personalizedInsightsEnabled: value)
      );
      
      setState(() {
        _personalizedInsightsEnabled = value;
      });
      
      _showSuccessSnackBar(
        value 
          ? 'Personalized insights enabled'
          : 'Personalized insights disabled'
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update setting: $e');
    }
  }

  Future<void> _updateAnalytics(bool value) async {
    try {
      final preferences = await _settingsService.getPreferences();
      await _settingsService.updatePreferences(
        preferences.copyWith(analyticsEnabled: value)
      );
      
      setState(() {
        _analyticsEnabled = value;
      });
      
      _showSuccessSnackBar(
        value 
          ? 'Usage analytics enabled'
          : 'Usage analytics disabled'
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update setting: $e');
    }
  }

  void _exportData() {
    Navigator.pushNamed(context, '/data-export');
  }

  void _showDeleteAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Delete All Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete ALL your data including:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• All journal entries'),
            Text('• AI analysis results'),
            Text('• Emotional core progress'),
            Text('• App settings and preferences'),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone. Make sure you have exported your data if you want to keep it.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    try {
      // Initialize deletion service
      await _deletionService.initialize();

      // Show progress dialog with real-time updates
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ChangeNotifierProvider.value(
          value: _deletionService,
          child: Consumer<SecureDataDeletionService>(
            builder: (context, service, child) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: service.deletionProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryOrange),
                    ),
                    const SizedBox(height: 16),
                    Text(service.deletionStatus.isNotEmpty 
                        ? service.deletionStatus 
                        : 'Preparing to delete data...'),
                    const SizedBox(height: 8),
                    Text(
                      '${(service.deletionProgress * 100).toInt()}% Complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Perform secure data deletion
      final result = await _deletionService.deleteAllUserData(
        createBackup: false, // User already confirmed they want to delete
      );
      
      Navigator.pop(context); // Close progress dialog
      
      if (result.success) {
        _showSuccessDialog();
      } else {
        _showDeletionErrorDialog(result);
      }
      
    } catch (e) {
      Navigator.pop(context); // Close progress dialog
      _showErrorSnackBar('Failed to delete data: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Data Deleted'),
          ],
        ),
        content: const Text(
          'All your data has been permanently deleted from this device. '
          'The app will now restart to its initial state.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDataSize(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toInt()} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeletionErrorDialog(DataDeletionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Deletion Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.error ?? 'An unknown error occurred during data deletion.'),
            if (result.deletionLog.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Deletion Log:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    result.deletionLog.join('\n'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteAllDataDialog(); // Allow user to try again
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
