import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/setup_screen.dart';
import 'services/firebase_service.dart';
import 'services/claude_ai_service.dart';
import 'services/analysis_service.dart';
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize configuration
  final configService = await ConfigService.getInstance();
  
  runApp(MyApp(configService: configService));
}

class MyApp extends StatelessWidget {
  final ConfigService configService;

  const MyApp({super.key, required this.configService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase Service
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        
        // Claude AI Service (lazy initialization with API key)
        Provider<ClaudeAIService?>(
          create: (_) {
            final apiKey = configService.getClaudeApiKey();
            return apiKey != null ? ClaudeAIService(apiKey: apiKey) : null;
          },
        ),
        
        // Analysis Service (depends on both Firebase and Claude)
        ChangeNotifierProvider<AnalysisService>(
          create: (context) {
            final firebaseService = context.read<FirebaseService>();
            final claudeService = context.read<ClaudeAIService?>();
            
            if (claudeService != null) {
              return AnalysisService(
                claudeService: claudeService,
                firebaseService: firebaseService,
              );
            } else {
              // Create a fallback service for demo mode
              return AnalysisService(
                claudeService: ClaudeAIService(apiKey: 'demo'), // Will fail gracefully
                firebaseService: firebaseService,
              );
            }
          },
        ),
        
        // Configuration Service
        Provider<ConfigService>.value(value: configService),
      ],
      child: const SpiralJournalApp(),
    );
  }
}

class SpiralJournalApp extends StatelessWidget {
  const SpiralJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spiral Journal',
      theme: AppTheme.lightTheme,
      home: Consumer<ConfigService>(
        builder: (context, configService, _) {
          // Check if app needs setup
          if (!configService.canRunDemo) {
            return const SetupScreen();
          }
          
          // App is configured, go to main screen
          return const MainScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
