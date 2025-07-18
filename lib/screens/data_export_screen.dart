import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_export_service.dart';
import '../models/export_data.dart';
import '../theme/app_theme.dart';

/// Data export and import screen for Spiral Journal
/// 
/// This screen provides a comprehensive interface for users to:
/// - Export their complete journal data
/// - Import data from previous exports
/// - Manage export files
/// - Configure export settings (encryption, format)
/// 
/// Features:
/// - Real-time export progress tracking
/// - Secure encryption options
/// - File management and sharing
/// - Import validation and preview
class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataExportService _exportService = DataExportService();
  
  // Export settings
  bool _includeSettings = true;
  bool _encryptExport = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Import settings
  final TextEditingController _importPasswordController = TextEditingController();
  bool _mergeWithExisting = false;
  
  // File management
  List<ExportFileInfo> _exportFiles = [];
  bool _isLoadingFiles = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeService();
    _loadExportFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    _importPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    // Initialize with default dependencies - these will be injected properly in production
    await _exportService.initialize();
  }

  Future<void> _loadExportFiles() async {
    setState(() => _isLoadingFiles = true);
    try {
      final files = await _exportService.listExportFiles();
      setState(() => _exportFiles = files);
    } catch (e) {
      _showErrorSnackBar('Failed to load export files: $e');
    } finally {
      setState(() => _isLoadingFiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export & Import'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.upload), text: 'Export'),
            Tab(icon: Icon(Icons.download), text: 'Import'),
            Tab(icon: Icon(Icons.folder), text: 'Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportTab(),
          _buildImportTab(),
          _buildFilesTab(),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return ChangeNotifierProvider.value(
      value: _exportService,
      child: Consumer<DataExportService>(
        builder: (context, service, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportHeader(),
                const SizedBox(height: 24),
                _buildExportOptions(),
                const SizedBox(height: 24),
                if (service.isExporting) _buildExportProgress(service),
                if (!service.isExporting) _buildExportButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: AppTheme.primaryOrange),
                const SizedBox(width: 8),
                Text(
                  'Export Your Data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Create a complete backup of your journal entries, emotional cores, and settings. '
              'Your data will be exported in a portable format that you can import later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Include settings option
            SwitchListTile(
              title: const Text('Include Settings'),
              subtitle: const Text('Export your app preferences and configuration'),
              value: _includeSettings,
              onChanged: (value) => setState(() => _includeSettings = value),
              activeColor: AppTheme.primaryOrange,
            ),
            
            // Encryption option
            SwitchListTile(
              title: const Text('Encrypt Export'),
              subtitle: const Text('Protect your data with password encryption'),
              value: _encryptExport,
              onChanged: (value) => setState(() => _encryptExport = value),
              activeColor: AppTheme.primaryOrange,
            ),
            
            // Password field (shown when encryption is enabled)
            if (_encryptExport) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Encryption Password',
                  hintText: 'Enter a strong password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add a note about this export',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportProgress(DataExportService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Exporting Data...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: service.exportProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            ),
            const SizedBox(height: 8),
            Text(
              service.exportStatus,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${(service.exportProgress * 100).toInt()}% Complete',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _performExport,
        icon: const Icon(Icons.backup),
        label: const Text('Export Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImportHeader(),
          const SizedBox(height: 24),
          _buildImportOptions(),
          const SizedBox(height: 24),
          _buildImportButton(),
        ],
      ),
    );
  }

  Widget _buildImportHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restore, color: AppTheme.primaryOrange),
                const SizedBox(width: 8),
                Text(
                  'Import Your Data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Restore your journal data from a previous export. You can choose to merge '
              'with existing data or replace all current data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Merge option
            SwitchListTile(
              title: const Text('Merge with Existing Data'),
              subtitle: const Text('Add imported data to current data (recommended)'),
              value: _mergeWithExisting,
              onChanged: (value) => setState(() => _mergeWithExisting = value),
              activeColor: AppTheme.primaryOrange,
            ),
            
            if (!_mergeWithExisting) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: This will replace ALL your current data!',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Password field for encrypted imports
            TextField(
              controller: _importPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password (if encrypted)',
                hintText: 'Enter password for encrypted exports',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_open),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _performImport,
        icon: const Icon(Icons.restore),
        label: const Text('Select File to Import'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilesTab() {
    return RefreshIndicator(
      onRefresh: _loadExportFiles,
      child: _isLoadingFiles
          ? const Center(child: CircularProgressIndicator())
          : _exportFiles.isEmpty
              ? _buildEmptyFilesState()
              : _buildFilesList(),
    );
  }

  Widget _buildEmptyFilesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Export Files',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first export to see files here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exportFiles.length,
      itemBuilder: (context, index) {
        final file = _exportFiles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: file.isEncrypted ? Colors.red[100] : Colors.blue[100],
              child: Icon(
                file.isEncrypted ? Icons.lock : Icons.file_copy,
                color: file.isEncrypted ? Colors.red[700] : Colors.blue[700],
              ),
            ),
            title: Text(file.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Size: ${file.formattedSize}'),
                Text('Created: ${file.formattedDate}'),
                if (file.isEncrypted)
                  Text(
                    'Encrypted',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleFileAction(action, file),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performExport() async {
    // Validate encryption settings
    if (_encryptExport && _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter a password for encryption');
      return;
    }

    try {
      final result = await _exportService.exportAllData(
        includeSettings: _includeSettings,
        encrypt: _encryptExport,
        password: _encryptExport ? _passwordController.text : null,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
      );

      if (result.success) {
        _showSuccessDialog(result);
        _loadExportFiles(); // Refresh file list
        _clearExportForm();
      } else {
        _showErrorSnackBar(result.error ?? 'Export failed');
      }
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    }
  }

  Future<void> _performImport() async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['spiral', 'enc', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        // Show import confirmation dialog
        _showImportConfirmationDialog(filePath);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select file: $e');
    }
  }

  Future<void> _handleFileAction(String action, ExportFileInfo file) async {
    switch (action) {
      case 'share':
        try {
          await _exportService.shareExportFile(file.path);
        } catch (e) {
          _showErrorSnackBar('Failed to share file: $e');
        }
        break;
      case 'delete':
        _showDeleteConfirmation(file);
        break;
    }
  }

  void _showDeleteConfirmation(ExportFileInfo file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Export File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _exportService.deleteExportFile(file.path);
                _loadExportFiles();
                _showSuccessSnackBar('File deleted successfully');
              } catch (e) {
                _showErrorSnackBar('Failed to delete file: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(ExportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your data has been exported successfully!'),
            if (result.statistics != null) ...[
              const SizedBox(height: 16),
              Text('Export Details:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text('• ${result.statistics!.totalEntries} journal entries'),
              Text('• ${result.statistics!.totalCores} emotional cores'),
              Text('• Size: ${result.statistics!.formattedSize}'),
              if (result.isEncrypted)
                Text('• Encrypted with password', style: TextStyle(color: Colors.green[700])),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (result.filePath != null)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _exportService.shareExportFile(result.filePath!);
              },
              child: const Text('Share'),
            ),
        ],
      ),
    );
  }

  void _clearExportForm() {
    _passwordController.clear();
    _descriptionController.clear();
    setState(() {
      _encryptExport = false;
      _includeSettings = true;
    });
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

  void _showImportConfirmationDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restore, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            const Text('Import Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import data from: ${filePath.split('/').last}'),
            const SizedBox(height: 16),
            if (!_mergeWithExisting) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will replace ALL your current data!',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _mergeWithExisting 
                  ? 'Imported data will be merged with your existing entries.'
                  : 'All current data will be permanently replaced.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _executeImport(filePath);
            },
            style: TextButton.styleFrom(
              foregroundColor: _mergeWithExisting ? AppTheme.primaryOrange : Colors.red,
            ),
            child: Text(_mergeWithExisting ? 'Import & Merge' : 'Replace All Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeImport(String filePath) async {
    try {
      final result = await _exportService.importData(
        filePath,
        password: _importPasswordController.text.isNotEmpty 
            ? _importPasswordController.text 
            : null,
        mergeWithExisting: _mergeWithExisting,
      );

      if (result.success) {
        _showImportSuccessDialog(result);
        _clearImportForm();
      } else {
        _showErrorSnackBar(result.error ?? 'Import failed');
      }
    } catch (e) {
      _showErrorSnackBar('Import failed: $e');
    }
  }

  void _showImportSuccessDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Import Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mergeWithExisting 
                ? 'Your data has been imported and merged successfully!'
                : 'Your data has been imported and replaced successfully!'),
            if (result.statistics != null) ...[
              const SizedBox(height: 16),
              Text('Import Details:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text('• ${result.statistics!.totalEntries} journal entries'),
              Text('• ${result.statistics!.totalCores} emotional cores'),
              Text('• Size: ${result.statistics!.formattedSize}'),
            ],
            if (result.hasWarnings) ...[
              const SizedBox(height: 16),
              Text('Warnings:', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.orange[700],
              )),
              const SizedBox(height: 8),
              ...result.warnings.map((warning) => Text(
                '• $warning',
                style: TextStyle(color: Colors.orange[700]),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearImportForm() {
    _importPasswordController.clear();
    setState(() {
      _mergeWithExisting = false;
    });
  }
}