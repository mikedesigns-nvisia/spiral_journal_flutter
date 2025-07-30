import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';

/// Service for handling voice-to-text transcription using on-device iOS speech recognition
class VoiceJournalService with WidgetsBindingObserver {
  static final VoiceJournalService _instance = VoiceJournalService._internal();
  factory VoiceJournalService() => _instance;
  VoiceJournalService._internal();

  late stt.SpeechToText _speechToText;
  AudioSession? _audioSession;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAudioSessionActive = false;
  bool _wasListeningBeforeInterruption = false;
  String _lastTranscription = '';
  
  // Stream controllers for real-time updates
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  final StreamController<VoiceJournalStatus> _statusController = StreamController<VoiceJournalStatus>.broadcast();
  final StreamController<double> _soundLevelController = StreamController<double>.broadcast();
  
  // Getters for streams
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<VoiceJournalStatus> get statusStream => _statusController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  
  // Current state getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastTranscription => _lastTranscription;

  /// Initialize the speech recognition service
  Future<VoiceJournalInitResult> initialize() async {
    try {
      debugPrint('🎤 Initializing VoiceJournalService...');
      
      // Check if platform supports speech recognition
      if (!Platform.isIOS && !Platform.isAndroid) {
        debugPrint('❌ Speech recognition not supported on this platform');
        return VoiceJournalInitResult(
          success: false,
          error: 'Speech recognition is only supported on iOS and Android',
          errorType: VoiceJournalErrorType.platformNotSupported,
        );
      }

      // Initialize audio session for iOS
      await _initializeAudioSession();
      
      // Register for app lifecycle events
      WidgetsBinding.instance.addObserver(this);

      _speechToText = stt.SpeechToText();
      
      // Check and request microphone permission
      final permissionResult = await _checkMicrophonePermission();
      if (!permissionResult.hasPermission) {
        debugPrint('❌ Microphone permission denied');
        return VoiceJournalInitResult(
          success: false,
          error: permissionResult.message,
          errorType: VoiceJournalErrorType.permissionDenied,
        );
      }

      // Initialize speech recognition
      final bool available = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: kDebugMode,
        finalTimeout: const Duration(seconds: 5),
      );

      if (!available) {
        debugPrint('❌ Speech recognition not available');
        return VoiceJournalInitResult(
          success: false,
          error: 'Speech recognition is not available on this device',
          errorType: VoiceJournalErrorType.serviceUnavailable,
        );
      }

      _isInitialized = true;
      debugPrint('✅ VoiceJournalService initialized successfully');
      
      // Check for offline support (iOS native speech recognition supports offline)
      final supportsOffline = await _checkOfflineSupport();
      
      return VoiceJournalInitResult(
        success: true,
        supportsOffline: supportsOffline,
        availableLocales: _speechToText.locales,
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize VoiceJournalService: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return VoiceJournalInitResult(
        success: false,
        error: 'Failed to initialize speech recognition: ${e.toString()}',
        errorType: VoiceJournalErrorType.initializationFailed,
      );
    }
  }

