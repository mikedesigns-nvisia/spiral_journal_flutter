import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/emotional_mirror_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (context) => EmotionalMirrorProvider()..initialize(),
        child: TestScreen(),
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Provider Test')),
      body: Consumer<EmotionalMirrorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Provider is working!'),
                Text('Mirror data: ${provider.mirrorData != null ? 'Loaded' : 'Not loaded'}'),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: Text('Refresh'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}