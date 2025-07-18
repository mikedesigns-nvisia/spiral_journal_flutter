import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spiral_journal/services/dev_config_service.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/theme/app_theme.dart';

/// Development-only AI settings screen
/// This screen is only accessible in debug builds
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final DevConfigService _devService = DevConfigService();
  final AIServiceManager _aiManager = AIServiceManager();
  final TextEditingController _apiKeyController = TextEditingController();
  
  bool _isLoading = false;
  bool _devModeEnabled = false;
  bool _hasApiKey = false;
  bool _apiKeyValid = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadDevStatus();
  }

  Future<void> _loadDevStatus() async {
    if (!kDebugMode) {
      // This screen should never be accessible in production
      Navigator.of(context).pop();
      return;
    }

    final status = await _devService.getDevStatus();
    final apiKey = await _devService.getDevClaudeApiKey();
    
    setState(() {
      _devModeEnabled = status['devModeEnabled'] ?? false;
      _hasApiKey = status['hasApiKey'] ?? false;
      _apiKeyValid = status['apiKeyValid'] ?? false;
      
      if (apiKey != null && apiKey.isNotEmpty) {
        // Show only first and last 4 characters for security
        _apiKeyController.text = '${apiKey.substring(0, 7)}...${apiKey.substring(apiKey.length - 4)}';
      } else {
        _apiKeyController.clear();
      }
    });
    
    debugPrint('Dev status loaded: devModeEnabled=$_devModeEnabled, hasApiKey=$_hasApiKey, apiKeyValid=$_apiKeyValid');
  }

  Future<void> _toggleDevMode() async {
    debugPrint('Toggling dev mode from $_devModeEnabled to ${!_devModeEnabled}');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final newState = !_devModeEnabled;
      await _devService.setDevModeEnabled(newState);
      
      // Verify the state was actually set
      final actualState = await _devService.isDevModeEnabled();
      debugPrint('Dev mode set to: $newState, actual state: $actualState');
      
      await _aiManager.initialize(); // Reinitialize AI service
      
      setState(() {
        _devModeEnabled = actualState;
        _successMessage = _devModeEnabled 
            ? 'Development mode enabled' 
            : 'Development mode disabled';
      });
      
      // Reload full status
      await _loadDevStatus();
    } catch (e) {
      debugPrint('Error toggling dev mode: $e');
      setState(() {
        _errorMessage = 'Failed to toggle dev mode: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an API key';
      });
      return;
    }

    // Skip validation if it's the masked display (contains ...)
    if (apiKey.contains('...')) {
      setState(() {
        _errorMessage = 'Please enter a new API key or clear the existing one';
      });
      return;
    }

    if (!_devService.isValidClaudeApiKey(apiKey)) {
      setState(() {
        _errorMessage = 'Invalid Claude API key format. Should start with sk-ant-';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _devService.setDevClaudeApiKey(apiKey);
      await _aiManager.initialize(); // Reinitialize AI service with new key
      
      setState(() {
        _successMessage = 'API key saved successfully';
      });
      
      await _loadDevStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save API key: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _aiManager.testCurrentService();
      setState(() {
        _successMessage = 'Connection test successful!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearApiKey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _devService.setDevClaudeApiKey('');
      await _aiManager.initialize();
      
      setState(() {
        _successMessage = 'API key cleared';
      });
      
      _apiKeyController.clear();
      await _loadDevStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to clear API key: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Double-check we're in debug mode
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(
          child: Text('This screen is only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('AI Settings (Dev)'),
        backgroundColor: AppTheme.backgroundPrimary,
        foregroundColor: AppTheme.primaryOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Development Mode Only',
                          style: AppTheme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          'This screen is only available in debug builds and will not appear in production.',
                          style: AppTheme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Development Mode Toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Development Mode',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable development features including custom API key configuration.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _devModeEnabled ? 'Enabled' : 'Disabled',
                          style: AppTheme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _devModeEnabled ? Colors.green : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: _devModeEnabled,
                          onChanged: _isLoading ? null : (_) => _toggleDevMode(),
                          activeColor: AppTheme.primaryOrange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // API Key Configuration (always show, but disabled if dev mode not enabled)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Claude API Key',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _devModeEnabled ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _devModeEnabled 
                          ? 'Enter your Claude API key for testing. This is stored securely and only used in development.'
                          : 'Enable development mode above to configure API key.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _devModeEnabled ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // API Key Status
                    if (_devModeEnabled && _hasApiKey) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _apiKeyValid ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _apiKeyValid ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _apiKeyValid ? Icons.check_circle : Icons.error,
                              color: _apiKeyValid ? Colors.green.shade600 : Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _apiKeyValid ? 'API key configured' : 'Invalid API key format',
                              style: AppTheme.getTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: _apiKeyValid ? Colors.green.shade600 : Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // API Key Input
                    TextField(
                      controller: _apiKeyController,
                      enabled: _devModeEnabled,
                      decoration: InputDecoration(
                        labelText: 'Claude API Key',
                        hintText: _devModeEnabled ? 'sk-ant-...' : 'Enable dev mode first',
                        prefixIcon: Icon(
                          Icons.key,
                          color: _devModeEnabled ? null : Colors.grey,
                        ),
                        suffixIcon: _devModeEnabled && _hasApiKey ? IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _apiKeyController.clear();
                            setState(() {
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          tooltip: 'Enter new API key',
                        ) : null,
                      ),
                      obscureText: true,
                      onChanged: (_) {
                        setState(() {
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_isLoading || !_devModeEnabled) ? null : _saveApiKey,
                            child: const Text('Save API Key'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_devModeEnabled && _hasApiKey) ...[
                          ElevatedButton(
                            onPressed: _isLoading ? null : _testConnection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('Test'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _clearApiKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Show disabled state message when dev mode is off
            if (!_devModeEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'API key configuration is disabled. Enable development mode above to configure your Claude API key for testing.',
                        style: AppTheme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Messages
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTheme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: AppTheme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}