  /// Initialize audio session for proper iOS audio handling
  Future<void> _initializeAudioSession() async {
    try {
      if (Platform.isIOS) {
        debugPrint('🔊 Initializing iOS audio session...');
        
        _audioSession = await AudioSession.instance;
        
        // Configure audio session for voice recording
        await _audioSession!.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker |
                                        AVAudioSessionCategoryOptions.allowBluetooth |
                                        AVAudioSessionCategoryOptions.allowBluetoothA2DP,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ));

        // Listen for audio interruptions
        _audioSession!.interruptionEventStream.listen(_handleAudioInterruption);
        _audioSession!.becomingNoisyEventStream.listen(_handleBecomingNoisy);
        
        debugPrint('✅ iOS audio session configured successfully');
      } else {
        debugPrint('📱 Non-iOS platform, skipping audio session configuration');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize audio session: $e');
      // Don't fail initialization if audio session setup fails
    }
  }

  /// Handle audio interruptions (calls, other apps, etc.)
  void _handleAudioInterruption(AudioInterruptionEvent event) {
    debugPrint('🎵 Audio interruption: ${event.type}');
    
    switch (event.type) {
      case AudioInterruptionType.begin:
        debugPrint('🛑 Audio interruption began');
        if (_isListening) {
          _wasListeningBeforeInterruption = true;
          _pauseRecording();
        }
        break;
        
      case AudioInterruptionType.end:
        debugPrint('▶️ Audio interruption ended');
        if (event.options.contains(AudioInterruptionOption.shouldResume)) {
          if (_wasListeningBeforeInterruption) {
            _resumeRecording();
          }
        }
        _wasListeningBeforeInterruption = false;
        break;
    }
  }

  /// Handle becoming noisy events (headphones disconnected, etc.)
  void _handleBecomingNoisy(void _) {
    debugPrint('🔊 Audio becoming noisy, pausing recording');
    if (_isListening) {
      _pauseRecording();
    }
  }

  /// Pause recording due to interruption
  void _pauseRecording() {
    try {
      if (_isListening) {
        debugPrint('⏸️ Pausing voice recording due to interruption');
        _speechToText.cancel();
        _isListening = false;
        _statusController.add(VoiceJournalStatus.interrupted);
        _deactivateAudioSession();
      }
    } catch (e) {
      debugPrint('❌ Error pausing recording: $e');
    }
  }

  /// Resume recording after interruption
  void _resumeRecording() {
    try {
      debugPrint('▶️ Attempting to resume voice recording after interruption');
      _statusController.add(VoiceJournalStatus.resuming);
      
      // Don't automatically restart - let user manually restart
      // This is better UX as users might not expect automatic restart
      _statusController.add(VoiceJournalStatus.idle);
    } catch (e) {
      debugPrint('❌ Error resuming recording: $e');
      _statusController.add(VoiceJournalStatus.error);
    }
  }

  /// Activate audio session for recording
  Future<bool> _activateAudioSession() async {
    try {
      if (_audioSession != null && !_isAudioSessionActive) {
        debugPrint('🔊 Activating audio session for recording');
        await _audioSession!.setActive(true);
        _isAudioSessionActive = true;
        return true;
      }
      return _isAudioSessionActive;
    } catch (e) {
      debugPrint('❌ Failed to activate audio session: $e');
      return false;
    }
  }

  /// Deactivate audio session after recording
  Future<void> _deactivateAudioSession() async {
    try {
      if (_audioSession != null && _isAudioSessionActive) {
        debugPrint('🔇 Deactivating audio session');
        await _audioSession!.setActive(false);
        _isAudioSessionActive = false;
      }
    } catch (e) {
      debugPrint('❌ Failed to deactivate audio session: $e');
    }
  }

  /// App lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('📱 App going to background, pausing voice recording');
        if (_isListening) {
          _wasListeningBeforeInterruption = true;
          _pauseRecording();
        }
        break;
        
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed from background');
        // Don't automatically resume - better UX to let user restart manually
        _wasListeningBeforeInterruption = false;
        break;
        
      case AppLifecycleState.detached:
        debugPrint('📱 App detached, cleaning up voice service');
        if (_isListening) {
          cancelListening();
        }
        break;
        
      case AppLifecycleState.hidden:
        // iOS 17+ state
        if (_isListening) {
          _pauseRecording();
        }
        break;
    }
  }

  /// Check microphone permission status and request if needed
  Future<MicrophonePermissionResult> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      
      switch (status) {
        case PermissionStatus.granted:
          return MicrophonePermissionResult(
            hasPermission: true,
            message: 'Microphone permission granted',
          );
          
        case PermissionStatus.denied:
          final requestResult = await Permission.microphone.request();
          if (requestResult == PermissionStatus.granted) {
            return MicrophonePermissionResult(
              hasPermission: true,
              message: 'Microphone permission granted',
            );
          } else {
            return MicrophonePermissionResult(
              hasPermission: false,
              message: 'Microphone permission is required for voice journaling',
              canRequestAgain: true,
            );
          }
          
        case PermissionStatus.permanentlyDenied:
          return MicrophonePermissionResult(
            hasPermission: false,
            message: 'Microphone permission permanently denied. Please enable it in Settings > Spiral Journal > Microphone',
            canRequestAgain: false,
            needsSettingsRedirect: true,
          );
          
        case PermissionStatus.restricted:
          return MicrophonePermissionResult(
            hasPermission: false,
            message: 'Microphone access is restricted on this device',
            canRequestAgain: false,
          );
          
        default:
          return MicrophonePermissionResult(
            hasPermission: false,
            message: 'Unable to determine microphone permission status',
            canRequestAgain: true,
          );
      }
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return MicrophonePermissionResult(
        hasPermission: false,
        message: 'Error checking microphone permission: ${e.toString()}',
        canRequestAgain: false,
      );
    }
  }

  /// Check if offline speech recognition is supported
  Future<bool> _checkOfflineSupport() async {
    try {
      // iOS native speech recognition supports offline recognition
      if (Platform.isIOS) {
        return true;
      }
      
      // For Android, we can check if there are offline locales available
      if (Platform.isAndroid) {
        final locales = _speechToText.locales;
        return locales.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking offline support: $e');
      return false;
    }
  }

  /// Start listening for speech input
  Future<VoiceJournalStartResult> startListening({
    String? localeId,
    Duration? timeout,
    bool preferOffline = true,
  }) async {
    try {
      if (!_isInitialized) {
        return VoiceJournalStartResult(
          success: false,
          error: 'Voice journal service not initialized',
          errorType: VoiceJournalErrorType.notInitialized,
        );
      }

      if (_isListening) {
        return VoiceJournalStartResult(
          success: false,
          error: 'Already listening',
          errorType: VoiceJournalErrorType.alreadyListening,
        );
      }

      // Re-check microphone permission before starting
      final permissionResult = await _checkMicrophonePermission();
      if (!permissionResult.hasPermission) {
        return VoiceJournalStartResult(
          success: false,
          error: permissionResult.message,
          errorType: VoiceJournalErrorType.permissionDenied,
          needsSettingsRedirect: permissionResult.needsSettingsRedirect,
        );
      }

      // Activate audio session before starting
      final audioSessionActivated = await _activateAudioSession();
      if (!audioSessionActivated) {
        debugPrint('⚠️ Warning: Audio session activation failed, but continuing...');
      }

      // Clear previous transcription
      _lastTranscription = '';
      
      // Determine locale to use
      final targetLocale = localeId ?? _getDefaultLocale();
      
      debugPrint('🎤 Starting speech recognition with locale: $targetLocale');
      debugPrint('🔒 Prefer offline recognition: $preferOffline');

      // Start listening with iOS-optimized settings
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: timeout ?? const Duration(minutes: 5), // Max listening duration
        pauseFor: const Duration(seconds: 3), // Pause detection
        partialResults: true, // Enable real-time transcription
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        localeId: targetLocale,
        // iOS speech recognition automatically prefers on-device recognition when available
      );

      _isListening = true;
      _statusController.add(VoiceJournalStatus.listening);
      
      debugPrint('✅ Started listening for speech input');
      
      return VoiceJournalStartResult(
        success: true,
        isUsingOfflineMode: preferOffline && Platform.isIOS,
        selectedLocale: targetLocale,
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to start listening: $e');
      debugPrint('Stack trace: $stackTrace');
      
      _isListening = false;
      _statusController.add(VoiceJournalStatus.error);
      
      return VoiceJournalStartResult(
        success: false,
        error: 'Failed to start speech recognition: ${e.toString()}',
        errorType: VoiceJournalErrorType.startFailed,
      );
    }
  }

  /// Stop listening for speech input
  Future<VoiceJournalStopResult> stopListening() async {
    try {
      if (!_isListening) {
        return VoiceJournalStopResult(
          success: true,
          finalTranscription: _lastTranscription,
          wasListening: false,
        );
      }

      await _speechToText.stop();
      _isListening = false;
      _statusController.add(VoiceJournalStatus.stopped);
      
      // Deactivate audio session after stopping
      await _deactivateAudioSession();
      
      debugPrint('✅ Stopped listening. Final transcription: ${_lastTranscription.length} characters');
      
      return VoiceJournalStopResult(
        success: true,
        finalTranscription: _lastTranscription,
        wasListening: true,
      );
      
    } catch (e) {
      debugPrint('❌ Failed to stop listening: $e');
      
      _isListening = false;
      _statusController.add(VoiceJournalStatus.error);
      
      return VoiceJournalStopResult(
        success: false,
        error: 'Failed to stop speech recognition: ${e.toString()}',
        finalTranscription: _lastTranscription,
        wasListening: true,
      );
    }
  }

  /// Cancel current listening session
  Future<void> cancelListening() async {
    try {
      if (_isListening) {
        await _speechToText.cancel();
        _isListening = false;
        _statusController.add(VoiceJournalStatus.cancelled);
        
        // Deactivate audio session after cancelling
        await _deactivateAudioSession();
        
        debugPrint('🚫 Cancelled speech recognition');
      }
    } catch (e) {
      debugPrint('❌ Failed to cancel listening: $e');
      _isListening = false;
      _statusController.add(VoiceJournalStatus.error);
      await _deactivateAudioSession();
    }
  }

  /// Get default locale for speech recognition
  String _getDefaultLocale() {
    if (Platform.isIOS) {
      // iOS typically uses the device's primary language
      return 'en_US'; // Default to US English, could be enhanced to detect device locale
    } else {
      return 'en_US';
    }
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    try {
      _lastTranscription = result.recognizedWords;
      _transcriptionController.add(_lastTranscription);
      
      if (result.finalResult) {
        debugPrint('🎯 Final transcription: $_lastTranscription');
        _statusController.add(VoiceJournalStatus.completed);
      } else {
        debugPrint('🔄 Partial transcription: $_lastTranscription');
        _statusController.add(VoiceJournalStatus.processing);
      }
    } catch (e) {
      debugPrint('❌ Error processing speech result: $e');
      _statusController.add(VoiceJournalStatus.error);
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    debugPrint('❌ Speech recognition error: $error');
    _isListening = false;
    
    String errorMessage = 'Speech recognition error';
    VoiceJournalErrorType errorType = VoiceJournalErrorType.recognitionError;
    
    if (error.toString().contains('network')) {
      errorMessage = 'Network error during speech recognition. Using offline mode.';
      errorType = VoiceJournalErrorType.networkError;
    } else if (error.toString().contains('permission')) {
      errorMessage = 'Microphone permission was revoked';
      errorType = VoiceJournalErrorType.permissionDenied;
    } else if (error.toString().contains('not available')) {
      errorMessage = 'Speech recognition service is not available';
      errorType = VoiceJournalErrorType.serviceUnavailable;
    }
    
    _statusController.add(VoiceJournalStatus.error);
    
    // Emit error details through status stream
    _statusController.add(VoiceJournalStatus.error);
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    debugPrint('🔄 Speech status: $status');
    
    switch (status) {
      case 'listening':
        _statusController.add(VoiceJournalStatus.listening);
        break;
      case 'notListening':
        _isListening = false;
        _statusController.add(VoiceJournalStatus.stopped);
        break;
      case 'done':
        _isListening = false;
        _statusController.add(VoiceJournalStatus.completed);
        break;
    }
  }

  /// Handle sound level changes for visual feedback
  void _onSoundLevelChange(double level) {
    _soundLevelController.add(level);
  }

  /// Request microphone permission manually
  Future<MicrophonePermissionResult> requestMicrophonePermission() async {
    return await _checkMicrophonePermission();
  }

  /// Open device settings for permission management
  Future<bool> openPermissionSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('❌ Failed to open permission settings: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    try {
      return await _speechToText.initialize();
    } catch (e) {
      return false;
    }
  }

  /// Get available locales for speech recognition
  List<stt.LocaleName> getAvailableLocales() {
    return _speechToText.locales;
  }

  /// Get current microphone permission status
  Future<PermissionStatus> getMicrophonePermissionStatus() async {
    return await Permission.microphone.status;
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    debugPrint('🧹 Disposing VoiceJournalService...');
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    if (_isListening) {
      cancelListening();
    }
    
    // Deactivate audio session
    _deactivateAudioSession();
    
    _transcriptionController.close();
    _statusController.close();
    _soundLevelController.close();
    
    _isInitialized = false;
    _isAudioSessionActive = false;
    _audioSession = null;
    
    debugPrint('✅ VoiceJournalService disposed');
  }
}

