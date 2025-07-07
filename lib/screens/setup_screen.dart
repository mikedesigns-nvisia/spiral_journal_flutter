import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

/// Setup screen for configuring API keys and initial app setup
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  
  bool _isLoading = false;
  bool _showApiKey = false;
  String? _errorMessage;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and welcome
                const Icon(
                  Icons.psychology,
                  size: 80,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Welcome to Spiral Journal',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Your AI-powered personal growth companion',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Setup sections
                _buildSetupSection(),
                
                const SizedBox(height: 32),
                
                // Action buttons
                _buildActionButtons(),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Claude API Key Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smart_toy, color: AppTheme.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Claude AI Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Enter your Claude API key to enable AI-powered journal analysis and insights.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: !_showApiKey,
                  decoration: InputDecoration(
                    labelText: 'Claude API Key',
                    hintText: 'sk-ant-...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your Claude API key';
                    }
                    if (!value!.startsWith('sk-ant-')) {
                      return 'Invalid Claude API key format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: _launchClaudeApiHelp,
                  child: Text(
                    'Need help getting your API key? →',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Demo Mode Option
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Demo Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Try the app with limited features. You can add AI analysis later.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _setupWithApiKey,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Setup with AI Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        
        const SizedBox(height: 12),
        
        OutlinedButton(
          onPressed: _isLoading ? null : _setupDemoMode,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Continue in Demo Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _setupWithApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final configService = context.read<ConfigService>();
      
      // Save API key
      await configService.setClaudeApiKey(_apiKeyController.text.trim());
      await configService.setFirebaseConfigured(true);
      await configService.setDemoMode(false);
      
      // Test Firebase connection
      final firebaseService = context.read<FirebaseService>();
      await firebaseService.signInAnonymously();
      
      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Setup failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _setupDemoMode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final configService = context.read<ConfigService>();
      
      // Configure demo mode
      await configService.setDemoMode(true);
      await configService.setFirebaseConfigured(true);
      await configService.setAnalysisEnabled(false);
      
      // Test Firebase connection
      final firebaseService = context.read<FirebaseService>();
      await firebaseService.signInAnonymously();
      
      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Demo setup failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _launchClaudeApiHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Getting Your Claude API Key'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('To get your Claude API key:'),
              SizedBox(height: 12),
              Text('1. Visit console.anthropic.com'),
              Text('2. Sign up or log in to your account'),
              Text('3. Navigate to API Keys section'),
              Text('4. Create a new API key'),
              Text('5. Copy the key (starts with "sk-ant-")'),
              SizedBox(height: 12),
              Text(
                'Note: You\'ll need to add credits to your Anthropic account to use the API.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