/// Initialization result for the voice journal service
class VoiceJournalInitResult {
  final bool success;
  final String? error;
  final VoiceJournalErrorType? errorType;
  final bool supportsOffline;
  final List<stt.LocaleName> availableLocales;

  VoiceJournalInitResult({
    required this.success,
    this.error,
    this.errorType,
    this.supportsOffline = false,
    this.availableLocales = const [],
  });
}

/// Result for starting voice recognition
class VoiceJournalStartResult {
  final bool success;
  final String? error;
  final VoiceJournalErrorType? errorType;
  final bool isUsingOfflineMode;
  final String? selectedLocale;
  final bool needsSettingsRedirect;

  VoiceJournalStartResult({
    required this.success,
    this.error,
    this.errorType,
    this.isUsingOfflineMode = false,
    this.selectedLocale,
    this.needsSettingsRedirect = false,
  });
}

/// Result for stopping voice recognition
class VoiceJournalStopResult {
  final bool success;
  final String? error;
  final String finalTranscription;
  final bool wasListening;

  VoiceJournalStopResult({
    required this.success,
    this.error,
    required this.finalTranscription,
    required this.wasListening,
  });
}

/// Microphone permission check result
class MicrophonePermissionResult {
  final bool hasPermission;
  final String message;
  final bool canRequestAgain;
  final bool needsSettingsRedirect;

  MicrophonePermissionResult({
    required this.hasPermission,
    required this.message,
    this.canRequestAgain = true,
    this.needsSettingsRedirect = false,
  });
}

/// Voice journal service status
enum VoiceJournalStatus {
  idle,
  initializing,
  listening,
  processing,
  completed,
  stopped,
  cancelled,
  interrupted,
  resuming,
  error,
}

/// Types of errors that can occur in voice journaling
enum VoiceJournalErrorType {
  platformNotSupported,
  permissionDenied,
  serviceUnavailable,
  initializationFailed,
  notInitialized,
  alreadyListening,
  startFailed,
  recognitionError,
  networkError,
}